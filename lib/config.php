<?php
// /fitness_ws/lib/config.php

// Caricamento variabili d'ambiente da file .env
$envFile = __DIR__ . '/../.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        $trim = trim($line);
        if ($trim === '' || strpos($trim, '#') === 0 || strpos($trim, '=') === false) continue;
        list($name, $value) = explode('=', $line, 2);
        $name  = trim($name);
        $value = trim($value);
        // strip surrounding quotes
        if ((str_starts_with($value, '"') && str_ends_with($value, '"')) ||
            (str_starts_with($value, "'") && str_ends_with($value, "'"))) {
            $value = substr($value, 1, -1);
        }
        $_ENV[$name] = $value;
    }
}

function env($name, $default = '') {
    return $_ENV[$name] ?? (getenv($name) !== false ? getenv($name) : $default);
}

// ── App ────────────────────────────────────────────────
define('APP_NAME', env('APP_NAME', 'FitnessWS'));
define('APP_ENV',  env('APP_ENV', 'production')); // 'production' | 'development'

// ── Database ───────────────────────────────────────────
define('DB_HOST',    env('DB_HOST', '127.0.0.1'));
define('DB_NAME',    env('DB_NAME', 'fitness_db'));
define('DB_USER',    env('DB_USER', 'fitness_user'));
define('DB_PASS',    env('DB_PASS', ''));
define('DB_CHARSET', env('DB_CHARSET', 'utf8mb4'));

// ── JWT ────────────────────────────────────────────────
define('JWT_SECRET', env('JWT_SECRET', ''));
define('JWT_TTL',    (int)env('JWT_TTL', 86400)); // 24h default

// ── CORS ───────────────────────────────────────────────
// comma-separated list, or "*" for any (NOT recommended in prod)
define('ALLOWED_ORIGINS', env('ALLOWED_ORIGINS', ''));

// ── Rate limiting ──────────────────────────────────────
define('LOGIN_MAX_ATTEMPTS', (int)env('LOGIN_MAX_ATTEMPTS', 5));
define('LOGIN_WINDOW_SEC',   (int)env('LOGIN_WINDOW_SEC', 900)); // 15 min

// ── AI / OpenRouter ────────────────────────────────────
define('OPENROUTER_URL',     env('OPENROUTER_URL', 'https://openrouter.ai/api/v1/chat/completions'));
define('OPENROUTER_API_KEY', env('OPENROUTER_API_KEY', ''));
define('AI_MODEL',           env('AI_MODEL', 'google/gemini-flash-1.5'));
