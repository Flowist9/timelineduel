import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'firebase_online_battle_repository.dart';
import 'local_online_battle_repository.dart';
import 'online_battle_controller.dart';
import 'online_models.dart';

class OnlineBootstrap {
  static Future<OnlineBattleController> createController() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 6));
      return OnlineBattleController(
        backendKind: OnlineBackendKind.firebase,
        identityGateway: FirebaseOnlineIdentityGateway(FirebaseAuth.instance),
        repository: FirebaseOnlineBattleRepository(FirebaseFirestore.instance),
      );
    } catch (_) {
      return OnlineBattleController(
        backendKind: OnlineBackendKind.localFallback,
        identityGateway: LocalOnlineIdentityGateway(),
        repository: LocalOnlineBattleRepository(),
      );
    }
  }
}
