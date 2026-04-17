import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_logo.dart';
import '../widgets/loading_overlay.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _etaCtrl = TextEditingController();
  String _sesso = 'M';
  bool _consenso = false;
  bool _obscure = true;

  static const _sessoOptions = ['M', 'F', 'Altro'];

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _etaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consenso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devi accettare la privacy')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      nome: _nomeCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      eta: int.parse(_etaCtrl.text.trim()),
      sesso: _sesso,
      consensoPrivacy: _consenso,
    );
    if (!mounted) return;
    if (ok) {
      context.go('/home/quiz');
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Registrati')),
      body: LoadingOverlay(
        loading: auth.loading,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AppLogo(size: 64)),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nomeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length < 2) {
                            return 'Minimo 2 caratteri';
                          }
                          if (v.trim().length > 100) return 'Massimo 100';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email richiesta';
                          }
                          if (!v.contains('@')) return 'Email non valida';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          helperText: 'Min 8 caratteri, 1 lettera + 1 numero',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 8) {
                            return 'Minimo 8 caratteri';
                          }
                          if (v.length > 128) return 'Massimo 128';
                          final hasLetter = RegExp(r'[A-Za-z]').hasMatch(v);
                          final hasDigit = RegExp(r'\d').hasMatch(v);
                          if (!hasLetter || !hasDigit) {
                            return 'Deve contenere lettera e numero';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _etaCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Età',
                                prefixIcon: Icon(Icons.cake_outlined),
                              ),
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                if (n == null) return 'Numero';
                                if (n < 13 || n > 100) {
                                  return '13-100';
                                }
                                return null;
                              },
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
                              items: _sessoOptions
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _sesso = v ?? 'M'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        value: _consenso,
                        onChanged: (v) =>
                            setState(() => _consenso = v ?? false),
                        title: const Text('Accetto informativa privacy'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: auth.loading ? null : _submit,
                        child: const Text('Crea account'),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Hai già un account? Accedi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
