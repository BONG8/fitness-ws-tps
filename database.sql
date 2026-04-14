CREATE DATABASE IF NOT EXISTS fitness_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE fitness_db;

CREATE TABLE utenti (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    nome       VARCHAR(100)        NOT NULL,
    email      VARCHAR(150)        NOT NULL UNIQUE,
    eta        TINYINT UNSIGNED    NOT NULL,
    sesso      ENUM('M','F','Altro') NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
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
