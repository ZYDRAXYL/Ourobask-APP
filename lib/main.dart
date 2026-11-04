import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'ui/root_shell.dart';
import 'utils/web_font.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      <String>['Noto Sans Thai'],
      await rootBundle.loadString('assets/fonts/NotoSansThai-OFL.txt'),
    );
  });
  await NotificationService.instance.init();

  final AppState state = AppState();
  unawaitedLoad(state);

  runApp(
    ChangeNotifierProvider<AppState>.value(value: state, child: const OurobaskApp()),
  );
}

void unawaitedLoad(AppState state) {
  state.load();
}

class OurobaskApp extends StatelessWidget {
  const OurobaskApp({super.key});

  static const Color seed = Color(0xFF6750A4);

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    return MaterialApp(
      title: 'Ourobask',
      debugShowCheckedModeBanner: false,
      themeMode: state.themeMode,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const RootShell(),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      // web ไม่มีฟอนต์ไทยของระบบ — ใช้ฟอนต์ที่แนบมากับแอปแทนการโหลดจาก CDN
      fontFamilyFallback: thaiFallback,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamilyFallback: thaiFallback,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(space: 1, thickness: 1),
    );
  }
}
