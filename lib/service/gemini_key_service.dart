import 'dart:math';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiKeyService {
  GeminiKeyService._();
  static final instance = GeminiKeyService._();

  final _remoteConfig = FirebaseRemoteConfig.instance;
  List<String> _keys = [];
  
  final String _fallbackKey = dotenv.env['GEMINI_API_KEY'] ?? 'SUA_CHAVE_DE_EMERGENCIA_AQUI';

  Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        
        // ###################### CORREÇÃO AQUI ######################
        // Mude de 'hours: 1' para 'seconds: 0' para forçar a busca
        minimumFetchInterval: const Duration(seconds: 60), 
        // ###########################################################
      ));
      
      await _remoteConfig.fetchAndActivate();
      
      final keysString = _remoteConfig.getString('gemini_api_keys');
      if (keysString.isNotEmpty) {
        _keys = keysString.split(',');
        print("✅ Chaves do Gemini carregadas: ${_keys.length} chaves encontradas.");
      } else {
        print("🚨 NENHUMA CHAVE DO GEMINI ENCONTRADA NO REMOTE CONFIG!");
      }

    } catch (e) {
      print("🚨 Erro ao carregar chaves do Remote Config: $e");
    }
  }

  String getAKey() {
    if (_keys.isEmpty) {
      print("🚨 Nenhuma chave na lista! Usando fallback de emergência.");
      return _fallbackKey; 
    }
    
    final randomKey = _keys[Random().nextInt(_keys.length)];
    return randomKey;
  }
  List<String> getAllKeys() {
    if (_keys.isEmpty) {
      print("🚨 Nenhuma chave na lista! Usando fallback de emergência.");
      return [_fallbackKey]; // Retorna uma lista com o fallback
    }
    return _keys;
  }
}