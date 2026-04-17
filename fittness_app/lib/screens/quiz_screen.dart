import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/quiz.dart';
import '../services/api_client.dart';
import '../services/quiz_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = QuizService();

  Obiettivo _obiettivo = Obiettivo.massa;
  Livello _livello = Livello.principiante;
  int _giorni = 3;
  int _durata = 60;
  final _attrezzaturaCtrl = TextEditingController(text: 'nessuna');
  final _limitazioniCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _attrezzaturaCtrl.dispose();
    _limitazioniCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final input = QuizInput(
      obiettivo: _obiettivo,
      livello: _livello,
      giorniSettimana: _giorni,
      durataSessione: _durata,
      attrezzatura: _attrezzaturaCtrl.text.trim().isEmpty
          ? 'nessuna'
          : _attrezzaturaCtrl.text.trim(),
      limitazioni: _limitazioniCtrl.text.trim(),
    );
    try {
      final r = await _service.submit(input);
      if (!mounted) return;
      context.go('/home/scheda/${r.schedaId}');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crea la tua scheda')),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Obiettivo',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: Obiettivo.values
                              .map((o) => ChoiceChip(
                                    label: Text(o.label),
                                    selected: _obiettivo == o,
                                    onSelected: (_) =>
                                        setState(() => _obiettivo = o),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Livello',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<Livello>(
                          segments: Livello.values
                              .map((l) => ButtonSegment<Livello>(
                                    value: l,
                                    label: Text(l.label),
                                  ))
                              .toList(),
                          selected: {_livello},
                          onSelectionChanged: (s) =>
                              setState(() => _livello = s.first),
                        ),
                        const SizedBox(height: 24),
                        _SliderRow(
                          label: 'Giorni a settimana',
                          value: _giorni.toDouble(),
                          min: 1,
                          max: 7,
                          divisions: 6,
                          suffix: '$_giorni',
                          onChanged: (v) =>
                              setState(() => _giorni = v.round()),
                        ),
                        const SizedBox(height: 12),
                        _SliderRow(
                          label: 'Durata sessione',
                          value: _durata.toDouble(),
                          min: 15,
                          max: 180,
                          divisions: (180 - 15) ~/ 5,
                          suffix: '$_durata min',
                          onChanged: (v) =>
                              setState(() => _durata = (v / 5).round() * 5),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _attrezzaturaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Attrezzatura disponibile',
                            hintText: 'es: manubri, panca',
                            prefixIcon: Icon(Icons.handyman_outlined),
                          ),
                          maxLength: 255,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _limitazioniCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Limitazioni / Infortuni (facoltativo)',
                            hintText: 'es: mal di schiena, spalla',
                            prefixIcon: Icon(Icons.healing_outlined),
                          ),
                          maxLines: 3,
                          maxLength: 2000,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Genera scheda AI'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'La generazione può richiedere fino a 90 secondi',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_submitting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Generazione scheda in corso...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final ValueChanged<double> onChanged;
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Text(suffix),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
