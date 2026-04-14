# Guida allo Sviluppo Frontend - Fitness API

Ciao! Questa è la guida veloce per collegare il nostro frontend all'API del backend per la gestione degli utenti, dei questionari fisici (quiz) e delle schede di allenamento.

Il nostro backend utilizza URL puliti senza estensioni (es. niente `.php`).

### ⚙️ Informazioni di Base
- **URL Base dell'API:** `http://localhost:8000`
- **Formato Dati:** Tutti i dati devono essere inviati in formato JSON (`Content-Type: application/json`).
- Tutte le risposte arriveranno sempre in formato JSON.

---

## 👥 Gestione Utenti (`/utenti`)

Prima di poter creare un quiz o una scheda, l'utente deve essere registrato.

### 1. Registrare un nuovo utente (POST)
- **URL:** `POST http://localhost:8000/utenti`
- **Body JSON da inviare:**
```json
{
  "nome": "Luca Bianchi",
  "email": "luca@example.com",
  "eta": 25,
  "sesso": "M" 
}
```
*(Nota: il `sesso` accetta solo 'M', 'F', 'Altro')*

**Cosa ti risponde il server:** Un ID utile per i passaggi successivi (+ status 201).
```json
{
  "id": 1,
  "message": "Utente creato"
}
```

### 2. Recuperare la lista degli utenti (GET)
- **URL:** `GET http://localhost:8000/utenti`
Ti restituisce un array di tutti gli utenti, utile magari per un pannello "admin".

### 3. Modificare e cancellare un utente
- **URL:** `PUT http://localhost:8000/utenti/1` (Il body JSON da inviare è uguale a quello del POST)
- **URL:** `DELETE http://localhost:8000/utenti/1` 

---

## 📝 Questionario Fitness (`/quiz`)

Con l'ID utente ottenuto al momento della registrazione, possiamo salvare le preferenze di allenamento.

### 1. Salvare le preferenze fisiche (POST)
- **URL:** `POST http://localhost:8000/quiz`
- **Body JSON da inviare:**
```json
{
  "utente_id": 1,
  "obiettivo": "massa",
  "livello": "intermedio",
  "giorni_settimana": 4,
  "durata_sessione": 60,
  "attrezzatura": "manubri, panca",
  "limitazioni": "nessuna"
}
```
**(Note importanti per le dropdown nel form):**
- **obiettivo:** `'dimagrimento'`, `'massa'`, `'resistenza'`, `'mobilita'`, `'forza'`
- **livello:** `'principiante'`, `'intermedio'`, `'avanzato'`

**Cosa ti risponde il server:** Un avviso di successo, l'ID del quiz e *L'INTERA SCHEDA* appena elaborata dall'intelligenza artificiale e salvata nel database (nel campo `scheda`).
```json
{
  "quiz_id": 1,
  "scheda_id": 1,
  "scheda": {
    "titolo": "...",
    "giorni": [...]
  },
  "message": "Quiz registrato e scheda generata"
}
```

### 2. Leggere i quiz (GET)
- **URL (di un utente):** `GET http://localhost:8000/quiz?utente_id=1` Restituisce i quiz inviati dall'utente 1
- **URL (singolo):** `GET http://localhost:8000/quiz/1` (Passando l'id del quiz)

---

## 🏋️‍♂️ Schede Allenamento (`/schede`)

Questa sezione permette di visualizzare le schede precedentemente generate per un utente.
**Nota Bene:** Come hai visto nel punto precedente, la scheda viene generata e salvata *automaticamente* dal server non appena invii il `POST /quiz`! Non c'è bisogno di fare una POST separata.

### 1. Recuperare la lista delle schede di un utente (GET)
- **URL:** `GET http://localhost:8000/schede?utente_id=1` 
Restituisce un array con l'elenco (id, titolo, modello AI) di tutte le schede intestate all'utente `1`.

### 2. Leggere il dettaglio di una singola scheda (GET)
- **URL:** `GET http://localhost:8000/schede/1` (Passando l'id della scheda)
Restituisce tutti i dettagli della scheda. A differenza di prima, il server si occupa già di farti arrivare il campo `contenuto` come un **Oggetto JSON già pronto**, non come stringa. Puoi ciclare i giorni e gli esercizi direttamente in JavaScript!

### 3. Struttura JSON della Scheda AI
Sia quando crei un quiz (`POST /quiz`), sia quando recuperi una scheda specifica (`GET /schede/{id}`), la proprietà `scheda` (o `contenuto`) conterrà un oggetto JSON strutturato sempre in questo modo, generato dall'AI:

```json
{
  "titolo": "Scheda Massa Intermedio",
  "descrizione": "Programma di 4 giorni su base upper/lower...",
  "settimane_consigliate": 4,
  "giorni": [
    {
      "giorno": "Lunedì",
      "focus": "Upper Body",
      "esercizi": [
        {
          "nome": "Panca Piana",
          "serie": 3,
          "ripetizioni": "10-12",
          "recupero_sec": 90,
          "note": "Movimento controllato"
        }
      ]
    }
  ]
}
```

---

### Esempio pratico in JavaScript 💻
Ecco come potresti usare la `fetch()` nel tuo codice frontend per inviare il modulo di registrazione:

```javascript
async function registraUtente(datiUtente) {
  try {
    const risposta = await fetch('http://localhost:8000/utenti', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(datiUtente)
    });

    const dati = await risposta.json();
    
    if(risposta.status === 201) {
       console.log("Registrato! Il tuo ID è:", dati.id);
    } else {
       console.error("Errore:", dati.error);
    }
  } catch (error) {
    console.error("Errore di connessione:", error);
  }
}
```