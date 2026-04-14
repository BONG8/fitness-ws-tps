<?php
// /fitness_ws/lib/config.php

// Caricamento variabili d'ambiente da file .env
$envFile = __DIR__ . '/../.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0 || strpos(trim($line), '=') === false) continue;
        list($name, $value) = explode('=', $line, 2);
        $_ENV[trim($name)] = trim($value);
    }
}

function env($name, $default = '') {
    return $_ENV[$name] ?? getenv($name) ?: $default;
}