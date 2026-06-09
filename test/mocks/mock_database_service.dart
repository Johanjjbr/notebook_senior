import 'package:mocktail/mocktail.dart';
import 'package:notebook_senior/data/database_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {
  static const testUserId = 'test-user-id';

  @override
  String get userId => testUserId;
}
