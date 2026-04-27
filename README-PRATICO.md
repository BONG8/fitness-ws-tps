# 🏋️ Fitness Web Service - Guida Pratica

## 📚 Indice

1. [Quick Start](#quick-start)
2. [Flusso Tipico](#flusso-tipico)
3. [Autenticazione Avanzata](#autenticazione-avanzata)
4. [Best Practices](#best-practices)
5. [Troubleshooting](#troubleshooting)
6. [Tools Consigliati](#tools-consigliati)

---

## Quick Start

### 1. Avviare il Server

```bash
# Avvia il server PHP
php -S localhost:8000

# Oppure usa docker
docker-compose up -d
```

### 2. Registrarsi

```bash
# Registra un nuovo utente
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

# Risposta:
# {
#   "id": 9,
#   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "user": {...}
# }
```

### 3. Usare il Token

```bash
# Salva il token
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Usa il token in tutte le richieste protette
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/me
```

---

## Flusso Tipico

```
┌─────────────────────────────────────────────────────────────┐
│ 1. REGISTRAZIONE & AUTENTICAZIONE                           │
│    POST /utenti → Ottenere token JWT                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. GESTIONE PROFILO                                          │
│    GET /me         → Visualizza profilo                     │
│    PUT /utenti/{id} → Modifica profilo                      │
│    POST /utenti/{id}/picture → Upload foto                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. QUIZ & SCHEDE                                             │
│    POST /quiz      → Crea quiz personalizzato              │
│    GET /schede/{id} → Ottieni scheda di allenamento        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. FOLLOW-UP                                                 │
│    GET /schede     → Visualizza tutte le schede            │
│    DELETE /quiz/{id} → Elimina quiz non graditi            │
└─────────────────────────────────────────────────────────────┘
```

---

## Autenticazione Avanzata

### Salvare il Token in Bash

```bash
#!/bin/bash

BASE_URL="http://localhost:8000"
EMAIL="mario@example.com"
PASSWORD="SecurePass123!"

# Registrati o esegui login
RESPONSE=$(curl -s -X POST $BASE_URL/login \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

# Estrai il token
TOKEN=$(echo $RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)
echo "Token: $TOKEN"

# Usa il token
curl -H "Authorization: Bearer $TOKEN" $BASE_URL/me
```

### Token Scaduto?

```bash
# Se ricevi 401 "Token mancante o non valido"
# 1. Esegui un nuovo login
# 2. Salva il nuovo token
# 3. Riprova la richiesta
```

### Refresh Token

Attualmente l'API non supporta refresh token. Il token JWT dura 24 ore.  
Quando scade, accedi di nuovo con `/login`.

---

## Best Practices

### 1️⃣ Validazione Input

```json
{
  "email": "mario@example.com",    // Deve essere un'email valida
  "password": "SecurePass123!",    // Min 8 char, 1 lettera, 1 numero
  "nome": "Mario Rossi",           // 2-100 caratteri
  "eta": 28,                       // 13-100 anni
  "sesso": "M"                     // "M" | "F" | "Altro"
}
```

### 2️⃣ Gestione Errori

```bash
# Verifica il codice HTTP
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X GET \
  -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/quiz)

if [ $STATUS -eq 401 ]; then
  echo "Token scaduto, accedi di nuovo"
elif [ $STATUS -eq 403 ]; then
  echo "Permesso negato"
elif [ $STATUS -eq 404 ]; then
  echo "Risorsa non trovata"
fi
```

### 3️⃣ Upload File

```bash
# Massimo 2 MB per foto profilo
# Massimo 4 MB per sfondo
# Formati: JPEG, PNG, WEBP

curl -X POST http://localhost:8000/utenti/9/picture \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/path/to/photo.jpg"

# Risposta contiene URL pubblico:
# "profile_pic_url": "http://localhost:8000/uploads/profiles/9.jpg?v=1234567890"
```

### 4️⃣ Parametri Opzionali

```json
{
  "nome": "Mario",          // Obbligatorio in PUT
  "email": "mario@ex.com",  // Obbligatorio in PUT
  "eta": 28,                // Obbligatorio in PUT
  "sesso": "M",             // Obbligatorio in PUT
  "password": "NewPass123!", // Opzionale - se omesso, non cambia
  "theme_seed": "#FF6B6B",  // Opzionale
  "theme_mode": "dark"      // Opzionale
}
```

### 5️⃣ Quiz - Parametri Validi

```bash
# Obiettivi
"obiettivo": "dimagrimento"  # Perdere peso
"obiettivo": "massa"         # Guadagnare massa muscolare
"obiettivo": "resistenza"    # Migliorare resistenza cardio
"obiettivo": "mobilita"      # Migliorare flessibilità
"obiettivo": "forza"         # Aumentare forza pura

# Livelli
"livello": "principiante"    # Nessuna esperienza
"livello": "intermedio"      # Esperienza 6+ mesi
"livello": "avanzato"        # Esperienza 2+ anni

# Giorni di allenamento
"giorni_settimana": 3        # 1-7 (quanti giorni alla settimana)

# Durata
"durata_sessione": 60        # 10-240 minuti per sessione
```

### 6️⃣ CORS - Configurare origini consentite

Nel file `.env`:

```env
# Permetti tutti (NOT raccomandato in produzione)
ALLOWED_ORIGINS=*

# Oppure origini specifiche
ALLOWED_ORIGINS=http://localhost:3000,https://miodominio.com
```

---

## Troubleshooting

### ❌ Errore: "Errore creazione utente"

**Possibili cause:**

```
1. Email già registrata
   → Soluzione: usa un'email diversa

2. Password non valida (< 8 char, no lettere/numeri)
   → Soluzione: usa una password più forte

3. Email non valida
   → Soluzione: verifica il formato

4. Consenso privacy = false
   → Soluzione: imposta consenso_privacy: true
```

### ❌ Errore 401: "Token mancante o non valido"

**Possibili cause:**

```
1. Header Authorization non presente
   → Soluzione: aggiungi -H "Authorization: Bearer $TOKEN"

2. Token malformato
   → Soluzione: verifica il token copiato correttamente

3. Token scaduto (24 ore)
   → Soluzione: esegui login di nuovo

4. Token invalido
   → Soluzione: accedi di nuovo con credenziali giuste
```

### ❌ Errore 429: "Troppi tentativi"

**Causa:** 5 tentativi di login falliti negli ultimi 15 minuti

```
Soluzione: aspetta 15 minuti prima di riprovare
(o usa un'altra email/IP)
```

### ❌ Database connection error

```bash
# Verifica che il container MySQL sia in esecuzione
docker-compose ps

# Se non è attivo, riavvialo
docker-compose up -d

# Testa la connessione
docker exec fitness_ws mysql -u fitness_user -pfitness_password \
  -D fitness_db -e "SELECT 1;"
```

### ❌ Upload file fallisce

```bash
# Verifica la dimensione
ls -lh /path/to/file.jpg

# Massimo 2 MB (foto profilo) o 4 MB (sfondo)
# Formati accettati: JPEG, PNG, WEBP

# Assicurati che la cartella uploads esista
mkdir -p uploads/profiles uploads/backgrounds
```

---

## Tools Consigliati

### 🔷 Postman

**Installazione:**
1. Scarica da https://www.postman.com/downloads/
2. Apri Postman
3. Clicca "Import"
4. Carica `postman-collection.json`
5. Configura le variabili d'ambiente

**Vantaggi:**
- UI intuitiva
- Salva automaticamente variabili (token, IDs)
- Testa script prima/dopo ogni richiesta
- Esporta risultati

### 🔷 Insomnia

**Installazione:**
```bash
# Su Linux/macOS
brew install insomnia

# Su Windows
choco install insomnia
```

**Uso:**
1. Crea un workspace
2. Importa collection Postman
3. Configura ambiente

### 🔷 VS Code REST Client

**Installazione:**
```
Extensions → Ricerca "REST Client" → Installa
```

**File di esempio (`requests.http`):**
```http
### Registrazione
POST http://localhost:8000/utenti
Content-Type: application/json

{
  "nome": "Mario",
  "email": "mario@example.com",
  "password": "SecurePass123!",
  "eta": 28,
  "sesso": "M",
  "consenso_privacy": true
}

### Login (esegui prima della registrazione)
@token = <copia il token dalla registrazione>
@base_url = http://localhost:8000

### Get Profilo
GET @base_url/me
Authorization: Bearer @token
```

### 🔷 cURL (CLI)

**Script bash automatico:**

```bash
#!/bin/bash
# Salva come test-api.sh

BASE_URL="http://localhost:8000"

# Registrati
echo "📝 Registrazione..."
TOKEN=$(curl -s -X POST $BASE_URL/utenti \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Test User",
    "email": "test@example.com",
    "password": "SecurePass123!",
    "eta": 25,
    "sesso": "M",
    "consenso_privacy": true
  }' | grep -o '"token":"[^"]*' | cut -d'"' -f4)

[ -z "$TOKEN" ] && echo "❌ Registrazione fallita" && exit 1
echo "✅ Token ottenuto"

# Get profilo
echo -e "\n📋 Profilo..."
curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/me | python3 -m json.tool

# Crea quiz
echo -e "\n🎯 Creazione quiz..."
curl -s -X POST $BASE_URL/quiz \
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

**Esecuzione:**
```bash
chmod +x test-api.sh
./test-api.sh
```

---

## 📊 Scenari di Utilizzo

### Scenario 1: Nuovo Utente

```bash
# 1. Registrazione
curl -X POST http://localhost:8000/utenti \
  -H "Content-Type: application/json" \
  -d '{...}'

# Ottiene token e id

# 2. Upload foto profilo
curl -X POST http://localhost:8000/utenti/9/picture \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@profile.jpg"

# 3. Crea primo quiz
curl -X POST http://localhost:8000/quiz \
  -H "Authorization: Bearer $TOKEN" \
  -d '{...}'

# 4. Visualizza scheda generata
curl -X GET http://localhost:8000/schede/1 \
  -H "Authorization: Bearer $TOKEN"
```

### Scenario 2: Modifica Profilo

```bash
# 1. Login
TOKEN=$(curl -s -X POST http://localhost:8000/login \
  -d '{"email":"mario@example.com","password":"SecurePass123!"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# 2. Aggiorna dati
curl -X PUT http://localhost:8000/utenti/9 \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "nome": "Mario Rossi Updated",
    "eta": 29,
    ...
  }'

# 3. Cambia tema
curl -X PUT http://localhost:8000/utenti/9 \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "theme_seed": "#FF6B6B",
    "theme_mode": "dark"
  }'
```

### Scenario 3: Gestione Quiz Multipli

```bash
# 1. Lista quiz
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/quiz

# 2. Crea nuovo quiz con obiettivo diverso
curl -X POST http://localhost:8000/quiz \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "obiettivo": "dimagrimento",
    "livello": "intermedio",
    ...
  }'

# 3. Visualizza specifico
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/quiz/2

# 4. Elimina se non piace
curl -X DELETE http://localhost:8000/quiz/1 \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🔒 Sicurezza

### Raccomandazioni

1. **JWT Secret**: Cambia il valore in `.env` in produzione
2. **CORS**: Specifica origini consentite (non usare `*`)
3. **HTTPS**: Usa HTTPS in produzione
4. **Password**: Richiedi password complesse
5. **Rate Limiting**: Implementato per login (5 tentativi in 15 min)
6. **Token Expiry**: 24 ore (configurabile)

### Protezione CORS

```env
# Sviluppo locale
ALLOWED_ORIGINS=http://localhost:3000

# Produzione
ALLOWED_ORIGINS=https://mioapp.com,https://www.mioapp.com
```

---

## 📞 Supporto

**File di documentazione:**
- `API-GUIDE.md` - Documentazione completa API
- `postman-collection.json` - Collection Postman importabile
- `test-curl-collection.sh` - Script bash con esempi

**Database:**
- Host: `localhost:3306` (Docker) o configurato in `.env`
- Database: `fitness_db`
- User: `fitness_user`

---

**Versione:** 1.0.0  
**Ultimo aggiornamento:** 27 Aprile 2026
