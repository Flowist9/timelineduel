import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ads/ads_service.dart';
import '../localization/app_language.dart';
import '../logic/game_progression.dart';
import '../logic/game_session.dart';
import '../models/category.dart';
import '../models/game_badge.dart';
import '../models/person.dart';
import '../models/person_rarity.dart';
import '../models/question.dart';
import '../monetization/purchase_service.dart';
import '../monetization/store_catalog.dart';
import '../widgets/person_portrait.dart';
import '../widgets/reward_card_reveal_dialog.dart';

enum _ShopCategory { boosts, packs, questions }

class ShopScreen extends StatefulWidget {
  final GameSession session;
  final AdsService adsService;
  final PurchaseService purchaseService;

  const ShopScreen({
    super.key,
    required this.session,
    required this.adsService,
    required this.purchaseService,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const int _capsuleCost = 60;
  static const int _chronicleCost = 110;
  bool _rewardLoading = false;
  bool _purchaseLoading = false;
  _ShopCategory _selectedCategory = _ShopCategory.packs;

  @override
  Widget build(BuildContext context) {
    final boosts = [
      _ShopItem(
        title: context.tr('XP-Boost', 'XP boost'),
        description: context.tr(
          'Extra XP for 3 correct answers.',
          'Extra XP for 3 correct answers.',
        ),
        price: 30,
        icon: Icons.auto_awesome_rounded,
        onBuy: () => _buyBoost(
          type: BadgeBoostType.xpSurge,
          cost: 30,
          charges: 3,
          successText: context.tr('XP-Boost gekauft.', 'XP boost purchased.'),
        ),
      ),
      _ShopItem(
        title: context.tr('Serien-Schutz', 'Streak shield'),
        description: context.tr(
          'Protects your streak from one mistake.',
          'Protects your streak when you make a mistake.',
        ),
        price: 40,
        icon: Icons.shield_rounded,
        onBuy: () => _buyBoost(
          type: BadgeBoostType.streakShield,
          cost: 40,
          charges: 1,
          successText: context.tr(
            'Serien-Schutz gekauft.',
            'Streak shield purchased.',
          ),
        ),
      ),
      _ShopItem(
        title: context.tr('Map Grace', 'Map grace'),
        description: context.tr(
          'Larger radius for 2 map attempts.',
          'Larger radius for 2 map attempts.',
        ),
        price: 35,
        icon: Icons.public_rounded,
        onBuy: () => _buyBoost(
          type: BadgeBoostType.mapGrace,
          cost: 35,
          charges: 2,
          successText: context.tr(
            'Map Grace purchased.',
            'Map grace purchased.',
          ),
        ),
      ),
    ];

    final questionOffers = _buildQuestionOffers();
    final nextQuestionOffer = questionOffers.firstWhere(
      (offer) => !offer.naturallyUnlocked && !offer.premiumUnlocked,
      orElse: () => const _QuestionUnlockOffer.completed(),
    );

    final packs = [
      _PackOffer(
        title: context.tr('Politics Capsule', 'Politics capsule'),
        description: context.tr(
          'Instantly draws a new politics card from your undiscovered pool.',
          'Pulls one new politician card from your undiscovered pool instantly.',
        ),
        icon: Icons.account_balance_rounded,
        cost: _capsuleCost,
        productId: StoreCatalog.politicsCapsuleProductId,
        category: Category.politician,
        badge:
            '${widget.session.undiscoveredCount(category: Category.politician)} left',
      ),
      _PackOffer(
        title: context.tr('Science Capsule', 'Science capsule'),
        description: context.tr(
          'Instantly draws a new science card from your undiscovered pool.',
          'Pulls one new scientist card from your undiscovered pool instantly.',
        ),
        icon: Icons.science_rounded,
        cost: _capsuleCost,
        productId: StoreCatalog.scienceCapsuleProductId,
        category: Category.scientist,
        badge:
            '${widget.session.undiscoveredCount(category: Category.scientist)} left',
      ),
      _PackOffer(
        title: context.tr('Art Capsule', 'Art capsule'),
        description: context.tr(
          'Instantly draws a new art or culture card from your undiscovered pool.',
          'Pulls one new art or culture card from your undiscovered pool instantly.',
        ),
        icon: Icons.palette_rounded,
        cost: _capsuleCost,
        productId: StoreCatalog.artCapsuleProductId,
        category: Category.artist,
        badge:
            '${widget.session.undiscoveredCount(category: Category.artist)} left',
      ),
      _PackOffer(
        title: context.tr('Sports Capsule', 'Sports capsule'),
        description: context.tr(
          'Instantly draws a new athlete card from your undiscovered pool.',
          'Pulls one new athlete card from your undiscovered pool instantly.',
        ),
        icon: Icons.sports_soccer_rounded,
        cost: _capsuleCost,
        productId: StoreCatalog.sportsCapsuleProductId,
        category: Category.athlete,
        badge:
            '${widget.session.undiscoveredCount(category: Category.athlete)} left',
      ),
      _PackOffer(
        title: context.tr('Chronicle Capsule', 'Chronicle capsule'),
        description: context.tr(
          'Instantly draws 2 new cards from all categories.',
          'Pulls 2 new cards from the full collection pool instantly.',
        ),
        icon: Icons.casino_rounded,
        cost: _chronicleCost,
        productId: StoreCatalog.chronicleCapsuleProductId,
        badge: '${widget.session.undiscoveredCount()} left',
        highlight: true,
        drawCount: 2,
      ),
    ];

    return AnimatedBuilder(
      animation: Listenable.merge([widget.session, widget.purchaseService]),
      builder: (context, _) {
        final undiscoveredCards = widget.session.undiscoveredCount();
        final premiumUnlockCount =
            widget.purchaseService.premiumQuestionUnlocks.length;
        return Scaffold(
          backgroundColor: const Color(0xFF120B07),
          appBar: AppBar(
            title: Text(context.tr('Shop', 'Shop')),
            backgroundColor: const Color(0xFF1E120D),
            foregroundColor: const Color(0xFFF7ECDD),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF26170F), Color(0xFF120B07)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                children: [
                  _CoinsHero(
                    coins: widget.session.coins,
                    adsRemoved: widget.purchaseService.adsRemoved,
                    undiscoveredCards: undiscoveredCards,
                    premiumUnlockCount: premiumUnlockCount,
                  ),
                  const SizedBox(height: 14),
                  _StoreStatusCard(
                    purchaseService: widget.purchaseService,
                    loading: _purchaseLoading,
                    onRestore: _restorePurchases,
                  ),
                  const SizedBox(height: 14),
                  _ShopCategorySwitcher(
                    selectedCategory: _selectedCategory,
                    onChanged: (category) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                  const SizedBox(height: 18),
                  if (_selectedCategory == _ShopCategory.boosts) ...[
                    _CategoryInfoCard(
                      icon: Icons.local_fire_department_rounded,
                      title: context.tr(
                        'Boosts for runs and streaks',
                        'Boosts for runs and streaks',
                      ),
                      body: context.tr(
                        'Use your coins on short-term boosts for more momentum, more safety, and stronger quiz runs.',
                        'Use your coins on short-term boosts for more momentum, more safety, and stronger quiz runs.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionHeading(
                      title: context.tr('Coins verdienen', 'Earn coins'),
                      subtitle:
                          'Free through rewarded ads or directly through the store. You can then spend coins on boosts and card packs.',
                    ),
                    const SizedBox(height: 10),
                    _RewardedCard(
                      loading: _rewardLoading,
                      onTap: _watchRewardedAd,
                    ),
                    const SizedBox(height: 14),
                    _StoreOfferCard(
                      title: context.tr(
                        'Early battle access',
                        'Early battle access',
                      ),
                      description: context.tr(
                        'Unlocks battle mode immediately, even if you have not reached level 10 yet.',
                        'Unlocks battle mode immediately, even if you have not reached level 10 yet.',
                      ),
                      icon: Icons.bolt_rounded,
                      priceLabel: widget.purchaseService.priceLabelFor(
                        StoreCatalog.earlyBattleAccessProductId,
                        fallback: context.tr('Unavailable', 'Unavailable'),
                      ),
                      enabled:
                          !_purchaseLoading &&
                          !widget.session.canAccessBattleMode,
                      badge: widget.session.canAccessBattleMode
                          ? context.tr('Active', 'Active')
                          : context.tr(
                              'Unlocks at level 10',
                              'Unlocks at level 10',
                            ),
                      onBuy: _buyEarlyBattleAccess,
                    ),
                    const SizedBox(height: 14),
                    _SectionHeading(
                      title: context.tr('Boost loadout', 'Boost loadout'),
                      subtitle: context.tr(
                        'Short but meaningful advantages for your sessions: more XP, streak protection, and more tolerance on map questions.',
                        'Short but meaningful advantages for your sessions: more XP, streak protection, and more tolerance on map questions.',
                      ),
                    ),
                  ],
                  if (_selectedCategory == _ShopCategory.packs) ...[
                    _CategoryInfoCard(
                      icon: Icons.auto_awesome_rounded,
                      title: context.tr(
                        'Every capsule gives you a new card',
                        'Every capsule gives you a new card',
                      ),
                      body: context.tr(
                        'No duplicates at this step: capsules always pull from your undiscovered pool. Category capsules are more targeted, while the Chronicle capsule is broader.',
                        'No duplicates at this step: capsules always pull from your undiscovered pool. Category capsules are more targeted, while the Chronicle capsule is broader.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionHeading(
                      title: context.tr('Premium unlocks', 'Premium unlocks'),
                      subtitle: context.tr(
                        'Find every real-money purchase here: ad-free play, early battle access, and direct capsule purchases for your collection.',
                        'This is where all real-money products live: ad-free play, early battle access, and direct capsule purchases for your collection.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _StoreOfferCard(
                      title: 'No ads',
                      description:
                          'Removes banners and interstitials. Rewarded ads for free coins remain optional.',
                      icon: Icons.block_rounded,
                      priceLabel: widget.purchaseService.priceLabelFor(
                        StoreCatalog.noAdsProductId,
                        fallback: 'Unavailable',
                      ),
                      enabled:
                          !widget.purchaseService.adsRemoved &&
                          !_purchaseLoading,
                      badge: widget.purchaseService.adsRemoved
                          ? 'Active'
                          : 'Permanent',
                      highlight: true,
                      onBuy: _buyNoAds,
                    ),
                    const SizedBox(height: 12),
                    _StoreOfferCard(
                      title: context.tr(
                        'Early battle access',
                        'Early battle access',
                      ),
                      description: context.tr(
                        'Unlocks battle mode immediately, even if you have not reached the regular level 10 unlock yet.',
                        'Unlocks battle mode immediately, even if you have not reached the regular level 10 unlock yet.',
                      ),
                      icon: Icons.bolt_rounded,
                      priceLabel: widget.purchaseService.priceLabelFor(
                        StoreCatalog.earlyBattleAccessProductId,
                        fallback: context.tr('Unavailable', 'Unavailable'),
                      ),
                      enabled:
                          !_purchaseLoading &&
                          !widget.session.canAccessBattleMode,
                      badge: widget.session.canAccessBattleMode
                          ? context.tr('Active', 'Active')
                          : context.tr(
                              'Unlocks at level 10',
                              'Unlocks at level 10',
                            ),
                      onBuy: _buyEarlyBattleAccess,
                    ),
                    const SizedBox(height: 18),
                    _CategoryInfoCard(
                      icon: Icons.stars_rounded,
                      title: context.tr(
                        'Collection progress that matters',
                        'Collection progress that matters',
                      ),
                      body: context.tr(
                        'Chronicle capsules always pull from your undiscovered pool. That makes each purchase feel like real progress instead of duplicate roulette.',
                        'Chronicle capsules always pull from your undiscovered pool. That makes every purchase feel like real collection progress instead of duplicate roulette.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionHeading(
                      title: context.tr('Card Packs', 'Card packs'),
                      subtitle:
                          'Buy direct pulls for your collection here. Every capsule instantly draws a new figure you have not discovered yet.',
                    ),
                    const SizedBox(height: 10),
                    for (final pack in packs) ...[
                      _PackCard(
                        offer: pack,
                        enabled:
                            widget.session.undiscoveredCount(
                              category: pack.category,
                            ) >
                            0,
                        hasPendingClaim:
                            widget.purchaseService.pendingPackGrantsFor(
                              pack.productId,
                            ) >
                            0,
                        storeLabel:
                            widget.purchaseService.pendingPackGrantsFor(
                                  pack.productId,
                                ) >
                                0
                            ? context.tr('Claim', 'Claim')
                            : widget.purchaseService.priceLabelFor(
                                pack.productId,
                                fallback: context.tr(
                                  'Unavailable',
                                  'Unavailable',
                                ),
                              ),
                        onStoreAction: () {
                          final pending = widget.purchaseService
                              .pendingPackGrantsFor(pack.productId);
                          if (pending > 0) {
                            _claimPremiumPack(pack);
                          } else {
                            _buyPremiumPack(pack);
                          }
                        },
                        storeEnabled:
                            !_purchaseLoading &&
                            (widget.purchaseService.pendingPackGrantsFor(
                                      pack.productId,
                                    ) >
                                    0 ||
                                widget.purchaseService.productFor(
                                      pack.productId,
                                    ) !=
                                    null),
                        onOpen: () => _openPack(pack),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                  if (_selectedCategory == _ShopCategory.questions) ...[
                    _CategoryInfoCard(
                      icon: Icons.timeline_rounded,
                      title: context.tr(
                        'Question types follow a progression order',
                        'Question types follow a progression order',
                      ),
                      body: context.tr(
                        'You can unlock new question types early with real-money purchases, but only in the game\'s intended order. That keeps progression readable.',
                        'You can unlock new question types early with real-money purchases, but only in the game\'s intended order. That keeps progression readable.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionHeading(
                      title: context.tr('Question types', 'Question types'),
                      subtitle:
                          'One purchase always skips exactly the next locked question type in the intended order.',
                    ),
                    const SizedBox(height: 8),
                    _NextQuestionUnlockCard(
                      offer: nextQuestionOffer.isCompleted
                          ? null
                          : nextQuestionOffer,
                      canBuy:
                          !_purchaseLoading &&
                          !nextQuestionOffer.isCompleted &&
                          widget.purchaseService.productFor(
                                StoreCatalog.nextQuestionUnlockProductId,
                              ) !=
                              null,
                      priceLabel: widget.purchaseService
                          .nextQuestionUnlockPriceLabel(fallback: 'Soon'),
                      onBuy: _buyNextQuestionUnlock,
                    ),
                    if (questionOffers
                        .where((offer) => offer.premiumUnlocked)
                        .isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _CategoryInfoCard(
                        icon: Icons.check_circle_rounded,
                        title: 'Unlocked early',
                        body: questionOffers
                            .where((offer) => offer.premiumUnlocked)
                            .map((offer) => offer.type.title)
                            .join(' • '),
                      ),
                    ],
                  ],
                  if (_selectedCategory == _ShopCategory.boosts) ...[
                    const SizedBox(height: 18),
                    _SectionHeading(
                      title: 'Boosts',
                      subtitle:
                          'Buy these upgrades with coins. That gives your in-game currency a clear purpose right away.',
                    ),
                    const SizedBox(height: 10),
                    for (final boost in boosts) ...[
                      boost,
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _watchRewardedAd() async {
    if (_rewardLoading) return;
    setState(() => _rewardLoading = true);
    final shown = await widget.adsService.showRewardedAd(
      onRewarded: () => widget.session.addCoins(20),
    );
    if (!mounted) return;
    setState(() => _rewardLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shown ? 'Received 20 coins.' : 'Rewarded ad is not ready yet.',
        ),
      ),
    );
  }

  Future<void> _buyNoAds() async {
    await _runPurchaseFlow(
      widget.purchaseService.buyNoAds,
      startedText: 'Google Play is opening the purchase for No Ads.',
    );
  }

  Future<void> _buyEarlyBattleAccess() async {
    await _runPurchaseFlow(
      widget.purchaseService.buyEarlyBattleAccess,
      startedText: context.tr(
        'Google Play is opening the purchase for early battle access.',
        'Google Play is opening the purchase for early battle access.',
      ),
    );
  }

  Future<void> _restorePurchases() async {
    await _runPurchaseFlow(
      widget.purchaseService.restorePurchases,
      startedText: 'Restoring previous purchases.',
    );
  }

  Future<void> _runPurchaseFlow(
    Future<String?> Function() action, {
    required String startedText,
  }) async {
    if (_purchaseLoading) return;
    setState(() => _purchaseLoading = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _purchaseLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? startedText)));
  }

  List<_QuestionUnlockOffer> _buildQuestionOffers() {
    final offers = <_QuestionUnlockOffer>[];
    final ordered = StoreCatalog.premiumQuestionUnlockOrder;

    for (final type in ordered) {
      final naturallyUnlocked = GameProgression.isQuestionTypeUnlocked(
        type: type,
        level: widget.session.level,
        unlockedPeople: widget.session.unlockedPersons.length,
      );
      final premiumUnlocked = widget.purchaseService.hasPremiumQuestionUnlock(
        type,
      );
      offers.add(
        _QuestionUnlockOffer(
          type: type,
          unlockLevel: GameProgression.questionUnlockLevel(type) ?? 0,
          stepNumber: StoreCatalog.questionStepNumber(type),
          naturallyUnlocked: naturallyUnlocked,
          premiumUnlocked: premiumUnlocked,
        ),
      );
    }
    return offers;
  }

  Future<void> _buyNextQuestionUnlock() async {
    final nextType = widget.purchaseService.nextPremiumQuestionUnlock(
      level: widget.session.level,
      unlockedPeople: widget.session.unlockedPersons.length,
    );
    await _runPurchaseFlow(
      widget.purchaseService.buyNextQuestionUnlock,
      startedText: nextType == null
          ? 'All premium question unlocks are already claimed.'
          : 'Google Play is opening the purchase for ${nextType.title}.',
    );
  }

  Future<void> _openPack(_PackOffer offer) async {
    final result = widget.session.openCardPack(
      cost: offer.cost,
      category: offer.category,
      drawCount: offer.drawCount,
    );
    await _handlePackResult(result, offer: offer);
  }

  Future<void> _claimPremiumPack(_PackOffer offer) async {
    final consumed = widget.purchaseService.consumePendingPackGrant(
      offer.productId,
    );
    if (!consumed) return;
    final result = widget.session.openCardPack(
      cost: 0,
      category: offer.category,
      drawCount: offer.drawCount,
    );
    await _handlePackResult(result, premiumPack: true, offer: offer);
  }

  Future<void> _buyPremiumPack(_PackOffer offer) async {
    await _runPurchaseFlow(
      () => widget.purchaseService.buyPackProduct(offer.productId),
      startedText: context.tr(
        'Google Play is opening the purchase for ${offer.title}. After purchase, you can claim the capsule right away.',
        'Google Play is opening the purchase for ${offer.title}. After purchase you can claim the capsule right here.',
      ),
    );
  }

  Future<void> _handlePackResult(
    CardPackOpenResult result, {
    bool premiumPack = false,
    _PackOffer? offer,
  }) async {
    switch (result.status) {
      case CardPackOpenStatus.insufficientCoins:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'Not enough coins for this pack.',
                'Not enough coins for this pack.',
              ),
            ),
          ),
        );
        return;
      case CardPackOpenStatus.soldOut:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'Dieses Pack ist fuer dich schon leer.',
                'This pack is already empty for you.',
              ),
            ),
          ),
        );
        return;
      case CardPackOpenStatus.success:
        for (final person in result.persons) {
          await _showAnimatedPackReveal(
            person,
            premiumPack: premiumPack,
            offer: offer,
          );
        }
    }
  }

  Future<void> _showAnimatedPackReveal(
    Person person, {
    required bool premiumPack,
    _PackOffer? offer,
  }) async {
    final isChronicle =
        offer?.productId == StoreCatalog.chronicleCapsuleProductId;
    final accentColor = isChronicle
        ? const Color(0xFFD4B06A)
        : _categoryAccentColor(person.category);
    final accentLabel = isChronicle
        ? 'Chronicle'
        : _labelForCategory(person.category);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RewardCardRevealDialog(
        eyebrow: isChronicle
            ? 'Chronicle capsule opened'
            : premiumPack
            ? 'Premium capsule opened'
            : 'New card unlocked',
        title: person.name,
        subtitle: isChronicle
            ? 'A Chronicle pull bursts open with a bigger walkout reveal.'
            : premiumPack
            ? 'A premium capsule just dropped a fresh collection card.'
            : 'A new collection card just flew into your archive.',
        confirmLabel: 'Nice',
        accentIcon: _iconForCategory(person.category),
        accentColor: accentColor,
        accentLabel: accentLabel,
        person: person,
        showOpeningPhase: true,
        openingEyebrow: isChronicle
            ? 'Chronicle capsule'
            : premiumPack
            ? 'Premium capsule'
            : 'Capsule opening',
        openingTitle: isChronicle ? 'Walkout loading' : 'Preparing reveal',
        openingBody: isChronicle
            ? 'The Chronicle capsule is opening with a bigger walkout before the card flips into view.'
            : premiumPack
            ? 'Your capsule is charging up and about to reveal a new card.'
            : 'The capsule is opening and the next collection card is being revealed.',
      ),
    );
  }

  Future<void> _showPackReveal(
    Person person, {
    required bool premiumPack,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1B100A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            premiumPack
                                ? 'Premium capsule opened'
                                : 'New card drawn',
                            premiumPack
                                ? 'Premium capsule opened'
                                : 'New card unlocked',
                          ),
                          style: const TextStyle(
                            color: Color(0xFFF7ECDD),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          person.name,
                          style: const TextStyle(
                            color: Color(0xFFF7ECDD),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
                    ),
                    child: Text(
                      person.rarity.name.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFD4B06A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    PersonPortrait(
                      person: person,
                      width: double.infinity,
                      height: 220,
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.black.withValues(alpha: 0.38),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _iconForCategory(person.category),
                              color: const Color(0xFFD4B06A),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_labelForCategory(person.category)} • ${person.birthYear}',
                                style: const TextStyle(
                                  color: Color(0xFFF7ECDD),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                person.hint,
                style: TextStyle(
                  color: const Color(0xFFD8CBB8).withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD4B06A),
                    foregroundColor: const Color(0xFF1B100A),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    context.tr('Stark', 'Nice'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(Category category) {
    switch (category) {
      case Category.politician:
        return Icons.account_balance_rounded;
      case Category.scientist:
        return Icons.science_rounded;
      case Category.artist:
        return Icons.palette_rounded;
      case Category.athlete:
        return Icons.sports_soccer_rounded;
    }
  }

  String _labelForCategory(Category category) {
    switch (category) {
      case Category.politician:
        return 'Politics';
      case Category.scientist:
        return 'Science';
      case Category.artist:
        return 'Art';
      case Category.athlete:
        return 'Sports';
    }
  }

  Color _categoryAccentColor(Category category) {
    switch (category) {
      case Category.politician:
        return const Color(0xFFE86E4B);
      case Category.scientist:
        return const Color(0xFF4F8CFF);
      case Category.artist:
        return const Color(0xFFE1A53B);
      case Category.athlete:
        return const Color(0xFF34B27B);
    }
  }

  void _buyBoost({
    required BadgeBoostType type,
    required int cost,
    required int charges,
    required String successText,
  }) {
    final success = widget.session.purchaseBoost(
      type: type,
      cost: cost,
      charges: charges,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? successText : 'Not enough coins.')),
    );
  }
}

class _CapsuleRevealDialog extends StatefulWidget {
  final Person person;
  final bool premiumPack;
  final IconData categoryIcon;
  final String categoryLabel;

  const _CapsuleRevealDialog({
    required this.person,
    required this.premiumPack,
    required this.categoryIcon,
    required this.categoryLabel,
  });

  @override
  State<_CapsuleRevealDialog> createState() => _CapsuleRevealDialogState();
}

class _CapsuleRevealDialogState extends State<_CapsuleRevealDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _revealed = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor(widget.person.category);
    final rarityColor = _rarityColor(widget.person.rarity);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF11264A), Color(0xFF09162D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFF1E2CB).withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withValues(alpha: 0.26),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 650),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
                  child: child,
                ),
              );
            },
            child: _revealed
                ? _buildRevealContent(context, categoryColor, rarityColor)
                : _buildOpeningPhase(categoryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildOpeningPhase(Color categoryColor) {
    return Column(
      key: const ValueKey('capsule-opening'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.premiumPack ? 'Premium capsule' : 'Capsule opening',
          style: const TextStyle(
            color: Color(0xFFD4B06A),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Preparing reveal',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFF8F0E3),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.premiumPack
              ? 'Your capsule is charging up and about to reveal a new card.'
              : 'The capsule is opening and the next collection card is being revealed.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFE0CFB5), height: 1.45),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 260,
          width: 260,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final pulse =
                  1 + (math.sin(_controller.value * math.pi * 2) * 0.06);
              final glow = 18 + (math.sin(_controller.value * math.pi * 2) * 8);
              return Transform.scale(
                scale: pulse,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFF17386D), Color(0xFF09162D)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFD4B06A,
                            ).withValues(alpha: 0.12),
                            blurRadius: glow,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Transform.rotate(
                      angle: _controller.value * math.pi * 2,
                      child: Container(
                        width: 174,
                        height: 174,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFF1E2CB,
                            ).withValues(alpha: 0.16),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 136,
                      height: 172,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(36),
                        gradient: LinearGradient(
                          colors: [
                            Color.lerp(categoryColor, Colors.white, 0.18)!,
                            Color.lerp(
                              categoryColor,
                              const Color(0xFF09162D),
                              0.34,
                            )!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: const Color(
                            0xFFF7ECDD,
                          ).withValues(alpha: 0.18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withValues(alpha: 0.26),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFFF8F0E3),
                            size: 34,
                          ),
                          const SizedBox(height: 10),
                          Icon(
                            widget.categoryIcon,
                            color: const Color(0xFFD4B06A),
                            size: 42,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRevealContent(
    BuildContext context,
    Color categoryColor,
    Color rarityColor,
  ) {
    return Column(
      key: const ValueKey('capsule-reveal'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.premiumPack
                        ? 'Premium capsule opened'
                        : 'New card unlocked',
                    style: const TextStyle(
                      color: Color(0xFFF7ECDD),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      widget.person.name,
                      style: const TextStyle(
                        color: Color(0xFFF7ECDD),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: rarityColor.withValues(alpha: 0.16),
              ),
              child: Text(
                widget.person.rarity.name.toUpperCase(),
                style: TextStyle(
                  color: rarityColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.92, end: 1),
          duration: const Duration(milliseconds: 620),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Opacity(
              opacity: ((value - 0.92) / 0.08).clamp(0, 1),
              child: Transform.scale(scale: value, child: child),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                PersonPortrait(
                  person: widget.person,
                  width: double.infinity,
                  height: 240,
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.14),
                          Colors.black.withValues(alpha: 0.42),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.black.withValues(alpha: 0.36),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.categoryIcon,
                          color: const Color(0xFFD4B06A),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${widget.categoryLabel} | ${widget.person.birthYear}',
                            style: const TextStyle(
                              color: Color(0xFFF7ECDD),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _RevealChip(
              color: categoryColor,
              icon: widget.categoryIcon,
              label: widget.categoryLabel,
            ),
            _RevealChip(
              color: rarityColor,
              icon: Icons.stars_rounded,
              label: widget.person.rarity.name.toUpperCase(),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          widget.person.hint,
          style: const TextStyle(
            color: Color(0xFFD8CBB8),
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD4B06A),
              foregroundColor: const Color(0xFF1B100A),
            ),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text(
              'Nice',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Color _categoryColor(Category category) {
    switch (category) {
      case Category.politician:
        return const Color(0xFFE86E4B);
      case Category.scientist:
        return const Color(0xFF4F8CFF);
      case Category.artist:
        return const Color(0xFFE1A53B);
      case Category.athlete:
        return const Color(0xFF34B27B);
    }
  }

  Color _rarityColor(PersonRarity rarity) {
    switch (rarity) {
      case PersonRarity.common:
        return const Color(0xFFB7BDC9);
      case PersonRarity.rare:
        return const Color(0xFF6FA8FF);
      case PersonRarity.epic:
        return const Color(0xFFD98CFF);
      case PersonRarity.legendary:
        return const Color(0xFFD4B06A);
    }
  }
}

class _RevealChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _RevealChip({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionUnlockOffer {
  final QuestionType type;
  final int unlockLevel;
  final int stepNumber;
  final bool naturallyUnlocked;
  final bool premiumUnlocked;

  const _QuestionUnlockOffer({
    required this.type,
    required this.unlockLevel,
    required this.stepNumber,
    required this.naturallyUnlocked,
    required this.premiumUnlocked,
  });

  const _QuestionUnlockOffer.completed()
    : type = QuestionType.birthCentury,
      unlockLevel = 0,
      stepNumber = 0,
      naturallyUnlocked = true,
      premiumUnlocked = true;

  bool get isCompleted => stepNumber == 0;
}

class _PackOffer {
  final String title;
  final String description;
  final IconData icon;
  final int cost;
  final String productId;
  final Category? category;
  final String badge;
  final bool highlight;
  final int drawCount;

  const _PackOffer({
    required this.title,
    required this.description,
    required this.icon,
    required this.cost,
    required this.productId,
    required this.badge,
    this.category,
    this.highlight = false,
    this.drawCount = 1,
  });
}

class _ShopCategorySwitcher extends StatelessWidget {
  final _ShopCategory selectedCategory;
  final ValueChanged<_ShopCategory> onChanged;

  const _ShopCategorySwitcher({
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_ShopCategory>(
      showSelectedIcon: false,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFD4B06A).withValues(alpha: 0.18);
          }
          return Colors.white.withValues(alpha: 0.03);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFF7ECDD);
          }
          return const Color(0xFFD8CBB8);
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      segments: [
        ButtonSegment<_ShopCategory>(
          value: _ShopCategory.boosts,
          label: Text(context.tr('Boosts', 'Boosts')),
          icon: Icon(Icons.auto_awesome_rounded),
        ),
        ButtonSegment<_ShopCategory>(
          value: _ShopCategory.packs,
          label: Text(context.tr('Chronicle capsules', 'Chronicle capsules')),
          icon: Icon(Icons.inventory_2_rounded),
        ),
        ButtonSegment<_ShopCategory>(
          value: _ShopCategory.questions,
          label: Text(context.tr('Questions', 'Questions')),
          icon: Icon(Icons.quiz_rounded),
        ),
      ],
      selected: <_ShopCategory>{selectedCategory},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          onChanged(selection.first);
        }
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFF7ECDD),
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: const Color(0xFFD8CBB8).withValues(alpha: 0.88),
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _CoinsHero extends StatelessWidget {
  final int coins;
  final bool adsRemoved;
  final int undiscoveredCards;
  final int premiumUnlockCount;

  const _CoinsHero({
    required this.coins,
    required this.adsRemoved,
    required this.undiscoveredCards,
    required this.premiumUnlockCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4B06A).withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFFD4B06A).withValues(alpha: 0.18),
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFFD4B06A),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your coins',
                style: TextStyle(
                  color: Color(0xFFD8CBB8),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$coins',
                style: const TextStyle(
                  color: Color(0xFFF7ECDD),
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
            ],
          ),
          if (adsRemoved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFFD4B06A).withValues(alpha: 0.16),
                border: Border.all(
                  color: const Color(0xFFD4B06A).withValues(alpha: 0.35),
                ),
              ),
              child: const Text(
                'Ad-free active',
                style: TextStyle(
                  color: Color(0xFFD4B06A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              '$undiscoveredCards ${context.tr('cards left', 'cards left')}',
              style: const TextStyle(
                color: Color(0xFFD8CBB8),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (premiumUnlockCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFF6FA8FF).withValues(alpha: 0.14),
                border: Border.all(
                  color: const Color(0xFF6FA8FF).withValues(alpha: 0.28),
                ),
              ),
              child: Text(
                '$premiumUnlockCount ${context.tr('early question unlocks', 'early question unlocks')}',
                style: const TextStyle(
                  color: Color(0xFF8DC8FF),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RewardedCard extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _RewardedCard({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final action = FilledButton.icon(
            onPressed: loading ? null : onTap,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD4B06A),
              foregroundColor: const Color(0xFF1B100A),
            ),
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_circle_fill_rounded),
            label: const Text(
              '20 Coins',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          );

          final text = const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Free coins',
                style: TextStyle(
                  color: Color(0xFFF7ECDD),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Watch a rewarded ad and get 20 coins.',
                style: TextStyle(
                  color: Color(0xFFD8CBB8),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 12), action],
            );
          }

          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 12),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _StoreStatusCard extends StatelessWidget {
  final PurchaseService purchaseService;
  final bool loading;
  final VoidCallback onRestore;

  const _StoreStatusCard({
    required this.purchaseService,
    required this.loading,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = purchaseService.canPurchase;
    final error = purchaseService.errorMessage;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Google Play',
                style: TextStyle(
                  color: Color(0xFFF7ECDD),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              OutlinedButton.icon(
                onPressed: loading ? null : onRestore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD4B06A),
                  side: BorderSide(
                    color: const Color(0xFFD4B06A).withValues(alpha: 0.35),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  context.tr('Restore purchases', 'Restore purchases'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isReady
                ? 'Buy capsules, remove ads, or restore previous purchases here.'
                : 'Restore previous purchases here if you already bought something on this account.',
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error,
              style: const TextStyle(
                color: Color(0xFFE39063),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StoreOfferCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String priceLabel;
  final bool enabled;
  final VoidCallback onBuy;
  final String? badge;
  final bool highlight;

  const _StoreOfferCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.priceLabel,
    required this.enabled,
    required this.onBuy,
    this.badge,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final highlightColor = highlight
        ? const Color(0xFFD4B06A).withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.03);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: highlightColor,
        border: Border.all(
          color: highlight
              ? const Color(0xFFD4B06A).withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final iconTile = Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: const Color(0xFFD4B06A)),
          );

          final textColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFF7ECDD),
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Color(0xFFD4B06A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFFD8CBB8),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          );

          final action = FilledButton(
            onPressed: enabled ? onBuy : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD4B06A),
              foregroundColor: const Color(0xFF1B100A),
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
              disabledForegroundColor: const Color(0xFFD8CBB8),
            ),
            child: Text(
              priceLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    iconTile,
                    const SizedBox(width: 12),
                    Expanded(child: textColumn),
                  ],
                ),
                const SizedBox(height: 12),
                action,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconTile,
              const SizedBox(width: 12),
              Expanded(child: textColumn),
              const SizedBox(width: 12),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _NextQuestionUnlockCard extends StatelessWidget {
  final _QuestionUnlockOffer? offer;
  final bool canBuy;
  final String priceLabel;
  final VoidCallback onBuy;

  const _NextQuestionUnlockCard({
    required this.offer,
    required this.canBuy,
    required this.priceLabel,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final currentOffer = offer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final buttonLabel = currentOffer == null
              ? context.tr('Done', 'Done')
              : !canBuy
              ? context.tr('Locked', 'Locked')
              : priceLabel;
          final action = FilledButton(
            onPressed: currentOffer != null && canBuy ? onBuy : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD4B06A),
              foregroundColor: const Color(0xFF1B100A),
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
              disabledForegroundColor: const Color(0xFFD8CBB8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: Size(compact ? double.infinity : 104, 38),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              buttonLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          );

          if (currentOffer == null) {
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Question path completed',
                        style: TextStyle(
                          color: Color(0xFFF7ECDD),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Every premium skip step is already claimed or naturally unlocked.',
                        style: TextStyle(
                          color: Color(0xFFD8CBB8),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 108, child: action),
              ],
            );
          }

          final previousType = StoreCatalog.previousPremiumQuestionType(
            currentOffer.type,
          );
          final stateLabel = currentOffer.naturallyUnlocked
              ? context.tr('Unlocked by level', 'Unlocked by level')
              : currentOffer.premiumUnlocked
              ? context.tr('Unlocked early', 'Unlocked early')
              : context.tr(
                  'Regular at level ${currentOffer.unlockLevel}',
                  'Regular at level ${currentOffer.unlockLevel}',
                );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0xFF6FA8FF).withValues(alpha: 0.14),
                    ),
                    child: Text(
                      context.tr(
                        'Step ${currentOffer.stepNumber}',
                        'Step ${currentOffer.stepNumber}',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF8DC8FF),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      currentOffer.type.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF7ECDD),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                currentOffer.type.description,
                maxLines: compact ? 2 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFD8CBB8),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.22,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
                      ),
                      child: Text(
                        stateLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD4B06A),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  if (previousType != null) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.tr(
                          'Next in line after ${previousType.title}.',
                          'Next in line after ${previousType.title}.',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE39063),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [content, const SizedBox(height: 8), action],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: content),
              const SizedBox(width: 8),
              SizedBox(width: 108, child: action),
            ],
          );
        },
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final _PackOffer offer;
  final bool enabled;
  final bool storeEnabled;
  final bool hasPendingClaim;
  final String storeLabel;
  final VoidCallback onOpen;
  final VoidCallback onStoreAction;

  const _PackCard({
    required this.offer,
    required this.enabled,
    required this.storeEnabled,
    required this.hasPendingClaim,
    required this.storeLabel,
    required this.onOpen,
    required this.onStoreAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: offer.highlight
            ? const Color(0xFFD4B06A).withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: offer.highlight
              ? const Color(0xFFD4B06A).withValues(alpha: 0.26)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final iconTile = Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
            ),
            child: Icon(offer.icon, color: const Color(0xFFD4B06A)),
          );
          final action = FilledButton.icon(
            onPressed: enabled ? onOpen : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD4B06A),
              foregroundColor: const Color(0xFF1B100A),
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
              disabledForegroundColor: const Color(0xFFD8CBB8),
            ),
            icon: Icon(
              enabled ? Icons.redeem_rounded : Icons.inventory_2_outlined,
            ),
            label: Text(
              enabled ? '${offer.cost}' : context.tr('Leer', 'Sold out'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          );
          final storeAction = OutlinedButton.icon(
            onPressed: storeEnabled ? onStoreAction : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8DC8FF),
              side: BorderSide(
                color: const Color(0xFF8DC8FF).withValues(alpha: 0.34),
              ),
            ),
            icon: Icon(
              hasPendingClaim
                  ? Icons.download_done_rounded
                  : Icons.shopping_bag_rounded,
            ),
            label: Text(storeLabel),
          );
          final textColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      offer.title,
                      style: const TextStyle(
                        color: Color(0xFFF7ECDD),
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
                    ),
                    child: Text(
                      offer.badge,
                      style: const TextStyle(
                        color: Color(0xFFD4B06A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                offer.description,
                style: const TextStyle(
                  color: Color(0xFFD8CBB8),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    iconTile,
                    const SizedBox(width: 12),
                    Expanded(child: textColumn),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [action, storeAction],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconTile,
              const SizedBox(width: 12),
              Expanded(child: textColumn),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [action, const SizedBox(height: 8), storeAction],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShopItem extends StatelessWidget {
  final String title;
  final String description;
  final int price;
  final IconData icon;
  final VoidCallback onBuy;

  const _ShopItem({
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final iconTile = Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: const Color(0xFFD4B06A)),
          );
          final action = FilledButton(
            onPressed: onBuy,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD4B06A),
              foregroundColor: const Color(0xFF1B100A),
            ),
            child: Text(
              '$price',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    iconTile,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFFF7ECDD),
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              color: Color(0xFFD8CBB8),
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                action,
              ],
            );
          }

          return Row(
            children: [
              iconTile,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFF7ECDD),
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFFD8CBB8),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _CategoryInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _CategoryInfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4B06A).withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFD4B06A).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: const Color(0xFFD4B06A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFFD8CBB8),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
