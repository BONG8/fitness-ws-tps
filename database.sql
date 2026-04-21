CREATE DATABASE IF NOT EXISTS fitness_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE fitness_db;

CREATE TABLE utenti (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    nome              VARCHAR(100)        NOT NULL,
    email             VARCHAR(150)        NOT NULL UNIQUE,
    password          VARCHAR(255)        NOT NULL,
    eta               TINYINT UNSIGNED    NOT NULL,
    sesso             ENUM('M','F','Altro') NOT NULL,
    consenso_privacy  TINYINT(1)          NOT NULL DEFAULT 0,
    theme_seed        VARCHAR(7)          NOT NULL DEFAULT '#00B894',
    theme_mode        ENUM('light','dark','system') NOT NULL DEFAULT 'system',
    profile_pic_path  VARCHAR(255)        DEFAULT NULL,
    bg_image_path     VARCHAR(255)        DEFAULT NULL,
    created_at        DATETIME            DEFAULT CURRENT_TIMESTAMP
);

-- Migration for existing DBs — run ONCE:
-- ALTER TABLE utenti
--   ADD COLUMN theme_seed VARCHAR(7) NOT NULL DEFAULT '#00B894',
--   ADD COLUMN theme_mode ENUM('light','dark','system') NOT NULL DEFAULT 'system',
--   ADD COLUMN profile_pic_path VARCHAR(255) DEFAULT NULL,
--   ADD COLUMN bg_image_path VARCHAR(255) DEFAULT NULL;

CREATE TABLE login_attempts (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    email      VARCHAR(150) NOT NULL,
    ip         VARCHAR(45)  NOT NULL,
    success    TINYINT(1)   NOT NULL DEFAULT 0,
    created_at DATETIME     DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email_time (email, created_at),
    INDEX idx_ip_time    (ip, created_at)
);

CREATE TABLE quiz (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    utente_id           INT NOT NULL,
    obiettivo           ENUM('dimagrimento','massa','resistenza','mobilita','forza') NOT NULL,
    livello             ENUM('principiante','intermedio','avanzato') NOT NULL,
    giorni_settimana    TINYINT UNSIGNED NOT NULL,    -- quanti giorni vuole allenarsi
    durata_sessione     SMALLINT UNSIGNED NOT NULL,   -- minuti per sessione
    attrezzatura        VARCHAR(255),                  -- es. "manubri,bilanciere,niente"
    limitazioni         TEXT,                          -- eventuali infortuni/note
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utente_id) REFERENCES utenti(id) ON DELETE CASCADE
);

CREATE TABLE schede (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    utente_id   INT NOT NULL,
    quiz_id     INT NOT NULL UNIQUE,      -- 1:1 con il quiz che l'ha generata
    titolo      VARCHAR(200),
    contenuto   LONGTEXT NOT NULL,        -- JSON restituito dall'AI
    modello_ai  VARCHAR(100),             -- es. "google/gemini-pro"
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utente_id) REFERENCES utenti(id) ON DELETE CASCADE,
    FOREIGN KEY (quiz_id)   REFERENCES quiz(id)   ON DELETE CASCADE
);
