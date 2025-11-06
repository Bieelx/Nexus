# Firebase Cloud Functions - Nexus HIBP Proxy

Proxy backend para contornar CORS na versão web do app Nexus.

## 🎯 O que faz

Estas Cloud Functions servem como **proxy** entre o app Flutter (web) e a API do Have I Been Pwned, resolvendo problemas de CORS.

### Functions disponíveis:

1. **checkEmailBreaches** - Verifica vazamentos de email
2. **checkEmailPastes** - Verifica pastes públicos

## 🚀 Setup Rápido

### 1. Instalar Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### 2. Selecionar Projeto

```bash
cd "C:\Users\Desktop\GS - 2025 - sec4u\Nexus"
firebase use --add
# Selecione seu projeto Firebase
```

### 3. Configurar API Key

```bash
firebase functions:config:set hibp.apikey="05715c8996d647e6acc17a177af6ecae"
```

### 4. Instalar Dependências

```bash
cd functions
npm install
```

### 5. Deploy

```bash
cd ..
firebase deploy --only functions
```

**Aguarde 2-5 minutos para o deploy completar.**

## 📝 Configuração no App

Após o deploy, copie a URL base das functions (algo como `https://us-central1-SEU-PROJETO.cloudfunctions.net`) e atualize em:

**`lib/service/hibp_service.dart`** linha ~90:

```dart
static const String _cloudFunctionsUrl =
    'https://us-central1-SEU-PROJETO-ID.cloudfunctions.net';
```

## 🧪 Testar Localmente (Opcional)

```bash
# Rodar emulador local
cd functions
npm run serve

# As functions estarão em:
# http://localhost:5001/SEU-PROJETO/us-central1/checkEmailBreaches
# http://localhost:5001/SEU-PROJETO/us-central1/checkEmailPastes
```

## 📊 Endpoints

### POST /checkEmailBreaches

**Request:**
```json
{
  "email": "teste@example.com"
}
```

**Response (200):**
```json
[
  {
    "Name": "Adobe",
    "Title": "Adobe",
    "Domain": "adobe.com",
    "BreachDate": "2013-10-04",
    "PwnCount": 152445165,
    "Description": "...",
    "DataClasses": ["Email addresses", "Passwords"],
    "IsVerified": true,
    "IsSensitive": false
  }
]
```

**Response (200 - não encontrado):**
```json
[]
```

**Errors:**
- `400` - Email inválido
- `429` - Rate limit excedido
- `500` - Erro interno

### POST /checkEmailPastes

**Request:**
```json
{
  "email": "teste@example.com"
}
```

**Response:** Similar ao checkEmailBreaches

## 💰 Custos

### Requer Firebase Blaze Plan (Pay-as-you-go)

**Cota grátis mensal:**
- 2 milhões de invocações
- 400.000 GB-segundos
- 200.000 CPU-segundos

**Custo estimado para app pequeno/médio:** R$ 0-10/mês

## 🔒 Segurança

### CORS

As functions habilitam CORS para todas as origens:

```javascript
const cors = require('cors')({ origin: true });
```

**Para produção**, restrinja para seu domínio:

```javascript
const cors = require('cors')({
  origin: 'https://seu-app.web.app'
});
```

### API Key

A API key do HIBP é armazenada de forma segura no Firebase Config:

```bash
firebase functions:config:set hibp.apikey="SUA_KEY"
```

**Nunca** commit a API key no código!

## 📈 Monitoramento

### Ver logs em tempo real:

```bash
firebase functions:log --only checkEmailBreaches
```

### Ver métricas no console:

https://console.firebase.google.com/project/SEU-PROJETO/functions/logs

## 🐛 Troubleshooting

### Erro: "Billing account not configured"

1. Acesse https://console.firebase.google.com
2. Settings → Usage and billing
3. Upgrade para plano Blaze
4. Adicione método de pagamento

### Erro: "API key not found"

```bash
# Verificar config
firebase functions:config:get

# Reconfigurar
firebase functions:config:set hibp.apikey="05715c8996d647e6acc17a177af6ecae"

# Re-deploy
firebase deploy --only functions
```

### Functions não aparecem

```bash
# Listar functions
firebase functions:list

# Se não aparecer, fazer deploy novamente
firebase deploy --only functions --force
```

## 📚 Documentação

- [Firebase Functions](https://firebase.google.com/docs/functions)
- [HIBP API](https://haveibeenpwned.com/API/v3)
- [Node.js Docs](https://nodejs.org/docs)

## 🔄 Updates

Para atualizar o código das functions:

```bash
# 1. Editar functions/index.js
# 2. Re-deploy
firebase deploy --only functions
```

## ✅ Checklist de Deploy

- [ ] Firebase CLI instalado
- [ ] Logged in (`firebase login`)
- [ ] Projeto selecionado (`firebase use`)
- [ ] API key configurada (`firebase functions:config:set`)
- [ ] Plano Blaze ativado
- [ ] Dependências instaladas (`npm install`)
- [ ] Deploy realizado (`firebase deploy --only functions`)
- [ ] URL atualizada no app Flutter
- [ ] Testado na web

---

**Desenvolvido para Nexus App** 🚀
