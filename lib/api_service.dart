import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sentiment_analysis/api_config.dart';
import 'models.dart';

class ApiService {
  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<String>> getModels() async {
    final uri = Uri.parse('${AppConfig.apiBase}/v1/models/');
    final r = await _client.get(uri);
    if (r.statusCode != 200) {
      throw Exception('Failed to get models (${r.statusCode})');
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return (data['models'] as List).cast<String>();
  }

  Future<Prediction> predict({
    required String text,
    required String model,
  }) async {
    debugPrint('predict');
    final uri = Uri.parse('${AppConfig.apiBase}/v1/predict/');
    debugPrint(uri.toString());
    final r = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text, 'model': model}),
        )
        .timeout(const Duration(seconds: 20));
    debugPrint(r.statusCode.toString());
    if (r.statusCode != 200) {
      debugPrint(r.body);
      throw Exception('Predict failed (${r.statusCode}): ${r.body}');
    }
    debugPrint(r.body);
    return Prediction.fromJson(jsonDecode(r.body));
  }

  Future<CompareResult> compare({required String text}) async {
    final uri = Uri.parse('${AppConfig.apiBase}/v1/compare/');
    final r = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text, 'model': 'auto'}),
    );
    if (r.statusCode != 200) {
      throw Exception('Compare failed (${r.statusCode}): ${r.body}');
    }
    return CompareResult.fromJson(jsonDecode(r.body));
  }
}
