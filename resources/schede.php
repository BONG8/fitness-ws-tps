<?php
// /fitness_ws/resources/schede.php

function handle_schede(array $route): void {
    require_auth();
    $id = $route['id'];
    switch (method()) {
        case 'GET':    $id ? get_scheda($id) : get_schede(); break;
        case 'DELETE': $id ? delete_scheda($id) : respond_method_not_allowed(); break;
        default:       respond_method_not_allowed();
    }
}

// GET /schede → solo schede dell'utente autenticato
function get_schede(): void {
    $u = require_auth();
    $stmt = db()->prepare(
        'SELECT id, utente_id, quiz_id, titolo, modello_ai, created_at
         FROM schede WHERE utente_id = ? ORDER BY id DESC'
    );
    $stmt->execute([$u['id']]);
    respond_ok($stmt->fetchAll());
}

// GET /schede/{id} → solo se owner
function get_scheda(string $id): void {
    $u = require_auth();
    $stmt = db()->prepare('SELECT * FROM schede WHERE id = ?');
    $stmt->execute([$id]);
    $row = $stmt->fetch();
    if (!$row) respond_not_found('Scheda non trovata');
    if ((int)$row['utente_id'] !== $u['id']) respond_forbidden();

    $row['contenuto'] = json_decode($row['contenuto'], true);
    respond_ok($row);
}

// DELETE /schede/{id}
function delete_scheda(string $id): void {
    $u = require_auth();
    $stmt = db()->prepare('SELECT utente_id FROM schede WHERE id = ?');
    $stmt->execute([$id]);
    $owner = $stmt->fetchColumn();
    if ($owner === false) respond_not_found('Scheda non trovata');
    if ((int)$owner !== $u['id']) respond_forbidden();

    $stmt = db()->prepare('DELETE FROM schede WHERE id = ?');
    $stmt->execute([$id]);
    respond_no_content();
}
