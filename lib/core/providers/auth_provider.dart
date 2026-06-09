import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase;
  StreamSubscription<AuthState>? _authSubscription;
  User? _user;
  bool _cargando = false;
  String? _error;

  AuthProvider({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client {
    _user = _supabase.auth.currentUser;
    _authSubscription = _supabase.auth.onAuthStateChange.listen((event) {
      _user = event.session?.user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get cargando => _cargando;
  String? get error => _error;
  bool get estaLogueado => _user != null;
  String get displayName => _user?.userMetadata?['display_name'] as String? ?? '';

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<String?> login(String email, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return null;
    } on AuthException catch (e) {
      _error = e.message;
      return e.message;
    } catch (e) {
      _error = 'Error al iniciar sesión';
      return 'Error al iniciar sesión';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<String?> registrar(String email, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return null;
    } on AuthException catch (e) {
      _error = e.message;
      return e.message;
    } catch (e) {
      _error = 'Error al registrar';
      return 'Error al registrar';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _error = null;
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      _error = 'Error al cerrar sesión';
      notifyListeners();
    }
  }

  Future<String?> cambiarNombre(String nombre) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.auth.updateUser(UserAttributes(
        data: {'display_name': nombre},
      ));
      return null;
    } on AuthException catch (e) {
      _error = e.message;
      return e.message;
    } catch (e) {
      _error = 'Error al actualizar nombre';
      return 'Error al actualizar nombre';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<String?> cambiarEmail(String email) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.auth.updateUser(UserAttributes(
        email: email,
      ));
      return null;
    } on AuthException catch (e) {
      _error = e.message;
      return e.message;
    } catch (e) {
      _error = 'Error al actualizar email';
      return 'Error al actualizar email';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<String?> cambiarPassword(String nuevaPassword) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.auth.updateUser(UserAttributes(
        password: nuevaPassword,
      ));
      return null;
    } on AuthException catch (e) {
      _error = e.message;
      return e.message;
    } catch (e) {
      _error = 'Error al actualizar contraseña';
      return 'Error al actualizar contraseña';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
