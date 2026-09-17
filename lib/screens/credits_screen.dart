import 'package:flutter/material.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  static const List<_CreditEntry> _portraitCredits = [
    _CreditEntry(
      personName: 'Marta',
      credit: 'Ricardo Stuckert/PR, Palacio do Planalto (Brasilia, Brazil)',
    ),
    _CreditEntry(personName: 'Yuna Kim', credit: 'TV10'),
    _CreditEntry(
      personName: 'Sachin Tendulkar',
      credit: 'Flying Cloud from Australia',
      sourceUrl: 'https://www.flickr.com/people/38419041@N00',
    ),
    _CreditEntry(
      personName: 'Benazir Bhutto',
      credit: 'Sajjad Ali Qureshi',
      sourceUrl: 'https://www.flickr.com/people/34015932@N00',
    ),
    _CreditEntry(
      personName: 'Ashoka',
      credit: 'Chainwit',
      sourceUrl: 'https://commons.wikimedia.org/wiki/User:Chainwit.',
    ),
    _CreditEntry(
      personName: 'Tim Berners-Lee',
      credit: 'Enrique Dans and Template:Creator titoun',
      sourceUrl: 'https://www.flickr.com/people/16189770@N00',
    ),
    _CreditEntry(
      personName: 'Hammurabi',
      credit: 'Sailko',
      sourceUrl: 'https://commons.wikimedia.org/wiki/User:Sailko',
    ),
    _CreditEntry(
      personName: 'George Orwell',
      credit: 'Cassowary Colorizations',
    ),
    _CreditEntry(
      personName: 'Hayao Miyazaki',
      credit: 'Natasha Baucas and Oliver Ayala',
    ),
    _CreditEntry(
      personName: 'Golda Meir',
      credit: 'Dan Hadani',
      sourceUrl: 'https://www.wikidata.org/wiki/Q47446143',
    ),
    _CreditEntry(
      personName: 'Greta Thunberg',
      credit: 'Frankie Fouganthin and Stefan Muller',
    ),
    _CreditEntry(
      personName: 'Gabriel Garcia Marquez',
      credit: 'Gorup de Besanez and Jose Lara',
      sourceUrl: 'https://commons.wikimedia.org/wiki/User:Gorupdebesanez',
    ),
    _CreditEntry(
      personName: 'J.K. Rowling',
      credit: 'Daniel Ogren',
      sourceUrl: 'https://www.flickr.com/people/27077452@N04',
    ),
    _CreditEntry(personName: 'Kobe Bryant', credit: 'Gene Wang'),
    _CreditEntry(
      personName: 'Neymar',
      credit: 'Alex Fau',
      sourceUrl: 'https://www.flickr.com/people/77223879@N05',
    ),
    _CreditEntry(
      personName: 'Niels Bohr',
      credit:
          'Photograph by Emilio Segre, courtesy AIP Emilio Segre Visual Archives, Segre Collection',
    ),
    _CreditEntry(
      personName: 'Novak Djokovic',
      credit: 'Andrew Campbell',
      sourceUrl: 'https://www.flickr.com/people/44419774@N04',
    ),
    _CreditEntry(
      personName: 'Chris Hemsworth',
      credit: 'Melinda Seckington and MTV International',
      sourceUrl: 'https://www.flickr.com/people/8413322@N06',
    ),
    _CreditEntry(
      personName: 'Hugh Jackman',
      credit: 'Dick Thomas Johnson',
      sourceUrl: 'https://www.flickr.com/people/31029865@N06/',
    ),
    _CreditEntry(
      personName: 'Rafael Nadal',
      credit: 'Doha Stadium Plus Qatar / Vinod Divakaran',
      sourceUrl: 'https://www.flickr.com/people/dohastadiumplusqatar/',
    ),
    _CreditEntry(
      personName: 'Ronaldinho',
      credit: 'Rafael Amado Deras',
      sourceUrl: 'https://www.flickr.com/photos/28050552@N03',
    ),
    _CreditEntry(personName: 'Ronaldo Nazario', credit: 'Antonio Cruz / ABr'),
    _CreditEntry(personName: 'Steve Jobs', credit: 'Steve Jurvetson'),
    _CreditEntry(
      personName: 'Otto the Great',
      credit: 'Axel Mauruszat',
      sourceUrl: 'https://commons.wikimedia.org/wiki/User:Axel.Mauruszat',
    ),
    _CreditEntry(personName: 'Simone de Beauvoir', credit: 'aeneastudio'),
    _CreditEntry(
      personName: 'Spartacus',
      credit: 'Gautier Poupeau from Paris, France',
    ),
    _CreditEntry(
      personName: 'Zinedine Zidane',
      credit: 'Hadi Abyar and David Ruddell',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120B07),
      appBar: AppBar(
        backgroundColor: const Color(0xFF120B07),
        foregroundColor: const Color(0xFFF7ECDD),
        elevation: 0,
        title: const Text(
          'Credits',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              children: [
                Text(
                  'Portrait Credits',
                  style: TextStyle(
                    color: const Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Listed here are the portrait image credits currently noted in the asset sheet.',
                  style: TextStyle(
                    color: const Color(0xFFD8CBB8).withValues(alpha: 0.84),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                for (final entry in _portraitCredits) ...[
                  _CreditTile(entry: entry),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreditEntry {
  final String personName;
  final String credit;
  final String? sourceUrl;

  const _CreditEntry({
    required this.personName,
    required this.credit,
    this.sourceUrl,
  });
}

class _CreditTile extends StatelessWidget {
  final _CreditEntry entry;

  const _CreditTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B2418).withValues(alpha: 0.88),
            const Color(0xFF21120B).withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFD4B06A).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.personName,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            entry.credit,
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.94),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (entry.sourceUrl != null && entry.sourceUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              entry.sourceUrl!,
              style: TextStyle(
                color: const Color(0xFFD4B06A),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
