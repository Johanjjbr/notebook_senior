import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notebook_senior/core/providers/tareas_provider.dart';
import 'package:notebook_senior/models/tarea.dart';
import '../mocks/mock_database_service.dart';

void main() {
  late MockDatabaseService mockDb;
  late TareasProvider provider;

  setUpAll(() {
    registerFallbackValue(
      Tarea(id: '', userId: '', titulo: '',
          createdAt: DateTime.now(), updatedAt: DateTime.now()),
    );
  });

  setUp(() {
    mockDb = MockDatabaseService();
    provider = TareasProvider(db: mockDb);
  });

  group('TareasProvider', () {
    test('initial state is correct', () {
      expect(provider.tareas, isEmpty);
      expect(provider.cargandoLista, false);
      expect(provider.guardando, false);
      expect(provider.eliminando, false);
    });

    test('cargarTareas loads tasks', () async {
      when(() => mockDb.cargarTareas(any(), any(), any(), any()))
          .thenAnswer((_) async => [
            Tarea(id: '1', userId: 'u1', titulo: 'Test task',
                createdAt: DateTime.now(), updatedAt: DateTime.now()),
          ]);

      await provider.cargarTareas();

      expect(provider.tareas.length, 1);
      expect(provider.tareas.first.titulo, 'Test task');
      expect(provider.cargandoLista, false);
    });

    test('filtroEstado filters correctly', () async {
      when(() => mockDb.cargarTareas(any(), any(), any(), any()))
          .thenAnswer((_) async => [
            Tarea(id: '1', userId: 'u1', titulo: 'A', completada: false,
                createdAt: DateTime.now(), updatedAt: DateTime.now()),
            Tarea(id: '2', userId: 'u1', titulo: 'B', completada: true,
                createdAt: DateTime.now(), updatedAt: DateTime.now()),
          ]);

      await provider.cargarTareas();
      provider.setFiltroEstado('pendientes');

      expect(provider.tareas.length, 1);
      expect(provider.tareas.first.id, '1');
    });

    test('toggleCompletada calls database', () async {
      when(() => mockDb.cargarTareas(any(), any(), any(), any()))
          .thenAnswer((_) async => []);
      when(() => mockDb.toggleTareaCompletada(any(), any()))
          .thenAnswer((_) async {});

      await provider.toggleCompletada('1', true);

      verify(() => mockDb.toggleTareaCompletada('1', true)).called(1);
    });

    test('sets error on database failure', () async {
      when(() => mockDb.cargarTareas(any(), any(), any(), any()))
          .thenThrow(Exception('Fail'));

      await provider.cargarTareas();

      expect(provider.error, isNotNull);
    });
  });
}
