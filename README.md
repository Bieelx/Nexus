# 🌌 Nexus – Comunidade e Segurança Digital

## 📱 Sobre o Projeto
O **Nexus** é um aplicativo mobile desenvolvido em **Flutter** que une **comunidade, aprendizado e segurança da informação** em um único ecossistema.  
Nosso objetivo é apoiar usuários na **Sociedade 5.0**, oferecendo ferramentas para **interagir, aprender e se proteger no ambiente digital**.

---

## ✨ Funcionalidades Principais

### 🗨️ Comunidade
- Timeline interativa para postagens, curtidas e comentários  
- Grupos de discussão com **chat em tempo real**  
- Bolhas de mensagem personalizadas e salvas no Firebase  

### 🤖 Lua – Assistente Virtual
- Mascote oficial do app, baseada em **IA Gemini**  
- Responde em português com tom emocional adaptado (feliz, triste, bravo, explicando, neutro)  
- Especializada em segurança digital, vazamentos, comunidade e notícias  

### 📰 Notícias Inteligentes
- Integração com APIs de tecnologia e cibersegurança  
- **Resumos automáticos por IA**, rápidos e objetivos  
- Planos premium enviam os resumos também por e-mail  

### 🎓 Cursos de Segurança Digital
- Conteúdo dividido em **básico, intermediário e avançado**  
- Certificação digital para níveis pagos  
- Experiência educativa simples e acessível  

### 🔐 Monitoramento de Vazamentos
- Consulta de e-mails em bases de dados expostas  
- Alertas de novos vazamentos (premium)  

### 🔔 Notificações
- Interações em posts e grupos  
- Alertas de segurança, cursos e notícias resumidas  

---

## 🚀 Tecnologias Utilizadas
- **Framework**: Flutter 3.x  
- **Backend**: Firebase (Firestore + Authentication + Messaging)  
- **IA**: Gemini API para chatbot e resumos  
- **Linguagem**: Dart  
- **Gerenciamento de Estado**: Provider  
- **Banco de Dados**: Cloud Firestore  
- **Autenticação**: Firebase Auth  
- **Notificações**: Firebase Messaging + Local Notifications  

---

## 📦 Dependências (principais)
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  provider: ^6.1.1
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^17.0.0
  http: ^1.1.0
  flutter_dotenv: ^5.1.0
```
---

## 🛠️ Como Executar o Projeto

### 📋 Pré-requisitos
- **Flutter SDK** 3.x instalado  
- **Dart** 3.x ou superior  
- Conta configurada no **Firebase**  
- Chave da **Gemini API** configurada em um arquivo `.env` na raiz do projeto  

### 📥 Instalação

1. **Clone o repositório**
   ```bash
   git clone [URL_DO_REPOSITORIO]
   cd nexus_app
   ```
2. **Instale as dependências**
  ```bash
  flutter pub get
  ```
3. **Configure o Firebase**
- Crie um projeto no Firebase Console
- Adicione o arquivo google-services.json em android/app/
- Adicione o arquivo GoogleService-Info.plist em ios/Runner/
- Ative Authentication (Email/Password)
- Configure o Cloud Firestore
  
4. **Configure a Gemini API**
  ```env
  GEMINI_API_KEY=SUA_CHAVE_AQUI
  ```
