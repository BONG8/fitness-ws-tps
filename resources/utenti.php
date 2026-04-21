<?php
// /fitness_ws/resources/utenti.php

const SESSO_VALUES = ['M', 'F', 'Altro'];
const THEME_MODE_VALUES = ['light', 'dark', 'system'];
const DUMMY_HASH   = '$2y$10$abcdefghijklmnopqrstuuGm2l5QK7B7p3A6jGkWqk7lJ0oQX9gKm'; // constant-time fallback

function handle_utenti(array $route): void {
    $id  = $route['id'];
    $sub = $route['sub'] ?? null;

    // Sub-routes on /utenti/{id}/...
    if ($id && $sub === 'picture') {
        switch (method()) {
            case 'POST':   upload_profile_picture($id); return;
            case 'DELETE': delete_profile_picture($id); return;
            default:       respond_method_not_allowed(); return;
        }
    }
    if ($id && $sub === 'background') {
        switch (method()) {
            case 'POST':   upload_background($id); return;
            case 'DELETE': delete_background($id); return;
            default:       respond_method_not_allowed(); return;
        }
    }

    switch (method()) {
        case 'GET':    $id ? get_utente($id)     : respond_forbidden('Elenco utenti non disponibile'); break;
        case 'POST':   !$id ? create_utente()    : respond_method_not_allowed(); break;
        case 'PUT':    $id  ? update_utente($id) : respond_method_not_allowed(); break;
        case 'DELETE': $id  ? delete_utente($id) : respond_method_not_allowed(); break;
        default:       respond_method_not_allowed();
    }
}

function fetch_utente_full(int $id): ?array {
    $stmt = db()->prepare(
        'SELECT id, nome, email, eta, sesso, theme_seed, theme_mode, profile_pic_path, bg_image_path, created_at
         FROM utenti WHERE id = ?'
    );
    $stmt->execute([$id]);
    $row = $stmt->fetch();
    if (!$row) return null;
    $row['profile_pic_url']   = public_pic_url($row['profile_pic_path'] ?? null);
    $row['background_url']    = public_pic_url($row['bg_image_path'] ?? null);
    unset($row['profile_pic_path'], $row['bg_image_path']);
    return $row;
}

// GET /utenti/{id} → solo il proprio profilo
function get_utente(string $id): void {
    require_owner((int)$id);
    $row = fetch_utente_full((int)$id);
    $row ? respond_ok($row) : respond_not_found('Utente non trovato');
}

// POST /utenti → registrazione
function create_utente(): void {
    $b = get_body();

    $nome     = v_string($b['nome']     ?? null, 2, 100, 'nome');
    $email    = v_email($b['email']     ?? null);
    $password = v_password($b['password'] ?? null);
    $eta      = v_int_range($b['eta']   ?? null, 13, 100, 'eta');
    $sesso    = v_enum($b['sesso']      ?? null, SESSO_VALUES, 'sesso');
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
            'id'      => $uid,
            'message' => 'Utente creato',
            'token'   => $token,
            'user'    => ['id' => $uid, 'nome' => $nome, 'email' => $email],
        ]);
    } catch (PDOException $e) {
        if ($e->getCode() === '23000') {
            respond_conflict('Email già in uso');
        }
        respond_server_error('Errore creazione utente', $e);
    }
}

// PUT /utenti/{id} → aggiornamento completo (owner-only)
function update_utente(string $id): void {
    require_owner((int)$id);
    $b = get_body();

    $nome  = v_string($b['nome']  ?? null, 2, 100, 'nome');
    $email = v_email($b['email']  ?? null);
    $eta   = v_int_range($b['eta'] ?? null, 13, 100, 'eta');
    $sesso = v_enum($b['sesso']   ?? null, SESSO_VALUES, 'sesso');

    // Optional theme fields — keep existing if omitted
    $hasThemeSeed = array_key_exists('theme_seed', $b);
    $hasThemeMode = array_key_exists('theme_mode', $b);
    $themeSeed = $hasThemeSeed ? v_hex_color($b['theme_seed'], 'theme_seed') : null;
    $themeMode = $hasThemeMode ? v_enum($b['theme_mode'], THEME_MODE_VALUES, 'theme_mode') : null;

    try {
        $sets = ['nome=?', 'email=?', 'eta=?', 'sesso=?'];
        $args = [$nome, $email, $eta, $sesso];

        if (!empty($b['password'])) {
            $password = v_password($b['password']);
            $sets[] = 'password=?';
            $args[] = password_hash($password, PASSWORD_DEFAULT);
        }
        if ($hasThemeSeed) {
            $sets[] = 'theme_seed=?';
            $args[] = $themeSeed;
        }
        if ($hasThemeMode) {
            $sets[] = 'theme_mode=?';
            $args[] = $themeMode;
        }
        $args[] = $id;

        $sql = 'UPDATE utenti SET ' . implode(', ', $sets) . ' WHERE id=?';
        $stmt = db()->prepare($sql);
        $stmt->execute($args);

        $user = fetch_utente_full((int)$id);
        respond_ok(['message' => 'Aggiornato', 'user' => $user]);
    } catch (PDOException $e) {
        if ($e->getCode() === '23000') {
            respond_conflict('Email già in uso');
        }
        if ($e->getCode() === '42S22') {
            respond_server_error(
                'Colonne DB mancanti. Esegui la migration ALTER TABLE utenti (vedi database.sql).',
                $e
            );
        }
        respond_server_error('Errore aggiornamento: ' . $e->getMessage(), $e);
    }
}

// POST /utenti/{id}/picture → upload immagine profilo (multipart/form-data, field "file")
function upload_profile_picture(string $id): void {
    require_owner((int)$id);
    $rel = handle_profile_upload('file', (int)$id);
    try {
        $stmt = db()->prepare('UPDATE utenti SET profile_pic_path=? WHERE id=?');
        $stmt->execute([$rel, $id]);
    } catch (PDOException $e) {
        respond_server_error('Errore salvataggio profilo', $e);
    }
    $user = fetch_utente_full((int)$id);
    respond_ok(['message' => 'Immagine caricata', 'user' => $user]);
}

// DELETE /utenti/{id}/picture → rimuove l'immagine
function delete_profile_picture(string $id): void {
    require_owner((int)$id);
    $stmt = db()->prepare('SELECT profile_pic_path FROM utenti WHERE id=?');
    $stmt->execute([$id]);
    $row = $stmt->fetch();
    if ($row && !empty($row['profile_pic_path'])) {
        $abs = __DIR__ . '/../' . $row['profile_pic_path'];
        if (is_file($abs)) @unlink($abs);
    }
    $stmt = db()->prepare('UPDATE utenti SET profile_pic_path=NULL WHERE id=?');
    $stmt->execute([$id]);
    $user = fetch_utente_full((int)$id);
    respond_ok(['message' => 'Immagine rimossa', 'user' => $user]);
}

// POST /utenti/{id}/background → upload sfondo (multipart, field "file")
function upload_background(string $id): void {
    require_owner((int)$id);
    $rel = handle_image_upload('file', (int)$id, 'backgrounds', 4 * 1024 * 1024);
    try {
        $stmt = db()->prepare('UPDATE utenti SET bg_image_path=? WHERE id=?');
        $stmt->execute([$rel, $id]);
    } catch (PDOException $e) {
        respond_server_error('Errore salvataggio sfondo', $e);
    }
    $user = fetch_utente_full((int)$id);
    respond_ok(['message' => 'Sfondo caricato', 'user' => $user]);
}

// DELETE /utenti/{id}/background → rimuove lo sfondo
function delete_background(string $id): void {
    require_owner((int)$id);
    $stmt = db()->prepare('SELECT bg_image_path FROM utenti WHERE id=?');
    $stmt->execute([$id]);
    $row = $stmt->fetch();
    if ($row && !empty($row['bg_image_path'])) {
        $abs = __DIR__ . '/../' . $row['bg_image_path'];
        if (is_file($abs)) @unlink($abs);
    }
    $stmt = db()->prepare('UPDATE utenti SET bg_image_path=NULL WHERE id=?');
    $stmt->execute([$id]);
    $user = fetch_utente_full((int)$id);
    respond_ok(['message' => 'Sfondo rimosso', 'user' => $user]);
}

// DELETE /utenti/{id} (owner-only)
function delete_utente(string $id): void {
    require_owner((int)$id);
    $stmt = db()->prepare('DELETE FROM utenti WHERE id = ?');
    $stmt->execute([$id]);
    $stmt->rowCount() ? respond_no_content() : respond_not_found('Utente non trovato');
}

// POST /login
function login_utente(): void {
    $b = get_body();
    if (empty($b['email']) || empty($b['password'])) {
        respond_bad_request('Campi obbligatori: email, password');
    }

    $email = is_string($b['email']) ? trim(mb_strtolower($b['email'])) : '';
    $pwd   = is_string($b['password']) ? $b['password'] : '';
    $ip    = client_ip();

    if ($email === '' || $pwd === '') {
        respond_bad_request('Credenziali mancanti');
    }

    if (login_attempts_count($email, $ip) >= LOGIN_MAX_ATTEMPTS) {
        respond_too_many('Troppi tentativi falliti. Riprova tra qualche minuto.');
    }

    $stmt = db()->prepare('SELECT id, password, nome, email FROM utenti WHERE email = ?');
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    // Constant-time: always run password_verify to avoid user enumeration via timing
    $hash = $user ? $user['password'] : DUMMY_HASH;
    $ok   = password_verify($pwd, $hash) && $user !== false;

    record_login_attempt($email, $ip, $ok);

    if (!$ok) {
        respond_unauthorized('Credenziali non valide');
    }

    $token = jwt_issue((int)$user['id'], $user['email']);
    respond_ok([
        'message' => 'Login completato',
        'token'   => $token,
        'user'    => [
            'id'    => (int)$user['id'],
            'nome'  => $user['nome'],
            'email' => $user['email'],
        ],
    ]);
}
