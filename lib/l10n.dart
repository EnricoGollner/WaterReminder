/// Idiomas suportados pelo aplicativo.
enum AppLang {
  pt('Português', 'PT'),
  en('English', 'EN'),
  es('Español', 'ES');

  const AppLang(this.label, this.code);
  final String label;
  final String code;

  static AppLang fromCode(String? code) =>
      values.firstWhere((l) => l.name == code, orElse: () => AppLang.en);
}

/// Textos traduzidos da interface e do menu da bandeja.
class Strings {
  const Strings._(
    this.subtitle,
    this.untilNext,
    this.paused,
    this.glass,
    this.glasses,
    this.today,
    this.pause,
    this.resume,
    this.justDrank,
    this.interval,
    this.customMinutes,
    this.set,
    this.messageTitle,
    this.messageHint,
    this.test,
    this.defaultMessage,
    this.noticeReadError,
    this.noticeSaveError,
    this.noticeNotifyError,
    this.noticeLogged,
    this.noticeRange,
    this.noticeUpdated,
    this.language,
    this.trayOpen,
    this.trayDrink,
    this.trayPause,
    this.trayResume,
    this.trayQuit,
  );

  final String subtitle,
      untilNext,
      paused,
      glass,
      glasses,
      today,
      pause,
      resume,
      justDrank,
      interval,
      customMinutes,
      set,
      messageTitle,
      messageHint,
      test,
      defaultMessage,
      noticeReadError,
      noticeSaveError,
      noticeNotifyError,
      noticeLogged,
      noticeRange,
      noticeUpdated,
      language,
      trayOpen,
      trayDrink,
      trayPause,
      trayResume,
      trayQuit;

  static const _pt = Strings._(
    'SEU COMPANHEIRO DE HIDRATAÇÃO',
    'ATÉ O PRÓXIMO LEMBRETE',
    'PAUSADO',
    'copo',
    'copos',
    'hoje',
    'Pausar',
    'Retomar',
    'Acabei de beber',
    'INTERVALO DO LEMBRETE',
    'Minutos personalizados',
    'Definir',
    'MENSAGEM DA NOTIFICAÇÃO',
    'Sua mensagem de lembrete',
    'Testar notificação',
    'Hora de beber água! Faça uma pausa rápida e mantenha-se hidratado.',
    'Não foi possível ler as configurações salvas. Usando padrões.',
    'Não foi possível salvar as configurações.',
    'O Windows não conseguiu exibir a notificação.',
    'Copo registrado. Temporizador reiniciado.',
    'Informe de 1 a 1440 minutos.',
    'Intervalo atualizado.',
    'IDIOMA',
    'Abrir WatterReminder',
    'Beber água agora',
    'Pausar lembretes',
    'Retomar lembretes',
    'Sair',
  );

  static const _en = Strings._(
    'YOUR HYDRATION COMPANION',
    'UNTIL NEXT REMINDER',
    'PAUSED',
    'glass',
    'glasses',
    'today',
    'Pause',
    'Resume',
    'Just drank',
    'REMINDER INTERVAL',
    'Custom minutes',
    'Set',
    'NOTIFICATION MESSAGE',
    'Your reminder message',
    'Test notification',
    'Time to drink water! Take a quick break and stay hydrated.',
    'Could not read saved settings. Defaults are in use.',
    'Settings could not be saved.',
    'Windows could not show the notification.',
    'Glass logged. Timer reset.',
    'Enter 1 to 1440 minutes.',
    'Reminder interval updated.',
    'LANGUAGE',
    'Open WatterReminder',
    'Drink Water Now',
    'Pause Reminders',
    'Resume Reminders',
    'Quit',
  );

  static const _es = Strings._(
    'TU COMPAÑERO DE HIDRATACIÓN',
    'HASTA EL PRÓXIMO RECORDATORIO',
    'EN PAUSA',
    'vaso',
    'vasos',
    'hoy',
    'Pausar',
    'Reanudar',
    'Acabo de beber',
    'INTERVALO DEL RECORDATORIO',
    'Minutos personalizados',
    'Definir',
    'MENSAJE DE NOTIFICACIÓN',
    'Tu mensaje de recordatorio',
    'Probar notificación',
    '¡Hora de beber agua! Haz una pausa rápida y mantente hidratado.',
    'No se pudo leer la configuración guardada. Usando valores por defecto.',
    'No se pudo guardar la configuración.',
    'Windows no pudo mostrar la notificación.',
    'Vaso registrado. Temporizador reiniciado.',
    'Introduce de 1 a 1440 minutos.',
    'Intervalo actualizado.',
    'IDIOMA',
    'Abrir WatterReminder',
    'Beber agua ahora',
    'Pausar recordatorios',
    'Reanudar recordatorios',
    'Salir',
  );

  static Strings of(AppLang lang) => switch (lang) {
    AppLang.pt => _pt,
    AppLang.en => _en,
    AppLang.es => _es,
  };

  /// Indica se [text] é a mensagem padrão de algum idioma.
  static bool isDefaultMessage(String text) =>
      AppLang.values.any((l) => of(l).defaultMessage == text);
}
