<?php
// /fitness_ws/lib/helpers.php

require_once __DIR__ . '/config.php';

/* ── Database ─────────────────────────────────────────── */

function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = sprintf('mysql:host=%s;dbname=%s;charset=%s', DB_HOST, DB_NAME, DB_CHARSET);
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
    }
    return $pdo;
}

/* ── HTTP Response ─────────────────────────────────────── */

function respond(int $status, mixed $data = null): void {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    if ($data !== null) {
        echo json_encode($data, JSON_UNESCAPED_UNICODE);
    }
    exit;
}

function respond_ok(mixed $data): void        { respond(200, $data); }
function respond_created(mixed $data): void   { respond(201, $data); }
function respond_no_content(): void           { respond(204); }
function respond_bad_request(string $msg): void  { respond(400, ['error' => $msg]); }
function respond_not_found(string $msg = 'Risorsa non trovata'): void { respond(404, ['error' => $msg]); }
function respond_method_not_allowed(): void   { respond(405, ['error' => 'Metodo non consentito']); }
function respond_server_error(string $msg = 'Errore interno'): void   { respond(500, ['error' => $msg]); }
function respond_conflict(string $msg): void  { respond(409, ['error' => $msg]); }

/* ── Request body ──────────────────────────────────────── */

function get_body(): array {
    $raw = file_get_contents('php://input');
    return json_decode($raw, true) ?? [];
}

/* ── Routing ───────────────────────────────────────────── */

/**
 * Analizza REQUEST_URI e restituisce:
 * [
 *   'resource' => 'utenti',   // prima parte del path
 *   'id'       => '42',       // seconda parte del path, null se assente
 *   'sub'      => 'schede',   // terza parte del path, null se assente
 * ]
 */
function parse_route(): array {
    $base   = '';               // modifica se il WS è in un altro path
    $uri    = $_SERVER['REQUEST_URI'];
    $path   = parse_url($uri, PHP_URL_PATH);
    $path   = preg_replace('#^' . preg_quote($base, '#') . '#', '', $path);
    $parts  = array_values(array_filter(explode('/', trim($path, '/'))));

    return [
        'resource' => $parts[0] ?? null,
        'id'       => $parts[1] ?? null,
        'sub'      => $parts[2] ?? null,
    ];
}

function method(): string {
    return $_SERVER['REQUEST_METHOD'];
}

/* ── AI — OpenRouter ───────────────────────────────────── */

/**
 * Invia un prompt a OpenRouter e restituisce il testo della risposta.
 * Lancia un'eccezione in caso di errore.
 */
function call_ai(string $prompt): string {
    $payload = json_encode([
        'model'    => AI_MODEL,
        'messages' => [
            ['role' => 'system', 'content' => 'Sei un personal trainer esperto. Rispondi SEMPRE con JSON valido, senza testo aggiuntivo.'],
            ['role' => 'user',   'content' => $prompt],
        ],
        'temperature' => 0.7,
    ]);

    $options = [
        'http' => [
            'header'  => "Content-Type: application/json\r\n" .
                         "Authorization: Bearer " . OPENROUTER_API_KEY . "\r\n" .
                         "HTTP-Referer: https://tuosito.it\r\n" .
                         "X-Title: " . APP_NAME . "\r\n",
            'method'  => 'POST',
            'content' => $payload,
            'timeout' => 30,
            'ignore_errors' => true
        ]
    ];
    $context = stream_context_create($options);
    $raw = @file_get_contents(OPENROUTER_URL, false, $context);

    if ($raw === false) {
        throw new RuntimeException('HTTP request failed');
    }

    $resp = json_decode($raw, true);
    if (!isset($resp['choices'][0]['message']['content'])) {
        throw new RuntimeException('Risposta AI non valida: ' . $raw);
    }

    return $resp['choices'][0]['message']['content'];
}

/**
 * Costruisce il prompt per generare la scheda a partire dal record quiz.
 */
function build_prompt(array $quiz): string {
    return <<<PROMPT
Crea una scheda di allenamento settimanale personalizzata in JSON.
Dati utente:
- Obiettivo: {$quiz['obiettivo']}
- Livello: {$quiz['livello']}
- Giorni disponibili a settimana: {$quiz['giorni_settimana']}
- Durata per sessione: {$quiz['durata_sessione']} minuti
- Attrezzatura: {$quiz['attrezzatura']}
- Limitazioni/note: {$quiz['limitazioni']}

Struttura JSON richiesta:
{
  "titolo": "...",
  "descrizione": "...",
  "settimane_consigliate": 4,
  "giorni": [
    {
      "giorno": "Lunedì",
      "focus": "...",
      "esercizi": [
        { "nome": "...", "serie": 3, "ripetizioni": "10-12", "recupero_sec": 60, "note": "..." }
      ]
    }
  ]
}
Rispondi SOLO con il JSON, senza markdown, senza backtick.
PROMPT;
}