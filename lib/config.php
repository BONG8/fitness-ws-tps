<?php
// /fitness_ws/lib/config.php

define('DB_HOST', '127.0.0.1');
define('DB_NAME', 'fitness_db');
define('DB_USER', 'fitness_user');
define('DB_PASS', 'fitness_password');
define('DB_CHARSET', 'utf8mb4');

// OpenRouter — registrarsi su https://openrouter.ai
define('OPENROUTER_API_KEY', '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');
define('OPENROUTER_URL', 'https://openrouter.ai/api/v1/chat/completions');
// Modello da usare (cambiabile facilmente):
// "google/gemini-flash-1.5", "openai/gpt-4o-mini", "anthropic/claude-haiku"
define('AI_MODEL', 'z-ai/glm-4.5-air:free');

define('APP_NAME', 'FitnessWS');