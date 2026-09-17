import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService extends ChangeNotifier {
  /// Set to true to disable all ads (e.g. for Play Console review).
  /// Set back to false before releasing to users.
  static const bool _adsDisabled = false;

  static const String _androidBannerTestId =
      'ca-app-pub-1868607600414176/4880956466';
  static const String _androidInterstitialTestId =
      'ca-app-pub-1868607600414176/9679199020';
  static const String _androidRewardedTestId =
      'ca-app-pub-1868607600414176/7181028198';

  bool _initialized = false;
  bool _adsRemoved = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  int _quizAnswersSinceInterstitial = 0;
  DateTime? _lastInterstitialAt;
  bool _pendingQuizInterstitial = false;

  bool get isSupportedPlatform =>
      !_adsDisabled &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get isInitialized => _initialized;
  bool get adsRemoved => _adsRemoved;

  void setAdsRemoved(bool value) {
    if (_adsRemoved == value) return;
    _adsRemoved = value;
    if (_adsRemoved) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
    } else if (_initialized) {
      _loadInterstitial();
    }
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_initialized || !isSupportedPlatform) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    _loadInterstitial();
    _loadRewarded();
    notifyListeners();
  }

  Future<void> registerQuizAnswerAndMaybeShowInterstitial() async {
    if (!isSupportedPlatform || _adsRemoved) return;
    _quizAnswersSinceInterstitial += 1;
    if (_quizAnswersSinceInterstitial < 8) return;
    _pendingQuizInterstitial = true;
    final shown = await showInterstitialIfReady();
    if (shown) {
      _quizAnswersSinceInterstitial = 0;
      _pendingQuizInterstitial = false;
    }
  }

  Future<void> showInterstitialForCompletedBattle() async {
    await showInterstitialIfReady();
  }

  Future<bool> showInterstitialIfReady() async {
    if (!_initialized || !isSupportedPlatform || _adsRemoved) return false;
    final lastAt = _lastInterstitialAt;
    if (lastAt != null &&
        DateTime.now().difference(lastAt) < const Duration(minutes: 2)) {
      return false;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitial();
      return false;
    }

    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _lastInterstitialAt = DateTime.now();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    await ad.show();
    return true;
  }

  Future<bool> showRewardedAd({required VoidCallback onRewarded}) async {
    if (!_initialized || !isSupportedPlatform) return false;
    final ad = _rewardedAd;
    if (ad == null) {
      _loadRewarded();
      return false;
    }

    _rewardedAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewarded();
      },
    );
    await ad.show(onUserEarnedReward: (_, __) => onRewarded());
    return true;
  }

  String get _interstitialAdUnitId => _androidInterstitialTestId;
  String get _rewardedAdUnitId => _androidRewardedTestId;

  void _loadInterstitial() {
    if (!isSupportedPlatform || _adsRemoved) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd?.dispose();
          _interstitialAd = ad;
          if (_pendingQuizInterstitial) {
            unawaited(
              showInterstitialIfReady().then((shown) {
                if (shown) {
                  _quizAnswersSinceInterstitial = 0;
                  _pendingQuizInterstitial = false;
                }
              }),
            );
          }
        },
        onAdFailedToLoad: (_) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void _loadRewarded() {
    if (!isSupportedPlatform) return;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd?.dispose();
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (_) {
          _rewardedAd = null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}

class HomeBannerAd extends StatefulWidget {
  final AdsService adsService;

  const HomeBannerAd({super.key, required this.adsService});

  @override
  State<HomeBannerAd> createState() => _HomeBannerAdState();
}

class _HomeBannerAdState extends State<HomeBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  int? _lastWidth;

  @override
  void initState() {
    super.initState();
    widget.adsService.addListener(_handleAdsServiceChange);
  }

  @override
  void didUpdateWidget(covariant HomeBannerAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adsService == widget.adsService) return;
    oldWidget.adsService.removeListener(_handleAdsServiceChange);
    widget.adsService.addListener(_handleAdsServiceChange);
    _handleAdsServiceChange();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureBannerLoaded();
  }

  void _handleAdsServiceChange() {
    if (!mounted) return;
    if (widget.adsService.adsRemoved) {
      _lastWidth = null;
      _bannerAd?.dispose();
      setState(() {
        _bannerAd = null;
        _isLoaded = false;
      });
      return;
    }
    unawaited(_ensureBannerLoaded());
    setState(() {});
  }

  Future<void> _ensureBannerLoaded() async {
    if (!widget.adsService.isSupportedPlatform ||
        widget.adsService.adsRemoved) {
      return;
    }
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0 || width == _lastWidth) return;
    _lastWidth = width;

    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (!mounted || size == null) return;

    await _bannerAd?.dispose();
    final banner = BannerAd(
      adUnitId: AdsService._androidBannerTestId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        },
      ),
    );

    setState(() {
      _isLoaded = false;
      _bannerAd = banner;
    });
    await banner.load();
  }

  @override
  void dispose() {
    widget.adsService.removeListener(_handleAdsServiceChange);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.adsService.isSupportedPlatform ||
        widget.adsService.adsRemoved ||
        !_isLoaded ||
        _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: const Color(0xFF160D08),
      child: Center(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
