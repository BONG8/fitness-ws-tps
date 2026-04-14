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

define('DB_HOST', env('DB_HOST', '127.0.0.1'));
define('DB_NAME', env('DB_NAME', 'fitness_db'));
define('DB_USER', env('DB_USER', 'fitness_user'));
define('DB_PASS', env('DB_PASS', 'fitness_password'));
define('DB_CHARSET', env('DB_CHARSET', 'utf8mb4'));

// OpenRouter — registrarsi su https://openrouter.ai
define('OPENROUTER_API_KEY', env('OPENROUTER_API_KEY', ''));
define('OPENROUTER_URL', env('OPENROUTER_URL', 'https://openrouter.ai/api/v1/chat/completions'));
// Modello da usare (cambiabile facilmente):
// "google/gemini-flash-1.5", "openai/gpt-4o-mini", "anthropic/claude-haiku"
define('AI_MODEL', env('AI_MODEL', 'z-ai/glm-4.5-air:free'));

define('APP_NAME', env('APP_NAME', 'FitnessWS'));