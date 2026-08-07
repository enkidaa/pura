class RoutineStep {
  const RoutineStep({
    required this.id,
    required this.title,
    required this.durationMinutes,
  });

  final String id;
  final String title;
  final int durationMinutes;
}

const morningRoutineSteps = [
  RoutineStep(
    id: 'sunlight',
    title: 'Luce solare negli occhi al mattino',
    durationMinutes: 15,
  ),
  RoutineStep(
    id: 'lymphatic_drainage',
    title: 'Drenaggio linfatico del viso',
    durationMinutes: 5,
  ),
  RoutineStep(
    id: 'salt_water',
    title: 'Acqua e sale marino al mattino',
    durationMinutes: 3,
  ),
  RoutineStep(
    id: 'double_cleansing',
    title: 'Doppia detersione',
    durationMinutes: 2,
  ),
  RoutineStep(
    id: 'cold_rinse',
    title: 'Risciacquo con acqua fredda',
    durationMinutes: 1,
  ),
];
