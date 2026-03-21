import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  List<String> _history = const [];

  @override
  void initState() {
    super.initState();
    _loadHostDefaults();
  }

  Future<void> _loadHostDefaults() async {
    final ctrl = ref.read(authSessionProvider.notifier);
    final history = await ctrl.getHostHistory();
    final last = await ctrl.getLastHost();
    if (!mounted) return;
    setState(() => _history = history);
    if ((last ?? '').trim().isNotEmpty) {
      _hostController.text = last!.trim();
    } else if (history.isNotEmpty) {
      _hostController.text = history.first;
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authSessionProvider);
    final authMessage = ref.watch(authMessageProvider);

    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_history.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _history.contains(_hostController.text.trim())
                        ? _hostController.text.trim()
                        : null,
                    items: _history
                        .map(
                          (h) => DropdownMenuItem<String>(
                            value: h,
                            child: Text(h, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: isLoading
                        ? null
                        : (v) {
                            if (v == null) return;
                            _hostController.text = v;
                          },
                    decoration: const InputDecoration(
                      labelText: 'Previous HOST_URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (_history.isNotEmpty) const SizedBox(height: 12),
                TextFormField(
                  controller: _hostController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'HOST_URL',
                    hintText: 'http://192.168.0.10:8080',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'HOST_URL is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Username is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  enabled: !isLoading,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Password is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                if (authMessage != null) ...[
                  Text(
                    authMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          await ref
                              .read(authSessionProvider.notifier)
                              .login(
                                hostUrl: _hostController.text,
                                username: _usernameController.text,
                                password: _passwordController.text,
                              );
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
