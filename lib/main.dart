import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ads/ads_service.dart';
import 'design/app_theme.dart';
import 'localization/app_language.dart';
import 'logic/game_session.dart';
import 'monetization/purchase_service.dart';
import 'online/online_bootstrap.dart';
import 'online/online_battle_controller.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final adsService = AdsService();
  final purchaseService = PurchaseService(adsService: adsService);
  final languageController = AppLanguageController();
  final session = await GameSession.load();
  await adsService.initialize();
  await purchaseService.initialize();
  await languageController.load();
  runApp(
    MyApp(
      adsService: adsService,
      purchaseService: purchaseService,
      languageController: languageController,
      session: session,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AdsService adsService;
  final PurchaseService purchaseService;
  final AppLanguageController languageController;
  final GameSession session;

  MyApp({
    super.key,
    required this.adsService,
    PurchaseService? purchaseService,
    AppLanguageController? languageController,
    GameSession? session,
  }) : purchaseService =
           purchaseService ?? PurchaseService(adsService: adsService),
       languageController = languageController ?? AppLanguageController(),
       session = session ?? GameSession();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageController,
      builder: (context, _) {
        return AppLanguageScope(
          controller: languageController,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            locale: languageController.locale,
            supportedLocales: AppLanguageController.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _BootstrapScreen(
              adsService: adsService,
              purchaseService: purchaseService,
              session: session,
            ),
          ),
        );
      },
    );
  }
}

class _BootstrapScreen extends StatefulWidget {
  final AdsService adsService;
  final PurchaseService purchaseService;
  final GameSession session;

  const _BootstrapScreen({
    required this.adsService,
    required this.purchaseService,
    required this.session,
  });

  @override
  State<_BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<_BootstrapScreen> {
  late final Future<OnlineBattleController> _controllerFuture;

  @override
  void initState() {
    super.initState();
    _controllerFuture = OnlineBootstrap.createController()
      ..then((controller) => controller.bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OnlineBattleController>(
      future: _controllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: const Color(0xFF120B07),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFD4B06A)),
                  const SizedBox(height: 18),
                  Text(
                    context.tr('Lade Spiel...', 'Loading game...'),
                    style: const TextStyle(
                      color: Color(0xFFF7ECDD),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF120B07),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFE39063),
                      size: 42,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.tr(
                        'App konnte nicht initialisiert werden.',
                        'The app could not be initialized.',
                      ),
                      style: const TextStyle(
                        color: Color(0xFFF7ECDD),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFD8CBB8).withValues(alpha: 0.86),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return HomeScreen(
          onlineController: snapshot.data!,
          adsService: widget.adsService,
          purchaseService: widget.purchaseService,
          session: widget.session,
        );
      },
    );
  }
}
