import 'package:flutter/material.dart';

/// Returns the chosen minutes, or null if skipped. Shown once at the first
/// morning open and once in the evening (~21:00) — see today_screen.dart.
Future<int?> showTimeBudgetPrompt(BuildContext context) {
  return showDialog<int?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _TimeBudgetDialog(),
  );
}

class _TimeBudgetDialog extends StatelessWidget {
  const _TimeBudgetDialog();

  static const _options = [5, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('QUANTO TEMPO HAI?', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Text('Quanto tempo hai?', style: theme.textTheme.displaySmall),
            const SizedBox(height: 10),
            Text(
              'Pura costruisce il rituale attorno al tuo tempo. Niente streak, niente pressione.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.8,
              physics: const NeverScrollableScrollPhysics(),
              children: _options.map((minutes) {
                return OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(minutes),
                  child: Text('$minutes min'),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('SALTA PER ORA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
