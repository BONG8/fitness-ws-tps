# 📋 Guida Completa all'Architettura - Fitness Web Service

Questo documento analizza ogni sezione logica del codice del progetto, spiegando cosa fa, quale strategia utilizza e perché è stata scelta.

---

## 🏗️ Parte 1: Architettura Generale

### Principio Fondamentale: API REST Stateless

Il progetto implementa un **API REST puro** con autenticazione basata su **JWT (JSON Web Tokens)**. Questa scelta garantisce:
- **Scalabilità orizzontale**: nessuno stato server, il token contiene tutto
- **Indipendenza dal client**: funziona con web, mobile, desktop
- **Sicurezza**: il token è verificabile senza query DB aggiuntive

```
┌──────────────┐       HTTP          ┌─────────────────┐
│   Client     │◄────────────────────►│  API REST PHP   │
│ (Web/Mobile) │     JSON + JWT      │  stateless      │
└──────────────┘                      └────────┬────────┘
                                               │
                                        ┌──────▼──────┐
                                        │  MySQL DB   │
                                        └─────────────┘
```

### Strategie Architetturali Chiave

**1. Separazione dei Livelli**
- `lib/config.php` → Configurazione centralizzata
- `lib/helpers.php` → Funzioni riutilizzabili
- `resources/` → Logica business per ogni risorsa
- `index.php` → Router principale

**Perché:** Facilita manutenzione, testing, riutilizzo del codice. Se cambio la logica di validazione, la cambia in un solo posto.

**2. Lazy Loading delle Risorse**
```php
// In index.php
case 'utenti':
    require_once __DIR__ . '/resources/utenti.php';
    handle_utenti($route);
```
Le funzioni di ogni risorsa sono caricate solo quando serve.

**Perché:** Riduce memoria e tempo di startup. Non carico la logica di quiz se l'utente fa una richiesta di login.

---

## ⚙️ Parte 2: Configurazione (`lib/config.php`)

### Sezione 1: Caricamento Variabili d'Ambiente

```php
$envFile = __DIR__ . '/../.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        // Parse "KEY=value" format
        list($name, $value) = explode('=', $line, 2);
        // Strip quotes se presenti
        if ((str_starts_with($value, '"') && str_ends_with($value, '"'))) {
            $value = substr($value, 1, -1);
        }
        $_ENV[$name] = $value;
    }
}
```

**Cosa fa:** Legge un file `.env` e carica le variabili d'ambiente.

**Strategia:** File `.env` separato dal codice (gitignored).

**Perché:**
- **Sicurezza**: Password e chiavi non finiscono nel repository
- **Flexibilità**: Stesso codice funziona in dev/staging/prod con diversi `.env`
- **Praticità**: Non devo ricompilare il codice per cambiare configurazione

**Esempio `.env`:**
```
DB_HOST=localhost
DB_NAME=fitness_db
JWT_SECRET=mia_chiave_super_segreta_64_caratteri
OPENROUTER_API_KEY=sk-xxxxx
```

### Sezione 2: Definizione Costanti

```php
define('APP_NAME', env('APP_NAME', 'FitnessWS'));
define('DB_HOST', env('DB_HOST', '127.0.0.1'));
define('JWT_SECRET', env('JWT_SECRET', ''));
```

**Cosa fa:** Definisce costanti globali con valori di default.

**Strategia:** `env($name, $default)` fornisce fallback se la variabile non esiste.

**Perché:**
- Evito valori hardcodati sparse nel codice
- Se devo usare il host DB 30 volte, lo prendo da `DB_HOST` costante, non da `$config['db']['host']`
- Costanti = immutabili = errori di digitazione lanciati a runtime su `define()`, non su runtime di una variabile typo

### Sezione 3: Gruppi di Configurazione

```php
// ── Database ──────────────────────────────────────────
define('DB_HOST', env('DB_HOST', '127.0.0.1'));
define('DB_CHARSET', env('DB_CHARSET', 'utf8mb4'));

// ── JWT ────────────────────────────────────────────────
define('JWT_SECRET', env('JWT_SECRET', ''));
define('JWT_TTL', (int)env('JWT_TTL', 86400)); // 24h

// ── CORS ───────────────────────────────────────────────
define('ALLOWED_ORIGINS', env('ALLOWED_ORIGINS', ''));
```

**Cosa fa:** Raggruppa le configurazioni per dominio logico.

**Perché:**
- Lettura più facile
- Se devo cambiare tutto il CORS, so dove guardare
- Evita il "magic number hell"

---

## 🛠️ Parte 3: Helper Functions (`lib/helpers.php`)

Il file helpers.php implementa il pattern **"funzioni di utilità centralizzate"**. Ogni helper è una micro-responsabilità.

### Sezione 1: Database Connection (Singleton Pattern)

```php
function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = sprintf('mysql:host=%s;dbname=%s;charset=%s', DB_HOST, DB_NAME, DB_CHARSET);
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);
    }
    return $pdo;
}
```

**Cosa fa:** Restituisce una connessione MySQL/MariaDB, creandola una sola volta per request.

**Strategia Usata:**
- **Singleton con `static`**: `$pdo` è inizializzato una sola volta per request, poi riutilizzato
- **Prepared Statements**: `PDO::ATTR_EMULATE_PREPARES => false` forza prepared statements reali (prevenzione SQL injection)
- **FETCH_ASSOC**: tutti i risultati sono array associativi (non oggetti)
- **ERRMODE_EXCEPTION**: errori DB diventano eccezioni

**Perché:**
- Una sola connessione per request = economia di risorse
- Prepared statements = difesa da SQL injection
- Eccezioni = error handling strutturato nei try/catch

### Sezione 2: HTTP Response Helpers

```php
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
function respond_unauthorized(string $msg = 'Non autenticato'): void { respond(401, ['error' => $msg]); }
```

**Cosa fa:** Funzioni shortcut per rispondere con HTTP status code e JSON.

**Strategia:**
- **Funzione base generica** `respond()` + wrapper specifici
- Ogni wrapper corrisponde a uno scenario (201 Created, 401 Unauthorized, etc.)
- `exit` dopo ogni risposta = interrompe subito l'esecuzione

**Perché:**
- **DRY (Don't Repeat Yourself)**: ogni response segue lo stesso formato
- **Consistenza**: tutti gli errori hanno `{"error": "..."}`, tutti i success hanno content-type JSON
- **Semantica HTTP**: uso gli status code corretti (201 per CREATE, 204 per DELETE senza content, etc.)

### Sezione 3: Validazione Input

```php
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
    if (!filter_var($val, FILTER_VALIDATE_EMAIL)) {
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

function v_enum(mixed $val, array $allowed, string $field): string {
    if (!is_string($val) || !in_array($val, $allowed, true)) {
        respond_bad_request("Campo '$field' deve essere uno di: " . implode(', ', $allowed));
    }
    return $val;
}
```

**Cosa fa:** Valida ogni tipo di dato in ingresso, restituendo il valore pulito oppure interrompendo con 400 Bad Request.

**Strategie Utilizzate:**

1. **Fail-Fast**: se la validazione fallisce, la risposta parte subito (exit in respond_bad_request)
2. **Type Coercion**: tutti i validatori ritornano il tipo corretto (string, int, bool)
3. **Pulizia**: trim(), mb_strtolower(), etc.
4. **Messaggi Chiari**: l'utente sa cosa ha sbagliato

**Password:**
- Lunghezza 8-128 (bilanciamento tra sicurezza e usabilità)
- Almeno una lettera + un numero (complessità minima)
- Non chiedo simboli perché molti utenti non li mettono

**Email:**
- Lowercased per evitare duplicati (mario@x.it == MARIO@x.it)
- `filter_var()` con `FILTER_VALIDATE_EMAIL` (standard RFC 5321)

**Enum:**
- `in_array($val, $allowed, true)` con **strict type** (`=== not ==`)
- Previene "0" == false

**Perché questa approccio:**
- Centralizzato: tutti gli input passano per uno di questi validatori
- Consistente: stesso livello di controllo ovunque
- Sicuro: niente garbage entra nel database

### Sezione 4: CORS (Cross-Origin Resource Sharing)

```php
function apply_cors(): void {
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    $allowed = array_map('trim', explode(',', ALLOWED_ORIGINS));

    if (ALLOWED_ORIGINS === '*') {
        header('Access-Control-Allow-Origin: *');
    } elseif ($origin !== '' && in_array($origin, $allowed, true)) {
        header('Access-Control-Allow-Origin: ' . $origin);
        header('Vary: Origin');
        header('Access-Control-Allow-Credentials: true');
    }
    // ... altri header
}
```

**Cosa fa:** Configura gli header CORS per consentire richieste da domini specifici.

**Strategia:**
- **Whitelist**: solo i domini in `ALLOWED_ORIGINS` possono accedere (not wildcard in production)
- **Vary: Origin**: dice ai cache che la risposta dipende da quale origin l'ha richiesta
- **Preflight OPTIONS**: gli header `Access-Control-Allow-Methods` supportano il preflight CORS

**Perché:**
- Sicurezza: non permetto a ANY dominio di usare la mia API
- Flessibilità: posso permettere localhost per dev, esempio.com per prod

### Sezione 5: JWT (JSON Web Tokens)

```php
function jwt_issue(int $uid, string $email): string {
    if (JWT_SECRET === '') respond_server_error('Configurazione JWT mancante');
    $now = time();
    $header = ['alg' => 'HS256', 'typ' => 'JWT'];
    $payload = [
        'sub' => $uid,
        'email' => $email,
        'iat' => $now,           // issued at
        'exp' => $now + JWT_TTL, // expiration
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
    if (!hash_equals($expected, $s)) return null; // Constant-time comparison!
    $payload = json_decode(b64url_decode($p), true);
    if (!is_array($payload)) return null;
    if (!isset($payload['exp']) || $payload['exp'] < time()) return null;
    return $payload;
}

function require_auth(): array {
    $u = current_user();
    if (!$u) respond_unauthorized('Token mancante o non valido');
    return $u;
}
```

**Cosa fa:** Crea e valida JWT. Protegge gli endpoint autenticati.

**JWT (HS256) Formato:** `header.payload.signature`
- **Header**: `{"alg":"HS256","typ":"JWT"}`
- **Payload**: `{"sub":123,"email":"...","iat":..., "exp":...}`
- **Signature**: HMAC-SHA256(header.payload, JWT_SECRET)

**Strategia:**
1. **Token Stateless**: il token contiene ID e email, niente query DB per verificarlo
2. **Firma**: `hash_hmac()` + `hash_equals()` = impossibile falsificare il token senza JWT_SECRET
3. **Expiration**: `exp` timestamp previene token stantii
4. **Constant-time Comparison**: `hash_equals()` previene timing attacks

**Perché:**
- **Scalabilità**: non devo cercare il token in una tabella `sessions`
- **Sicurezza**: `hash_equals()` evita side-channel attacks
- **Standard**: JWT è RFC 7519, supportato ovunque

### Sezione 6: Upload File

```php
function handle_image_upload(string $field, int $userId, string $sub = 'profiles', int $maxBytes = 2097152): string {
    if (!isset($_FILES[$field]) || !is_array($_FILES[$field])) {
        respond_bad_request("File '$field' mancante");
    }
    $f = $_FILES[$field];
    if (($f['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
        respond_bad_request('Upload fallito');
    }
    if (!is_uploaded_file($f['tmp_name'])) {
        respond_bad_request('File non valido');
    }
    
    // Validazione MIME type
    $finfo = new finfo(FILEINFO_MIME_TYPE);
    $mime = $finfo->file($f['tmp_name']) ?: '';
    $extMap = [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
    ];
    if (!isset($extMap[$mime])) {
        respond_bad_request('Formato non supportato (solo JPEG, PNG, WEBP)');
    }
    
    $dir = uploads_dir($sub);
    // Elimina vecchi file dello stesso utente
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
```

**Cosa fa:** Valida e salva file uploaddati, restituisce il percorso relativo.

**Strategie Utilizzate:**

1. **Validazione MIME**: `finfo` controlla il valore magico del file (non l'estensione, che è facilmente falsificabile)
2. **Whitelist**: solo JPEG, PNG, WEBP
3. **Max Size**: limite sulla dimensione per evitare denial of service
4. **Naming User-Based**: `{$userId}.{$ext}` = un'immagine per utente, file sovrascrittura automatica
5. **Temporary File Check**: `is_uploaded_file()` = il file viene davvero da un upload, non da directory locali
6. **Cleanup**: elimino i file vecchi dello stesso utente

**Perché:**
- **Sicurezza**: MIME magic byte > trust dell'estensione
- **Storage**: naming user-based = facile pulire i file se l'utente viene eliminato
- **UX**: sovrascrittura automatica = l'utente non ha 100 versioni di profile_pic

### Sezione 7: Rate Limiting (Login)

```php
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
```

**Cosa fa:** Traccia i tentativi di login falliti, blocca dopo N tentativi.

**Strategia:**
- **By email OR ip**: blocco chi tenta brute force su una specifica email, oppure un IP che fa 1000 tentativi su 1000 email diverse
- **Time window**: `LOGIN_WINDOW_SEC` (default 15 min) = i tentativi più vecchi vengono ignorati
- **Registro**: record di successi e fallimenti per audit

**Perché:**
- **Sicurezza**: previene brute force e password spray
- **Flexibilità**: considera sia email che IP per catch entrambi gli attacchi
- **Recovery**: dopo 15 min l'utente può riprovare

---

## 🔀 Parte 4: Routing (`index.php`)

```php
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

    default:
        respond_not_found('Endpoint non trovato');
}
```

**Cosa fa:** Dispatcher principale. Riceve una richiesta HTTP, la smista alla risorsa corretta.

**Strategia:**
- **Parse Route**: estrae `resource`, `id`, `sub` da `/resource/id/sub`
- **Switch su resource**: ogni case carica il file della risorsa e chiama la handler
- **Lazy loading**: `require_once` solo quando serve
- **CORS Pre-flight**: `method() === 'OPTIONS'` ritorna 204 prima del switch

**Esempio:**
```
GET /quiz/42
→ parse_route() = ['resource' => 'quiz', 'id' => '42', 'sub' => null]
→ case 'quiz': require resources/quiz.php; handle_quiz(['id' => '42'])
→ get_quiz('42') carica la scheda 42
```

**Perché:**
- Centralizzato: logica routing in un posto
- Semplice: no framework, solo switch/case
- Estensibile: aggiungere una nuova risorsa = aggiungere un case

---

## 👤 Parte 5: Gestione Utenti (`resources/utenti.php`)

### Sezione 1: CRUD Handler

```php
function handle_utenti(array $route): void {
    $id = $route['id'];
    $sub = $route['sub'] ?? null;

    // Sub-routes: /utenti/{id}/picture, /utenti/{id}/background
    if ($id && $sub === 'picture') {
        switch (method()) {
            case 'POST':   upload_profile_picture($id); return;
            case 'DELETE': delete_profile_picture($id); return;
        }
    }

    switch (method()) {
        case 'GET':    $id ? get_utente($id) : respond_forbidden('Elenco utenti non disponibile'); break;
        case 'POST':   !$id ? create_utente() : respond_method_not_allowed(); break;
        case 'PUT':    $id ? update_utente($id) : respond_method_not_allowed(); break;
        case 'DELETE': $id ? delete_utente($id) : respond_method_not_allowed(); break;
    }
}
```

**Cosa fa:** Handler principale per la risorsa utenti. Smista a funzioni specifiche.

**Strategia:**
- **Semantica REST**: POST (create), GET (read), PUT (update), DELETE (delete)
- **URL structure**:
  - `GET /utenti/42` = leggi utente 42
  - `POST /utenti` = crea nuovo utente (no ID)
  - `PUT /utenti/42` = modifica utente 42
  - `DELETE /utenti/42` = cancella utente 42
  - `POST /utenti/42/picture` = upload foto di utente 42
  
- **Sub-resources**: `/utenti/{id}/picture`, `/utenti/{id}/background` per gestire media

**Perché:**
- Standard REST: predicibile, chiunque sa che `DELETE /utenti/42` cancella
- Flessibilità: il suffisso `/picture` permette di aggiungere logica speciale

### Sezione 2: Creazione Utente (Registrazione)

```php
function create_utente(): void {
    $b = get_body();

    $nome = v_string($b['nome'] ?? null, 2, 100, 'nome');
    $email = v_email($b['email'] ?? null);
    $password = v_password($b['password'] ?? null);
    $eta = v_int_range($b['eta'] ?? null, 13, 100, 'eta');
    $sesso = v_enum($b['sesso'] ?? null, SESSO_VALUES, 'sesso');
    $consenso = v_bool($b['consenso_privacy'] ?? false);

    if (!$consenso) {
        respond_bad_request('Consenso privacy obbligatorio');
    }

    $hash = password_hash($password, PASSWORD_DEFAULT);

    try {
        $stmt = db()->prepare(
            'INSERT INTO utenti (nome, email, password, eta, sesso, consenso_privacy)
             VALUES (?, ?, ?, ?, ?, 1)'
        );
        $stmt->execute([$nome, $email, $hash, $eta, $sesso]);
        $uid = (int)db()->lastInsertId();

        $token = jwt_issue($uid, $email);
        respond_created([
            'id' => $uid,
            'message' => 'Utente creato',
            'token' => $token,
            'user' => ['id' => $uid, 'nome' => $nome, 'email' => $email],
        ]);
    } catch (PDOException $e) {
        if ($e->getCode() === '23000') {
            respond_conflict('Email già in uso');
        }
        respond_server_error('Errore creazione utente', $e);
    }
}
```

**Cosa fa:** Registra un nuovo utente, ritorna un token JWT.

**Strategie Utilizzate:**

1. **Validazione Input**: passa tutti i campi per validatori specifici
2. **Password Hashing**: `password_hash($password, PASSWORD_DEFAULT)` = bcrypt con salt random
3. **Duplicato Email**: constraint `UNIQUE` sulla colonna + cattura dell'errore PDO 23000
4. **Token Immediato**: il client riceve subito il JWT (no step di login separato)
5. **201 Created**: HTTP status code corretto per creazione

**Password Hashing - Perché?**
- `PASSWORD_DEFAULT` = bcrypt, che è lento (millisec per verifica) = difesa contro brute force
- Salt random generato automaticamente
- Hash non è reversibile: anche se il DB è compromesso, le password rimangono al sicuro

**Errore 23000 - Perché intercettarlo?**
- Codice di errore standard per "constraint violation" (in questo caso UNIQUE)
- Permetto al client di sapere che l'email è già in uso (vs generico 500 Internal Server Error)

### Sezione 3: Autenticazione (Login)

```php
function login_utente(): void {
    $b = get_body();
    if (empty($b['email']) || empty($b['password'])) {
        respond_bad_request('Campi obbligatori: email, password');
    }

    $email = is_string($b['email']) ? trim(mb_strtolower($b['email'])) : '';
    $pwd = is_string($b['password']) ? $b['password'] : '';
    $ip = client_ip();

    if (login_attempts_count($email, $ip) >= LOGIN_MAX_ATTEMPTS) {
        respond_too_many('Troppi tentativi falliti. Riprova tra qualche minuto.');
    }

    $stmt = db()->prepare('SELECT id, password, nome, email FROM utenti WHERE email = ?');
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    // Constant-time password verification
    $hash = $user ? $user['password'] : DUMMY_HASH;
    $ok = password_verify($pwd, $hash) && $user !== false;

    record_login_attempt($email, $ip, $ok);

    if (!$ok) {
        respond_unauthorized('Credenziali non valide');
    }

    $token = jwt_issue((int)$user['id'], $user['email']);
    respond_ok([
        'message' => 'Login completato',
        'token' => $token,
        'user' => ['id' => (int)$user['id'], 'nome' => $user['nome'], 'email' => $user['email']],
    ]);
}
```

**Cosa fa:** Verifica email e password, ritorna un JWT valido per 24h.

**Strategie Utilizzate:**

1. **Rate Limiting**: verifica fallimenti precedenti prima di verificare la password
2. **Constant-Time Verification**: `password_verify()` + `DUMMY_HASH` quando l'utente non esiste
   - Previene user enumeration: chi attacca non sa se fallisce perché l'email non esiste o la password è sbagliata
   - Tutti i tentativi impiegano lo stesso tempo
3. **Lowercasing Email**: email trattata case-insensitive (mario@x.it == MARIO@x.it)
4. **Recording**: ogni tentativo (successo o fallimento) è registrato per audit

**User Enumeration - Perché è importante prevvenirlo?**
```
SBAGLIATO:
if (user not found) → "Utente non trovato" (401)
else → verifica password → "Password sbagliata" (401)
Attacker: "Ah! mario@example.com non esiste, provo a registrarmi come lui"

CORRETTO (questo codice):
Sempre 401, stesso tempo di risposta
Attacker: "Non so se maria@example.com esiste o no, meglio provare altrove"
```

### Sezione 4: Gestione Profilo

```php
function fetch_utente_full(int $id): ?array {
    $stmt = db()->prepare(
        'SELECT id, nome, email, eta, sesso, theme_seed, theme_mode, profile_pic_path, bg_image_path, created_at
         FROM utenti WHERE id = ?'
    );
    $stmt->execute([$id]);
    $row = $stmt->fetch();
    if (!$row) return null;
    $row['profile_pic_url'] = public_pic_url($row['profile_pic_path'] ?? null);
    $row['background_url'] = public_pic_url($row['bg_image_path'] ?? null);
    unset($row['profile_pic_path'], $row['bg_image_path']);
    return $row;
}

function get_utente(string $id): void {
    require_owner((int)$id);
    $row = fetch_utente_full((int)$id);
    $row ? respond_ok($row) : respond_not_found('Utente non trovato');
}

function update_utente(string $id): void {
    require_owner((int)$id);
    $b = get_body();

    // Validazione campi
    $nome = v_string($b['nome'] ?? null, 2, 100, 'nome');
    // ...

    $hasThemeSeed = array_key_exists('theme_seed', $b);
    $themeSeed = $hasThemeSeed ? v_hex_color($b['theme_seed'], 'theme_seed') : null;

    try {
        $sets = ['nome=?', 'email=?', 'eta=?', 'sesso=?'];
        $args = [$nome, $email, $eta, $sesso];

        if (!empty($b['password'])) {
            $sets[] = 'password=?';
            $args[] = password_hash($password, PASSWORD_DEFAULT);
        }
        if ($hasThemeSeed) {
            $sets[] = 'theme_seed=?';
            $args[] = $themeSeed;
        }

        $sql = 'UPDATE utenti SET ' . implode(', ', $sets) . ' WHERE id=?';
        $stmt = db()->prepare($sql);
        $stmt->execute([$args]);
    } catch (PDOException $e) {
        // Handle errors
    }
}
```

**Cosa fa:** Recupera e modifica il profilo utente.

**Strategie Utilizzate:**

1. **Fetch Helper**: `fetch_utente_full()` centralizza la logica di lettura
2. **URL Transformation**: percorso file → URL pubblica (con versioning query param `?v=timestamp`)
3. **Dynamic Query Building**: `$sets` array che si costruisce based su quali campi l'utente invia
4. **Conditional Updates**: campi facoltativi (es. theme_seed) non vengono modificati se omessi

**URL Versioning - Perché `?v=timestamp`?**
```
1. Salvo file: /uploads/profiles/42.jpg (timestamp: 1000)
2. Client scarica: /uploads/profiles/42.jpg?v=1000 → cache per 1 anno
3. Utente cambia foto: nuovo file, nuovo timestamp
4. Client accede: /uploads/profiles/42.jpg?v=2000 → ricarica (URL differente)
```
Senza versioning, la cache del browser mostrerebbe la foto vecchia.

---

## ❓ Parte 6: Quiz (`resources/quiz.php`)

### Sezione 1: Quiz Handler & Listing

```php
function handle_quiz(array $route): void {
    require_auth();
    $id = $route['id'];
    switch (method()) {
        case 'GET': $id ? get_quiz($id) : get_quiz_list(); break;
        case 'POST': !$id ? create_quiz() : respond_method_not_allowed(); break;
        case 'DELETE': $id ? delete_quiz($id) : respond_method_not_allowed(); break;
    }
}

function get_quiz_list(): void {
    $u = require_auth();
    $stmt = db()->prepare(
        'SELECT id, utente_id, obiettivo, livello, giorni_settimana, created_at
         FROM quiz WHERE utente_id = ? ORDER BY id DESC'
    );
    $stmt->execute([$u['id']]);
    respond_ok($stmt->fetchAll());
}
```

**Cosa fa:** Elenca tutti i quiz creati dall'utente autenticato, ordinati più recenti prima.

**Strategia:**
- **Owner-based filtering**: `WHERE utente_id = ?` → l'utente vede solo i suoi quiz
- **Reverse chronological**: `ORDER BY id DESC` = quiz più nuovi prima (UX: cosa ho fatto di recente?)
- **Partial select**: non carica la colonna `limitazioni` che potrebbe essere lunga

**Perché:**
- Sicurezza: nessun leak di dati di altri utenti
- Performance: query più leggera (no testo limitazioni)

### Sezione 2: Creazione Quiz + Generazione Scheda AI

```php
function create_quiz(): void {
    $u = require_auth();
    $b = get_body();

    // 1. Validazione input
    $obiettivo = v_enum($b['obiettivo'] ?? null, QUIZ_OBIETTIVI, 'obiettivo');
    $livello = v_enum($b['livello'] ?? null, QUIZ_LIVELLI, 'livello');
    // ... altri campi

    // 2. Salva il quiz nel DB
    try {
        $stmt = db()->prepare(
            'INSERT INTO quiz (utente_id, obiettivo, livello, giorni_settimana, durata_sessione, attrezzatura, limitazioni)
             VALUES (?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([$u['id'], $obiettivo, $livello, $giorni, $durata, $attrezzatura, $limitazioni]);
        $quiz_id = (int)db()->lastInsertId();
    } catch (PDOException $e) {
        respond_server_error('Errore salvataggio quiz', $e);
    }

    // 3. Genera scheda via AI
    try {
        $quiz_row = [
            'id' => $quiz_id,
            'obiettivo' => $obiettivo,
            // ... dati del quiz
        ];
        $prompt = build_prompt($quiz_row);
        $ai_json = call_ai($prompt);

        $decoded = json_decode($ai_json, true);
        if (!$decoded) throw new RuntimeException('JSON AI non valido');

        // 4. Salva scheda nel DB
        $stmt2 = db()->prepare(
            'INSERT INTO schede (utente_id, quiz_id, titolo, contenuto, modello_ai) VALUES (?, ?, ?, ?, ?)'
        );
        $stmt2->execute([$u['id'], $quiz_id, $titolo, $ai_json, AI_MODEL]);
        $scheda_id = (int)db()->lastInsertId();

        respond_created([
            'quiz_id' => $quiz_id,
            'scheda_id' => $scheda_id,
            'scheda' => $decoded,
            'message' => 'Quiz registrato e scheda generata',
        ]);
    } catch (RuntimeException $e) {
        error_log('[AI] ' . $e->getMessage());
        respond(202, [
            'quiz_id' => $quiz_id,
            'warning' => 'Quiz salvato, ma generazione scheda fallita',
        ]);
    }
}
```

**Cosa fa:** Crea un quiz (salva nel DB), poi genera una scheda di allenamento personalizzata via API OpenRouter.

**Flusso:**
```
1. Validazione input (obiettivo, livello, giorni, durata, attrezzatura, limitazioni)
2. INSERT INTO quiz
3. Costruisci prompt con i dati del quiz
4. Chiama API AI (OpenRouter) con modello Gemini
5. Parsa JSON ritornato
6. INSERT INTO schede con il JSON come contenuto
7. Ritorna scheda + quiz_id al client
```

**Strategie Utilizzate:**

1. **Two-Step Insert**: quiz salvato prima di chiedere all'AI
   - Se AI fallisce, il quiz rimane (l'utente può rigenerare)
   - Se salvo la scheda prima del quiz, e il quiz INSERT fallisce, rimane una scheda orfana
   
2. **Graceful Degradation**: se AI fallisce (RuntimeException), ritorno 202 Accepted con quiz_id
   - Client sa: "Il quiz è salvato, la scheda no, riprova dopo"
   - Non è 500 Internal Server Error (colpa mia), non è 400 Bad Request (colpa tua)

3. **Prompt Engineering**: `build_prompt()` costruisce un prompt dettagliato
   ```
   "Crea una scheda di allenamento settimanale personalizzata in JSON.
   Dati utente:
   - Obiettivo: {$quiz['obiettivo']}
   - Livello: {$quiz['livello']}
   ...
   Struttura JSON richiesta: {...}
   Rispondi SOLO con il JSON, senza markdown, senza backtick."
   ```
   Questo costringe il modello AI a ritornare JSON pulito, facile da parsare.

4. **Modello Salvato**: `modello_ai` colonna traccia quale modello AI ha generato la scheda
   - Domani cambio a Claude → posso vedere quali schede sono di Gemini, quali di Claude
   - Utile per A/B testing qualità

**Perché questo approccio:**
- Robustezza: quiz salvato anche se AI fallisce
- Transparenza: il client sa esattamente cosa è successo (201, 202, 500, etc.)
- Audit: traccia quale AI model ha generato cosa

---

## 📋 Parte 7: Schede (`resources/schede.php`)

```php
function handle_schede(array $route): void {
    require_auth();
    $id = $route['id'];
    switch (method()) {
        case 'GET': $id ? get_scheda($id) : get_schede(); break;
        case 'DELETE': $id ? delete_scheda($id) : respond_method_not_allowed(); break;
    }
}

function get_schede(): void {
    $u = require_auth();
    $stmt = db()->prepare(
        'SELECT id, utente_id, quiz_id, titolo, modello_ai, created_at
         FROM schede WHERE utente_id = ? ORDER BY id DESC'
    );
    $stmt->execute([$u['id']]);
    respond_ok($stmt->fetchAll());
}

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
```

**Cosa fa:** Gestisce le schede di allenamento generate.

**Differenza tra `get_schede()` e `get_scheda()`:**
- `get_schede()`: lista parziale (no `contenuto`), perché il JSON della scheda è LONGTEXT e pesante
- `get_scheda()`: contiene il JSON decodificato, pronto per il frontend

**Strategia:**
- **Lazy Loading**: il contenuto completo (JSON) viene caricato solo quando richiesto
- **JSON Parsing Lato Server**: decodifico il JSON nel server, non faccio ritornare una stringa

**Perché:**
- Banda: se l'utente lista 10 schede, non voglio caricarne il JSON completo
- Parsing: il client riceve direttamente un oggetto, non una stringa JSON da parsare

---

## 🗄️ Parte 8: Database Schema

```sql
CREATE TABLE utenti (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    eta TINYINT UNSIGNED NOT NULL,
    sesso ENUM('M','F','Altro') NOT NULL,
    consenso_privacy TINYINT(1) NOT NULL DEFAULT 0,
    theme_seed VARCHAR(7) NOT NULL DEFAULT '#00B894',
    theme_mode ENUM('light','dark','system') NOT NULL DEFAULT 'system',
    profile_pic_path VARCHAR(255) DEFAULT NULL,
    bg_image_path VARCHAR(255) DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**Design Decisions:**

1. **email UNIQUE**: non posso avere due utenti con stessa email
2. **password VARCHAR(255)**: hash bcrypt lungo ~60 char, ma lascio spazio
3. **eta TINYINT UNSIGNED**: 0-255 anni, sufficienti per il use case
4. **sesso ENUM**: valori limitati → spazio minore, validazione a livello DB
5. **theme_seed VARCHAR(7)**: colore esadecimale tipo `#00B894` (6 char + #)
6. **created_at DATETIME DEFAULT CURRENT_TIMESTAMP**: timestamp creazione automatico

```sql
CREATE TABLE quiz (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utente_id INT NOT NULL,
    obiettivo ENUM('dimagrimento','massa','resistenza','mobilita','forza') NOT NULL,
    livello ENUM('principiante','intermedio','avanzato') NOT NULL,
    giorni_settimana TINYINT UNSIGNED NOT NULL,
    durata_sessione SMALLINT UNSIGNED NOT NULL,
    attrezzatura VARCHAR(255),
    limitazioni TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utente_id) REFERENCES utenti(id) ON DELETE CASCADE
);
```

**Design:**
- **ON DELETE CASCADE**: se cancello un utente, cancello automaticamente i suoi quiz
- **ENUM obiettivo/livello**: valori fissi, previene typo nel codice
- **SMALLINT durata_sessione**: 0-65535 minuti = fino a ~45 giorni (più che sufficiente)
- **TEXT limitazioni**: potrebbe essere lungo (es. "ho problemi alle ginocchia, articoli compromesse, posso fare solo esercizi a corpo libero senza atterraggi")

```sql
CREATE TABLE schede (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utente_id INT NOT NULL,
    quiz_id INT NOT NULL UNIQUE,
    titolo VARCHAR(200),
    contenuto LONGTEXT NOT NULL,
    modello_ai VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utente_id) REFERENCES utenti(id) ON DELETE CASCADE,
    FOREIGN KEY (quiz_id) REFERENCES quiz(id) ON DELETE CASCADE
);
```

**Design:**
- **LONGTEXT contenuto**: il JSON della scheda (potrebbe essere 10KB+)
- **quiz_id UNIQUE**: ogni quiz genera una sola scheda (1:1 relationship)
- **modello_ai**: traccia quale AI model ha generato la scheda

```sql
CREATE TABLE login_attempts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(150) NOT NULL,
    ip VARCHAR(45) NOT NULL,
    success TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email_time (email, created_at),
    INDEX idx_ip_time (ip, created_at)
);
```

**Design:**
- **INDEX su (email, created_at)**: velocizza query `WHERE email = ? AND created_at > ?`
- **IPv6 support**: `VARCHAR(45)` per indirizzi IPv6 lungo ::1 (max 45 char)
- **success flag**: traccia successi e fallimenti per distinguere attacchi da utenti dimenticati

---

## 🔑 Parte 9: Pattern Ricorrenti nel Codice

### Pattern 1: Validazione → Salvataggio → Fallback Graceful

```php
// Valida
$nome = v_string($b['nome'], 2, 100, 'nome');

// Prova a salvare
try {
    $stmt = db()->prepare('INSERT INTO ...');
    $stmt->execute([...]);
} catch (PDOException $e) {
    // Fallback: se l'errore è "email duplicata", messaggio specifico
    if ($e->getCode() === '23000') {
        respond_conflict('Email già in uso');
    }
    respond_server_error('Errore', $e);
}
```

**Perché:**
- Validazione lato client + server
- Gestione errori DB specifici
- Niente stack trace leak al client in production

### Pattern 2: Owner-Based Authorization

```php
function require_owner(int $resource_owner_id): void {
    $u = require_auth();
    if ($u['id'] !== $resource_owner_id) respond_forbidden();
}

// Uso:
function get_utente(string $id): void {
    require_owner((int)$id);
    // ... resto della logica
}
```

**Perché:**
- Centralizzato: regola stessa usata ovunque
- Fail-fast: se non sei il proprietario, esci subito con 403

### Pattern 3: Dynamic Query Building

```php
$sets = ['nome=?', 'email=?'];
$args = [$nome, $email];

if (!empty($b['password'])) {
    $sets[] = 'password=?';
    $args[] = password_hash($password, PASSWORD_DEFAULT);
}

$sql = 'UPDATE utenti SET ' . implode(', ', $sets) . ' WHERE id=?';
```

**Perché:**
- Campi facoltativi: non aggiorno password se non inviata
- Evito: "SET password = NULL" quando l'utente non invia password

---

## 🔐 Parte 10: Strategie di Sicurezza

### 1. SQL Injection Prevention
- **Prepared Statements**: `db()->prepare()` + `execute([])`
- **No string concatenation**: `SELECT * FROM utenti WHERE email = '$email'` ❌
- **Parametri sempre legati**: `execute([$email])`

### 2. Password Security
- **Bcrypt**: `password_hash($password, PASSWORD_DEFAULT)`
- **No plain text**: il DB contiene solo hash
- **No reversibility**: nemmeno chi controlla il server recupera la password

### 3. Timing Attack Prevention
```php
$hash = $user ? $user['password'] : DUMMY_HASH;
$ok = password_verify($pwd, $hash) && $user !== false;
```
- `password_verify()` impiega sempre tempo O(n) (costante per hash di una certa lunghezza)
- Attacker non può dedurre se l'utente esiste dal tempo di risposta

### 4. CORS Whitelist
- `ALLOWED_ORIGINS` contiene lista di domini permessi
- Non uso `*` in production (chiunque potrebbe usare la mia API)

### 5. JWT Security
- **Secret Length**: JWT_SECRET deve essere almeno 32 char (256 bit)
- **Expiration**: 24h default, niente token eterni
- **Signature Verification**: `hash_equals()` = constant-time comparison (no timing attacks)

### 6. File Upload Validation
- **MIME Magic**: `finfo` verifica il valore magico, non l'estensione
- **Whitelist**: solo JPEG, PNG, WEBP
- **Size Limits**: max 2-4 MB
- **User-Based Naming**: `{userId}.{ext}` = no directory traversal

### 7. Rate Limiting
- **Login brute-force**: max 5 tentativi in 15 min per (email OR ip)
- **Tracking**: tabella `login_attempts` registra tutto per audit

### 8. Input Validation
- Tutti gli input passano per `v_*` function
- Validazione lato server (il client potrebbe essere compromesso)
- Messaggi di errore non rivelano dettagli (es. "credenziali non valide" vs "utente non esiste")

---

## 📊 Parte 11: Flusso Completo d'Uso

```
┌─────────────────────────────────────────────────────────────┐
│ FASE 1: REGISTRAZIONE                                       │
│ POST /utenti                                                │
│ { nome, email, password, eta, sesso, consenso_privacy }   │
└─────────────────────────────────────────────────────────────┘
                        ↓
    Validazione input → Password hash → INSERT utenti
                        ↓
    Generazione JWT → 201 Created + Token
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ FASE 2: LOGIN (Se utente dimenticato il token)             │
│ POST /login                                                 │
│ { email, password }                                         │
└─────────────────────────────────────────────────────────────┘
                        ↓
    Rate limiting check → password_verify() → Generazione JWT
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ FASE 3: PROFILO                                             │
│ GET /me        → Visualizza profilo                        │
│ PUT /utenti/{id} → Modifica profilo, tema, password        │
│ POST /utenti/{id}/picture → Upload foto profilo            │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ FASE 4: QUIZ & SCHEDA                                       │
│ POST /quiz                                                  │
│ { obiettivo, livello, giorni_settimana, durata_sessione,  │
│   attrezzatura, limitazioni }                              │
└─────────────────────────────────────────────────────────────┘
                        ↓
    INSERT quiz → OpenRouter API → Gemini AI generates JSON
                        ↓
    INSERT schede → 201 Created + scheda JSON
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ FASE 5: VISUALIZZAZIONE & GESTIONE                          │
│ GET /schede     → Lista tutte le schede (no contenuto)     │
│ GET /schede/{id} → Visualizza scheda completa              │
│ GET /quiz       → Lista tutti i quiz                        │
│ DELETE /quiz/{id} → Cancella quiz + scheda associata      │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Parte 12: Scelte Architetturali e Loro Motivazioni

### Scelta 1: No Framework vs. Framework Leggero

**Scelto:** No framework (vanilla PHP)

**Alternativa:** Laravel, Symfony, etc.

**Pro Vanilla:**
- Controllo completo
- Niente magia nascosta
- Deploy semplice (solo PHP builtin)
- Ideale per progetto scolastico (impara tutto)

**Contro Vanilla:**
- Devo implementare manualmente: routing, validation, auth
- Meno protezione da errori comuni

**Per questo progetto:** Vanilla è la scelta giusta (didattico, semplice).

---

### Scelta 2: JWT vs. Session + Cookie

**Scelto:** JWT

**Alternativa:** Server-side sessions con DB + cookie

**Pro JWT:**
- Stateless: no session table nel DB
- Scalabile: funziona con load balancing
- Mobile-friendly: il token è nel header Authorization
- Debugging facile: leggo il payload decodificandolo

**Contro JWT:**
- Revoca difficile (il token è valido finché non scade)
- File size (il token è lungo)

**Per questo progetto:** JWT perfetto (API REST, stateless).

---

### Scelta 3: OpenRouter + Gemini vs. Self-Hosted LLM

**Scelto:** OpenRouter API + Google Gemini Flash

**Alternativa:** Ollama, Llama 2 localmente

**Pro OpenRouter:**
- Niente setup complicato
- Modelli di qualità (Gemini, Claude, Llama)
- Failover automatico (se Gemini is down, prova Claude)
- Billing per token (pay-as-you-go)

**Contro OpenRouter:**
- Dipendenza da servizio esterno
- Latenza rete

**Per questo progetto:** OpenRouter è pragmatico (MVP veloce).

---

### Scelta 4: LONGTEXT per Schede vs. Tabella Separata

**Scelto:** Colonna `schede.contenuto` con LONGTEXT

**Alternativa:** Tabella `scheda_esercizi`, `scheda_giorni`, etc.

**Pro LONGTEXT:**
- Semplice: il JSON è auto-contained
- Flessibilità: il formato JSON può evolversi senza migration
- Denormalizzato: una query = tutto

**Contro LONGTEXT:**
- Non queryable (non posso filtrare per "schede con esercizio 'squat'")
- Redundanza se molte schede hanno stessi esercizi

**Per questo progetto:** LONGTEXT è il compromesso migliore (queryability non serve, semplicicità sì).

---

### Scelta 5: File System vs. S3 per Upload

**Scelto:** File system locale (`/uploads/profiles/`)

**Alternativa:** AWS S3, Google Cloud Storage

**Pro File System:**
- Gratuito
- Setup zero
- No API esterna

**Contro File System:**
- Non scalabile (file fissi in disco)
- Backup manuale
- Hard con multiple servers

**Per questo progetto:** File system va bene (progetto didattico, un server).

---

## ✅ Conclusione

Questo API REST segue principi solidi:

1. **Sicurezza**: JWT, password hashing, prepared statements, CORS, rate limiting
2. **Usabilità**: REST semantico, errori chiari, rate limiting morbido
3. **Manutenibilità**: helpers centralizzati, lazy loading, dynamic queries
4. **Scalabilità**: stateless, single responsibility, indici DB

Ogni scelta architetturale ha un tradeoff esplicito. Per un MVP in ambiente scolastico, questo design è equilibrato tra semplicità e robustezza.

---

**Fine Guida**
