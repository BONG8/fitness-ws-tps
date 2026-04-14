<?php
// /fitness_ws/resources/utenti.php

function handle_utenti(array $route): void {
    $id = $route['id'];
    switch (method()) {
        case 'GET':    $id ? get_utente($id)  : get_utenti();   break;
        case 'POST':   !$id ? create_utente() : respond_method_not_allowed(); break;
        case 'PUT':    $id  ? update_utente($id) : respond_method_not_allowed(); break;
        case 'DELETE': $id  ? delete_utente($id) : respond_method_not_allowed(); break;
        default:       respond_method_not_allowed();
    }
}

// GET /utenti → lista parziale (id, nome, email)
function get_utenti(): void {
    $rows = db()->query('SELECT id, nome, email FROM utenti ORDER BY id')->fetchAll();
    respond_ok($rows);
}

// GET /utenti/{id} → dettaglio completo
function get_utente(string $id): void {
    $stmt = db()->prepare('SELECT * FROM utenti WHERE id = ?');
    $stmt->execute([$id]);
    $row = $stmt->fetch();
    $row ? respond_ok($row) : respond_not_found('Utente non trovato');
}

// POST /utenti → crea utente
function create_utente(): void {
    $b = get_body();
    if (empty($b['nome']) || empty($b['email']) || empty($b['eta']) || empty($b['sesso'])) {
        respond_bad_request('Campi obbligatori: nome, email, eta, sesso');
    }
    try {
        $stmt = db()->prepare(
            'INSERT INTO utenti (nome, email, eta, sesso) VALUES (?, ?, ?, ?)'
        );
        $stmt->execute([$b['nome'], $b['email'], (int)$b['eta'], $b['sesso']]);
        respond_created(['id' => (int)db()->lastInsertId(), 'message' => 'Utente creato']);
    } catch (PDOException $e) {
        if ($e->getCode() === '23000') {
            respond_conflict('Email già in uso');
        }
        respond_server_error($e->getMessage());
    }
}

// PUT /utenti/{id} → aggiornamento completo
function update_utente(string $id): void {
    $b = get_body();
    if (empty($b['nome']) || empty($b['email']) || empty($b['eta']) || empty($b['sesso'])) {
        respond_bad_request('Campi obbligatori: nome, email, eta, sesso');
    }
    $stmt = db()->prepare(
        'UPDATE utenti SET nome=?, email=?, eta=?, sesso=? WHERE id=?'
    );
    $stmt->execute([$b['nome'], $b['email'], (int)$b['eta'], $b['sesso'], $id]);
    $stmt->rowCount() ? respond_ok(['message' => 'Aggiornato']) : respond_not_found('Utente non trovato');
}

// DELETE /utenti/{id}
function delete_utente(string $id): void {
    $stmt = db()->prepare('DELETE FROM utenti WHERE id = ?');
    $stmt->execute([$id]);
    $stmt->rowCount() ? respond_no_content() : respond_not_found('Utente non trovato');
}