import '../models/school.dart';

/// Repository interface for school queries and code verification.
abstract class SchoolRepository {
  /// Finds a school by its unique case-insensitive registration code.
  Future<School?> findSchoolByCode(String code);

  /// Validates whether a school code is active and valid.
  Future<bool> validateSchoolCode(String code);

  /// Gets a school by its internal ID.
  Future<School?> getSchool(String id);

  /// Retrieves list of all available active partner schools.
  Future<List<School>> getAvailableSchools();
}
