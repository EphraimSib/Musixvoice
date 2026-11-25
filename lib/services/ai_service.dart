import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum AiProvider { deepseek, claude }

/// Optional cloud AI. The user adds their own API key in Settings, so no key
/// is ever stored inside the APK. Without a key the app falls back to the
/// built-in on-device taste profile.
class AiService extends ChangeNotifier {
  AiProvider provider = AiProvider.deepseek;
  String apiKey = '';

  bool get hasKey => apiKey.trim().isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    apiKey = prefs.getString('ai_key') ?? '';
    provider = prefs.getString('ai_provider') == 'claude'
        ? AiProvider.claude
        : AiProvider.deepseek;
  }

  Future<void> save(AiProvider p, String key) async {
    provider = p;
    apiKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_key', apiKey);
    await prefs.setString('ai_provider', p == AiProvider.claude ? 'claude' : 'deepseek');
    notifyListeners();
  }

  Future<String> ask(String prompt, {String system = ''}) async {
    if (!hasKey) throw Exception('Add an AI key in Settings first.');
    final http.Response r;
    if (provider == AiProvider.claude) {
      r = await http
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'model': 'claude-sonnet-5-5',
              'max_tokens': 600,
              'system': system,
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
            }),
          )
          .timeout(const Duration(seconds: 40));
      if (r.statusCode != 200) throw Exception('AI error ${r.statusCode}');
      return (jsonDecode(r.body)['content'][0]['text'] as String).trim();
    } else {
      r = await http
          .post(
            Uri.parse('https://api.deepseek.com/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'model': 'deepseek-chat',
              'max_tokens': 600,
              'messages': [
                if (system.isNotEmpty) {'role': 'system', 'content': system},
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 40));
      if (r.statusCode != 200) throw Exception('AI error ${r.statusCode}');
      return (jsonDecode(r.body)['choices'][0]['message']['content'] as String).trim();
    }
  }
}
