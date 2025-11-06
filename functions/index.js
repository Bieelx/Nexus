/**
 * Firebase Cloud Functions para Nexus App
 * Proxy para API do Have I Been Pwned (resolve CORS na web)
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });
const axios = require('axios');

admin.initializeApp();

/**
 * Função: checkEmailBreaches
 * Verifica vazamentos de email via HIBP API
 *
 * Endpoint: https://us-central1-[seu-projeto].cloudfunctions.net/checkEmailBreaches
 * Método: POST
 * Body: { "email": "teste@example.com" }
 *
 * Retorna: Array de breaches ou array vazio
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
            // Aceita 200 (found) e 404 (not found) como válidos
            return status === 200 || status === 404;
          },
        }
      );

      if (response.status === 404) {
        // Email não encontrado em vazamentos
        return res.status(200).json([]);
      }

      // Retorna os breaches encontrados
      return res.status(200).json(response.data);

    } catch (error) {
      console.error('Erro ao consultar HIBP:', error.message);

      if (error.response) {
        // Erro da API HIBP
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
 * Verifica pastes públicos onde o email aparece
 *
 * Endpoint: https://us-central1-[seu-projeto].cloudfunctions.net/checkEmailPastes
 * Método: POST
 * Body: { "email": "teste@example.com" }
 *
 * Retorna: Array de pastes ou array vazio
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
        // Pastes requer API key premium
        return res.status(403).json({ error: 'Sem permissão para pastes' });
      }

      return res.status(500).json({ error: 'Erro ao consultar pastes' });
    }
  });
});
