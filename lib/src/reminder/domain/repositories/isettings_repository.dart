import '../entities/reminder_data.dart';

/// Contrato de persistência local do estado do aplicativo.
abstract interface class ISettingsRepository {
  /// Carrega o estado salvo. Retorna `null` quando não há dados ou eles estão corrompidos.
  Future<ReminderData?> load();

  /// Salva [data]. Retorna `false` quando a escrita falha.
  Future<bool> save(ReminderData data);
}
