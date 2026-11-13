import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n.dart';

const _channel = MethodChannel('watter_reminder/native');
const _background = Color(0xFF071923);
const _panel = Color(0xFF102B39);
const _ice = Color(0xFF78DBEE);

void main() => runApp(const WatterReminderApp());

class WatterReminderApp extends StatelessWidget {
  const WatterReminderApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'WatterReminder',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _ice,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    home: const ReminderPage(),
  );
}

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  int interval = 30;
  int glasses = 0;
  bool paused = false;
  AppLang lang = AppLang.en;
  late String message = Strings.of(lang).defaultMessage;
  Strings get t => Strings.of(lang);
  DateTime deadline = DateTime.now().add(const Duration(minutes: 30));
  Duration pausedRemaining = const Duration(minutes: 30);
  Timer? ticker;
  late final TextEditingController customController;
  late final TextEditingController messageController;
  late final File settingsFile;
  bool ready = false;
  String? notice;

  @override
  void initState() {
    super.initState();
    customController = TextEditingController();
    messageController = TextEditingController();
    final base = Platform.environment['APPDATA'] ?? Directory.current.path;
    settingsFile = File(
      '$base${Platform.pathSeparator}WatterReminder${Platform.pathSeparator}settings.json',
    );
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'drinkWater') _drink();
      if (call.method == 'togglePause') _togglePause();
    });
    _load();
  }

  Future<void> _load() async {
    try {
      if (await settingsFile.exists()) {
        final data = jsonDecode(
          await settingsFile.readAsString(),
        ) as Map<String, dynamic>;
        lang = AppLang.fromCode(data['lang'] as String?);
        interval = ((data['interval'] as num?)?.toInt() ?? 30).clamp(1, 1440);
        final saved = (data['message'] as String?)?.trim() ?? '';
        message = saved.isEmpty || Strings.isDefaultMessage(saved)
            ? t.defaultMessage
            : saved;
        paused = data['paused'] == true;
        final today = DateTime.now().toIso8601String().substring(0, 10);
        glasses = data['day'] == today
            ? ((data['glasses'] as num?)?.toInt() ?? 0)
            : 0;
        pausedRemaining = Duration(
          seconds:
              ((data['remainingSeconds'] as num?)?.toInt() ?? interval * 60)
                  .clamp(1, interval * 60),
        );
        deadline =
            DateTime.tryParse(data['deadline'] as String? ?? '') ??
            DateTime.now().add(Duration(minutes: interval));
      }
    } catch (_) {
      notice = t.noticeReadError;
    }
    messageController.text = message;
    customController.text = interval.toString();
    await _syncNative();
    if (!mounted) return;
    setState(() => ready = true);
    ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
  }

  Future<void> _save() async {
    try {
      await settingsFile.parent.create(recursive: true);
      await settingsFile.writeAsString(
        jsonEncode({
          'lang': lang.name,
          'interval': interval,
          'message': message,
          'paused': paused,
          'glasses': glasses,
          'day': DateTime.now().toIso8601String().substring(0, 10),
          'deadline': deadline.toIso8601String(),
          'remainingSeconds': pausedRemaining.inSeconds,
        }),
      );
    } catch (_) {
      if (mounted) setState(() => notice = t.noticeSaveError);
    }
  }

  Duration get remaining => paused
      ? pausedRemaining
      : Duration(
          milliseconds: math.max(
            0,
            deadline.difference(DateTime.now()).inMilliseconds,
          ),
        );

  void _tick() {
    if (!mounted || !ready) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_savedDay != today) {
      _savedDay = today;
      glasses = 0;
      _save();
    }
    if (!paused && !deadline.isAfter(DateTime.now())) {
      _notify();
      deadline = DateTime.now().add(Duration(minutes: interval));
      _save();
    }
    setState(() {});
  }

  String _savedDay = DateTime.now().toIso8601String().substring(0, 10);

  Future<void> _notify() async {
    try {
      await _channel.invokeMethod<void>('showNotification', message);
    } on PlatformException {
      if (mounted) {
        setState(() => notice = t.noticeNotifyError);
      }
    }
  }

  void _drink() {
    setState(() {
      glasses++;
      deadline = DateTime.now().add(Duration(minutes: interval));
      pausedRemaining = Duration(minutes: interval);
      notice = t.noticeLogged;
    });
    _save();
  }

  void _togglePause() {
    setState(() {
      if (paused) {
        deadline = DateTime.now().add(pausedRemaining);
      } else {
        pausedRemaining = remaining;
      }
      paused = !paused;
    });
    _syncNative();
    _save();
  }

  /// Envia ao runner nativo o estado de pausa e os textos do menu da bandeja.
  Future<void> _syncNative() async {
    try {
      await _channel.invokeMethod<void>('configure', {
        'paused': paused,
        'open': t.trayOpen,
        'drink': t.trayDrink,
        'pause': t.trayPause,
        'resume': t.trayResume,
        'quit': t.trayQuit,
      });
    } on PlatformException {
      // Menu nativo mantém os textos anteriores.
    }
  }

  void _setLang(AppLang value) {
    setState(() {
      final custom = !Strings.isDefaultMessage(message);
      lang = value;
      if (!custom) {
        message = t.defaultMessage;
        messageController.text = message;
      }
      notice = null;
    });
    _syncNative();
    _save();
  }

  void _setInterval(int minutes) {
    if (minutes < 1 || minutes > 1440) {
      setState(() => notice = t.noticeRange);
      return;
    }
    setState(() {
      interval = minutes;
      deadline = DateTime.now().add(Duration(minutes: minutes));
      pausedRemaining = Duration(minutes: minutes);
      customController.text = minutes.toString();
      notice = t.noticeUpdated;
    });
    _save();
  }

  @override
  void dispose() {
    ticker?.cancel();
    customController.dispose();
    messageController.dispose();
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = remaining;
    final hours = left.inHours;
    final time =
        '${hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : ''}${(left.inMinutes % 60).toString().padLeft(2, '0')}:${(left.inSeconds % 60).toString().padLeft(2, '0')}';
    final progress = paused
        ? 1 - pausedRemaining.inSeconds / (interval * 60)
        : 1 - left.inMilliseconds / (interval * 60000);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _ice.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/app_icon.png',
                      width: 30,
                      height: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WatterReminder',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.5,
                        ),
                      ),
                      Text(
                        t.subtitle,
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.8,
                          color: _ice,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  PopupMenuButton<AppLang>(
                    tooltip: t.language,
                    initialValue: lang,
                    onSelected: _setLang,
                    color: _panel,
                    itemBuilder: (_) => [
                      for (final l in AppLang.values)
                        PopupMenuItem(value: l, child: Text(l.label)),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _panel,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _ice.withValues(alpha: .2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language, size: 16, color: _ice),
                          const SizedBox(width: 6),
                          Text(
                            lang.code,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 23),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _ice.withValues(alpha: .12)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 190,
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: progress.clamp(0, 1),
                              strokeWidth: 9,
                              backgroundColor: const Color(0xFF244351),
                              color: _ice,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                paused
                                    ? Icons.pause_rounded
                                    : Icons.water_drop_rounded,
                                color: _ice,
                                size: 27,
                              ),
                              const SizedBox(height: 7),
                              Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              Text(
                                paused ? t.paused : t.untilNext,
                                style: const TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  color: Color(0xFF9AB8C3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      '$glasses ${glasses == 1 ? t.glass : t.glasses} ${t.today}',
                      style: const TextStyle(
                        color: _ice,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  Expanded(
                    child: _action(
                      paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      paused ? t.resume : t.pause,
                      _togglePause,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _action(
                      Icons.water_drop_outlined,
                      t.justDrank,
                      _drink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                t.interval,
                style: TextStyle(
                  color: _ice,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [15, 30, 45, 60]
                    .map(
                      (v) => ChoiceChip(
                        label: Text('${v}m'),
                        selected: interval == v,
                        onSelected: (_) => _setInterval(v),
                        selectedColor: _ice,
                        labelStyle: TextStyle(
                          color: interval == v ? _background : Colors.white,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _input(t.customMinutes),
                    ),
                  ),
                  const SizedBox(width: 9),
                  FilledButton(
                    onPressed: () =>
                        _setInterval(int.tryParse(customController.text) ?? 0),
                    child: Text(t.set),
                  ),
                ],
              ),
              const SizedBox(height: 21),
              Text(
                t.messageTitle,
                style: TextStyle(
                  color: _ice,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: messageController,
                maxLines: 2,
                maxLength: 200,
                decoration: _input(t.messageHint),
                onChanged: (value) {
                  message = value.trim().isEmpty
                      ? t.defaultMessage
                      : value.trim();
                  _save();
                },
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _notify,
                  icon: const Icon(Icons.notifications_outlined),
                  label: Text(t.test),
                ),
              ),
              if (notice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    notice!,
                    style: const TextStyle(color: _ice, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onPressed) =>
      FilledButton.icon(
        onPressed: ready ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: _ice,
          foregroundColor: _background,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        icon: Icon(icon, size: 19),
        label: Text(label),
      );

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: _panel,
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _ice.withValues(alpha: .2)),
    ),
  );
}
