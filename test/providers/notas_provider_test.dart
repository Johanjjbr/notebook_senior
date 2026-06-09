import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notebook_senior/core/providers/notas_provider.dart';
import 'package:notebook_senior/models/nota.dart';
import '../mocks/mock_database_service.dart';

void main() {
  late MockDatabaseService mockDb;
  late NotasProvider provider;

  setUpAll(() {
    registerFallbackValue(
      Nota(id: '', userId: '', titulo: '', contenido: '',
          createdAt: DateTime.now(), updatedAt: DateTime.now()),
    );
  });

  setUp(() {
    mockDb = MockDatabaseService();
    provider = NotasProvider(db: mockDb);
  });

  group('NotasProvider', () {
    test('initial state is correct', () {
      expect(provider.notas, isEmpty);
      expect(provider.categorias, isEmpty);
      expect(provider.cargandoLista, false);
      expect(provider.guardando, false);
      expect(provider.eliminando, false);
      expect(provider.hasMore, true);
      expect(provider.error, isNull);
    });

    test('cargarNotas sets notas and hasMore', () async {
      final notas = [
        Nota(id: '1', userId: 'u1', titulo: 'Test',
            contenido: 'Content', createdAt: DateTime.now(),
            updatedAt: DateTime.now()),
      ];
      when(() => mockDb.cargarNotas(any(), any(), any(), any()))
          .thenAnswer((_) async => notas);

      await provider.cargarNotas();

      expect(provider.notas.length, 1);
      expect(provider.notas.first.titulo, 'Test');
      expect(provider.cargandoLista, false);
      expect(provider.hasMore, false);
    });

    test('setBusqueda filters notas after loading', () async {
      final notas = [
        Nota(id: '1', userId: 'u1', titulo: 'Hola mundo',
            contenido: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Nota(id: '2', userId: 'u1', titulo: 'Otra cosa',
            contenido: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];
      when(() => mockDb.cargarNotas(any(), any(), any(), any()))
          .thenAnswer((_) async => notas);

      await provider.cargarNotas();
      provider.setBusqueda('hola');

      expect(provider.notas.length, 1);
      expect(provider.notas.first.id, '1');
    });

    test('crearNota calls database and reloads', () async {
      when(() => mockDb.cargarNotas(any(), any(), any(), any()))
          .thenAnswer((_) async => []);
      when(() => mockDb.crearNota(any())).thenAnswer((_) async {});

      final nota = Nota(
        id: '', userId: '', titulo: 'Nueva',
        contenido: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );

      await provider.crearNota(nota);

      verify(() => mockDb.crearNota(any())).called(1);
      expect(provider.guardando, false);
    });

    test('eliminarNota calls database', () async {
      when(() => mockDb.cargarNotas(any(), any(), any(), any()))
          .thenAnswer((_) async => []);
      when(() => mockDb.eliminarNota(any())).thenAnswer((_) async {});

      await provider.eliminarNota('1');

      verify(() => mockDb.eliminarNota('1')).called(1);
      expect(provider.eliminando, false);
    });

    test('archivarNota calls database', () async {
      when(() => mockDb.cargarNotas(any(), any(), any(), any()))
          .thenAnswer((_) async => []);
      when(() => mockDb.archivarNota(any(), any())).thenAnswer((_) async {});

      await provider.archivarNota('1');

      verify(() => mockDb.archivarNota('1', true)).called(1);
    });

    test('sets error on database failure', () async {
      when(() => mockDb.cargarNotas(any(), any(), any(), any()))
          .thenThrow(Exception('Network error'));

      await provider.cargarNotas();

      expect(provider.error, isNotNull);
      expect(provider.cargandoLista, false);
    });
  });
}
