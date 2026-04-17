import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_overlay.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _etaCtrl;
  final _passwordCtrl = TextEditingController();
  late String _sesso;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    _nomeCtrl = TextEditingController(text: u?.nome ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _etaCtrl = TextEditingController(text: u?.eta.toString() ?? '');
    _sesso = u?.sesso ?? 'M';
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _etaCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final body = <String, dynamic>{
      'nome': _nomeCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'eta': int.parse(_etaCtrl.text.trim()),
      'sesso': _sesso,
    };
    if (_passwordCtrl.text.isNotEmpty) {
      body['password'] = _passwordCtrl.text;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(body);
    if (!mounted) return;
    if (ok) {
      setState(() => _editing = false);
      _passwordCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilo aggiornato')),
      );
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare account?'),
        content: const Text(
            'Tutti i tuoi dati e le tue schede saranno rimossi. Irreversibile.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla')),
          FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Elimina')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final done = await auth.deleteAccount();
    if (!mounted) return;
    if (done) {
      context.go('/login');
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: LoadingOverlay(
        loading: auth.loading,
        child: user == null
            ? const Center(child: Text('Nessun utente'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            child: Text(
                              user.nome.isNotEmpty
                                  ? user.nome[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _nomeCtrl,
                            enabled: _editing,
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            enabled: _editing,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _etaCtrl,
                                  enabled: _editing,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Età',
                                    prefixIcon: Icon(Icons.cake_outlined),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _sesso,
                                  decoration: const InputDecoration(
                                    labelText: 'Sesso',
                                    prefixIcon: Icon(Icons.wc),
                                  ),
                                  items: const ['M', 'F', 'Altro']
                                      .map((s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s),
                                          ))
                                      .toList(),
                                  onChanged: _editing
                                      ? (v) => setState(() => _sesso = v ?? 'M')
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          if (_editing) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Nuova password (opzionale)',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          if (_editing) ...[
                            FilledButton.icon(
                              onPressed: _save,
                              icon: const Icon(Icons.save),
                              label: const Text('Salva'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _editing = false),
                              child: const Text('Annulla'),
                            ),
                          ],
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _deleteAccount,
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Elimina account'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
