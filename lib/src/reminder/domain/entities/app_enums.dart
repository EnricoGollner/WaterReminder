/// Idiomas suportados pelo aplicativo.
enum AppLang {
  pt('Português', 'PT'),
  en('English', 'EN'),
  es('Español', 'ES');

  const AppLang(this.label, this.code);

  /// Nome do idioma escrito no próprio idioma.
  final String label;

  /// Sigla curta exibida no seletor.
  final String code;

  /// Converte o nome persistido em [AppLang], retornando `null` quando desconhecido.
  static AppLang? tryParse(String? name) => values.where((l) => l.name == name).firstOrNull;

  /// Resolve o idioma a partir de um código de idioma do sistema (ex.: `pt_BR`), usando inglês como padrão.
  static AppLang fromLocale(String locale) {
    final code = locale.toLowerCase();
    if (code.startsWith('pt')) return AppLang.pt;
    if (code.startsWith('es')) return AppLang.es;
    return AppLang.en;
  }
}

/// Tema visual escolhido pelo usuário.
enum AppThemeMode {
  system,
  light,
  dark;

  /// Converte o nome persistido em [AppThemeMode], usando [system] como padrão.
  static AppThemeMode parse(String? name) => values.where((m) => m.name == name).firstOrNull ?? system;
}

/// Nível de atividade física usado no cálculo da meta sugerida.
enum ActivityLevel {
  low(0),
  moderate(350),
  high(700);

  const ActivityLevel(this.extraMl);

  /// Quantidade extra de água (ml) recomendada para o nível de atividade.
  final int extraMl;

  /// Converte o nome persistido em [ActivityLevel], usando [moderate] como padrão.
  static ActivityLevel parse(String? name) => values.where((a) => a.name == name).firstOrNull ?? moderate;
}

/// Ações disparadas pelo lado nativo (bandeja, notificação ou atalho global).
enum NativeAction { drinkWater, togglePause, snooze }
