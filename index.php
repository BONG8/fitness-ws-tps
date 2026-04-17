<?php
// /fitness_ws/index.php

require_once __DIR__ . '/lib/helpers.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if (method() === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$route = parse_route();

switch ($route['resource']) {
    case 'utenti':
        require_once __DIR__ . '/resources/utenti.php';
        handle_utenti($route);
        break;

    case 'login':
        require_once __DIR__ . '/resources/utenti.php';
        if (method() === 'POST') {
            login_utente();
        } else {
            respond_method_not_allowed();
        }
        break;

    case 'quiz':
        require_once __DIR__ . '/resources/quiz.php';
        handle_quiz($route);
        break;

    case 'schede':
        require_once __DIR__ . '/resources/schede.php';
        handle_schede($route);
        break;

    default:
        respond_not_found('Endpoint non trovato');
}