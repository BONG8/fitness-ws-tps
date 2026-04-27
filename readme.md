# 🏋️ Fitness Web Service API

Un'API **RESTful** moderna costruita con **PHP** per gestire profili fitness, questionari e schede di allenamento. Il servizio utilizza autenticazione **basata su JWT**, **MariaDB** per la persistenza e Docker per la containerizzazione.

---

## 📋 Indice dei Contenuti
- [Caratteristiche](#caratteristiche)
- [Architettura](#architettura)
- [Prerequisiti](#prerequisiti)
- [Come Iniziare](#come-iniziare)
- [Overview API](#overview-api)
- [Struttura del Progetto](#struttura-del-progetto)

---

## ✨ Caratteristiche

- **API REST Stateless** con autenticazione JWT
- **Gestione Utenti**: registrazione, login, aggiornamento profilo
- **Questionari Fitness**: raccogli obiettivi e livelli di fitness
- **Schede di Allenamento**: genera e gestisci programmi personalizzati
- **Caricamento File**: supporto per foto profilo e immagini di sfondo
- **CORS abilitato** per richieste cross-origin
- **Database containerizzato** con inizializzazione automatica dello schema
- **Validazione input** e gestione errori su tutti gli endpoint

---

## 🏗️ Architettura

L'API segue un modello di **architettura a strati**:

```
┌─────────────────────────────────────────┐
│   Client (Web / Mobile / Desktop)       │
└────────────────┬────────────────────────┘
                 │ HTTP + JSON + JWT
                 │
┌────────────────▼─────────────────┐
│  index.php (Router)              │
│  ├─ /resources/utenti.php        │
│  ├─ /resources/quiz.php          │
│  └─ /resources/schede.php        │
└────────────────┬─────────────────┘
                 │
┌────────────────▼─────────────────┐
│  /lib/helpers.php                │
│  ├─ Gestione JWT                 │
│  ├─ Query DB                     │
│  └─ Formattazione risposte       │
└────────────────┬─────────────────┘
                 │
┌────────────────▼──────────────────┐
│   MariaDB (Docker Container)       │
│   Database: fitness_db             │
└────────────────────────────────────┘
```

**Decisioni Architetturali Chiave:**
- **Stateless**: Ogni richiesta è auto-contenuta tramite token JWT
- **Lazy Loading**: I gestori delle risorse sono caricati solo quando necessario
- **Separazione dei Compiti**: Config, helpers e logica business sono isolati
- **Database Unico**: Archivio dati centralizzato con migrazioni automatiche

Per una spiegazione architetturale dettagliata, vedi [ARCHITETTURA-GUIDA.md](ARCHITETTURA-GUIDA.md).

---

## 📋 Prerequisiti

- **PHP** ≥ 7.4 (con estensione PDO MySQL)
- **Docker** & **Docker Compose** (per MariaDB)
- **Git** (per clonare il repository)
- Un client REST come **Postman** o **cURL** (opzionale, per i test)

---

## 🚀 Come Iniziare

Scegli il metodo di setup che preferisci: **Docker** (consigliato per lo sviluppo) o **XAMPP** (per setup all-in-one).

---

### ⚙️ OPZIONE A: Docker + Server PHP Built-in (Consigliato)

Questo è l'approccio più pulito per lo sviluppo, usando Docker per il database e il server PHP built-in per l'API.

#### Passo 1: Clona e Setup

```bash
git clone <repository-url>
cd fitness-ws
```

#### Passo 2: Configura le Variabili d'Ambiente

Copia il file di ambiente:

```bash
cp .env.example .env
```

Modifica `.env` con le credenziali del database (i valori di default sono già forniti):
```env
APP_NAME=FitnessWS
APP_ENV=development
DB_HOST=127.0.0.1
DB_NAME=fitness_db
DB_USER=fitness_user
DB_PASS=s
JWT_SECRET=your-secret-key-here
JWT_TTL=86400
```

#### Passo 3: Avvia il Database (Docker)

```bash
docker compose up -d
```

Questo farà:
- Scaricherà l'immagine **MariaDB 10.5**
- Creerà il database `fitness_db`
- Inizializzerà le tabelle da `database.sql`
- Esporrà il database su `localhost:3306`

**Credenziali del Database:**
- Host: `127.0.0.1` | Porta: `3306`
- Database: `fitness_db`
- Utente: `fitness_user` | Password: `s`
- Password Root: `root`

Verifica che il database sia in esecuzione:
```bash
docker compose ps
```

#### Passo 4: Avvia il Server PHP

Apri un **nuovo terminale** nella root del progetto:

```bash
php -S localhost:8000
```

L'API è ora disponibile su **`http://localhost:8000`**

#### Passo 5: Verifica che Tutto Funzioni

Testa un endpoint veloce:
```bash
curl http://localhost:8000/utenti
```

#### Fermare Tutto

**Ferma il server PHP:**
```bash
# Premi Ctrl+C nel terminale del PHP
```

**Ferma il database:**
```bash
docker compose down
```

I tuoi dati persisteranno nel Docker volume. Per rimuovere tutto:
```bash
docker compose down -v
```

---

### 🪟 OPZIONE B: XAMPP (Windows / All-in-One)

Se preferisci un setup tutto integrato senza Docker, usa XAMPP che include PHP, Apache e MySQL.

#### Passo 1: Installa XAMPP

1. Scarica [XAMPP](https://www.apachefriends.org/) (Windows/Mac/Linux)
2. Esegui l'installer e seleziona almeno:
   - ✅ Apache
   - ✅ MySQL/MariaDB
   - ✅ PHP
3. Completa l'installazione

#### Passo 2: Clona il Progetto

Naviga nella cartella `htdocs` di XAMPP e clona:

```bash
# Windows: C:\xampp\htdocs
# Mac: /Applications/XAMPP/htdocs
# Linux: /opt/lampp/htdocs

cd htdocs
git clone <repository-url> fitness-ws
cd fitness-ws
```

#### Passo 3: Configura le Variabili d'Ambiente

Copia il file di ambiente:

```bash
cp .env.example .env
```

Modifica `.env` per XAMPP (MySQL al posto di Docker):
```env
APP_NAME=FitnessWS
APP_ENV=development
DB_HOST=localhost
DB_NAME=fitness_db
DB_USER=root
DB_PASS=
JWT_SECRET=your-secret-key-here
JWT_TTL=86400
```

**Nota:** L'utente MySQL di default in XAMPP è `root` **senza password**.

#### Passo 4: Avvia i Servizi XAMPP

1. Apri il **Pannello di Controllo XAMPP**
2. Clicca **Start** per:
   - ✅ Apache
   - ✅ MySQL
3. Attendi che entrambi mostrino "Running" (verde)

#### Passo 5: Crea il Database e Importa lo Schema

1. Apri **phpMyAdmin**: http://localhost/phpmyadmin/
2. Clicca **Database** → Crea nuovo database:
   - Nome: `fitness_db`
   - Collazione: `utf8mb4_unicode_ci`
   - Clicca **Crea**
3. Clicca sul nuovo database `fitness_db`
4. Clicca sulla tab **Importa**
5. Clicca **Scegli File** → seleziona `database.sql` dal tuo progetto
6. Clicca **Importa**

Il database è ora pronto con tutte le tabelle e i dati di esempio.

#### Passo 6: Accedi all'API

L'API è ora disponibile su:

```
http://localhost/fitness-ws
```

Testa un endpoint veloce:
```bash
curl http://localhost/fitness-ws/utenti
```

#### Passo 7: Fermare Tutto

1. Apri il **Pannello di Controllo XAMPP**
2. Clicca **Stop** per Apache e MySQL

O dalla riga di comando:

**Windows (PowerShell come Admin):**
```powershell
# Ferma Apache
C:\xampp\apache_stop.bat

# Ferma MySQL
C:\xampp\mysql_stop.bat
```

**Mac/Linux:**
```bash
# Ferma tutti i servizi
sudo /Applications/XAMPP/xamppfiles/xampp stop
```

---

### 🔄 Passare da un Setup all'Altro

Se vuoi passare da Docker a XAMPP (o vice versa):

1. **Aggiorna `.env`** con le nuove credenziali del database:
   ```env
   # Per Docker:
   DB_HOST=127.0.0.1
   DB_USER=fitness_user
   DB_PASS=s
   
   # Per XAMPP:
   DB_HOST=localhost
   DB_USER=root
   DB_PASS=
   ```

2. **Riavvia i tuoi servizi** (database o XAMPP)

3. **Il codice dell'API rimane esattamente uguale** — non è necessario fare nessun cambiamento!

---

## 🔗 Overview API

### Autenticazione
La maggior parte degli endpoint richiede un **token JWT** ottenuto dall'endpoint `/login`. Includilo nelle richieste:
```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:8000/utenti/1
```

### Risorse Principali

| Risorsa | Endpoint | Scopo |
|---------|----------|-------|
| **Utenti** | `POST /utenti`, `GET /utenti/{id}`, `PUT /utenti/{id}`, `DELETE /utenti/{id}` | Profili utente e registrazione |
| **Login** | `POST /login`, `GET /me` | Autenticazione e info sessione |
| **Quiz** | `POST /quiz`, `GET /quiz`, `GET /quiz/{id}`, `DELETE /quiz/{id}` | Questionari fitness |
| **Schede** | `GET /schede`, `GET /schede/{id}`, `DELETE /schede/{id}` | Schede di allenamento |

### Richieste di Esempio

**Registra un Utente:**
```bash
curl -X POST http://localhost:8000/utenti \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Mario Rossi",
    "email": "mario@example.com",
    "password": "SecurePass123!",
    "eta": 28,
    "sesso": "M",
    "consenso_privacy": true
  }'
```

**Login:**
```bash
curl -X POST http://localhost:8000/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mario@example.com",
    "password": "SecurePass123!"
  }'
```

**Ottieni Profilo Utente Autenticato:**
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8000/me
```

Per un riferimento completo di tutti gli endpoint con parametri e codici di risposta, vedi [QUICK-REFERENCE.md](QUICK-REFERENCE.md).

---

## 📂 Struttura del Progetto

```
fitness-ws/
├── index.php                    # Router principale
├── lib/
│   ├── config.php              # Configurazione & variabili d'ambiente
│   └── helpers.php             # Funzioni utility condivise
├── resources/
│   ├── utenti.php              # Gestori per gestione utenti
│   ├── quiz.php                # Gestori per questionari
│   └── schede.php              # Gestori per schede di allenamento
├── database.sql                 # Schema database e dati di seed
├── docker-compose.yml          # Configurazione Docker
├── .env                        # Variabili d'ambiente (non in git)
├── readme.md                   # Questo file
├── guide.md                    # Guida di setup
├── QUICK-REFERENCE.md          # Riferimento rapido degli endpoint
├── ARCHITETTURA-GUIDA.md       # Guida dettagliata all'architettura
├── postman-collection.json     # Collezione API Postman
└── test-curl-collection.sh     # Script shell per i test degli endpoint
```

### Descrizioni dei File

- **index.php**: Punto di ingresso che instrada tutte le richieste ai gestori delle risorse
- **lib/config.php**: Carica le variabili d'ambiente e definisce le costanti dell'applicazione
- **lib/helpers.php**: Contiene la gestione dei token JWT, le query DB, la logica CORS e la formattazione delle risposte
- **resources/***: Logica business per ogni risorsa API (utenti, quiz, schede)
- **database.sql**: Schema completo del database con tabelle e dati iniziali
- **docker-compose.yml**: Definisce la configurazione del servizio MariaDB

---

## 🧪 Test

### Usando cURL

Testa un endpoint con curl:
```bash
# Senza autenticazione richiesta
curl http://localhost:8000/utenti \
  -H "Content-Type: application/json" \
  -d '{"nome":"John","email":"john@test.com","password":"Pass123!","eta":25,"sesso":"M","consenso_privacy":true}'

# Autenticazione richiesta (usa il token dalla risposta di login)
curl http://localhost:8000/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Usando Postman

1. Importa `postman-collection.json` in Postman
2. Configura la variabile `{{base_url}}` a `http://localhost:8000`
3. Esegui le richieste dalla collezione

### Usando lo Script di Test

Esegui la suite di test inclusa:
```bash
bash test-curl-collection.sh
```

---

## 🔐 Sicurezza

- **Token JWT**: Autenticazione sicura e stateless
- **Hashing Password**: Password hashate con bcrypt
- **CORS Protection**: Accesso cross-origin configurabile
- **Validazione Input**: Tutti gli input validati prima delle operazioni su database
- **Prevenzione SQL Injection**: Prepared statements su tutte le query

---

## 📝 Variabili d'Ambiente

Variabili richieste nel file `.env`:

```env
APP_NAME=FitnessWS                    # Nome applicazione
APP_ENV=development                    # development | production
DB_HOST=127.0.0.1                     # Host del database
DB_NAME=fitness_db                     # Nome del database
DB_USER=fitness_user                   # Utente del database
DB_PASS=s                              # Password del database
DB_CHARSET=utf8mb4                     # Encoding caratteri
JWT_SECRET=your-secret-key             # Segreto per la firma JWT
JWT_TTL=86400                          # TTL del token in secondi (24h)
```

---

## 🐛 Troubleshooting

**Il database non si connette:**
- Assicurati che Docker sia in esecuzione: `docker ps`
- Controlla che le credenziali corrispondano a `.env`
- Verifica che il database sia attivo: `docker compose logs`

**Il server PHP non parte:**
- Assicurati che la porta 8000 sia libera: `lsof -i :8000`
- Controlla la versione di PHP: `php -v` (richiede ≥ 7.4)

**Errori di token JWT:**
- Assicurati che `JWT_SECRET` sia impostato nel `.env`
- Controlla il formato del token: `Authorization: Bearer TOKEN`
- I token scadono dopo `JWT_TTL` secondi (default 24h)

---

## 📄 Licenza

Questo progetto fa parte di un'assegnazione scolastica (TPS - Quinto Anno).
