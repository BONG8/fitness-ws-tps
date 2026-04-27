# 📚 API Fitness Web Service - Guida Completa

## Panoramica

API REST per un sistema di fitness che permette di:
- Gestire profili utenti con autenticazione JWT
- Creare e consultare quiz per l'allenamento
- Generare schede di allenamento personalizzate tramite AI

**Base URL:** `http://localhost:8000`  
**Authentication:** Bearer Token (JWT HS256)

---

## 📋 Indice

1. [Autenticazione](#autenticazione)
2. [Utenti](#utenti)
3. [Login](#login)
4. [Quiz](#quiz)
5. [Schede](#schede)
6. [Codici di Risposta](#codici-di-risposta)

---

## Autenticazione

### Come ottenere un token JWT

Tutti gli endpoint protetti richiedono un token JWT nell'header `Authorization`:

```
Authorization: Bearer <token>
```

Il token viene ottenuto tramite:
- **Registrazione** (POST `/utenti`) → token generato automaticamente
- **Login** (POST `/login`) → token generato al login

**Token di esempio:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjksImVtYWlsIjoibWFyaW9AZXhhbXBsZS5jb20iLCJpYXQiOjE3NzcyODY5NTgsImV4cCI6MTc3NzM3MzM1OH0.1dxrCwPktfBDre5GNhGsqSAN6ItoLiUmjdmt6iI8Jik
```

**Validità del token:** 24 ore (configurabile in `.env` con `JWT_TTL`)

---

## UTENTI

### 1️⃣ Registrazione Utente

**Endpoint:** `POST /utenti`  
**Autenticazione:** No  
**Content-Type:** `application/json`

#### Request

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

#### Parametri

| Campo | Tipo | Obbligatorio | Descrizione |
|-------|------|------|-------------|
| `nome` | string | ✅ | Nome utente (2-100 caratteri) |
| `email` | string | ✅ | Email valida (max 150 caratteri) |
| `password` | string | ✅ | Min 8 char, max 128, almeno 1 lettera e 1 numero |
| `eta` | integer | ✅ | Età (13-100 anni) |
| `sesso` | string | ✅ | Uno di: `M`, `F`, `Altro` |
| `consenso_privacy` | boolean | ✅ | Deve essere `true` |

#### Response (201 Created)

```json
{
  "id": 9,
  "message": "Utente creato",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 9,
    "nome": "Mario Rossi",
    "email": "mario@example.com"
  }
}
```

#### Errori

| Codice | Messaggio | Causa |
|--------|-----------|-------|
| 400 | Campo non valido | Validazione fallita |
| 409 | Email già in uso | Email già registrata |

---

### 2️⃣ Get Profilo Utente

**Endpoint:** `GET /utenti/{id}`  
**Autenticazione:** ✅ Sì (solo il proprietario)  

#### Request

```bash
curl -X GET http://localhost:8000/utenti/9 \
  -H "Authorization: Bearer <token>"
```

#### Response (200 OK)

```json
{
  "id": 9,
  "nome": "Mario Rossi",
  "email": "mario@example.com",
  "eta": 28,
  "sesso": "M",
  "theme_seed": "#00B894",
  "theme_mode": "system",
  "created_at": "2026-04-27 10:49:17",
  "profile_pic_url": null,
  "background_url": null
}
```

#### Errori

| Codice | Messaggio |
|--------|-----------|
| 401 | Token mancante o non valido |
| 403 | Accesso negato (non sei il proprietario) |
| 404 | Utente non trovato |

---

### 3️⃣ Aggiorna Profilo Utente

**Endpoint:** `PUT /utenti/{id}`  
**Autenticazione:** ✅ Sì (solo il proprietario)  
**Content-Type:** `application/json`

#### Request

```bash
curl -X PUT http://localhost:8000/utenti/9 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "nome": "Mario Rossi Updated",
    "email": "mario@example.com",
    "eta": 29,
    "sesso": "M",
    "password": "NewSecurePass456!",
    "theme_seed": "#FF6B6B",
    "theme_mode": "dark"
  }'
```

#### Parametri

| Campo | Tipo | Obbligatorio | Descrizione |
|-------|------|------|-------------|
| `nome` | string | ✅ | Nome utente (2-100 caratteri) |
| `email` | string | ✅ | Email valida |
| `eta` | integer | ✅ | Età (13-100 anni) |
| `sesso` | string | ✅ | `M`, `F`, `Altro` |
| `password` | string | ❌ | Nuova password (se vuoto, non cambia) |
| `theme_seed` | string | ❌ | Colore tema esadecimale (#RRGGBB) |
| `theme_mode` | string | ❌ | `light`, `dark`, `system` |

#### Response (200 OK)

```json
{
  "message": "Aggiornato",
  "user": {
    "id": 9,
    "nome": "Mario Rossi Updated",
    "email": "mario@example.com",
    "eta": 29,
    "sesso": "M",
    "theme_seed": "#FF6B6B",
    "theme_mode": "dark",
    "created_at": "2026-04-27 10:49:17",
    "profile_pic_url": null,
    "background_url": null
  }
}
```

---

### 4️⃣ Upload Foto Profilo

**Endpoint:** `POST /utenti/{id}/picture`  
**Autenticazione:** ✅ Sì (solo il proprietario)  
**Content-Type:** `multipart/form-data`  
**Max size:** 2 MB  
**Formati:** JPEG, PNG, WEBP

#### Request

```bash
curl -X POST http://localhost:8000/utenti/9/picture \
  -H "Authorization: Bearer <token>" \
  -F "file=@/path/to/profile.jpg"
```

#### Response (200 OK)

```json
{
  "message": "Immagine caricata",
  "user": {
    "id": 9,
    "nome": "Mario Rossi",
    "email": "mario@example.com",
    "eta": 28,
    "sesso": "M",
    "theme_seed": "#00B894",
    "theme_mode": "system",
    "created_at": "2026-04-27 10:49:17",
    "profile_pic_url": "http://localhost:8000/uploads/profiles/9.jpg?v=1234567890",
    "background_url": null
  }
}
```

---

### 5️⃣ Cancella Foto Profilo

**Endpoint:** `DELETE /utenti/{id}/picture`  
**Autenticazione:** ✅ Sì (solo il proprietario)

#### Request

```bash
curl -X DELETE http://localhost:8000/utenti/9/picture \
  -H "Authorization: Bearer <token>"
```

#### Response (200 OK)

```json
{
  "message": "Immagine rimossa",
  "user": {
    "id": 9,
    "nome": "Mario Rossi",
    "email": "mario@example.com",
    "profile_pic_url": null,
    "background_url": null
  }
}
```

---

### 6️⃣ Upload Sfondo

**Endpoint:** `POST /utenti/{id}/background`  
**Autenticazione:** ✅ Sì (solo il proprietario)  
**Content-Type:** `multipart/form-data`  
**Max size:** 4 MB  
**Formati:** JPEG, PNG, WEBP

#### Request

```bash
curl -X POST http://localhost:8000/utenti/9/background \
  -H "Authorization: Bearer <token>" \
  -F "file=@/path/to/background.jpg"
```

#### Response (200 OK)

```json
{
  "message": "Sfondo caricato",
  "user": {
    "id": 9,
    "nome": "Mario Rossi",
    "profile_pic_url": null,
    "background_url": "http://localhost:8000/uploads/backgrounds/9.jpg?v=1234567890"
  }
}
```

---

### 7️⃣ Cancella Sfondo

**Endpoint:** `DELETE /utenti/{id}/background`  
**Autenticazione:** ✅ Sì (solo il proprietario)

#### Request

```bash
curl -X DELETE http://localhost:8000/utenti/9/background \
  -H "Authorization: Bearer <token>"
```

#### Response (200 OK)

```json
{
  "message": "Sfondo rimosso",
  "user": {
    "background_url": null
  }
}
```

---

### 8️⃣ Cancella Utente

**Endpoint:** `DELETE /utenti/{id}`  
**Autenticazione:** ✅ Sì (solo il proprietario)

#### Request

```bash
curl -X DELETE http://localhost:8000/utenti/9 \
  -H "Authorization: Bearer <token>"
```

#### Response (204 No Content)

(Nessun body di risposta)

#### Errori

| Codice | Messaggio |
|--------|-----------|
| 401 | Token mancante o non valido |
| 403 | Accesso negato |
| 404 | Utente non trovato |

---

## LOGIN

### 9️⃣ Login Utente

**Endpoint:** `POST /login`  
**Autenticazione:** No  
**Content-Type:** `application/json`

#### Request

```bash
curl -X POST http://localhost:8000/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mario@example.com",
    "password": "SecurePass123!"
  }'
```

#### Parametri

| Campo | Tipo | Obbligatorio | Descrizione |
|-------|------|------|-------------|
| `email` | string | ✅ | Email registrata |
| `password` | string | ✅ | Password dell'account |

#### Response (200 OK)

```json
{
  "message": "Login completato",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 9,
    "nome": "Mario Rossi",
    "email": "mario@example.com"
  }
}
```

#### Errori

| Codice | Messaggio | Causa |
|--------|-----------|-------|
| 400 | Credenziali mancanti | Email o password vuote |
| 401 | Credenziali non valide | Password errata |
| 429 | Troppi tentativi | Blocco temporaneo dopo 5 tentativi falliti |

---

### 🔟 Get Profilo Autenticato (/me)

**Endpoint:** `GET /me`  
**Autenticazione:** ✅ Sì

#### Request

```bash
curl -X GET http://localhost:8000/me \
  -H "Authorization: Bearer <token>"
```

#### Response (200 OK)

```json
{
  "id": 9,
  "nome": "Mario Rossi",
  "email": "mario@example.com",
  "eta": 28,
  "sesso": "M",
  "theme_seed": "#00B894",
  "theme_mode": "system",
  "created_at": "2026-04-27 10:49:17",
  "profile_pic_url": null,
  "background_url": null
}
```

---

## QUIZ

### 1️⃣1️⃣ Crea Quiz

**Endpoint:** `POST /quiz`  
**Autenticazione:** ✅ Sì  
**Content-Type:** `application/json`

#### Request

```bash
curl -X POST http://localhost:8000/quiz \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "obiettivo": "massa",
    "livello": "principiante",
    "giorni_settimana": 3,
    "durata_sessione": 60,
    "attrezzatura": "manubri",
    "limitazioni": "Nessuna"
  }'
```

#### Parametri

| Campo | Tipo | Obbligatorio | Valori |
|-------|------|------|--------|
| `obiettivo` | string | ✅ | `dimagrimento`, `massa`, `resistenza`, `mobilita`, `forza` |
| `livello` | string | ✅ | `principiante`, `intermedio`, `avanzato` |
| `giorni_settimana` | integer | ✅ | 1-7 (giorni a settimana) |
| `durata_sessione` | integer | ✅ | 10-240 (minuti) |
| `attrezzatura` | string | ❌ | Es: `manubri`, `bilanciere`, `niente` |
| `limitazioni` | string | ❌ | Note su infortuni o limitazioni |

#### Response (201 Created)

```json
{
  "quiz_id": 5,
  "scheda_id": 3,
  "scheda": {
    "titolo": "Scheda Guadagno Massa - Principianti",
    "descrizione": "Programma di 4 settimane...",
    "settimane_consigliate": 4,
    "giorni": [
      {
        "giorno": "Lunedì",
        "focus": "Petto e Tricipiti",
        "esercizi": [
          {
            "nome": "Panca Piana",
            "serie": 3,
            "ripetizioni": "8-10",
            "recupero_sec": 90,
            "note": "Controllato"
          }
        ]
      }
    ]
  },
  "message": "Quiz registrato e scheda generata"
}
```

#### Errori Possibili

- **202 Accepted**: Quiz salvato ma generazione scheda IA fallita
- **400 Bad Request**: Parametri non validi
- **401 Unauthorized**: Token mancante

---

### 1️⃣2️⃣ Lista Quiz Utente

**Endpoint:** `GET /quiz`  
**Autenticazione:** ✅ Sì

#### Request

```bash
curl -X GET http://localhost:8000/quiz \
  -H "Authorization: Bearer <token>"
```

#### Response (200 OK)

```json
[
  {
    "id": 5,
    "utente_id": 9,
    "obiettivo": "massa",
    "livello": "principiante",
    "giorni_settimana": 3,
    "created_at": "2026-04-27 10:49:18"
  },
  {
    "id": 4,
    "utente_id": 9,
    "obiettivo": "dimagrimento",
    "livello": "intermedio",
    "giorni_settimana": 5,
    "created_at": "2026-04-27 10:45:00"
  }
]
```

---

### 1️⃣3️⃣ Get Quiz Specifico

**Endpoint:** `GET /quiz/{id}`  
**Autenticazione:** ✅ Sì (solo il proprietario)

#### Request

```bash
curl -X GET http://localhost:8000/quiz/5 \
  -H "Authorization: Bearer <token>"
```

#### Response (200 OK)

```json
{
  "id": 5,
  "utente_id": 9,
  "obiettivo": "massa",
  "livello": "principiante",
  "giorni_settimana": 3,
  "durata_sessione": 60,
  "attrezzatura": "manubri",
  "limitazioni": "",
  "created_at": "2026-04-27 10:49:18"
}
```

#### Errori

| Codice | Messaggio |
|--------|-----------|
| 401 | Token mancante |
| 403 | Non sei il proprietario |
| 404 | Quiz non trovato |

---

### 1️⃣4️⃣ Cancella Quiz

**Endpoint:** `DELETE /quiz/{id}`  
**Autenticazione:** ✅ Sì (solo il proprietario)

#### Request

```bash
curl -X DELETE http://localhost:8000/quiz/5 \
  -H "Authorization: Bearer <token>"
```

#### Response (204 No Content)

(Nessun body)

---

## SCHEDE

### 1️⃣5️⃣ Lista Schede Utente

**Endpoint:** `GET /schede`  
**Autenticazione:** ✅ Sì

#### Request

```bash
curl -X GET http://localhost:8000/schede \
  -H "Authorization: Bearer <token>"
```

#### Response (200 OK)

```json
[
  {
    "id": 3,
    "utente_id": 9,
    "quiz_id": 5,
    "titolo": "Scheda Guadagno Massa - Principianti",
    "modello_ai": "openrouter/elephant-alpha",
    "created_at": "2026-04-27 10:49:18"
  },
  {
    "id": 2,
    "utente_id": 9,
    "quiz_id": 4,
    "titolo": "Scheda Dimagrimento Intermedio",
    "modello_ai": "openrouter/elephant-alpha",
    "created_at": "2026-04-27 10:45:00"
  }
]
```

---

### 1️⃣6️⃣ Get Scheda Specifica

**Endpoint:** `GET /schede/{id}`  
**Autenticazione:** ✅ Sì (solo il proprietario)

#### Request

```bash
curl -X GET http://localhost:8000/schede/3 \
  -H "Authorization: Bearer <token>"
```

#### Response (200 OK)

```json
{
  "id": 3,
  "utente_id": 9,
  "quiz_id": 5,
  "titolo": "Scheda Guadagno Massa - Principianti",
  "modello_ai": "openrouter/elephant-alpha",
  "created_at": "2026-04-27 10:49:18",
  "contenuto": {
    "titolo": "Scheda Guadagno Massa - Principianti",
    "descrizione": "Programma di 4 settimane per guadagnare massa muscolare...",
    "settimane_consigliate": 4,
    "giorni": [
      {
        "giorno": "Lunedì",
        "focus": "Petto e Tricipiti",
        "esercizi": [
          {
            "nome": "Panca Piana",
            "serie": 3,
            "ripetizioni": "8-10",
            "recupero_sec": 90,
            "note": "Controllato"
          },
          {
            "nome": "Spalle Manubri",
            "serie": 3,
            "ripetizioni": "10-12",
            "recupero_sec": 60,
            "note": "Lento e controllato"
          }
        ]
      },
      {
        "giorno": "Mercoledì",
        "focus": "Schiena e Bicipiti",
        "esercizi": [
          {
            "nome": "Rematore Manubri",
            "serie": 3,
            "ripetizioni": "8-10",
            "recupero_sec": 90
          }
        ]
      },
      {
        "giorno": "Venerdì",
        "focus": "Gambe",
        "esercizi": [
          {
            "nome": "Squat",
            "serie": 4,
            "ripetizioni": "8-10",
            "recupero_sec": 120,
            "note": "Forma corretta"
          }
        ]
      }
    ]
  }
}
```

---

### 1️⃣7️⃣ Cancella Scheda

**Endpoint:** `DELETE /schede/{id}`  
**Autenticazione:** ✅ Sì (solo il proprietario)

#### Request

```bash
curl -X DELETE http://localhost:8000/schede/3 \
  -H "Authorization: Bearer <token>"
```

#### Response (204 No Content)

(Nessun body)

---

## Codici di Risposta

| Codice | Significato | Esempio |
|--------|-------------|---------|
| **200** | OK | Richiesta completata con successo |
| **201** | Created | Risorsa creata (registrazione, quiz) |
| **202** | Accepted | Richiesta accettata ma in elaborazione (scheda AI in background) |
| **204** | No Content | Successo senza body (DELETE) |
| **400** | Bad Request | Errore di validazione input |
| **401** | Unauthorized | Token mancante o non valido |
| **403** | Forbidden | Non hai permesso (non sei il proprietario) |
| **404** | Not Found | Risorsa non trovata |
| **405** | Method Not Allowed | Metodo HTTP non supportato |
| **409** | Conflict | Email già registrata |
| **429** | Too Many Requests | Troppi tentativi falliti (blocco login) |
| **500** | Server Error | Errore interno del server |

---

## 📝 Struttura Errore Standard

Tutti gli errori restituiscono JSON nel formato:

```json
{
  "error": "Descrizione dell'errore",
  "debug": "Dettagli tecnici (solo in development)"
}
```

**Esempio:**
```json
{
  "error": "Email già in uso",
  "debug": null
}
```

---

## 🔐 Rate Limiting

**Login:** Massimo 5 tentativi falliti ogni 15 minuti per IP/email  
**Blocco:** Risposta 429 "Troppi tentativi"

---

## 🧪 Variabili d'Ambiente (.env)

```env
DB_HOST=127.0.0.1
DB_NAME=fitness_db
DB_USER=fitness_user
DB_PASS=fitness_password

JWT_SECRET=your-secret-key-change-this-in-production
JWT_TTL=86400

LOGIN_MAX_ATTEMPTS=5
LOGIN_WINDOW_SEC=900

ALLOWED_ORIGINS=*

OPENROUTER_API_KEY=sk-or-v1-...
OPENROUTER_URL=https://openrouter.ai/api/v1/chat/completions
AI_MODEL=openrouter/elephant-alpha

APP_NAME=FitnessWS
APP_ENV=development
```

---

## 📦 Tools Consigliati

### Postman
1. Importa la collection
2. Configura le variabili d'ambiente
3. Testa gli endpoint

### cURL
```bash
# Salva il token in una variabile
TOKEN=$(curl -s -X POST http://localhost:8000/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mario@example.com","password":"SecurePass123!"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# Usa il token nelle richieste
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/me
```

### Insomnia
Importa la collection e configura l'ambiente di test.

---

## 🎯 Flusso Tipico

1. **Registrazione**: `POST /utenti` → Ottieni token
2. **Get Profilo**: `GET /me` con token
3. **Crea Quiz**: `POST /quiz` con parametri allenamento
4. **Visualizza Scheda**: `GET /schede/{id}` → Ricevi il programma IA
5. **Modifica Profilo**: `PUT /utenti/{id}` → Aggiorna dati
6. **Upload Foto**: `POST /utenti/{id}/picture` → Profilo con immagine

---

## ⚠️ Limitazioni e Note

- I token JWT scadono dopo 24 ore
- Solo il proprietario può visualizzare/modificare i propri dati
- Ogni quiz genera automaticamente una scheda IA (se disponibile)
- Le immagini sono salvate in `uploads/profiles/` e `uploads/backgrounds/`
- L'API supporta CORS (configurabile in `.env`)

---

**Ultima aggiornamento:** 27 Aprile 2026  
**Versione API:** 1.0.0
