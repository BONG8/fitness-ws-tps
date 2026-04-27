# 📋 Fitness API - Riferimento Rapido Endpoint

## 🎯 Tabella Riepilogativa

| # | Endpoint | Metodo | Auth | Status | Descrizione |
|---|----------|--------|------|--------|-------------|
| 1 | `/utenti` | POST | ❌ | 201 | Registra nuovo utente |
| 2 | `/utenti/{id}` | GET | ✅ | 200 | Ottieni profilo utente |
| 3 | `/utenti/{id}` | PUT | ✅ | 200 | Aggiorna profilo |
| 4 | `/utenti/{id}` | DELETE | ✅ | 204 | Cancella utente |
| 5 | `/utenti/{id}/picture` | POST | ✅ | 200 | Upload foto profilo |
| 6 | `/utenti/{id}/picture` | DELETE | ✅ | 200 | Rimuovi foto profilo |
| 7 | `/utenti/{id}/background` | POST | ✅ | 200 | Upload sfondo |
| 8 | `/utenti/{id}/background` | DELETE | ✅ | 200 | Rimuovi sfondo |
| 9 | `/login` | POST | ❌ | 200 | Login utente |
| 10 | `/me` | GET | ✅ | 200 | Profilo autenticato |
| 11 | `/quiz` | POST | ✅ | 201/202 | Crea quiz |
| 12 | `/quiz` | GET | ✅ | 200 | Lista quiz utente |
| 13 | `/quiz/{id}` | GET | ✅ | 200 | Ottieni quiz specifico |
| 14 | `/quiz/{id}` | DELETE | ✅ | 204 | Cancella quiz |
| 15 | `/schede` | GET | ✅ | 200 | Lista schede |
| 16 | `/schede/{id}` | GET | ✅ | 200 | Ottieni scheda |
| 17 | `/schede/{id}` | DELETE | ✅ | 204 | Cancella scheda |

---

## 📦 Parametri per Endpoint

### POST /utenti (Registrazione)

```json
{
  "nome": "Mario Rossi",              // string, 2-100 chars ✅
  "email": "mario@example.com",       // string, valid email ✅
  "password": "SecurePass123!",       // string, 8-128 chars, lettera+numero ✅
  "eta": 28,                          // int, 13-100 ✅
  "sesso": "M",                       // "M" | "F" | "Altro" ✅
  "consenso_privacy": true            // boolean, must be true ✅
}
```

### PUT /utenti/{id} (Aggiorna)

```json
{
  "nome": "Mario Rossi",              // string ✅ (obbligatorio)
  "email": "mario@example.com",       // string ✅ (obbligatorio)
  "eta": 29,                          // int ✅ (obbligatorio)
  "sesso": "M",                       // string ✅ (obbligatorio)
  "password": "NewPass123!",          // string ❌ (opzionale)
  "theme_seed": "#FF6B6B",            // string, hex color ❌ (opzionale)
  "theme_mode": "dark"                // "light"|"dark"|"system" ❌ (opzionale)
}
```

### POST /login

```json
{
  "email": "mario@example.com",       // string ✅
  "password": "SecurePass123!"        // string ✅
}
```

### POST /quiz (Crea)

```json
{
  "obiettivo": "massa",               // "dimagrimento"|"massa"|"resistenza"|"mobilita"|"forza" ✅
  "livello": "principiante",          // "principiante"|"intermedio"|"avanzato" ✅
  "giorni_settimana": 3,              // int, 1-7 ✅
  "durata_sessione": 60,              // int, 10-240 (minuti) ✅
  "attrezzatura": "manubri",          // string ❌
  "limitazioni": "Nessuna"            // string ❌
}
```

### POST /utenti/{id}/picture (multipart/form-data)

```
Field: file
Type: image (JPEG, PNG, WEBP)
Max: 2 MB
```

### POST /utenti/{id}/background (multipart/form-data)

```
Field: file
Type: image (JPEG, PNG, WEBP)
Max: 4 MB
```

---

## 🔑 Header Richiesti

### Autenticazione (✅ Auth)

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Content-Type (richiesta JSON)

```
Content-Type: application/json
```

---

## 📊 Risposte Tipiche per Codice HTTP

| Codice | Significato | Azione |
|--------|-------------|--------|
| **200** | OK | Richiesta riuscita |
| **201** | Created | Risorsa creata |
| **202** | Accepted | Accepted, elaborazione in corso |
| **204** | No Content | Successo, niente da restituire |
| **400** | Bad Request | Input non valido |
| **401** | Unauthorized | Token mancante/scaduto |
| **403** | Forbidden | Permesso negato (non sei il proprietario) |
| **404** | Not Found | Risorsa non trovata |
| **405** | Method Not Allowed | Metodo HTTP non supportato |
| **409** | Conflict | Email già registrata |
| **429** | Too Many Requests | Rate limit raggiunto |
| **500** | Server Error | Errore interno |

---

## 🎯 Obiettivi Quiz

| Valore | Descrizione |
|--------|-------------|
| `dimagrimento` | Perdere peso e grasso corporeo |
| `massa` | Guadagnare massa muscolare |
| `resistenza` | Migliorare resistenza cardio/resistenza |
| `mobilita` | Aumentare flessibilità e mobilità |
| `forza` | Aumentare forza massimale |

---

## 📈 Livelli Quiz

| Valore | Esperienza | Descrizione |
|--------|-----------|-------------|
| `principiante` | 0 mesi | Nessuna esperienza di allenamento |
| `intermedio` | 6+ mesi | Esperienza base, fondamenti acquisiti |
| `avanzato` | 2+ anni | Esperienza estesa, tecniche avanzate |

---

## 🎨 Temi

### theme_seed (Colore)

Formato: Esadecimale (es: `#FF6B6B`)

```
#FF6B6B  - Rosso
#4ECDC4  - Teal
#45B7D1  - Blu
#FFA07A  - Salmone
#98D8C8  - Verde acqua
#F7DC6F  - Giallo
```

### theme_mode

| Valore | Descrizione |
|--------|-------------|
| `light` | Tema chiaro |
| `dark` | Tema scuro |
| `system` | Usa impostazioni sistema |

---

## 💾 Variabili d'Ambiente (.env)

```env
# Database
DB_HOST=127.0.0.1
DB_NAME=fitness_db
DB_USER=fitness_user
DB_PASS=fitness_password
DB_CHARSET=utf8mb4

# JWT
JWT_SECRET=your-secret-key-change-this
JWT_TTL=86400

# Rate Limiting
LOGIN_MAX_ATTEMPTS=5
LOGIN_WINDOW_SEC=900

# CORS
ALLOWED_ORIGINS=*

# OpenRouter API
OPENROUTER_API_KEY=sk-or-v1-...
OPENROUTER_URL=https://openrouter.ai/api/v1/chat/completions
AI_MODEL=openrouter/elephant-alpha

# App
APP_NAME=FitnessWS
APP_ENV=development
PUBLIC_BASE_URL=http://localhost:8000
```

---

## 🔄 Sequenza di Richieste Tipiche

### Flusso 1: Registrazione → Profilo → Quiz

```bash
# 1. Registrazione
POST /utenti
→ Ottieni: id, token

# 2. Ottieni Profilo
GET /me
Header: Authorization: Bearer {token}

# 3. Crea Quiz
POST /quiz
Header: Authorization: Bearer {token}
Body: {obiettivo, livello, giorni_settimana, ...}
→ Ottieni: quiz_id, scheda_id

# 4. Visualizza Scheda
GET /schede/{scheda_id}
Header: Authorization: Bearer {token}
```

### Flusso 2: Login → Modifica → Upload

```bash
# 1. Login
POST /login
→ Ottieni: token

# 2. Aggiorna Profilo
PUT /utenti/{id}
Header: Authorization: Bearer {token}

# 3. Upload Foto
POST /utenti/{id}/picture
Header: Authorization: Bearer {token}
Body: multipart/form-data
```

---

## 🛡️ Rate Limiting

| Risorsa | Limite | Finestra |
|---------|--------|----------|
| Login fallito | 5 tentativi | 15 minuti |
| Blocco IP | Dopo 5 falliti | 15 minuti |

**Risposta quando bloccato:**

```json
{
  "error": "Troppi tentativi",
  "code": 429
}
```

---

## 🧪 Test Rapidi

### Controllare che il server è online

```bash
curl http://localhost:8000/invalid
# Atteso: {"error":"Endpoint non trovato"}
```

### Testare autenticazione non riuscita

```bash
curl http://localhost:8000/quiz
# Atteso: {"error":"Token mancante o non valido"}
```

### Testare email duplicata

```bash
# Primo tentativo: successo (201)
# Secondo tentativo stessa email: conflitto (409)
curl -X POST http://localhost:8000/utenti \
  -H "Content-Type: application/json" \
  -d '{"email":"same@example.com",...}'
```

---

## 📱 Esempio Completo cURL

```bash
#!/bin/bash

# 1. Registrazione
RESP=$(curl -s -X POST http://localhost:8000/utenti \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Test User",
    "email": "test@example.com",
    "password": "TestPass123!",
    "eta": 25,
    "sesso": "M",
    "consenso_privacy": true
  }')

TOKEN=$(echo $RESP | grep -o '"token":"[^"]*' | cut -d'"' -f4)
ID=$(echo $RESP | grep -o '"id":[0-9]*' | cut -d':' -f2)

echo "Token: $TOKEN"
echo "ID: $ID"

# 2. Get profilo
curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/me | python3 -m json.tool

# 3. Aggiorna
curl -s -X PUT http://localhost:8000/utenti/$ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "nome": "Updated Name",
    "email": "test@example.com",
    "eta": 26,
    "sesso": "M"
  }' | python3 -m json.tool

# 4. Crea Quiz
curl -s -X POST http://localhost:8000/quiz \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "obiettivo": "massa",
    "livello": "principiante",
    "giorni_settimana": 3,
    "durata_sessione": 60,
    "attrezzatura": "manubri",
    "limitazioni": ""
  }' | python3 -m json.tool
```

---

## 📞 File Correlati

- `API-GUIDE.md` - Documentazione completa con esempi
- `README-PRATICO.md` - Guida pratica e troubleshooting
- `postman-collection.json` - Collection Postman
- `test-curl-collection.sh` - Script test bash

---

**Versione:** 1.0.0  
**Ultima modifica:** 27 Aprile 2026
