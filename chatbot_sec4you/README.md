# 🛡️ Sec4You - Sistema de Monitoramento de Segurança

## 📱 Sobre o Projeto

O **Sec4You** é um aplicativo móvel desenvolvido em Flutter que oferece monitoramento de segurança em tempo real, focado na proteção de dados e autenticação segura. O app registra e monitora eventos de segurança, fornecendo insights valiosos sobre tentativas de login e atividades suspeitas.

## ✨ Funcionalidades Principais

### 🔐 **Sistema de Autenticação Segura**
- Login e cadastro com Firebase Authentication
- Monitoramento automático de tentativas de login
- Registro de eventos de segurança (sucessos e falhas)

### 📊 **Dashboard de Segurança**
- Visualização de eventos de segurança por usuário
- Monitoramento em tempo real de atividades
- Histórico detalhado de tentativas de acesso
- Alertas de segurança personalizados

### �️ **Verificador de Vazamentos de Dados**
- Verificação de emails e senhas em bases de dados de vazamentos
- Integração com APIs de segurança (HaveIBeenPwned)
- Análise de força de senhas
- Alertas sobre exposição de dados

### 🗺️ **Mapa de Usuários em Tempo Real**
- Visualização geográfica de usuários conectados
- Localização em tempo real com Firebase
- Marcadores interativos no mapa
- Sistema de geolocalização integrado

### 📋 **Sistema de Boards/Fóruns**
- Criação e gerenciamento de boards temáticos
- Sistema de posts com imagens
- Comentários e respostas aninhadas
- Armazenamento local de dados

### �💬 **Chat Interativo**
- Interface de chat para suporte
- Navegação intuitiva entre telas
- Experiência do usuário otimizada

### 🔔 **Notificações Push**
- Firebase Messaging integrado
- Notificações locais personalizadas
- Alertas de segurança em tempo real

### 🎨 **Temas e Personalização**
- Sistema de temas claro/escuro
- Interface responsiva e moderna
- Paleta de cores personalizável

## 🚀 Tecnologias Utilizadas

- **Framework**: Flutter 3.32.0
- **Backend**: Firebase (Firestore + Authentication + Messaging)
- **Linguagem**: Dart
- **Gerenciamento de Estado**: Provider
- **Banco de Dados**: Cloud Firestore + Armazenamento Local
- **Autenticação**: Firebase Auth
- **Mapas**: Flutter Map + OpenStreetMap
- **Notificações**: Firebase Messaging + Flutter Local Notifications
- **Imagens**: Image Picker
- **Geolocalização**: Geolocator + Geocoding
- **APIs Externas**: HaveIBeenPwned (verificação de vazamentos)
- **Criptografia**: Crypto (para hashing de senhas)

## 📦 Dependências Principais

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
  image_picker: ^1.0.4
  shared_preferences: ^2.2.2
  flutter_map: ^6.1.0
  latlong2: ^0.8.1
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  http: ^1.1.0
  crypto: ^3.0.3
  flutter_dotenv: ^5.1.0
```

## 🛠️ Configuração do Projeto

### Pré-requisitos
- Flutter SDK 3.32.0 ou superior
- Dart 3.0+
- Android Studio / VS Code
- Conta Firebase ativa

### 📥 Instalação

1. **Clone o repositório**
```bash
git clone [URL_DO_REPOSITORIO]
cd chatbot_sec4you
```

2. **Instale as dependências**
```bash
flutter pub get
```

3. **Configure o Firebase**
   - Crie um projeto no [Firebase Console](https://console.firebase.google.com/)
   - Adicione o arquivo `google-services.json` em `android/app/`
   - Configure Authentication (Email/Password)
   - Configure Firestore Database

4. **Execute o aplicativo**
```bash
flutter run
```

## 🏗️ Estrutura do Projeto

```
lib/
├── main.dart                          # Ponto de entrada da aplicação
├── auth_exception.dart                # Tratamento de exceções de autenticação
├── firebase_options.dart              # Configurações do Firebase
├── navbar.dart                        # Barra de navegação principal
├── theme_provider.dart                # Gerenciamento de temas
├── local_data.dart                    # Armazenamento local
├── local_user_id.dart                 # Identificação de usuário local
│
├── screens/                           # Telas da aplicação
│   ├── login_page.dart               # Tela de login
│   ├── home_screen.dart              # Tela inicial
│   ├── chat_screen.dart              # Interface de chat
│   ├── security_alerts_screen_real.dart # Dashboard de segurança
│   ├── leak_check_screen.dart        # Verificador de vazamentos
│   ├── users_map_screen.dart         # Mapa de usuários
│   ├── boards_screen.dart            # Lista de boards/fóruns
│   ├── board_screen.dart             # Board individual
│   ├── security_test_screen.dart     # Tela de testes de segurança
│   └── custom_nav_scaffold.dart      # Scaffold personalizado
│
├── service/                          # Serviços da aplicação
│   ├── auth_service.dart             # Serviço de autenticação
│   ├── security_event_service.dart   # Monitoramento de segurança
│   ├── firebase_messaging_service.dart # Notificações push
│   └── user_location_service.dart    # Serviços de localização
│
├── widgets/                          # Componentes reutilizáveis
│   └── security_summary.dart        # Widget de resumo de segurança
│
└── core/                            # Configurações centrais
```

## 🔒 Sistema de Segurança

### Eventos Monitorados
- ✅ **LOGIN_SUCCESS**: Login realizado com sucesso
- ❌ **LOGIN_FAILURE**: Tentativa de login falhada
- 📊 **Análise por usuário**: Eventos filtrados por email

### Dados Coletados
```dart
{
  'userEmail': 'usuario@exemplo.com',
  'success': true/false,
  'errorMessage': 'Detalhes do erro (se houver)',
  'timestamp': DateTime,
  'eventType': 'LOGIN_SUCCESS/LOGIN_FAILURE',
  'source': 'SecurApp Mobile'
}
```

## 🎯 Como Usar

### 1. **Cadastro/Login**
- Abra o aplicativo
- Faça login ou crie uma nova conta
- Todos os eventos são automaticamente registrados

### 2. **Monitoramento de Segurança**
- Acesse o dashboard de segurança
- Visualize seus eventos de login
- Monitore atividades suspeitas

### 3. **Verificação de Vazamentos**
- Acesse a seção "Leak Check"
- Digite seu email ou senha para verificar
- Receba alertas sobre exposição de dados

### 4. **Mapa de Usuários**
- Visualize usuários conectados em tempo real
- Explore localização geográfica
- Monitore atividade por região

### 5. **Sistema de Boards**
- Crie e participe de discussões
- Poste imagens e textos
- Responda a outros usuários

### 6. **Chat de Suporte**
- Use o chat para obter ajuda
- Interface intuitiva e responsiva

### 7. **Configurações e Temas**
- Personalize a aparência do app
- Configure notificações
- Gerencie sua conta

## 🔧 Configuração Firebase

### Firestore Collections

#### `security_events`
```javascript
{
  userEmail: string,
  success: boolean,
  errorMessage?: string,
  timestamp: Timestamp,
  eventType: string,
  source: string
}
```

#### `usuarios`
```javascript
{
  nome: string,
  sobrenome: string,
  email: string,
  criadoEm: Timestamp
}
```

#### `user_locations`
```javascript
{
  userId: string,
  latitude: number,
  longitude: number,
  timestamp: Timestamp,
  isActive: boolean
}
```

#### `boards`
```javascript
{
  name: string,
  description: string,
  createdBy: string,
  createdAt: Timestamp,
  posts: array
}
```

### APIs Externas
- **HaveIBeenPwned API**: Verificação de vazamentos de dados
- **OpenStreetMap**: Dados de mapas
- **Firebase APIs**: Authentication, Firestore, Messaging

## 🧪 Testes

```bash
# Executar todos os testes
flutter test

# Executar testes de widget específicos
flutter test test/widget_test.dart
```

## 📱 Plataformas Suportadas

- ✅ Android
- ✅ iOS
- ✅ Web (limitado)

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 👨‍💻 Desenvolvedores

Desenvolvido pela SecurityConnect

## 🔄 Versão Atual

**v1.0.0** - Sistema básico de monitoramento de segurança implementado

---

### 🚨 Importante

Este aplicativo coleta dados de segurança apenas para fins de monitoramento e proteção. Todos os dados são tratados com segurança e privacidade, seguindo as melhores práticas de proteção de dados.
