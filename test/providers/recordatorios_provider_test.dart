import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notebook_senior/core/providers/recordatorios_provider.dart';
import 'package:notebook_senior/models/recordatorio.dart';
import '../mocks/mock_database_service.dart';

void main() {
  late MockDatabaseService mockDb;
  late RecordatoriosProvider provider;

  setUpAll(() {
    registerFallbackValue(
      Recordatorio(id: '', userId: '', titulo: '',
          fechaHora: DateTime.now(), createdAt: DateTime.now()),
    );
  });

  setUp(() {
    mockDb = MockDatabaseService();
    provider = RecordatoriosProvider(db: mockDb);
  });

  group('RecordatoriosProvider', () {
    test('initial state is correct', () {
      expect(provider.recordatorios, isEmpty);
      expect(provider.cargandoLista, false);
      expect(provider.guardando, false);
      expect(provider.eliminando, false);
    });

    test('cargarRecordatorios loads data', () async {
      when(() => mockDb.cargarRecordatorios(any(), any()))
          .thenAnswer((_) async => [
            Recordatorio(
              id: '1', userId: 'u1', titulo: 'Test',
              fechaHora: DateTime.now().add(const Duration(hours: 1)),
              createdAt: DateTime.now(),
            ),
          ]);

      await provider.cargarRecordatorios();

      expect(provider.recordatorios.length, 1);
      expect(provider.cargandoLista, false);
    });

    test('proximos returns only future reminders', () async {
      when(() => mockDb.cargarRecordatorios(any(), any()))
          .thenAnswer((_) async => [
            Recordatorio(
              id: '1', userId: 'u1', titulo: 'Future',
              fechaHora: DateTime.now().add(const Duration(hours: 1)),
              createdAt: DateTime.now(),
            ),
            Recordatorio(
              id: '2', userId: 'u1', titulo: 'Past',
              fechaHora: DateTime.now().subtract(const Duration(hours: 1)),
              createdAt: DateTime.now(),
            ),
          ]);

      await provider.cargarRecordatorios();

      expect(provider.proximos.length, 1);
      expect(provider.proximos.first.titulo, 'Future');
    });

    test('crearRecordatorio calls database', () async {
      when(() => mockDb.cargarRecordatorios(any(), any()))
          .thenAnswer((_) async => []);
      when(() => mockDb.crearRecordatorio(any())).thenAnswer((_) async {});

      final r = Recordatorio(
        id: '', userId: '', titulo: 'New',
        fechaHora: DateTime.now(), createdAt: DateTime.now(),
      );

      await provider.crearRecordatorio(r);

      verify(() => mockDb.crearRecordatorio(any())).called(1);
      expect(provider.guardando, false);
    });
  });
}
