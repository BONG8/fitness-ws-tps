<?php
// /fitness_ws/resources/quiz.php

const QUIZ_OBIETTIVI = ['dimagrimento','massa','resistenza','mobilita','forza'];
const QUIZ_LIVELLI   = ['principiante','intermedio','avanzato'];

function handle_quiz(array $route): void {
    require_auth();
    $id = $route['id'];
    switch (method()) {
        case 'GET':    $id ? get_quiz($id) : get_quiz_list(); break;
        case 'POST':   !$id ? create_quiz() : respond_method_not_allowed(); break;
        case 'DELETE': $id  ? delete_quiz($id) : respond_method_not_allowed(); break;
        default:       respond_method_not_allowed();
    }
}

// GET /quiz → solo quiz dell'utente autenticato
function get_quiz_list(): void {
    $u = require_auth();
    $stmt = db()->prepare(
        'SELECT id, utente_id, obiettivo, livello, giorni_settimana, created_at
         FROM quiz WHERE utente_id = ? ORDER BY id DESC'
    );
    $stmt->execute([$u['id']]);
    respond_ok($stmt->fetchAll());
}

// GET /quiz/{id} → solo se owner
function get_quiz(string $id): void {
    $u = require_auth();
    $stmt = db()->prepare('SELECT * FROM quiz WHERE id = ?');
    $stmt->execute([$id]);
    $row = $stmt->fetch();
    if (!$row) respond_not_found('Quiz non trovato');
    if ((int)$row['utente_id'] !== $u['id']) respond_forbidden();
    respond_ok($row);
}

// POST /quiz
function create_quiz(): void {
    $u = require_auth();
    $b = get_body();

    $obiettivo       = v_enum($b['obiettivo'] ?? null, QUIZ_OBIETTIVI, 'obiettivo');
    $livello         = v_enum($b['livello']   ?? null, QUIZ_LIVELLI,   'livello');
    $giorni          = v_int_range($b['giorni_settimana'] ?? null, 1, 7, 'giorni_settimana');
    $durata          = v_int_range($b['durata_sessione']  ?? null, 10, 240, 'durata_sessione');
    $attrezzatura    = isset($b['attrezzatura']) ? v_string($b['attrezzatura'], 0, 255, 'attrezzatura') : 'nessuna';
    $limitazioni     = isset($b['limitazioni'])  ? v_string($b['limitazioni'],  0, 2000, 'limitazioni')  : '';

    // 1. Salva il quiz (utente_id preso dal token, mai dal body)
    try {
        $stmt = db()->prepare(
            'INSERT INTO quiz (utente_id, obiettivo, livello, giorni_settimana, durata_sessione, attrezzatura, limitazioni)
             VALUES (?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([$u['id'], $obiettivo, $livello, $giorni, $durata, $attrezzatura, $limitazioni]);
        $quiz_id = (int)db()->lastInsertId();
    } catch (PDOException $e) {
        respond_server_error('Errore salvataggio quiz', $e);
    }

    // 2. AI → scheda
    try {
        $quiz_row = [
            'id'                => $quiz_id,
            'obiettivo'         => $obiettivo,
            'livello'           => $livello,
            'giorni_settimana'  => $giorni,
            'durata_sessione'   => $durata,
            'attrezzatura'      => $attrezzatura,
            'limitazioni'       => $limitazioni,
        ];
        $prompt   = build_prompt($quiz_row);
        $ai_json  = call_ai($prompt);

        $decoded = json_decode($ai_json, true);
        if (!$decoded) throw new RuntimeException('JSON AI non valido');

        $titolo = $decoded['titolo'] ?? 'Scheda personalizzata';

        $stmt2 = db()->prepare(
            'INSERT INTO schede (utente_id, quiz_id, titolo, contenuto, modello_ai) VALUES (?, ?, ?, ?, ?)'
        );
        $stmt2->execute([$u['id'], $quiz_id, $titolo, $ai_json, AI_MODEL]);
        $scheda_id = (int)db()->lastInsertId();

        respond_created([
            'quiz_id'   => $quiz_id,
            'scheda_id' => $scheda_id,
            'scheda'    => $decoded,
            'message'   => 'Quiz registrato e scheda generata',
        ]);
    } catch (RuntimeException $e) {
        error_log('[AI] ' . $e->getMessage());
        respond(202, [
            'quiz_id' => $quiz_id,
            'warning' => 'Quiz salvato, ma generazione scheda fallita',
        ]);
    }
}

// DELETE /quiz/{id}
function delete_quiz(string $id): void {
    $u = require_auth();
    $stmt = db()->prepare('SELECT utente_id FROM quiz WHERE id = ?');
    $stmt->execute([$id]);
    $owner = $stmt->fetchColumn();
    if ($owner === false) respond_not_found('Quiz non trovato');
    if ((int)$owner !== $u['id']) respond_forbidden();

    $stmt = db()->prepare('DELETE FROM quiz WHERE id = ?');
    $stmt->execute([$id]);
    respond_no_content();
}
