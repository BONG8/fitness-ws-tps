<?php
// /fitness_ws/resources/schede.php

function handle_schede(array $route): void {
    $id = $route['id'];
    switch (method()) {
        case 'GET':    $id ? get_scheda($id) : get_schede(); break;
        case 'DELETE': $id ? delete_scheda($id) : respond_method_not_allowed(); break;
        default:       respond_method_not_allowed();
    }
}

// GET /schede  (supporta ?utente_id=X)
function get_schede(): void {
    $uid = $_GET['utente_id'] ?? null;
    if ($uid) {
        $stmt = db()->prepare(
            'SELECT id, utente_id, quiz_id, titolo, modello_ai, created_at FROM schede WHERE utente_id = ? ORDER BY id DESC'
        );
        $stmt->execute([$uid]);
    } else {
        $stmt = db()->query(
            'SELECT id, utente_id, quiz_id, titolo, modello_ai, created_at FROM schede ORDER BY id DESC'
        );
    }
    respond_ok($stmt->fetchAll());
}

// GET /schede/{id} → restituisce anche il contenuto AI (JSON già parsato)
function get_scheda(string $id): void {
    $stmt = db()->prepare('SELECT * FROM schede WHERE id = ?');
    $stmt->execute([$id]);
    $row = $stmt->fetch();
    if (!$row) respond_not_found('Scheda non trovata');
    
    // Restituisce il contenuto come oggetto già decodificato, non stringa
    $row['contenuto'] = json_decode($row['contenuto'], true);
    respond_ok($row);
}

// DELETE /schede/{id}
function delete_scheda(string $id): void {
    $stmt = db()->prepare('DELETE FROM schede WHERE id = ?');
    $stmt->execute([$id]);
    $stmt->rowCount() ? respond_no_content() : respond_not_found('Scheda non trovata');
}