import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _esRegistro = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final error = _esRegistro
        ? await auth.registrar(email, password)
        : await auth.login(email, password);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else if (mounted && !_esRegistro) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final isSmallScreen = screenSize.width < 600;
    final isLargeScreen = screenSize.width > 900;

    final iconSize = isSmallScreen ? 64.0 : (isLargeScreen ? 100.0 : 80.0);
    final formPadding = isSmallScreen ? 24.0 : (isLargeScreen ? 48.0 : 32.0);
    final spacingLarge = isSmallScreen ? 32.0 : 48.0;
    final spacingMedium = isSmallScreen ? 16.0 : 24.0;
    final spacingSmall = isSmallScreen ? 8.0 : 12.0;
    final titleFontSize = isSmallScreen
        ? theme.textTheme.headlineSmall
        : theme.textTheme.headlineMedium;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxFormWidth = constraints.maxWidth > 600 ? 400.0 : double.infinity;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(formPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxFormWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          size: iconSize,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(height: spacingSmall),
                        Text(
                          'Notebook Senior',
                          style: titleFontSize?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: spacingSmall),
                        if (!isLandscape || isLargeScreen)
                          Text(
                            'Tus notas y tareas siempre contigo',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        SizedBox(height: spacingLarge),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: const Icon(Icons.email_outlined),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: isSmallScreen ? 14 : 18,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa tu correo';
                            if (!v.contains('@')) return 'Correo inválido';
                            return null;
                          },
                        ),
                        SizedBox(height: spacingMedium),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: isSmallScreen ? 14 : 18,
                            ),
                          ),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                        SizedBox(height: spacingMedium),
                        SizedBox(
                          width: double.infinity,
                          height: isSmallScreen ? 48 : 52,
                          child: FilledButton(
                            onPressed: auth.cargando ? null : _submit,
                            child: auth.cargando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    _esRegistro ? 'Crear cuenta' : 'Iniciar sesión',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : 18,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: spacingSmall),
                        TextButton(
                          onPressed: () => setState(() => _esRegistro = !_esRegistro),
                          child: Text(
                            _esRegistro
                                ? '¿Ya tienes cuenta? Inicia sesión'
                                : '¿No tienes cuenta? Regístrate',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
