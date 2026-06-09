import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:notebook_senior/core/providers/notas_provider.dart';
import 'package:notebook_senior/core/providers/tareas_provider.dart';
import 'package:notebook_senior/core/providers/recordatorios_provider.dart';
import 'package:notebook_senior/models/enums.dart';
import 'package:notebook_senior/models/nota.dart';
import 'package:notebook_senior/models/tarea.dart';
import 'package:notebook_senior/models/recordatorio.dart';
import 'package:notebook_senior/dashboard/dashboard_screen.dart';
import '../mocks/mock_database_service.dart';
import 'test_helper.dart';

void main() {
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();
    when(() => mockDb.cargarNotas(any(), any(), any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockDb.cargarTareas(any(), any(), any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockDb.cargarRecordatorios(any(), any()))
        .thenAnswer((_) async => []);
  });

  testWidgets('DashboardScreen shows title and quick actions', (tester) async {
    await tester.pumpWidget(createTestApp(child: const DashboardScreen(), db: mockDb));
    await tester.pumpAndSettle();

    expect(find.text('Resumen del día'), findsOneWidget);
    expect(find.text('Acceso rápido'), findsOneWidget);
    expect(find.text('Nota rápida'), findsOneWidget);
    expect(find.text('Nueva tarea'), findsOneWidget);
    expect(find.text('Recordatorio'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
  });

  testWidgets('DashboardScreen shows recent notes when available',
      (tester) async {
    final notas = [
      Nota(
        id: '1',
        userId: 'test',
        titulo: 'Nota de prueba',
        contenido: 'Contenido',
        color: '#FFFFFF',
        archivada: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    when(() => mockDb.cargarNotas(any(), any(), any(), any()))
        .thenAnswer((_) async => notas);

    await tester.pumpWidget(createTestApp(child: const DashboardScreen(), db: mockDb));
    // Load data into the provider
    await tester.pumpAndSettle();

    // Get the provider and load data
    final ctx = tester.element(find.byType(DashboardScreen));
    final provider = ctx.read<NotasProvider>();
    await provider.cargarNotas();
    await tester.pumpAndSettle();

    expect(find.text('Notas recientes'), findsOneWidget);
    expect(find.textContaining('Nota de prueba'), findsOneWidget);
  });

  testWidgets('DashboardScreen shows next reminder when available',
      (tester) async {
    final recordatorios = [
      Recordatorio(
        id: '1',
        userId: 'test',
        titulo: 'Recordatorio importante',
        descripcion: '',
        fechaHora: DateTime.now().add(const Duration(hours: 1)),
        completado: false,
        createdAt: DateTime.now(),
      ),
    ];

    when(() => mockDb.cargarRecordatorios(any(), any()))
        .thenAnswer((_) async => recordatorios);

    await tester.pumpWidget(createTestApp(child: const DashboardScreen(), db: mockDb));
    await tester.pumpAndSettle();

    final ctx = tester.element(find.byType(DashboardScreen));
    final provider = ctx.read<RecordatoriosProvider>();
    await provider.cargarRecordatorios();
    await tester.pumpAndSettle();

    expect(find.text('Próximo recordatorio'), findsOneWidget);
  });

  testWidgets('DashboardScreen shows tasks today count', (tester) async {
    final tareas = [
      Tarea(
        id: '1',
        userId: 'test',
        titulo: 'Tarea urgente',
        descripcion: '',
        completada: false,
        prioridad: Prioridad.alta,
        fechaVencimiento: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    when(() => mockDb.cargarTareas(any(), any(), any(), any()))
        .thenAnswer((_) async => tareas);

    await tester.pumpWidget(createTestApp(child: const DashboardScreen(), db: mockDb));
    await tester.pumpAndSettle();

    final ctx = tester.element(find.byType(DashboardScreen));
    final provider = ctx.read<TareasProvider>();
    await provider.cargarTareas();
    await tester.pumpAndSettle();

    expect(find.text('Tareas para hoy'), findsOneWidget);
  });
}
