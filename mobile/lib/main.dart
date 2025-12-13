import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/database_service.dart';
import 'core/router.dart';
import 'core/telemetry_service.dart';
import 'core/theme.dart';
import 'core/sync/connectivity_service.dart';
import 'features/export/failsafe_backup_service.dart';
import 'repositories/work_sample_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock to portrait mode for single-handed use
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize local database (Hive)
  await DatabaseService.instance.initialize();
  
  // Initialize work sample repository
  final workSampleRepo = WorkSampleRepository();
  await workSampleRepo.init();
  
  // Initialize telemetry (anonymous usage tracking)
  await TelemetryService.instance.init();
  
  // Initialize connectivity monitoring
  await ConnectivityService.instance.init();
  
  // Start failsafe backup service (dead man's switch)
  FailsafeBackupService.instance.start();
  
  runApp(
    const ProviderScope(
      child: HomeschoolKeeperApp(),
    ),
  );
}

class HomeschoolKeeperApp extends ConsumerStatefulWidget {
  const HomeschoolKeeperApp({super.key});

  @override
  ConsumerState<HomeschoolKeeperApp> createState() => _HomeschoolKeeperAppState();
}

class _HomeschoolKeeperAppState extends ConsumerState<HomeschoolKeeperApp> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Backup when app goes to background (paused) or is about to close (detached)
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      FailsafeBackupService.instance.performBackupNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Homeschool Keeper',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
