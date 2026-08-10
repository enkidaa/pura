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
    id: 'cold_rinse',
    title: 'Risciacquo con acqua fredda',
    durationMinutes: 1,
  ),
];

// double_cleansing was originally listed under morning steps, but the
// Lovable prototype's real data has it as "ogni sera" — moved here to
// match, along with two more evening-specific steps from the same source.
const eveningRoutineSteps = [
  RoutineStep(
    id: 'double_cleansing',
    title: 'Doppia detersione',
    durationMinutes: 4,
  ),
  RoutineStep(
    id: 'targeted_serum',
    title: 'Siero mirato',
    durationMinutes: 1,
  ),
  RoutineStep(
    id: 'retinoid',
    title: 'Retinoide (gradualmente)',
    durationMinutes: 1,
  ),
];
