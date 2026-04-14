<?php
// /fitness_ws/resources/quiz.php

function handle_quiz(array $route): void {
    $id = $route['id'];
    switch (method()) {
        case 'GET':    $id ? get_quiz($id) : get_quiz_list(); break;
        case 'POST':   !$id ? create_quiz() : respond_method_not_allowed(); break;
        case 'DELETE': $id  ? delete_quiz($id) : respond_method_not_allowed(); break;
        default:       respond_method_not_allowed();
    }
}

// GET /quiz  (supporta ?utente_id=X come query param opzionale)
function get_quiz_list(): void {
    $uid = $_GET['utente_id'] ?? null;
    if ($uid) {
        $stmt = db()->prepare(
            'SELECT id, utente_id, obiettivo, livello, giorni_settimana, created_at FROM quiz WHERE utente_id = ? ORDER BY id DESC'
        );
        $stmt->execute([$uid]);
    } else {
        $stmt = db()->query(
            'SELECT id, utente_id, obiettivo, livello, giorni_settimana, created_at FROM quiz ORDER BY id DESC'
        );
    }
    respond_ok($stmt->fetchAll());
}

// GET /quiz/{id}
function get_quiz(string $id): void {
    $stmt = db()->prepare('SELECT * FROM quiz WHERE id = ?');
    $stmt->execute([$id]);
    $row = $stmt->fetch();
    $row ? respond_ok($row) : respond_not_found('Quiz non trovato');
}

// POST /quiz → salva quiz E genera la scheda AI
function create_quiz(): void {
    $b = get_body();
    $required = ['utente_id','obiettivo','livello','giorni_settimana','durata_sessione'];
    foreach ($required as $f) {
        if (!isset($b[$f])) respond_bad_request("Campo mancante: $f");
    }

    // 1. Salva il quiz
    try {
        $stmt = db()->prepare(
            'INSERT INTO quiz (utente_id, obiettivo, livello, giorni_settimana, durata_sessione, attrezzatura, limitazioni)
             VALUES (?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            (int)$b['utente_id'],
            $b['obiettivo'],
            $b['livello'],
            (int)$b['giorni_settimana'],
            (int)$b['durata_sessione'],
            $b['attrezzatura']  ?? 'nessuna',
            $b['limitazioni']   ?? '',
        ]);
        $quiz_id = (int)db()->lastInsertId();
    } catch (PDOException $e) {
        respond_server_error('Errore salvataggio quiz');
    }

    // 2. Chiama l'AI per generare la scheda
    try {
        $quiz_row = array_merge($b, ['id' => $quiz_id]);
        $prompt   = build_prompt($quiz_row);
        $ai_json  = call_ai($prompt);

        // Valida che sia JSON valido
        $decoded = json_decode($ai_json, true);
        if (!$decoded) throw new RuntimeException('JSON AI non valido');

        $titolo = $decoded['titolo'] ?? 'Scheda personalizzata';

        // 3. Salva la scheda
        $stmt2 = db()->prepare(
            'INSERT INTO schede (utente_id, quiz_id, titolo, contenuto, modello_ai) VALUES (?, ?, ?, ?, ?)'
        );
        $stmt2->execute([(int)$b['utente_id'], $quiz_id, $titolo, $ai_json, AI_MODEL]);
        $scheda_id = (int)db()->lastInsertId();

        respond_created([
            'quiz_id'   => $quiz_id,
            'scheda_id' => $scheda_id,
            'scheda'    => $decoded,
            'message'   => 'Quiz registrato e scheda generata',
        ]);
    } catch (RuntimeException $e) {
        // Quiz salvato ma AI fallita: restituiamo comunque il quiz_id
        respond(202, [
            'quiz_id' => $quiz_id,
            'warning' => 'Quiz salvato, ma generazione scheda fallita: ' . $e->getMessage(),
        ]);
    }
}

// DELETE /quiz/{id}
function delete_quiz(string $id): void {
    $stmt = db()->prepare('DELETE FROM quiz WHERE id = ?');
    $stmt->execute([$id]);
    $stmt->rowCount() ? respond_no_content() : respond_not_found('Quiz non trovato');
}