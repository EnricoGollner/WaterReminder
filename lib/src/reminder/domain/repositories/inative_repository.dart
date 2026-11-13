import '../entities/app_enums.dart';

/// Textos do menu da bandeja e dos botões da notificação, no idioma atual.
typedef NativeLabels = ({String open, String drink, String snooze, String pause, String resume, String quit, String drankAction, String snoozeAction});

/// Contrato de integração com o Windows (bandeja, notificações, inicialização e atalho global).
abstract interface class INativeRepository {
  /// Ações vindas do menu da bandeja, da notificação ou do atalho global.
  Stream<NativeAction> get actions;

  /// Exibe a notificação com [title] e [message]. Retorna `false` quando o Windows não a exibe.
  Future<bool> showNotification({required String title, required String message, required bool sound});

  /// Atualiza os textos nativos e o estado de pausa usado no menu.
  Future<void> configure({required NativeLabels labels, required bool paused});

  /// Atualiza a dica da bandeja e o ícone de pausado.
  Future<void> updateTray({required String tooltip, required bool paused});

  /// Indica se o usuário está em tela cheia, apresentação ou modo não perturbe.
  Future<bool> isUserBusy();

  /// Indica se o aplicativo inicia junto com o Windows.
  Future<bool> getAutostart();

  /// Liga ou desliga a inicialização com o Windows. Retorna `false` em caso de falha.
  Future<bool> setAutostart(bool enabled);

  /// Registra ou remove o atalho global Ctrl+Alt+W. Retorna `false` quando o atalho já está em uso.
  Future<bool> setHotkey(bool enabled);
}
