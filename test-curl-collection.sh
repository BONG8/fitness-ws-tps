#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# 📚 API Fitness - Collection di Comandi cURL Pronti all'Uso
# ═══════════════════════════════════════════════════════════════════════════════

BASE_URL="http://localhost:8000"

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      API FITNESS - Collezione cURL Interattiva                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# 1. REGISTRAZIONE E AUTENTICAZIONE
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${YELLOW}1️⃣  REGISTRAZIONE UTENTE${NC}"
echo -e "${GREEN}POST /utenti${NC}"
echo ""
echo "Request:"
echo 'curl -X POST http://localhost:8000/utenti \'
echo '  -H "Content-Type: application/json" \'
echo "  -d '{
    \"nome\": \"Mario Rossi\",
    \"email\": \"mario@example.com\",
    \"password\": \"SecurePass123!\",
    \"eta\": 28,
    \"sesso\": \"M\",
    \"consenso_privacy\": true
  }'"
echo ""
echo "Esecuzione:"
REGISTER=$(curl -s -X POST $BASE_URL/utenti \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Mario Rossi",
    "email": "mario@example.com",
    "password": "SecurePass123!",
    "eta": 28,
    "sesso": "M",
    "consenso_privacy": true
  }')
echo "$REGISTER" | python3 -m json.tool
TOKEN=$(echo "$REGISTER" | python3 -c "import sys, json; print(json.load(sys.stdin).get('token', ''))" 2>/dev/null)
USER_ID=$(echo "$REGISTER" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))" 2>/dev/null)
echo ""
[ -n "$TOKEN" ] && echo -e "${GREEN}✓ Token salvato: ${TOKEN:0:30}...${NC}" || echo -e "${RED}✗ Token non ottenuto${NC}"
[ -n "$USER_ID" ] && echo -e "${GREEN}✓ User ID: $USER_ID${NC}" || echo -e "${RED}✗ User ID non ottenuto${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# 2. LOGIN
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${YELLOW}2️⃣  LOGIN UTENTE${NC}"
echo -e "${GREEN}POST /login${NC}"
echo ""
echo "Request:"
echo 'curl -X POST http://localhost:8000/login \'
echo '  -H "Content-Type: application/json" \'
echo "  -d '{
    \"email\": \"mario@example.com\",
    \"password\": \"SecurePass123!\"
  }'"
echo ""
echo "Esecuzione:"
LOGIN=$(curl -s -X POST $BASE_URL/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mario@example.com",
    "password": "SecurePass123!"
  }')
echo "$LOGIN" | python3 -m json.tool
[ -n "$TOKEN" ] && echo -e "${GREEN}✓ Token disponibile per le richieste autenticate${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# 3. PROFILO UTENTE
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${YELLOW}3️⃣  GET PROFILO AUTENTICATO (/me)${NC}"
echo -e "${GREEN}GET /me${NC}"
echo ""
echo "Request:"
echo 'curl -X GET http://localhost:8000/me \'
echo "  -H \"Authorization: Bearer \$TOKEN\""
echo ""
if [ -n "$TOKEN" ]; then
  echo "Esecuzione:"
  curl -s -X GET $BASE_URL/me \
    -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
else
  echo -e "${RED}✗ Token non disponibile${NC}"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}4️⃣  GET PROFILO SPECIFICO${NC}"
echo -e "${GREEN}GET /utenti/{id}${NC}"
echo ""
echo "Request:"
echo "curl -X GET http://localhost:8000/utenti/$USER_ID \\"
echo "  -H \"Authorization: Bearer \$TOKEN\""
echo ""
if [ -n "$TOKEN" ] && [ -n "$USER_ID" ]; then
  echo "Esecuzione:"
  curl -s -X GET $BASE_URL/utenti/$USER_ID \
    -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
else
  echo -e "${RED}✗ Token o User ID non disponibile${NC}"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}5️⃣  AGGIORNA PROFILO${NC}"
echo -e "${GREEN}PUT /utenti/{id}${NC}"
echo ""
echo "Request:"
echo "curl -X PUT http://localhost:8000/utenti/$USER_ID \\"
echo '  -H "Content-Type: application/json" \'
echo "  -H \"Authorization: Bearer \$TOKEN\" \\"
echo "  -d '{
    \"nome\": \"Mario Rossi Updated\",
    \"email\": \"mario@example.com\",
    \"eta\": 29,
    \"sesso\": \"M\",
    \"theme_seed\": \"#FF6B6B\",
    \"theme_mode\": \"dark\"
  }'"
echo ""
if [ -n "$TOKEN" ] && [ -n "$USER_ID" ]; then
  echo "Esecuzione:"
  curl -s -X PUT $BASE_URL/utenti/$USER_ID \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
      "nome": "Mario Rossi Updated",
      "email": "mario@example.com",
      "eta": 29,
      "sesso": "M",
      "theme_seed": "#FF6B6B",
      "theme_mode": "dark"
    }' | python3 -m json.tool
else
  echo -e "${RED}✗ Token o User ID non disponibile${NC}"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# 6. QUIZ
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${YELLOW}6️⃣  CREA QUIZ${NC}"
echo -e "${GREEN}POST /quiz${NC}"
echo ""
echo "Request:"
echo 'curl -X POST http://localhost:8000/quiz \'
echo '  -H "Content-Type: application/json" \'
echo "  -H \"Authorization: Bearer \$TOKEN\" \\"
echo "  -d '{
    \"obiettivo\": \"massa\",
    \"livello\": \"principiante\",
    \"giorni_settimana\": 3,
    \"durata_sessione\": 60,
    \"attrezzatura\": \"manubri\",
    \"limitazioni\": \"\"
  }'"
echo ""
if [ -n "$TOKEN" ]; then
  echo "Esecuzione:"
  QUIZ=$(curl -s -X POST $BASE_URL/quiz \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
      "obiettivo": "massa",
      "livello": "principiante",
      "giorni_settimana": 3,
      "durata_sessione": 60,
      "attrezzatura": "manubri",
      "limitazioni": ""
    }')
  echo "$QUIZ" | python3 -m json.tool
  QUIZ_ID=$(echo "$QUIZ" | python3 -c "import sys, json; print(json.load(sys.stdin).get('quiz_id', ''))" 2>/dev/null)
  [ -n "$QUIZ_ID" ] && echo -e "${GREEN}✓ Quiz ID: $QUIZ_ID${NC}"
else
  echo -e "${RED}✗ Token non disponibile${NC}"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}7️⃣  LISTA QUIZ${NC}"
echo -e "${GREEN}GET /quiz${NC}"
echo ""
echo "Request:"
echo 'curl -X GET http://localhost:8000/quiz \'
echo "  -H \"Authorization: Bearer \$TOKEN\""
echo ""
if [ -n "$TOKEN" ]; then
  echo "Esecuzione:"
  curl -s -X GET $BASE_URL/quiz \
    -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
else
  echo -e "${RED}✗ Token non disponibile${NC}"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -n "$QUIZ_ID" ]; then
  echo -e "${YELLOW}8️⃣  GET QUIZ SPECIFICO${NC}"
  echo -e "${GREEN}GET /quiz/{id}${NC}"
  echo ""
  echo "Request:"
  echo "curl -X GET http://localhost:8000/quiz/$QUIZ_ID \\"
  echo "  -H \"Authorization: Bearer \$TOKEN\""
  echo ""
  echo "Esecuzione:"
  curl -s -X GET $BASE_URL/quiz/$QUIZ_ID \
    -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 7. SCHEDE
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${YELLOW}9️⃣  LISTA SCHEDE${NC}"
echo -e "${GREEN}GET /schede${NC}"
echo ""
echo "Request:"
echo 'curl -X GET http://localhost:8000/schede \'
echo "  -H \"Authorization: Bearer \$TOKEN\""
echo ""
if [ -n "$TOKEN" ]; then
  echo "Esecuzione:"
  curl -s -X GET $BASE_URL/schede \
    -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
else
  echo -e "${RED}✗ Token non disponibile${NC}"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}🔟 ERRORI E EDGE CASES${NC}"
echo ""

echo -e "${RED}Endpoint inesistente (404):${NC}"
echo "curl -s http://localhost:8000/invalid | python3 -m json.tool"
echo ""
curl -s http://localhost:8000/invalid | python3 -m json.tool
echo ""

echo -e "${RED}Accesso non autenticato (401):${NC}"
echo "curl -s http://localhost:8000/quiz | python3 -m json.tool"
echo ""
curl -s http://localhost:8000/quiz | python3 -m json.tool
echo ""

echo -e "${RED}Email duplicata (409):${NC}"
echo "curl -s -X POST http://localhost:8000/utenti -H \"Content-Type: application/json\" -d '{\"nome\":\"Test\",\"email\":\"mario@example.com\",\"password\":\"Pass123!\",\"eta\":25,\"sesso\":\"M\",\"consenso_privacy\":true}' | python3 -m json.tool"
echo ""
curl -s -X POST http://localhost:8000/utenti \
  -H "Content-Type: application/json" \
  -d '{"nome":"Test","email":"mario@example.com","password":"Pass123!","eta":25,"sesso":"M","consenso_privacy":true}' | python3 -m json.tool
echo ""

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  COMANDI COMPLETATI                           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
