import 'package:flutter/material.dart';
import 'package:sentiment_analysis/api_service.dart';
import 'package:sentiment_analysis/models.dart';
import 'main.dart'; // for ThemeScope

class SentimentHomePage extends StatefulWidget {
  const SentimentHomePage({super.key});

  @override
  State<SentimentHomePage> createState() => _SentimentHomePageState();
}

class _SentimentHomePageState extends State<SentimentHomePage> {
  final _api = ApiService();
  final _textCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _models = const ['auto', 'bert', 'gpt2']; // n-gram skipped
  String _selectedModel = 'auto';

  Prediction? _singleResult;
  CompareResult? _compareResult;
  String? _error;
  bool _loading = false;

  // UX helpers
  static const int _maxChars = 4000;
  final _sample = 'The plot was wonderful and the acting was superb!';

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _fillSample() {
    setState(() {
      _textCtrl.text = _sample;
      _singleResult = null;
      _compareResult = null;
      _error = null;
    });
  }

  void _clear() {
    setState(() {
      _textCtrl.clear();
      _singleResult = null;
      _compareResult = null;
      _error = null;
    });
  }

  Future<void> _doPredict() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _singleResult = null;
      _compareResult = null;
    });

    try {
      final res = await _api.predict(
        text: _textCtrl.text.trim(),
        model: _selectedModel,
      );
      setState(() => _singleResult = res);
    } catch (e) {
      setState(() => _error = e.toString());
      _showErrorSnack('Predict failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _doCompare() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _singleResult = null;
      _compareResult = null;
    });

    try {
      final res = await _api.compare(text: _textCtrl.text.trim());
      setState(() => _compareResult = res);
    } catch (e) {
      setState(() => _error = e.toString());
      _showErrorSnack('Compare failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildProbRow(Map<String, dynamic> p) {
    final label = (p['label'] ?? '').toString();
    final score = (p['score'] as num).toDouble().clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: score),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 56, child: Text(score.toStringAsFixed(3))),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(Prediction p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text(p.model.toUpperCase())),
                const SizedBox(width: 8),
                Text(
                  'Label: ${p.label}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Confidence',
                  child: Text('Conf: ${p.confidence.toStringAsFixed(3)}'),
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: 'Latency (ms)',
                  child: Text('Latency: ${p.latencyMs} ms'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Probabilities'),
            const SizedBox(height: 6),
            ...p.probs.map(_buildProbRow),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_loading && _textCtrl.text.trim().isNotEmpty;
    final themeCtl = ThemeScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Sentiment Analysis — BERT & GPT-2'),
        centerTitle: false,
        actions: [
          // Model selector in the AppBar
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedModel,
                items: _models
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: _loading
                    ? null
                    : (v) => setState(() => _selectedModel = v ?? 'auto'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            onPressed: themeCtl.toggle,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          PopupMenuButton<String>(
            tooltip: 'Options',
            onSelected: (value) {
              if (value == 'sample') _fillSample();
              if (value == 'clear') _clear();
              if (value == 'about') {
                showAboutDialog(
                  context: context,
                  applicationName: 'Sentiment Analysis (Web)',
                  applicationVersion: '1.0.0',
                  children: const [
                    Text(
                      'Fine-tuned BERT & GPT-2 on SST-5. Django REST backend, Flutter Web client.',
                    ),
                  ],
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'sample',
                child: ListTile(
                  leading: Icon(Icons.text_snippet),
                  title: Text('Fill sample text'),
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.clear),
                  title: Text('Clear text'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? const [Color(0xFF0F172A), Color.fromARGB(255, 18, 33, 67)]
                    : const [Color(0xFFEFF6FF), Color(0xFFE0F2FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // INPUT
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _textCtrl,
                                minLines: 4,
                                maxLines: 8,
                                maxLength: _maxChars,
                                buildCounter:
                                    (
                                      context, {
                                      required currentLength,
                                      required isFocused,
                                      maxLength,
                                    }) {
                                      return Text(
                                        '$currentLength / $maxLength',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      );
                                    },
                                enabled: !_loading,
                                textInputAction: TextInputAction.newline,
                                decoration: InputDecoration(
                                  labelText: 'Enter text',
                                  hintText: 'Type a review or sentence…',
                                  prefixIcon: const Icon(Icons.edit),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Fill sample',
                                        onPressed: _loading
                                            ? null
                                            : _fillSample,
                                        icon: const Icon(
                                          Icons.text_snippet_outlined,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Clear',
                                        onPressed:
                                            _loading || _textCtrl.text.isEmpty
                                            ? null
                                            : _clear,
                                        icon: const Icon(Icons.clear),
                                      ),
                                    ],
                                  ),
                                  helperText:
                                      'We support models: ${_models.map((e) => e.toUpperCase()).join(", ")}',
                                ),
                                validator: (v) {
                                  final t = v?.trim() ?? '';
                                  if (t.length < 2)
                                    return 'Please enter at least 2 characters';
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  FilledButton.icon(
                                    onPressed:
                                        (!_loading &&
                                            _textCtrl.text.trim().isNotEmpty)
                                        ? _doPredict
                                        : null,
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Predict'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed:
                                        (!_loading &&
                                            _textCtrl.text.trim().isNotEmpty)
                                        ? _doCompare
                                        : null,
                                    icon: const Icon(Icons.compare_arrows),
                                    label: const Text(
                                      'Compare (BERT vs GPT-2)',
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_loading)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.6,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ERROR
                        if (_error != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),

                        // SINGLE RESULT
                        if (_singleResult != null) ...[
                          const SizedBox(height: 12),
                          _buildPredictionCard(_singleResult!),
                        ],

                        // COMPARE RESULT
                        if (_compareResult != null) ...[
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Best:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          '${_compareResult!.best.model.toUpperCase()} → ${_compareResult!.best.label} '
                                          '(${_compareResult!.best.confidence.toStringAsFixed(3)})',
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Latency: ${_compareResult!.best.latencyMs} ms',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  const Text('All results'),
                                  const SizedBox(height: 8),
                                  ..._compareResult!.all.map(
                                    _buildPredictionCard,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          'Powered by Sentimebt Analysis API • Models: BERT, GPT-2',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
