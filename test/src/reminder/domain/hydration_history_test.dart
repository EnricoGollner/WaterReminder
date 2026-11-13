import 'package:flutter_test/flutter_test.dart';
import 'package:water_reminder/src/reminder/domain/entities/hydration_history.dart';

void main() {
  final today = DateTime(2026, 3, 10, 14);

  group('HydrationHistory', () {
    test('add soma ao dia e nunca fica negativo', () {
      final history = const HydrationHistory().add(today, 250).add(today, 250);
      expect(history.totalOn(today), 500);
      expect(history.add(today, -1000).totalOn(today), 0);
    });

    test('add descarta dias mais antigos que keepDays', () {
      final old = DateTime(2025, 1, 1);
      final history = const HydrationHistory().add(old, 300).add(today, 100);
      expect(history.totalOn(old), 0);
      expect(history.entries.length, 1);
    });

    test('lastDays devolve os dias em ordem cronológica, incluindo dias sem consumo', () {
      final history = const HydrationHistory().add(today.subtract(const Duration(days: 1)), 400);
      final days = history.lastDays(today, 3);
      expect(days.map((d) => d.ml), [0, 400, 0]);
      expect(days.last.day, DateTime(2026, 3, 10));
    });

    test('streak conta dias consecutivos na meta e só inclui hoje após atingi-la', () {
      var history = const HydrationHistory();
      for (var i = 1; i <= 3; i++) {
        history = history.add(today.subtract(Duration(days: i)), 2000);
      }
      history = history.add(today.subtract(const Duration(days: 5)), 2000);
      expect(history.streak(today, 2000), 3);
      expect(history.add(today, 2000).streak(today, 2000), 4);
    });

    test('average calcula a média do período', () {
      final history = const HydrationHistory().add(today, 700).add(today.subtract(const Duration(days: 1)), 700);
      expect(history.average(today, 7), 200);
    });
  });
}
