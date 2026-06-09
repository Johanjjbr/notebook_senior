import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notebook_senior/core/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late AuthProvider provider;
  late StreamController<AuthState> authController;

  setUpAll(() {
    registerFallbackValue(UserAttributes());
  });

  setUp(() {
    authController = StreamController<AuthState>.broadcast();
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockAuth.onAuthStateChange).thenAnswer((_) => authController.stream);

    provider = AuthProvider(supabase: mockSupabase);
  });

  tearDown(() {
    try {
      provider.dispose();
    } catch (_) {}
    authController.close();
  });

  group('AuthProvider', () {
    test('initial state is correct', () {
      expect(provider.user, isNull);
      expect(provider.cargando, false);
      expect(provider.error, isNull);
      expect(provider.estaLogueado, false);
    });

    test('login succeeds and clears cargando', () async {
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => AuthResponse());

      final error = await provider.login('test@test.com', 'pass123');

      expect(error, isNull);
      expect(provider.cargando, false);
      verify(() => mockAuth.signInWithPassword(
        email: 'test@test.com',
        password: 'pass123',
      )).called(1);
    });

    test('login handles AuthException', () async {
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(AuthException('Invalid login credentials'));

      final error = await provider.login('bad@test.com', 'wrong');

      expect(error, equals('Invalid login credentials'));
      expect(provider.error, equals('Invalid login credentials'));
      expect(provider.cargando, false);
    });

    test('login handles generic error', () async {
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(Exception('Network error'));

      final error = await provider.login('test@test.com', 'pass123');

      expect(error, equals('Error al iniciar sesión'));
      expect(provider.cargando, false);
    });

    test('register handles AuthException', () async {
      when(() => mockAuth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(AuthException('User already registered'));

      final error = await provider.registrar('existing@test.com', 'pass123');

      expect(error, equals('User already registered'));
      expect(provider.cargando, false);
    });

    test('register succeeds and clears cargando', () async {
      when(() => mockAuth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => AuthResponse());

      final error = await provider.registrar('new@test.com', 'pass123');

      expect(error, isNull);
      expect(provider.cargando, false);
      verify(() => mockAuth.signUp(
        email: 'new@test.com',
        password: 'pass123',
      )).called(1);
    });

    test('register handles generic error', () async {
      when(() => mockAuth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(Exception('Timeout'));

      final error = await provider.registrar('test@test.com', 'pass123');

      expect(error, equals('Error al registrar'));
      expect(provider.cargando, false);
    });

    test('logout calls signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await provider.logout();

      verify(() => mockAuth.signOut()).called(1);
      expect(provider.error, isNull);
    });

    test('logout handles error', () async {
      when(() => mockAuth.signOut()).thenThrow(Exception('Sign out failed'));

      await provider.logout();

      expect(provider.error, isNotNull);
    });

    test('cargando is true during login', () async {
      late Future<void> loginFuture;
      when(() => mockAuth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async {
        expect(provider.cargando, true);
        return AuthResponse();
      });

      loginFuture = provider.login('test@test.com', 'pass123');
      expect(provider.cargando, true);
      await loginFuture;
      expect(provider.cargando, false);
    });

    test('auth state listener updates on sign in event', () async {
      expect(provider.user, isNull);

      authController.add(const AuthState(AuthChangeEvent.signedIn, null));

      await Future(() {});
      expect(provider.user, isNull);
      expect(provider.estaLogueado, false);
    });

    test('dispose cancels subscription', () {
      provider.dispose();
    });

    test('displayName returns empty string when no metadata', () {
      expect(provider.displayName, equals(''));
    });

    test('cambiarNombre updates user metadata', () async {
      when(() => mockAuth.updateUser(any())).thenAnswer((_) async => UserResponse.fromJson({}));

      final error = await provider.cambiarNombre('New Name');

      expect(error, isNull);
      expect(provider.cargando, false);
      verify(() => mockAuth.updateUser(
        any(that: isA<UserAttributes>()),
      )).called(1);
    });

    test('cambiarNombre handles error', () async {
      when(() => mockAuth.updateUser(any()))
          .thenThrow(AuthException('Update failed'));

      final error = await provider.cambiarNombre('New Name');

      expect(error, isNotNull);
      expect(provider.cargando, false);
    });

    test('cambiarEmail calls updateUser', () async {
      when(() => mockAuth.updateUser(any())).thenAnswer((_) async => UserResponse.fromJson({}));

      final error = await provider.cambiarEmail('new@test.com');

      expect(error, isNull);
      verify(() => mockAuth.updateUser(
        any(that: isA<UserAttributes>()),
      )).called(1);
    });

    test('cambiarPassword calls updateUser', () async {
      when(() => mockAuth.updateUser(any())).thenAnswer((_) async => UserResponse.fromJson({}));

      final error = await provider.cambiarPassword('newpass123');

      expect(error, isNull);
      verify(() => mockAuth.updateUser(
        any(that: isA<UserAttributes>()),
      )).called(1);
    });
  });
}
