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
            PDO::ATTR_EMULATE_PREPARES   => false,
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
function respond_unauthorized(string $msg = 'Non autenticato'): void { respond(401, ['error' => $msg]); }
function respond_forbidden(string $msg = 'Accesso negato'): void     { respond(403, ['error' => $msg]); }
function respond_not_found(string $msg = 'Risorsa non trovata'): void { respond(404, ['error' => $msg]); }
function respond_method_not_allowed(): void   { respond(405, ['error' => 'Metodo non consentito']); }
function respond_conflict(string $msg): void  { respond(409, ['error' => $msg]); }
function respond_too_many(string $msg = 'Troppi tentativi'): void { respond(429, ['error' => $msg]); }

function respond_server_error(string $msg = 'Errore interno', ?Throwable $e = null): void {
    if ($e) error_log('[' . APP_NAME . '] ' . $e->getMessage() . "\n" . $e->getTraceAsString());
    $payload = ['error' => $msg];
    if (APP_ENV !== 'production' && $e) {
        $payload['debug'] = $e->getMessage();
    }
    respond(500, $payload);
}

/* ── Request body ──────────────────────────────────────── */

function get_body(): array {
    $raw = file_get_contents('php://input');
    if ($raw === '' || $raw === false) return [];
    $decoded = json_decode($raw, true);
    if (!is_array($decoded)) {
        respond_bad_request('JSON body non valido');
    }
    return $decoded;
}

/* ── Routing ───────────────────────────────────────────── */

function parse_route(): array {
    $base   = '';
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

function client_ip(): string {
    return $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
}

/* ── CORS ──────────────────────────────────────────────── */

function apply_cors(): void {
    $origin  = $_SERVER['HTTP_ORIGIN'] ?? '';
    $allowed = array_map('trim', explode(',', ALLOWED_ORIGINS));

    if (ALLOWED_ORIGINS === '*') {
        header('Access-Control-Allow-Origin: *');
    } elseif ($origin !== '' && in_array($origin, $allowed, true)) {
        header('Access-Control-Allow-Origin: ' . $origin);
        header('Vary: Origin');
        header('Access-Control-Allow-Credentials: true');
    }
    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    header('Access-Control-Max-Age: 86400');
}

/* ── Validation ────────────────────────────────────────── */

function v_string(mixed $val, int $min, int $max, string $field): string {
    if (!is_string($val)) respond_bad_request("Campo '$field' non valido");
    $val = trim($val);
    $len = mb_strlen($val);
    if ($len < $min || $len > $max) {
        respond_bad_request("Campo '$field' deve essere tra $min e $max caratteri");
    }
    return $val;
}

function v_email(mixed $val): string {
    if (!is_string($val)) respond_bad_request('Email non valida');
    $val = trim(mb_strtolower($val));
    if (mb_strlen($val) > 150 || !filter_var($val, FILTER_VALIDATE_EMAIL)) {
        respond_bad_request('Email non valida');
    }
    return $val;
}

function v_password(mixed $val): string {
    if (!is_string($val)) respond_bad_request('Password non valida');
    if (strlen($val) < 8 || strlen($val) > 128) {
        respond_bad_request('Password deve essere tra 8 e 128 caratteri');
    }
    if (!preg_match('/[A-Za-z]/', $val) || !preg_match('/\d/', $val)) {
        respond_bad_request('Password deve contenere almeno una lettera e un numero');
    }
    return $val;
}

function v_int_range(mixed $val, int $min, int $max, string $field): int {
    if (!is_numeric($val)) respond_bad_request("Campo '$field' non valido");
    $n = (int)$val;
    if ($n < $min || $n > $max) {
        respond_bad_request("Campo '$field' deve essere tra $min e $max");
    }
    return $n;
}

function v_enum(mixed $val, array $allowed, string $field): string {
    if (!is_string($val) || !in_array($val, $allowed, true)) {
        respond_bad_request("Campo '$field' deve essere uno di: " . implode(', ', $allowed));
    }
    return $val;
}

function v_bool(mixed $val): bool {
    return filter_var($val, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE) === true;
}

function v_hex_color(mixed $val, string $field = 'theme_seed'): string {
    if (!is_string($val) || !preg_match('/^#[0-9A-Fa-f]{6}$/', $val)) {
        respond_bad_request("Campo '$field' deve essere un colore esadecimale (#RRGGBB)");
    }
    return strtoupper($val);
}

/* ── Uploads ───────────────────────────────────────────── */

function uploads_dir(string $sub = 'profiles'): string {
    $dir = __DIR__ . '/../uploads/' . $sub;
    if (!is_dir($dir)) {
        @mkdir($dir, 0755, true);
    }
    return $dir;
}

function public_pic_url(?string $relPath): ?string {
    if (!$relPath) return null;
    $base = rtrim(env('PUBLIC_BASE_URL', ''), '/');
    if ($base === '') {
        $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
        $host   = $_SERVER['HTTP_HOST'] ?? 'localhost';
        $base   = "$scheme://$host";
    }
    $abs = __DIR__ . '/../' . ltrim($relPath, '/');
    $v   = is_file($abs) ? filemtime($abs) : time();
    return $base . '/' . ltrim($relPath, '/') . '?v=' . $v;
}

/**
 * Handle a single file upload from $_FILES[$field].
 * Returns relative path (e.g. "uploads/profiles/5.jpg") on success.
 * $sub: sub-directory under uploads/ (e.g. "profiles" or "backgrounds").
 * $maxBytes: size cap.
 */
function handle_image_upload(string $field, int $userId, string $sub = 'profiles', int $maxBytes = 2097152): string {
    if (!isset($_FILES[$field]) || !is_array($_FILES[$field])) {
        respond_bad_request("File '$field' mancante");
    }
    $f = $_FILES[$field];
    if (($f['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
        respond_bad_request('Upload fallito (errore ' . $f['error'] . ')');
    }
    if (!is_uploaded_file($f['tmp_name'])) {
        respond_bad_request('File non valido');
    }
    $size = (int)$f['size'];
    if ($size <= 0 || $size > $maxBytes) {
        $mb = round($maxBytes / (1024 * 1024), 1);
        respond_bad_request("Dimensione file fuori range (max {$mb} MB)");
    }

    $mime = '';
    if (class_exists('finfo')) {
        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime  = $finfo->file($f['tmp_name']) ?: '';
    } else {
        $mime = (string)($f['type'] ?? '');
    }
    $extMap = [
        'image/jpeg' => 'jpg',
        'image/png'  => 'png',
        'image/webp' => 'webp',
    ];
    if (!isset($extMap[$mime])) {
        respond_bad_request('Formato non supportato (solo JPEG, PNG, WEBP)');
    }
    $ext = $extMap[$mime];

    $dir = uploads_dir($sub);

    // Delete existing images for this user (any extension)
    foreach (glob($dir . "/{$userId}.*") ?: [] as $old) {
        @unlink($old);
    }

    $destAbs = $dir . "/{$userId}.{$ext}";
    if (!move_uploaded_file($f['tmp_name'], $destAbs)) {
        respond_server_error('Errore salvataggio file');
    }
    @chmod($destAbs, 0644);

    return "uploads/{$sub}/{$userId}.{$ext}";
}

// Back-compat alias
function handle_profile_upload(string $field, int $userId): string {
    return handle_image_upload($field, $userId, 'profiles', 2 * 1024 * 1024);
}

/* ── Rate limiting (login) ─────────────────────────────── */

function login_attempts_count(string $email, string $ip): int {
    $stmt = db()->prepare(
        'SELECT COUNT(*) FROM login_attempts
         WHERE success = 0
           AND created_at > (NOW() - INTERVAL ? SECOND)
           AND (email = ? OR ip = ?)'
    );
    $stmt->execute([LOGIN_WINDOW_SEC, $email, $ip]);
    return (int)$stmt->fetchColumn();
}

function record_login_attempt(string $email, string $ip, bool $success): void {
    $stmt = db()->prepare('INSERT INTO login_attempts (email, ip, success) VALUES (?, ?, ?)');
    $stmt->execute([$email, $ip, $success ? 1 : 0]);
}

/* ── JWT (HS256) ───────────────────────────────────────── */

function b64url_encode(string $data): string {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function b64url_decode(string $data): string {
    $pad = strlen($data) % 4;
    if ($pad) $data .= str_repeat('=', 4 - $pad);
    return base64_decode(strtr($data, '-_', '+/'));
}

function jwt_issue(int $uid, string $email): string {
    if (JWT_SECRET === '') {
        respond_server_error('Configurazione JWT mancante');
    }
    $now = time();
    $header  = ['alg' => 'HS256', 'typ' => 'JWT'];
    $payload = [
        'sub'   => $uid,
        'email' => $email,
        'iat'   => $now,
        'exp'   => $now + JWT_TTL,
    ];
    $h = b64url_encode(json_encode($header));
    $p = b64url_encode(json_encode($payload));
    $sig = hash_hmac('sha256', "$h.$p", JWT_SECRET, true);
    return "$h.$p." . b64url_encode($sig);
}

function jwt_decode(string $token): ?array {
    if (JWT_SECRET === '') return null;
    $parts = explode('.', $token);
    if (count($parts) !== 3) return null;
    [$h, $p, $s] = $parts;
    $expected = b64url_encode(hash_hmac('sha256', "$h.$p", JWT_SECRET, true));
    if (!hash_equals($expected, $s)) return null;
    $payload = json_decode(b64url_decode($p), true);
    if (!is_array($payload)) return null;
    if (!isset($payload['exp']) || $payload['exp'] < time()) return null;
    return $payload;
}

/* ── Auth middleware ───────────────────────────────────── */

function current_user(): ?array {
    static $cache = false;
    if ($cache !== false) return $cache;

    $hdr = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/^Bearer\s+(.+)$/i', $hdr, $m)) return $cache = null;

    $payload = jwt_decode(trim($m[1]));
    if (!$payload || !isset($payload['sub'])) return $cache = null;

    return $cache = ['id' => (int)$payload['sub'], 'email' => $payload['email'] ?? ''];
}

function require_auth(): array {
    $u = current_user();
    if (!$u) respond_unauthorized('Token mancante o non valido');
    return $u;
}

function require_owner(int $resource_owner_id): void {
    $u = require_auth();
    if ($u['id'] !== $resource_owner_id) respond_forbidden();
}

/* ── AI — OpenRouter ───────────────────────────────────── */

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
        throw new RuntimeException('Risposta AI non valida');
    }

    return $resp['choices'][0]['message']['content'];
}

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
