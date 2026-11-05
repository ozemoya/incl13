import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(CampusAuth(AuthService(FirebaseAuth.instance)));
}

class CampusAuth extends StatelessWidget {
  const CampusAuth(this.service, {super.key});
  final AuthService service;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Campus Access',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: const Color(0xff176c5f)),
    home: StreamBuilder<User?>(
      stream: service.changes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Could not check your session. Restart the app to try again.',
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Checking session',
              ),
            ),
          );
        }
        final user = snapshot.data;
        return user == null
            ? AccountPage(service: service)
            : AccountPage(
                key: ValueKey(user.uid),
                service: service,
                user: user,
              );
      },
    ),
  );
}

class AccountPage extends StatefulWidget {
  const AccountPage({required this.service, this.user, super.key});
  final AuthService service;
  final User? user;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _currentPassword = TextEditingController();
  bool _register = false;
  bool _updating = false;
  bool _reauthenticate = false;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _currentPassword.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'requires-recent-login' && _updating) {
          _reauthenticate = true;
          _error = 'Enter your current password to confirm this change.';
        } else {
          _error = authMessage(e.code);
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await _run(() async {
      if (_updating) {
        await widget.service.updatePassword(
          _password.text,
          currentPassword: _reauthenticate ? _currentPassword.text : null,
        );
        if (!mounted) return;
        _password.clear();
        _currentPassword.clear();
        setState(() {
          _updating = false;
          _reauthenticate = false;
          _notice = 'Password updated.';
        });
      } else if (_register) {
        await widget.service.register(_email.text.trim(), _password.text);
      } else {
        await widget.service.signIn(_email.text.trim(), _password.text);
      }
    });
  }

  void _switchMode() {
    _form.currentState?.reset();
    _password.clear();
    _currentPassword.clear();
    setState(() {
      if (widget.user == null) {
        _register = !_register;
      } else {
        _updating = !_updating;
      }
      _reauthenticate = false;
      _error = null;
      _notice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final title = user != null
        ? 'Your profile'
        : _register
        ? 'Create account'
        : 'Sign in';
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Access')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      user == null
                          ? Icons.lock_outline
                          : Icons.account_circle_outlined,
                      size: 54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    if (user != null)
                      SelectableText(user.email ?? 'Email unavailable'),
                    if (user == null)
                      TextFormField(
                        controller: _email,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) =>
                            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(value?.trim() ?? '')
                            ? null
                            : 'Enter a valid email address.',
                      ),
                    if (_reauthenticate)
                      TextFormField(
                        controller: _currentPassword,
                        enabled: !_busy,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Current password',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your current password.'
                            : null,
                      ),
                    if (user == null || _updating)
                      TextFormField(
                        controller: _password,
                        enabled: !_busy,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: _updating ? 'New password' : 'Password',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter a password.';
                          }
                          if ((_register || _updating) && value.length < 6) {
                            return 'Use at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                    if (_busy)
                      const LinearProgressIndicator(
                        semanticsLabel: 'Authentication request in progress',
                      ),
                    if (_error case final error?)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (_notice case final notice?)
                      Semantics(liveRegion: true, child: Text(notice)),
                    if (user == null || _updating)
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(_updating ? 'Save new password' : title),
                      ),
                    TextButton(
                      onPressed: _busy ? null : _switchMode,
                      child: Text(
                        user != null
                            ? _updating
                                  ? 'Cancel password change'
                                  : 'Change password'
                            : _register
                            ? 'Back to sign in'
                            : 'Create an account',
                      ),
                    ),
                    if (user != null)
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _run(widget.service.signOut),
                        child: const Text('Sign out'),
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
