import 'package:flutter/material.dart';

import '../data/persons.dart';
import '../logic/game_session.dart';
import '../models/category.dart';
import '../models/person.dart';
import '../models/person_rarity.dart';
import '../models/person_status.dart';
import '../widgets/person_archive_card_dialog.dart';
import '../widgets/person_portrait.dart';

enum _CollectionSort { oldest, newest, rarity, name }

enum _CollectionEraFilter { all, ancient, earlyModern, industrial, modern }

class CollectionScreen extends StatefulWidget {
  final GameSession session;

  const CollectionScreen({super.key, required this.session});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  Category? _categoryFilter;
  PersonRarity? _rarityFilter;
  _CollectionEraFilter _eraFilter = _CollectionEraFilter.all;
  _CollectionSort _sort = _CollectionSort.oldest;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final unlockedCount = widget.session.unlockedPersons.length;
        final discoveredCount = widget.session.discoveredNotUnlocked.length;
        final hiddenCount = widget.session.undiscoveredCount();
        final visiblePersons = _buildVisiblePersons();
        final sections = _buildSections(visiblePersons);

        return Scaffold(
          backgroundColor: const Color(0xFF120B07),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFFF7ECDD),
            elevation: 0,
            title: const Text('Collection'),
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(
                    unlockedCount: unlockedCount,
                    discoveredCount: discoveredCount,
                    hiddenCount: hiddenCount,
                    shownCount: visiblePersons.length,
                  ),
                  const SizedBox(height: 12),
                  _buildFilterBar(shownCount: visiblePersons.length),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = (constraints.maxWidth / 180)
                            .floor()
                            .clamp(2, 5);
                        return CustomScrollView(
                          slivers: [
                            for (final section in sections) ...[
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _CollectionSectionHeader(
                                    title: _categoryLabel(section.category),
                                    count: section.persons.length,
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.only(bottom: 18),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 0.68,
                                      ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final person = section.persons[index];
                                    final status = _statusFor(person);
                                    return _CollectionCard(
                                      person: person,
                                      status: status,
                                      categoryLabel: _categoryLabel(
                                        person.category,
                                      ),
                                      rarityColor: _rarityColor(person.rarity),
                                      timeLabel: _timeLabel(person),
                                      onTap: () =>
                                          _showPersonCardDialog(person, status),
                                    );
                                  }, childCount: section.persons.length),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Person> _buildVisiblePersons() {
    final filtered = allPersons.where((person) {
      if (_categoryFilter != null && person.category != _categoryFilter) {
        return false;
      }
      if (_rarityFilter != null && person.rarity != _rarityFilter) {
        return false;
      }
      return _matchesEra(person);
    }).toList();

    return _sortPersons(filtered);
  }

  List<_CollectionSectionData> _buildSections(List<Person> persons) {
    final categories = _categoryFilter == null
        ? Category.values
        : <Category>[_categoryFilter!];
    final sections = <_CollectionSectionData>[];
    for (final category in categories) {
      final categoryPersons = persons
          .where((person) => person.category == category)
          .toList();
      if (categoryPersons.isEmpty) continue;
      sections.add(
        _CollectionSectionData(category: category, persons: categoryPersons),
      );
    }
    return sections;
  }

  List<Person> _sortPersons(List<Person> persons) {
    persons.sort((a, b) {
      final statusCompare = _statusRank(
        _statusFor(b),
      ).compareTo(_statusRank(_statusFor(a)));
      if (statusCompare != 0) return statusCompare;

      switch (_sort) {
        case _CollectionSort.oldest:
          return a.birthYear.compareTo(b.birthYear);
        case _CollectionSort.newest:
          return b.birthYear.compareTo(a.birthYear);
        case _CollectionSort.rarity:
          final rarityOrder = _rarityRank(
            b.rarity,
          ).compareTo(_rarityRank(a.rarity));
          return rarityOrder != 0
              ? rarityOrder
              : a.birthYear.compareTo(b.birthYear);
        case _CollectionSort.name:
          return a.name.compareTo(b.name);
      }
    });

    return persons;
  }

  PersonStatus _statusFor(Person person) {
    return widget.session.statusById[person.id] ?? PersonStatus.undiscovered;
  }

  int _statusRank(PersonStatus status) {
    switch (status) {
      case PersonStatus.unlocked:
        return 2;
      case PersonStatus.discovered:
        return 1;
      case PersonStatus.undiscovered:
        return 0;
    }
  }

  bool _matchesEra(Person person) {
    switch (_eraFilter) {
      case _CollectionEraFilter.all:
        return true;
      case _CollectionEraFilter.ancient:
        return person.birthYear < 1500;
      case _CollectionEraFilter.earlyModern:
        return person.birthYear >= 1500 && person.birthYear < 1800;
      case _CollectionEraFilter.industrial:
        return person.birthYear >= 1800 && person.birthYear < 1900;
      case _CollectionEraFilter.modern:
        return person.birthYear >= 1900;
    }
  }

  int _rarityRank(PersonRarity rarity) {
    switch (rarity) {
      case PersonRarity.common:
        return 0;
      case PersonRarity.rare:
        return 1;
      case PersonRarity.epic:
        return 2;
      case PersonRarity.legendary:
        return 3;
    }
  }

  Widget _buildHeaderSection({
    required int unlockedCount,
    required int discoveredCount,
    required int hiddenCount,
    required int shownCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your archive',
          style: TextStyle(
            color: Color(0xFFF7ECDD),
            fontWeight: FontWeight.w900,
            fontSize: 28,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Every figure stays visible in the archive, even before discovery.',
          style: TextStyle(
            color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatPill(
              label: '$unlockedCount unlocked',
              icon: Icons.lock_open_rounded,
              accent: const Color(0xFFD4B06A),
            ),
            _StatPill(
              label: '$discoveredCount discovered',
              icon: Icons.visibility_rounded,
              accent: const Color(0xFF8DC8FF),
            ),
            _StatPill(
              label: '$hiddenCount hidden',
              icon: Icons.help_outline_rounded,
              accent: const Color(0xFFE6D6BF),
            ),
            _StatPill(
              label: '$shownCount shown',
              icon: Icons.grid_view_rounded,
              accent: const Color(0xFFB98CFF),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.025),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Refine archive',
                  style: TextStyle(
                    color: Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _categoryFilter = null;
                    _rarityFilter = null;
                    _eraFilter = _CollectionEraFilter.all;
                    _sort = _CollectionSort.oldest;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD4B06A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text(
                  'Reset',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FilterRow(
            label: 'Sort',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChoiceChip(
                  label: 'Oldest',
                  selected: _sort == _CollectionSort.oldest,
                  onTap: () => setState(() => _sort = _CollectionSort.oldest),
                ),
                _ChoiceChip(
                  label: 'Newest',
                  selected: _sort == _CollectionSort.newest,
                  onTap: () => setState(() => _sort = _CollectionSort.newest),
                ),
                _ChoiceChip(
                  label: 'Rarity',
                  selected: _sort == _CollectionSort.rarity,
                  onTap: () => setState(() => _sort = _CollectionSort.rarity),
                ),
                _ChoiceChip(
                  label: 'Name',
                  selected: _sort == _CollectionSort.name,
                  onTap: () => setState(() => _sort = _CollectionSort.name),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _FilterRow(
            label: 'Category',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChoiceChip(
                  label: 'All',
                  selected: _categoryFilter == null,
                  onTap: () => setState(() => _categoryFilter = null),
                ),
                for (final category in Category.values)
                  _ChoiceChip(
                    label: _categoryLabel(category),
                    selected: _categoryFilter == category,
                    onTap: () => setState(() => _categoryFilter = category),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _FilterRow(
            label: 'Rarity',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChoiceChip(
                  label: 'All',
                  selected: _rarityFilter == null,
                  onTap: () => setState(() => _rarityFilter = null),
                ),
                for (final rarity in PersonRarity.values)
                  _ChoiceChip(
                    label: rarity.label,
                    selected: _rarityFilter == rarity,
                    onTap: () => setState(() => _rarityFilter = rarity),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _FilterRow(
            label: 'Era',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChoiceChip(
                  label: 'All time',
                  selected: _eraFilter == _CollectionEraFilter.all,
                  onTap: () =>
                      setState(() => _eraFilter = _CollectionEraFilter.all),
                ),
                _ChoiceChip(
                  label: 'Before 1500',
                  selected: _eraFilter == _CollectionEraFilter.ancient,
                  onTap: () =>
                      setState(() => _eraFilter = _CollectionEraFilter.ancient),
                ),
                _ChoiceChip(
                  label: '1500-1799',
                  selected: _eraFilter == _CollectionEraFilter.earlyModern,
                  onTap: () => setState(
                    () => _eraFilter = _CollectionEraFilter.earlyModern,
                  ),
                ),
                _ChoiceChip(
                  label: '1800-1899',
                  selected: _eraFilter == _CollectionEraFilter.industrial,
                  onTap: () => setState(
                    () => _eraFilter = _CollectionEraFilter.industrial,
                  ),
                ),
                _ChoiceChip(
                  label: '1900+',
                  selected: _eraFilter == _CollectionEraFilter.modern,
                  onTap: () =>
                      setState(() => _eraFilter = _CollectionEraFilter.modern),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar({required int shownCount}) {
    final activeFilters = _activeFilterCount;
    return InkWell(
      onTap: _showFilterSheet,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
              ),
              child: const Icon(Icons.tune_rounded, color: Color(0xFFD4B06A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters & sort',
                    style: TextStyle(
                      color: Color(0xFFF7ECDD),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeFilters == 0
                        ? '$shownCount figures shown'
                        : '$shownCount figures shown • $activeFilters active filters',
                    style: TextStyle(
                      color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (activeFilters > 0) ...[
                    Text(
                      '$activeFilters',
                      style: const TextStyle(
                        color: Color(0xFFD4B06A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFFF7ECDD),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int get _activeFilterCount {
    var count = 0;
    if (_categoryFilter != null) count++;
    if (_rarityFilter != null) count++;
    if (_eraFilter != _CollectionEraFilter.all) count++;
    if (_sort != _CollectionSort.oldest) count++;
    return count;
  }

  Future<void> _showFilterSheet() async {
    Category? tempCategory = _categoryFilter;
    PersonRarity? tempRarity = _rarityFilter;
    var tempEra = _eraFilter;
    var tempSort = _sort;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget chip({
              required String label,
              required bool selected,
              required VoidCallback onTap,
            }) {
              return _ChoiceChip(
                label: label,
                selected: selected,
                onTap: () => setModalState(onTap),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF17100B),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Refine archive',
                                style: TextStyle(
                                  color: Color(0xFFF7ECDD),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  tempCategory = null;
                                  tempRarity = null;
                                  tempEra = _CollectionEraFilter.all;
                                  tempSort = _CollectionSort.oldest;
                                });
                              },
                              child: const Text(
                                'Reset',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _FilterRow(
                          label: 'Sort',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              chip(
                                label: 'Oldest',
                                selected: tempSort == _CollectionSort.oldest,
                                onTap: () => tempSort = _CollectionSort.oldest,
                              ),
                              chip(
                                label: 'Newest',
                                selected: tempSort == _CollectionSort.newest,
                                onTap: () => tempSort = _CollectionSort.newest,
                              ),
                              chip(
                                label: 'Rarity',
                                selected: tempSort == _CollectionSort.rarity,
                                onTap: () => tempSort = _CollectionSort.rarity,
                              ),
                              chip(
                                label: 'Name',
                                selected: tempSort == _CollectionSort.name,
                                onTap: () => tempSort = _CollectionSort.name,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FilterRow(
                          label: 'Category',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              chip(
                                label: 'All',
                                selected: tempCategory == null,
                                onTap: () => tempCategory = null,
                              ),
                              for (final category in Category.values)
                                chip(
                                  label: _categoryLabel(category),
                                  selected: tempCategory == category,
                                  onTap: () => tempCategory = category,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FilterRow(
                          label: 'Rarity',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              chip(
                                label: 'All',
                                selected: tempRarity == null,
                                onTap: () => tempRarity = null,
                              ),
                              for (final rarity in PersonRarity.values)
                                chip(
                                  label: rarity.label,
                                  selected: tempRarity == rarity,
                                  onTap: () => tempRarity = rarity,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FilterRow(
                          label: 'Era',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              chip(
                                label: 'All time',
                                selected: tempEra == _CollectionEraFilter.all,
                                onTap: () => tempEra = _CollectionEraFilter.all,
                              ),
                              chip(
                                label: 'Before 1500',
                                selected:
                                    tempEra == _CollectionEraFilter.ancient,
                                onTap: () =>
                                    tempEra = _CollectionEraFilter.ancient,
                              ),
                              chip(
                                label: '1500-1799',
                                selected:
                                    tempEra == _CollectionEraFilter.earlyModern,
                                onTap: () =>
                                    tempEra = _CollectionEraFilter.earlyModern,
                              ),
                              chip(
                                label: '1800-1899',
                                selected:
                                    tempEra == _CollectionEraFilter.industrial,
                                onTap: () =>
                                    tempEra = _CollectionEraFilter.industrial,
                              ),
                              chip(
                                label: '1900+',
                                selected:
                                    tempEra == _CollectionEraFilter.modern,
                                onTap: () =>
                                    tempEra = _CollectionEraFilter.modern,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _categoryFilter = tempCategory;
                                _rarityFilter = tempRarity;
                                _eraFilter = tempEra;
                                _sort = tempSort;
                              });
                              Navigator.of(context).pop();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFD4B06A),
                              foregroundColor: const Color(0xFF22150D),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Apply filters',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _categoryLabel(Category category) {
    switch (category) {
      case Category.politician:
        return 'Leaders';
      case Category.scientist:
        return 'Scientists';
      case Category.artist:
        return 'Artists';
      case Category.athlete:
        return 'Athletes';
    }
  }

  Color _rarityColor(PersonRarity rarity) {
    switch (rarity) {
      case PersonRarity.common:
        return const Color(0xFFB6A58C);
      case PersonRarity.rare:
        return const Color(0xFF6BB2E4);
      case PersonRarity.epic:
        return const Color(0xFFD17FE7);
      case PersonRarity.legendary:
        return const Color(0xFFFFC55E);
    }
  }

  String _timeLabel(Person person) {
    if (person.birthYear < 0) {
      return '${person.birthYear.abs()} BCE';
    }
    return '${person.birthYear}';
  }

  Future<void> _showPersonCardDialog(Person person, PersonStatus status) async {
    await showPersonArchiveCardDialog(
      context: context,
      person: person,
      status: status,
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final Person person;
  final PersonStatus status;
  final String categoryLabel;
  final Color rarityColor;
  final String timeLabel;
  final VoidCallback? onTap;

  const _CollectionCard({
    required this.person,
    required this.status,
    required this.categoryLabel,
    required this.rarityColor,
    required this.timeLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHidden = status == PersonStatus.undiscovered;
    final isDiscovered = status == PersonStatus.discovered;
    final raritySpec = _raritySpec(person.rarity);
    final title = isHidden ? 'Unknown Figure' : person.name;
    final subtitle = isHidden ? 'Silhouette until discovered' : person.hint;
    final statusLabel = switch (status) {
      PersonStatus.unlocked => '',
      PersonStatus.discovered => 'Discovered',
      PersonStatus.undiscovered => 'Hidden',
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: isHidden
                ? [const Color(0xFF1B120D), const Color(0xFF110B08)]
                : raritySpec.surfaceColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isHidden
                ? Colors.white.withValues(alpha: 0.06)
                : raritySpec.borderColor.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: isHidden
                  ? Colors.black.withValues(alpha: 0.12)
                  : raritySpec.glowColor.withValues(alpha: 0.18),
              blurRadius: raritySpec.glowBlur,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  if (!isHidden)
                    Positioned(
                      top: -16,
                      right: -10,
                      child: IgnorePointer(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                raritySpec.glowColor.withValues(alpha: 0.18),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: PersonPortrait(
                        person: person,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 18,
                        obscured: isHidden,
                      ),
                    ),
                  ),
                  if (status != PersonStatus.unlocked)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color(0xCC1A120C),
                          border: Border.all(
                            color: isHidden
                                ? Colors.white.withValues(alpha: 0.10)
                                : rarityColor.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: isHidden
                                ? const Color(0xFFE6D6BF)
                                : rarityColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  if (isHidden)
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: Icon(
                            Icons.help_outline_rounded,
                            color: Color(0xFFF1E2CB),
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                  if (status == PersonStatus.unlocked)
                    Positioned(
                      right: 16,
                      bottom: 10,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.34),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: const Icon(
                          Icons.open_in_full_rounded,
                          color: Color(0xFFF7ECDD),
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF7ECDD),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MetaChip(label: person.rarity.label, color: rarityColor),
                      _MetaChip(
                        label: categoryLabel,
                        color: const Color(0xFFD4B06A),
                      ),
                      _MetaChip(
                        label: isDiscovered || !isHidden ? timeLabel : '???',
                        color: const Color(0xFFE6D6BF),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionPersonDialog extends StatefulWidget {
  final Person person;
  final PersonStatus status;
  final String categoryLabel;
  final Color rarityColor;
  final String timeLabel;

  const _CollectionPersonDialog({
    required this.person,
    required this.status,
    required this.categoryLabel,
    required this.rarityColor,
    required this.timeLabel,
  });

  @override
  State<_CollectionPersonDialog> createState() =>
      _CollectionPersonDialogState();
}

class _CollectionPersonDialogState extends State<_CollectionPersonDialog> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    final raritySpec = _raritySpec(person.rarity);
    final isHidden = widget.status == PersonStatus.undiscovered;
    final isDiscovered = widget.status == PersonStatus.discovered;
    final displayName = isHidden ? 'Unknown Figure' : person.name;
    final lifeLabel = isHidden
        ? '???'
        : person.deathYear == null
        ? widget.timeLabel
        : '${widget.timeLabel} - ${person.deathYear}';
    final placeLabel = isHidden
        ? '???'
        : person.birthPlaceLabel == null
        ? person.birthCountry
        : '${person.birthPlaceLabel}, ${person.birthCountry}';
    final countryLabel = isHidden ? '???' : person.birthCountry;
    final categoryLabel = isHidden ? '???' : widget.categoryLabel;
    final rarityLabel = isHidden ? 'Unknown' : person.rarity.label;
    final knownForText = isHidden
        ? 'Still hidden in your archive.'
        : person.hint;
    final helperText = _showBack
        ? 'Tap again to return to the VS card'
        : isHidden
        ? 'Tap the silhouette to inspect the sealed archive card'
        : isDiscovered
        ? 'Tap the card to flip it and inspect the figure'
        : 'Tap the card to flip it and view the full archive profile';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: GestureDetector(
        onTap: () => setState(() => _showBack = !_showBack),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: isHidden
                  ? [const Color(0xFF18100B), const Color(0xFF0E0906)]
                  : raritySpec.dialogColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: (isHidden ? Colors.black : raritySpec.glowColor)
                    .withValues(alpha: 0.24),
                blurRadius: raritySpec.glowBlur + 6,
                offset: const Offset(0, 16),
              ),
            ],
            border: Border.all(
              color: isHidden
                  ? Colors.white.withValues(alpha: 0.08)
                  : raritySpec.borderColor.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  transitionBuilder: (child, animation) {
                    final rotate = Tween<double>(
                      begin: 0.04,
                      end: 0,
                    ).animate(animation);
                    return AnimatedBuilder(
                      animation: rotate,
                      child: child,
                      builder: (context, child) {
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0012)
                            ..rotateY(rotate.value),
                          child: child,
                        );
                      },
                    );
                  },
                  child: _showBack
                      ? _CollectionBackCard(
                          key: const ValueKey('back'),
                          person: person,
                          isHidden: isHidden,
                          displayName: displayName,
                          categoryLabel: categoryLabel,
                          rarityColor: widget.rarityColor,
                          rarityLabel: rarityLabel,
                          lifeLabel: lifeLabel,
                          placeLabel: placeLabel,
                          countryLabel: countryLabel,
                          knownForText: knownForText,
                        )
                      : _CollectionFrontCard(
                          key: const ValueKey('front'),
                          person: person,
                          isHidden: isHidden,
                          displayName: displayName,
                          categoryLabel: categoryLabel,
                          rarityColor: widget.rarityColor,
                          lifeLabel: lifeLabel,
                          rarityLabel: rarityLabel,
                        ),
                ),
                const SizedBox(height: 14),
                Text(
                  helperText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionFrontCard extends StatelessWidget {
  final Person person;
  final bool isHidden;
  final String displayName;
  final String categoryLabel;
  final Color rarityColor;
  final String lifeLabel;
  final String rarityLabel;

  const _CollectionFrontCard({
    super.key,
    required this.person,
    required this.isHidden,
    required this.displayName,
    required this.categoryLabel,
    required this.rarityColor,
    required this.lifeLabel,
    required this.rarityLabel,
  });

  @override
  Widget build(BuildContext context) {
    final raritySpec = _raritySpec(person.rarity);
    return Container(
      height: 520,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: isHidden
              ? [const Color(0xFF21150E), const Color(0xFF17100B)]
              : raritySpec.cardFaceColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: (isHidden ? const Color(0xFFE6D6BF) : raritySpec.borderColor)
              .withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: (isHidden ? Colors.black : raritySpec.glowColor).withValues(
              alpha: 0.18,
            ),
            blurRadius: raritySpec.glowBlur,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PersonPortrait(
                      person: person,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 26,
                      variant: PersonImageVariant.vs,
                      obscured: isHidden,
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
                        gradient: LinearGradient(
                          colors: isHidden
                              ? [
                                  Colors.black.withValues(alpha: 0.42),
                                  Colors.black.withValues(alpha: 0.28),
                                ]
                              : [
                                  raritySpec.glowColor.withValues(alpha: 0.20),
                                  Colors.black.withValues(alpha: 0.34),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: isHidden
                              ? Colors.white.withValues(alpha: 0.08)
                              : raritySpec.borderColor.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Color(0xFFF8F0E3),
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: rarityColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$categoryLabel | $lifeLabel',
                                  style: const TextStyle(
                                    color: Color(0xFFF7ECDD),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  label: rarityLabel,
                  color: isHidden ? const Color(0xFFE6D6BF) : rarityColor,
                ),
                _MetaChip(
                  label: categoryLabel,
                  color: isHidden
                      ? const Color(0xFFE6D6BF)
                      : const Color(0xFFD4B06A),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionBackCard extends StatelessWidget {
  final Person person;
  final bool isHidden;
  final String displayName;
  final String categoryLabel;
  final Color rarityColor;
  final String rarityLabel;
  final String lifeLabel;
  final String placeLabel;
  final String countryLabel;
  final String knownForText;

  const _CollectionBackCard({
    super.key,
    required this.person,
    required this.isHidden,
    required this.displayName,
    required this.categoryLabel,
    required this.rarityColor,
    required this.rarityLabel,
    required this.lifeLabel,
    required this.placeLabel,
    required this.countryLabel,
    required this.knownForText,
  });

  @override
  Widget build(BuildContext context) {
    final raritySpec = _raritySpec(person.rarity);
    return Container(
      height: 520,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: isHidden
              ? [const Color(0xFF1A120D), const Color(0xFF110B08)]
              : raritySpec.cardBackColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: (isHidden ? const Color(0xFFE6D6BF) : raritySpec.borderColor)
              .withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: (isHidden ? Colors.black : raritySpec.glowColor).withValues(
              alpha: 0.16,
            ),
            blurRadius: raritySpec.glowBlur,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
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
                        displayName,
                        style: const TextStyle(
                          color: Color(0xFFF8F0E3),
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MetaChip(
                        label: rarityLabel,
                        color: isHidden ? const Color(0xFFE6D6BF) : rarityColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 64,
                  height: 84,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: isHidden
                          ? [
                              Colors.white.withValues(alpha: 0.04),
                              Colors.white.withValues(alpha: 0.02),
                            ]
                          : [
                              raritySpec.glowColor.withValues(alpha: 0.14),
                              Colors.white.withValues(alpha: 0.03),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: isHidden
                          ? Colors.white.withValues(alpha: 0.08)
                          : raritySpec.borderColor.withValues(alpha: 0.22),
                    ),
                  ),
                  child: PersonPortrait(
                    person: person,
                    width: 56,
                    height: 76,
                    borderRadius: 14,
                    obscured: isHidden,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Category', value: categoryLabel),
            _InfoRow(label: 'Years', value: lifeLabel),
            _InfoRow(label: 'Birthplace', value: placeLabel),
            _InfoRow(label: 'Country', value: countryLabel),
            const SizedBox(height: 14),
            const Text(
              'Known for',
              style: TextStyle(
                color: Color(0xFFD4B06A),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                knownForText,
                style: TextStyle(
                  color: const Color(0xFFD8CBB8).withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                'Tap to flip back',
                style: TextStyle(
                  color: const Color(0xFFD8CBB8).withValues(alpha: 0.76),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_RarityCardSpec _raritySpec(PersonRarity rarity) {
  switch (rarity) {
    case PersonRarity.common:
      return const _RarityCardSpec(
        surfaceColors: [Color(0xFF21150E), Color(0xFF16100C)],
        dialogColors: [Color(0xFF1B130E), Color(0xFF0F0A07)],
        cardFaceColors: [Color(0xFF2A1A11), Color(0xFF18100B)],
        cardBackColors: [Color(0xFF1C140F), Color(0xFF120C09)],
        borderColor: Color(0xFFB6A58C),
        glowColor: Color(0xFF7D6950),
        glowBlur: 20,
      );
    case PersonRarity.rare:
      return const _RarityCardSpec(
        surfaceColors: [Color(0xFF15202A), Color(0xFF12100B)],
        dialogColors: [Color(0xFF131D27), Color(0xFF0B0A08)],
        cardFaceColors: [Color(0xFF1A2F42), Color(0xFF12100B)],
        cardBackColors: [Color(0xFF142430), Color(0xFF100C09)],
        borderColor: Color(0xFF6BB2E4),
        glowColor: Color(0xFF3D82B8),
        glowBlur: 24,
      );
    case PersonRarity.epic:
      return const _RarityCardSpec(
        surfaceColors: [Color(0xFF24152B), Color(0xFF140D16)],
        dialogColors: [Color(0xFF201226), Color(0xFF0D090E)],
        cardFaceColors: [Color(0xFF37184A), Color(0xFF150D18)],
        cardBackColors: [Color(0xFF271536), Color(0xFF110B12)],
        borderColor: Color(0xFFD17FE7),
        glowColor: Color(0xFF9146AE),
        glowBlur: 28,
      );
    case PersonRarity.legendary:
      return const _RarityCardSpec(
        surfaceColors: [Color(0xFF322113), Color(0xFF17100B)],
        dialogColors: [Color(0xFF2A1B10), Color(0xFF0F0906)],
        cardFaceColors: [Color(0xFF503214), Color(0xFF1B120B)],
        cardBackColors: [Color(0xFF3A2511), Color(0xFF130C07)],
        borderColor: Color(0xFFFFC55E),
        glowColor: Color(0xFFE09A2A),
        glowBlur: 32,
      );
  }
}

class _RarityCardSpec {
  final List<Color> surfaceColors;
  final List<Color> dialogColors;
  final List<Color> cardFaceColors;
  final List<Color> cardBackColors;
  final Color borderColor;
  final Color glowColor;
  final double glowBlur;

  const _RarityCardSpec({
    required this.surfaceColors,
    required this.dialogColors,
    required this.cardFaceColors,
    required this.cardBackColors,
    required this.borderColor,
    required this.glowColor,
    required this.glowBlur,
  });
}

class _CollectionSectionData {
  final Category category;
  final List<Person> persons;

  const _CollectionSectionData({required this.category, required this.persons});
}

class _CollectionSectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _CollectionSectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFFD8CBB8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _FilterRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFFD8CBB8).withValues(alpha: 0.88),
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? const Color(0xFFD4B06A)
                : Colors.white.withValues(alpha: 0.035),
            border: Border.all(
              color: selected
                  ? const Color(0xFFD4B06A)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF22150D)
                  : const Color(0xFFF7ECDD),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;

  const _StatPill({
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: 0.10),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: accent == const Color(0xFFE6D6BF)
                  ? const Color(0xFFF7ECDD)
                  : accent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}
