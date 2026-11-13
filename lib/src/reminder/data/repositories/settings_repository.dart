import 'dart:convert';
import 'dart:io';

import '../../domain/entities/reminder_data.dart';
import '../../domain/repositories/isettings_repository.dart';
import '../dtos/reminder_data_dto.dart';

/// Persiste o estado em um arquivo JSON local.
class SettingsRepository implements ISettingsRepository {
  const SettingsRepository({required this.file, this.legacyFile});

  /// Cria o repositório na pasta `%APPDATA%\WaterReminder`, migrando de `%APPDATA%\WatterReminder` (versão 0.1).
  factory SettingsRepository.appData() {
    final base = Platform.environment['APPDATA'] ?? Directory.current.path;
    String path(String folder) => [base, folder, 'settings.json'].join(Platform.pathSeparator);
    return .new(file: File(path('WaterReminder')), legacyFile: File(path('WatterReminder')));
  }

  /// Arquivo de configurações atual.
  final File file;

  /// Arquivo da versão anterior, lido apenas quando [file] ainda não existe.
  final File? legacyFile;

  @override
  Future<ReminderData?> load() async {
    try {
      final source = await file.exists() ? file : (legacyFile != null && await legacyFile!.exists() ? legacyFile : null);
      if (source == null) return null;
      final json = jsonDecode(await source.readAsString());
      return json is Map<String, dynamic> ? ReminderDataDto(json).toEntity() : null;
    } on Object {
      return null;
    }
  }

  @override
  Future<bool> save(ReminderData data) async {
    try {
      await file.parent.create(recursive: true);
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(jsonEncode(ReminderDataDto.fromEntity(data).json), flush: true);
      await temp.rename(file.path);
      return true;
    } on Object {
      return false;
    }
  }
}
