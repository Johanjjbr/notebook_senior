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
}
