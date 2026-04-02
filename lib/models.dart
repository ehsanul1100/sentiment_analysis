class Prediction {
  final String model;
  final String label;
  final double confidence;
  final List<Map<String, dynamic>> probs;
  final int latencyMs;

  Prediction({
    required this.model,
    required this.label,
    required this.confidence,
    required this.probs,
    required this.latencyMs,
  });

  factory Prediction.fromJson(Map<String, dynamic> j) => Prediction(
    model: j['model'] as String,
    label: j['label'] as String,
    confidence: (j['confidence'] as num).toDouble(),
    probs: (j['probs'] as List).cast<Map<String, dynamic>>(),
    latencyMs: j['latency_ms'] as int,
  );
}

class CompareResult {
  final Prediction best;
  final List<Prediction> all;

  CompareResult({required this.best, required this.all});

  factory CompareResult.fromJson(Map<String, dynamic> j) => CompareResult(
    best: Prediction.fromJson(j['best']),
    all: (j['all'] as List).map((e) => Prediction.fromJson(e)).toList(),
  );
}
