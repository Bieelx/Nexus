/**
 * Firebase Cloud Functions para Nexus App
 * - Proxy para API do Have I Been Pwned (resolve CORS na web)
 * - Proxy seguro para API do Gemini (com rotação de chaves)
 */

// --- Importações V1 (para HIBP) ---
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });
const axios = require('axios');

// --- Importações V2 (para o Gemini) ---
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { GoogleGenerativeAI } = require("@google/generative-ai");

admin.initializeApp();

// =======================================================
// SEGREDO (usado pela função v2 do Gemini)
// =======================================================
const GEMINI_KEYS = defineSecret("GEMINI_KEYS");

// =======================================================
// SUAS FUNÇÕES HIBP (v1) - (Sem alterações)
// =======================================================

/**
 * Função: checkEmailBreaches
 */
exports.checkEmailBreaches = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    // Aceita apenas POST
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    const { email } = req.body;

    // Validação básica
    if (!email || typeof email !== 'string') {
      return res.status(400).json({ error: 'Email inválido' });
    }

    // Validação de formato de email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: 'Formato de email inválido' });
    }

    try {
      // API key do HIBP (configurar no Firebase Config)
      const apiKey = functions.config().hibp?.apikey || process.env.HIBP_API_KEY;

      if (!apiKey) {
        console.error('HIBP API key não configurada');
        return res.status(500).json({ error: 'Configuração inválida' });
      }

      // Requisição para HIBP API
      const response = await axios.get(
        `https://haveibeenpwned.com/api/v3/breachedaccount/${encodeURIComponent(email)}`,
        {
          headers: {
            'hibp-api-key': apiKey,
            'user-agent': 'Nexus-App-Backend',
          },
          validateStatus: (status) => {
            return status === 200 || status === 404;
          },
        }
      );

      if (response.status === 404) {
        return res.status(200).json([]);
      }
      return res.status(200).json(response.data);

    } catch (error) {
      console.error('Erro ao consultar HIBP:', error.message);
      if (error.response) {
        if (error.response.status === 401) {
          return res.status(500).json({ error: 'API key inválida' });
        }
        if (error.response.status === 429) {
          return res.status(429).json({ error: 'Rate limit excedido' });
        }
      }
      return res.status(500).json({ error: 'Erro ao consultar vazamentos' });
    }
  });
});

/**
 * Função: checkEmailPastes
 */
exports.checkEmailPastes = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    const { email } = req.body;

    if (!email || typeof email !== 'string') {
      return res.status(400).json({ error: 'Email inválido' });
    }

    try {
      const apiKey = functions.config().hibp?.apikey || process.env.HIBP_API_KEY;

      if (!apiKey) {
        return res.status(500).json({ error: 'Configuração inválida' });
      }

      const response = await axios.get(
        `https://haveibeenpwned.com/api/v3/pasteaccount/${encodeURIComponent(email)}`,
        {
          headers: {
            'hibp-api-key': apiKey,
            'user-agent': 'Nexus-App-Backend',
          },
          validateStatus: (status) => status === 200 || status === 404,
        }
      );

      if (response.status === 404) {
        return res.status(200).json([]);
      }
      return res.status(200).json(response.data);

    } catch (error) {
      console.error('Erro ao consultar pastes:', error.message);
      if (error.response?.status === 403) {
        return res.status(403).json({ error: 'Sem permissão para pastes' });
      }
      return res.status(500).json({ error: 'Erro ao consultar pastes' });
    }
  });
});


// =======================================================
// NOVA FUNÇÃO DO GEMINI (v2)
// =======================================================

exports.callGemini = onCall(
  { secrets: [GEMINI_KEYS] }, // Informa ao Firebase para carregar o segredo
  async (request) => {
    // 1. Pega o prompt enviado pelo app Flutter
    if (!request.data || !request.data.prompt) {
      throw new HttpsError("invalid-argument", "O prompt não pode ser vazio.");
    }
    const prompt = request.data.prompt;

    try {
      // 2. Pega sua lista de chaves do Secret Manager
      const keysString = GEMINI_KEYS.value();
      const keys = keysString.split(",");
      
      // 3. Pega uma chave aleatória da sua lista
      const randomKey = keys[Math.floor(Math.random() * keys.length)];

      // 4. Inicializa o Gemini com essa chave
      const genAI = new GoogleGenerativeAI(randomKey);
      const model = genAI.getGenerativeModel({ model: "gemini-pro" }); // ou o modelo que você usa

      // 5. Faz a chamada para o Gemini (do servidor!)
      const result = await model.generateContent(prompt);
      const response = await result.response;
      
      // 6. Retorna o texto da resposta para o app
      return { text: response.text() };

    } catch (error) {
      console.error("Erro ao chamar o Gemini:", error);
      // Loga o erro para você ver no console do Firebase
      throw new HttpsError("internal", "Não foi possível processar a resposta do Gemini.");
    }
  }
);