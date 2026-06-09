import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../models/nota.dart';
import '../../models/tarea.dart';
import '../../models/recordatorio.dart';
import '../../models/categoria.dart';

class LocalDatabase {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'notebook_senior_cache.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS notas (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tareas (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS recordatorios (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS categorias (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> cacheNotas(List<Nota> notas) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('notas');
    for (final n in notas) {
      batch.insert('notas', {
        'id': n.id,
        'data': jsonEncode(n.toJson()),
        'updated_at': n.updatedAt.toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Nota>> getNotas() async {
    final db = await database;
    final rows = await db.query('notas', orderBy: 'updated_at DESC');
    return rows.map((r) => Nota.fromJson(jsonDecode(r['data'] as String) as Map<String, dynamic>)).toList();
  }

  Future<void> cacheTareas(List<Tarea> tareas) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('tareas');
    for (final t in tareas) {
      batch.insert('tareas', {
        'id': t.id,
        'data': jsonEncode(t.toJson()),
        'updated_at': t.updatedAt.toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Tarea>> getTareas() async {
    final db = await database;
    final rows = await db.query('tareas', orderBy: 'updated_at DESC');
    return rows.map((r) => Tarea.fromJson(jsonDecode(r['data'] as String) as Map<String, dynamic>)).toList();
  }

  Future<void> cacheRecordatorios(List<Recordatorio> recordatorios) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('recordatorios');
    for (final r in recordatorios) {
      batch.insert('recordatorios', {
        'id': r.id,
        'data': jsonEncode(r.toJson()),
        'updated_at': r.createdAt.toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Recordatorio>> getRecordatorios() async {
    final db = await database;
    final rows = await db.query('recordatorios', orderBy: 'updated_at DESC');
    return rows.map((r) => Recordatorio.fromJson(jsonDecode(r['data'] as String) as Map<String, dynamic>)).toList();
  }

  Future<void> cacheCategorias(List<Categoria> categorias) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('categorias');
    for (final c in categorias) {
      batch.insert('categorias', {
        'id': c.id,
        'data': jsonEncode(c.toJson()),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Categoria>> getCategorias() async {
    final db = await database;
    final rows = await db.query('categorias');
    return rows.map((r) => Categoria.fromJson(jsonDecode(r['data'] as String) as Map<String, dynamic>)).toList();
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('notas');
    await db.delete('tareas');
    await db.delete('recordatorios');
    await db.delete('categorias');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
