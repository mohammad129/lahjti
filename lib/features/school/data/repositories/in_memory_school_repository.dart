import '../../domain/models/school.dart';
import '../../domain/repositories/school_repository.dart';

/// In-memory implementation of SchoolRepository for deterministic testing and local execution.
class InMemorySchoolRepository implements SchoolRepository {
  final Map<String, School> _schools = {};

  InMemorySchoolRepository({List<School>? seedSchools}) {
    final seeds = seedSchools ?? _defaultSeedSchools;
    for (final school in seeds) {
      _schools[school.code.toUpperCase()] = school;
    }
  }

  static List<School> get _defaultSeedSchools => [
    School(
      id: 'sch_amman_01',
      name: 'أكاديمية عمان الدولية',
      code: 'SCH-1001',
      city: 'عمان',
      country: 'الأردن',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    School(
      id: 'sch_lahjti_02',
      name: 'مدارس لهجتي النموذجية',
      code: 'LAH-EDU-2026',
      city: 'عمان',
      country: 'الأردن',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    School(
      id: 'sch_riyadh_03',
      name: 'مدارس الرياض الأهلية',
      code: 'RIYADH-SCH-01',
      city: 'الرياض',
      country: 'السعودية',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    School(
      id: 'sch_cairo_04',
      name: 'مدرسة النيل الدولية',
      code: 'CAIRO-EDU-99',
      city: 'القاهرة',
      country: 'مصر',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  @override
  Future<School?> findSchoolByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    return _schools[normalized];
  }

  @override
  Future<bool> validateSchoolCode(String code) async {
    final school = await findSchoolByCode(code);
    return school != null && school.isActive;
  }

  @override
  Future<School?> getSchool(String id) async {
    try {
      return _schools.values.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<School>> getAvailableSchools() async {
    return _schools.values.where((s) => s.isActive).toList();
  }

  /// Helper method for tests to register custom school
  void addSchool(School school) {
    _schools[school.code.toUpperCase()] = school;
  }
}
