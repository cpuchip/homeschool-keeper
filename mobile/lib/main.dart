import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/database_service.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/export/failsafe_backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local database (Hive)
  await DatabaseService.instance.initialize();
  
  // Start failsafe backup service (dead man's switch)
  FailsafeBackupService.instance.start();
  
  runApp(
    const ProviderScope(
      child: HomeschoolKeeperApp(),
    ),
  );
}

class HomeschoolKeeperApp extends ConsumerWidget {
  const HomeschoolKeeperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
