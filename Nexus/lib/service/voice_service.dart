import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

// Classe auxiliar para o just_audio conseguir ler os bytes da memória
class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;

  _BytesAudioSource(this._bytes) : super(tag: 'BytesAudioSource');

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final startVal = start ?? 0;
    final endVal = end ?? _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: endVal - startVal,
      offset: startVal,
      stream: Stream.value(_bytes.sublist(startVal, endVal)),
      contentType: 'audio/mpeg',
    );
  }
}

class VoiceService {
  // Guardamos a instância do player para evitar criar um novo a cada vez
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Suas chaves e IDs da ElevenLabs
  static const String _apiKey = 'sk_2d130af3afb686a0ef513e6579ec77771cea46a58c959e77';
  static const String _voiceId = 'Sm1seazb4gs7RSlUVw7c';
  static const String _baseUrl = 'https://api.elevenlabs.io/v1/text-to-speech/';

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    final url = Uri.parse('$_baseUrl$_voiceId');
    final headers = {
      'Content-Type': 'application/json',
      'xi-api-key': _apiKey,
    };
    final body = jsonEncode({
      'text': text,
      'model_id': 'eleven_multilingual_v2',
      'voice_settings': {'stability': 0.4, 'similarity_boost': 0.8}
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Uint8List audioBytes = response.bodyBytes;

        // Para qualquer áudio que esteja tocando antes de iniciar o novo
        await _audioPlayer.stop();

        // Usa o just_audio para tocar os bytes recebidos da API
        final audioSource = _BytesAudioSource(audioBytes);
        await _audioPlayer.setAudioSource(audioSource);
        _audioPlayer.play();

      } else {
        print('Erro na API da ElevenLabs: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exceção ao tentar gerar ou tocar a fala: $e');
    }
  }

  // É uma boa prática ter um método para liberar os recursos do player
  void dispose() {
    _audioPlayer.dispose();
  }
}