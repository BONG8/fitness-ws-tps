import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/scheda.dart';
import '../services/scheda_service.dart';

class SchedaDetailScreen extends StatefulWidget {
  final int id;
  const SchedaDetailScreen({super.key, required this.id});

  @override
  State<SchedaDetailScreen> createState() => _SchedaDetailScreenState();
}

class _SchedaDetailScreenState extends State<SchedaDetailScreen> {
  final _service = SchedaService();
  late Future<Scheda> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.get(widget.id);
  }

  Future<void> _delete(Scheda s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare scheda?'),
        content: const Text('Operazione irreversibile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(s.id);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Scheda>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text('${snap.error}')),
            );
          }
          final s = snap.data!;
          final c = s.contenuto;
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: Text(s.titolo),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(s),
                  ),
                ],
              ),
              SliverList.list(children: [
                if (c.descrizione.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      c.descrizione,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                if (c.settimaneConsigliate != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Chip(
                      avatar: const Icon(Icons.calendar_month, size: 18),
                      label: Text(
                          'Durata consigliata: ${c.settimaneConsigliate} settimane'),
                    ),
                  ),
                const SizedBox(height: 8),
              ]),
              SliverList.builder(
                itemCount: c.giorni.length,
                itemBuilder: (_, i) => _GiornoCard(giorno: c.giorni[i]),
              ),
              if (s.modelloAi != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Generata da ${s.modelloAi}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}

class _GiornoCard extends StatelessWidget {
  final Giorno giorno;
  const _GiornoCard({required this.giorno});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        color: scheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      giorno.giorno,
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      giorno.focus,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              ...giorno.esercizi.map((e) => _EsercizioTile(ex: e)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EsercizioTile extends StatelessWidget {
  final Esercizio ex;
  const _EsercizioTile({required this.ex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.circle, size: 8),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ex.nome,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _Tag(text: '${ex.serie}x${ex.ripetizioni}'),
                _Tag(text: 'Rec ${ex.recuperoSec}s'),
              ],
            ),
          ),
          if (ex.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 4),
              child: Text(
                ex.note,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: scheme.onSecondaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
