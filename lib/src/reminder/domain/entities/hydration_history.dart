import 'package:equatable/equatable.dart';

/// Consumo de água de um dia.
class DailyIntake extends Equatable {
  const DailyIntake(this.day, this.ml);

  /// Dia (sem horário).
  final DateTime day;

  /// Total consumido no dia, em ml.
  final int ml;

  @override
  List<Object?> get props => [day, ml];
}

/// Histórico imutável de consumo diário, indexado por data `yyyy-MM-dd`.
class HydrationHistory extends Equatable {
  const HydrationHistory([this.entries = const {}]);

  /// Quantidade de dias mantidos no histórico.
  static const keepDays = 90;

  /// Consumo em ml por dia (`yyyy-MM-dd`).
  final Map<String, int> entries;

  /// Chave `yyyy-MM-dd` de [date].
  static String keyOf(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Total consumido no dia de [date].
  int totalOn(DateTime date) => entries[keyOf(date)] ?? 0;

  /// Soma [ml] ao dia de [date] (nunca abaixo de zero) e descarta dias mais antigos que [keepDays].
  HydrationHistory add(DateTime date, int ml) {
    final limit = keyOf(DateTime(date.year, date.month, date.day - keepDays));
    final next = {
      for (final e in entries.entries)
        if (e.key.compareTo(limit) > 0) e.key: e.value,
    };
    next[keyOf(date)] = (totalOn(date) + ml).clamp(0, 1 << 30);
    return .new(Map.unmodifiable(next));
  }

  /// Últimos [count] dias terminando em [today], do mais antigo ao mais recente.
  List<DailyIntake> lastDays(DateTime today, int count) => [
    for (var i = count - 1; i >= 0; i--)
      DailyIntake(DateTime(today.year, today.month, today.day - i), totalOn(DateTime(today.year, today.month, today.day - i))),
  ];

  /// Dias consecutivos que atingiram [goalMl]. Hoje só entra na contagem depois de atingir a meta.
  int streak(DateTime today, int goalMl) {
    if (goalMl <= 0) return 0;
    var day = DateTime(today.year, today.month, today.day);
    if (totalOn(day) < goalMl) day = DateTime(day.year, day.month, day.day - 1);
    var count = 0;
    while (totalOn(day) >= goalMl) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  /// Média diária (ml) dos últimos [count] dias terminando em [today].
  int average(DateTime today, int count) => count <= 0 ? 0 : (lastDays(today, count).fold<int>(0, (s, d) => s + d.ml) / count).round();

  @override
  List<Object?> get props => [entries];
}
