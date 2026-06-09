import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notebook_senior/auth/login_screen.dart';
import 'package:notebook_senior/core/providers/auth_provider.dart';
import 'test_helper.dart';

void main() {
  late MockAuthProvider auth;

  setUp(() {
    auth = MockAuthProvider();
    when(() => auth.user).thenReturn(null);
    when(() => auth.cargando).thenReturn(false);
    when(() => auth.error).thenReturn(null);
    when(() => auth.estaLogueado).thenReturn(false);
    when(() => auth.displayName).thenReturn('');
    when(() => auth.login(any(), any())).thenAnswer((_) async => null);
    when(() => auth.registrar(any(), any())).thenAnswer((_) async => null);
  });

  testWidgets('LoginScreen shows app title and form fields', (tester) async {
    await tester.pumpWidget(createTestApp(child: const LoginScreen(), auth: auth));

    expect(find.text('Iniciar sesión'), findsAtLeast(1));
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('¿No tienes cuenta? Regístrate'), findsOneWidget);
  });

  testWidgets('LoginScreen switches to register mode', (tester) async {
    await tester.pumpWidget(createTestApp(child: const LoginScreen(), auth: auth));

    await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
    await tester.pumpAndSettle();

    expect(find.text('Crear cuenta'), findsAtLeast(1));
    expect(find.text('¿Ya tienes cuenta? Inicia sesión'), findsOneWidget);
  });

  testWidgets('LoginScreen shows loading indicator when cargando', (tester) async {
    when(() => auth.cargando).thenReturn(true);

    await tester.pumpWidget(createTestApp(child: const LoginScreen(), auth: auth));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('LoginScreen validates empty fields', (tester) async {
    await tester.pumpWidget(createTestApp(child: const LoginScreen(), auth: auth));

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('LoginScreen shows snackbar on login error', (tester) async {
    when(() => auth.login(any(), any())).thenAnswer((_) async => 'Error de prueba');

    await tester.pumpWidget(createTestApp(child: const LoginScreen(), auth: auth));

    // Fill fields
    await tester.enterText(find.byType(TextFormField).at(0), 'test@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Error de prueba'), findsOneWidget);
  });
}
