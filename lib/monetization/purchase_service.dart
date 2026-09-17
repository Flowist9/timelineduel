import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ads/ads_service.dart';
import '../logic/game_progression.dart';
import '../logic/game_session.dart';
import '../models/question.dart';
import 'store_catalog.dart';

class PurchaseService extends ChangeNotifier {
  static const String noAdsProductId = StoreCatalog.noAdsProductId;
  static const String earlyBattleAccessProductId =
      StoreCatalog.earlyBattleAccessProductId;
  static const String nextQuestionUnlockProductId =
      StoreCatalog.nextQuestionUnlockProductId;
  static const String coinPackSmallProductId =
      StoreCatalog.coinPackSmallProductId;
  static const String coinPackMediumProductId =
      StoreCatalog.coinPackMediumProductId;
  static const String politicsCapsuleProductId =
      StoreCatalog.politicsCapsuleProductId;
  static const String scienceCapsuleProductId =
      StoreCatalog.scienceCapsuleProductId;
  static const String artCapsuleProductId = StoreCatalog.artCapsuleProductId;
  static const String sportsCapsuleProductId =
      StoreCatalog.sportsCapsuleProductId;
  static const String chronicleCapsuleProductId =
      StoreCatalog.chronicleCapsuleProductId;
  static const String _adsRemovedPrefsKey = 'purchase.no_ads';
  static const String _fulfilledPurchasesPrefsKey = 'purchase.fulfilled_ids';
  static const String _questionUnlockPrefsKey = 'purchase.question_unlocks';
  static const String _premiumBattleAccessPrefsKey =
      'purchase.early_battle_access';
  static const String _pendingPackGrantsPrefsKey = 'purchase.pending_packs';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final AdsService adsService;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  SharedPreferences? _prefs;
  GameSession? _session;

  bool _initialized = false;
  bool _isLoading = false;
  bool _storeAvailable = false;
  bool _adsRemoved = false;
  bool _premiumBattleAccess = false;
  int _pendingCoinGrant = 0;
  String? _errorMessage;

  final Map<String, ProductDetails> _productsById = <String, ProductDetails>{};
  final Map<String, int> _pendingPackGrants = <String, int>{};
  final Set<String> _fulfilledPurchaseIds = <String>{};
  final Set<QuestionType> _premiumQuestionUnlocks = <QuestionType>{};

  PurchaseService({required this.adsService});

  bool get isInitialized => _initialized;
  bool get isLoading => _isLoading;
  bool get isStoreAvailable => _storeAvailable;
  bool get hasLoadedProducts => _productsById.isNotEmpty;
  bool get canPurchase => _storeAvailable && _productsById.isNotEmpty;
  bool get adsRemoved => _adsRemoved;
  bool get premiumBattleAccess => _premiumBattleAccess;
  String? get errorMessage => _errorMessage;

  List<QuestionType> get premiumQuestionUnlocks =>
      _premiumQuestionUnlocks.toList(growable: false)..sort(
        (a, b) => (GameProgression.questionUnlockLevel(a) ?? 0).compareTo(
          GameProgression.questionUnlockLevel(b) ?? 0,
        ),
      );

  bool hasPremiumQuestionUnlock(QuestionType type) =>
      _premiumQuestionUnlocks.contains(type);

  int pendingPackGrantsFor(String productId) =>
      _pendingPackGrants[productId] ?? 0;

  void attachSession(GameSession session) {
    _session = session;
    session.applyPremiumQuestionTypeUnlocks(_premiumQuestionUnlocks);
    session.applyPremiumBattleAccess(_premiumBattleAccess);
    if (_pendingCoinGrant > 0) {
      session.addCoins(_pendingCoinGrant);
      _pendingCoinGrant = 0;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _isLoading = true;
    notifyListeners();

    _prefs = await SharedPreferences.getInstance();
    _adsRemoved = _prefs?.getBool(_adsRemovedPrefsKey) ?? false;
    _premiumBattleAccess =
        _prefs?.getBool(_premiumBattleAccessPrefsKey) ?? false;
    _fulfilledPurchaseIds
      ..clear()
      ..addAll(
        _prefs?.getStringList(_fulfilledPurchasesPrefsKey) ?? const <String>[],
      );
    _premiumQuestionUnlocks
      ..clear()
      ..addAll(
        (_prefs?.getStringList(_questionUnlockPrefsKey) ?? const <String>[])
            .map(_questionTypeFromName)
            .whereType<QuestionType>(),
      );
    _pendingPackGrants
      ..clear()
      ..addAll(_loadPendingPackGrants());
    adsService.setAdsRemoved(_adsRemoved);
    _session?.applyPremiumQuestionTypeUnlocks(_premiumQuestionUnlocks);
    _session?.applyPremiumBattleAccess(_premiumBattleAccess);

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (Object error) {
        _errorMessage = 'Store updates could not be read.';
        debugPrint('Purchase stream error: $error');
        notifyListeners();
      },
    );

    await refreshStore();
    _initialized = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshStore() async {
    _errorMessage = null;
    _storeAvailable = await _inAppPurchase.isAvailable();
    if (!_storeAvailable) {
      _productsById.clear();
      _errorMessage = 'Google Play is not available right now.';
      notifyListeners();
      return;
    }

    final response = await _inAppPurchase.queryProductDetails(
      StoreCatalog.allProductIds,
    );
    _productsById
      ..clear()
      ..addEntries(
        response.productDetails.map((product) => MapEntry(product.id, product)),
      );

    if (response.error != null) {
      _errorMessage = response.error!.message;
    } else if (response.notFoundIDs.isNotEmpty) {
      _errorMessage =
          'Some shop products are still missing in Google Play: ${response.notFoundIDs.join(', ')}';
    }
    notifyListeners();
  }

  ProductDetails? productFor(String productId) => _productsById[productId];

  String priceLabelFor(String productId, {required String fallback}) {
    return _productsById[productId]?.price ?? fallback;
  }

  Future<String?> buyNoAds() {
    return _buyProduct(noAdsProductId, consumable: false);
  }

  Future<String?> buyEarlyBattleAccess() {
    return _buyProduct(earlyBattleAccessProductId, consumable: false);
  }

  Future<String?> buyCoinPackSmall() {
    return _buyProduct(coinPackSmallProductId, consumable: true);
  }

  Future<String?> buyCoinPackMedium() {
    return _buyProduct(coinPackMediumProductId, consumable: true);
  }

  Future<String?> buyPackProduct(String productId) {
    return _buyProduct(productId, consumable: true);
  }

  bool consumePendingPackGrant(String productId) {
    final count = _pendingPackGrants[productId] ?? 0;
    if (count <= 0) return false;
    if (count == 1) {
      _pendingPackGrants.remove(productId);
    } else {
      _pendingPackGrants[productId] = count - 1;
    }
    _persistPendingPackGrants();
    notifyListeners();
    return true;
  }

  QuestionType? nextPremiumQuestionUnlock({int? level, int? unlockedPeople}) {
    final resolvedLevel = level ?? _session?.level ?? 1;
    final resolvedUnlockedPeople =
        unlockedPeople ?? _session?.unlockedPersons.length ?? 0;

    for (final type in StoreCatalog.premiumQuestionUnlockOrder) {
      final naturallyUnlocked = GameProgression.isQuestionTypeUnlocked(
        type: type,
        level: resolvedLevel,
        unlockedPeople: resolvedUnlockedPeople,
      );
      if (naturallyUnlocked || _premiumQuestionUnlocks.contains(type)) {
        continue;
      }
      return type;
    }
    return null;
  }

  Future<String?> buyNextQuestionUnlock() {
    final nextType = nextPremiumQuestionUnlock();
    if (nextType == null) {
      return Future.value('All premium question unlocks are already claimed.');
    }
    return _buyProduct(nextQuestionUnlockProductId, consumable: true);
  }

  String nextQuestionUnlockPriceLabel({required String fallback}) {
    return priceLabelFor(nextQuestionUnlockProductId, fallback: fallback);
  }

  Future<String?> restorePurchases() async {
    if (!_storeAvailable) {
      return 'Google Play is not available right now.';
    }
    _errorMessage = null;
    notifyListeners();
    await _inAppPurchase.restorePurchases();
    return null;
  }

  Future<String?> _buyProduct(
    String productId, {
    required bool consumable,
  }) async {
    if (!_storeAvailable) {
      return 'Google Play is not available right now.';
    }
    final product = _productsById[productId];
    if (product == null) {
      return 'This product is not available in Google Play yet.';
    }

    _errorMessage = null;
    notifyListeners();

    final purchaseParam = PurchaseParam(productDetails: product);
    final started = consumable
        ? await _inAppPurchase.buyConsumable(
            purchaseParam: purchaseParam,
            autoConsume: true,
          )
        : await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

    if (!started) {
      return 'Der Kauf konnte nicht gestartet werden.';
    }
    return null;
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _errorMessage = null;
          break;
        case PurchaseStatus.error:
          _errorMessage =
              purchase.error?.message ?? 'Der Kauf ist fehlgeschlagen.';
          break;
        case PurchaseStatus.canceled:
          _errorMessage = 'Kauf abgebrochen.';
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliverPurchase(purchase);
          _errorMessage = null;
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  QuestionType? _questionTypeFromName(String raw) {
    for (final type in QuestionType.values) {
      if (type.name == raw) return type;
    }
    return null;
  }

  Future<void> _persistQuestionUnlocks() async {
    await _prefs?.setStringList(
      _questionUnlockPrefsKey,
      _premiumQuestionUnlocks.map((type) => type.name).toList(growable: false),
    );
  }

  Future<void> _deliverPurchase(PurchaseDetails purchase) async {
    if (purchase.productID == nextQuestionUnlockProductId) {
      final questionType = nextPremiumQuestionUnlock();
      if (questionType == null) return;
      if (_premiumQuestionUnlocks.add(questionType)) {
        await _persistQuestionUnlocks();
        _session?.unlockQuestionTypePremium(questionType);
      }
      return;
    }

    switch (purchase.productID) {
      case noAdsProductId:
        if (_adsRemoved) return;
        _adsRemoved = true;
        adsService.setAdsRemoved(true);
        await _prefs?.setBool(_adsRemovedPrefsKey, true);
        return;
      case earlyBattleAccessProductId:
        if (_premiumBattleAccess) return;
        _premiumBattleAccess = true;
        _session?.applyPremiumBattleAccess(true);
        await _prefs?.setBool(_premiumBattleAccessPrefsKey, true);
        return;
      case coinPackSmallProductId:
        await _grantCoinsForPurchase(
          purchase,
          amount: StoreCatalog.coinPackSmallAmount,
        );
        return;
      case coinPackMediumProductId:
        await _grantCoinsForPurchase(
          purchase,
          amount: StoreCatalog.coinPackMediumAmount,
        );
        return;
      case politicsCapsuleProductId:
      case scienceCapsuleProductId:
      case artCapsuleProductId:
      case sportsCapsuleProductId:
      case chronicleCapsuleProductId:
        await _grantFulfilledPurchaseToken(purchase);
        _pendingPackGrants.update(
          purchase.productID,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        await _persistPendingPackGrants();
        return;
    }
  }

  Future<void> _grantFulfilledPurchaseToken(PurchaseDetails purchase) async {
    final token = _purchaseTokenFor(purchase);
    if (_fulfilledPurchaseIds.contains(token)) return;
    _fulfilledPurchaseIds.add(token);
    await _prefs?.setStringList(
      _fulfilledPurchasesPrefsKey,
      _fulfilledPurchaseIds.toList(growable: false),
    );
  }

  Future<void> _grantCoinsForPurchase(
    PurchaseDetails purchase, {
    required int amount,
  }) async {
    final token = _purchaseTokenFor(purchase);
    if (_fulfilledPurchaseIds.contains(token)) return;
    _fulfilledPurchaseIds.add(token);
    await _prefs?.setStringList(
      _fulfilledPurchasesPrefsKey,
      _fulfilledPurchaseIds.toList(growable: false),
    );

    final session = _session;
    if (session == null) {
      _pendingCoinGrant += amount;
    } else {
      session.addCoins(amount);
    }
  }

  String _purchaseTokenFor(PurchaseDetails purchase) {
    return purchase.purchaseID ??
        '${purchase.productID}_${purchase.transactionDate ?? DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, int> _loadPendingPackGrants() {
    final raw = _prefs?.getString(_pendingPackGrantsPrefsKey);
    if (raw == null || raw.isEmpty) return const <String, int>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const <String, int>{};
    final result = <String, int>{};
    decoded.forEach((key, value) {
      if (key is String && value is int && value > 0) {
        result[key] = value;
      }
    });
    return result;
  }

  Future<void> _persistPendingPackGrants() async {
    await _prefs?.setString(
      _pendingPackGrantsPrefsKey,
      jsonEncode(_pendingPackGrants),
    );
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
