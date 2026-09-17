class FamousForQuiz {
  final String correct;
  final List<String> wrong;

  const FamousForQuiz({required this.correct, required this.wrong});
}

final Map<String, FamousForQuiz> famousForQuiz = {
  "caesar": FamousForQuiz(
    correct: "Conquering Gaul and reshaping the Roman Republic",
    wrong: [
      "Founding Athenian democracy and popular assemblies",
      "Opening Atlantic routes to the Americas",
      "Reuniting the eastern and western churches",
    ],
  ),
  "cleopatra": FamousForQuiz(
    correct: "Ruling Ptolemaic Egypt as its last active queen",
    wrong: [
      "Establishing the Roman Empire under one crown",
      "Leading Indian independence from British rule",
      "Defeating Napoleon at the Battle of Waterloo",
    ],
  ),
  "napoleon": FamousForQuiz(
    correct: "Building a French empire through the Napoleonic Wars",
    wrong: [
      "Leading the American colonies to independence",
      "Ending serfdom across the Russian Empire",
      "Discovering penicillin through laboratory research",
    ],
  ),
  "lincoln": FamousForQuiz(
    correct: "Leading the Union in the Civil War and ending slavery",
    wrong: [
      "Creating the United Nations after World War II",
      "Commanding the Spanish conquest of Mexico",
      "Directing the first successful moon landing",
    ],
  ),
  "merkel": FamousForQuiz(
    correct: "Serving for years as chancellor of modern Germany",
    wrong: [
      "Negotiating the reunification of North and South Korea",
      "Inventing the early architecture of the internet",
      "Sparking the upheaval of the French Revolution",
    ],
  ),
  "galileo": FamousForQuiz(
    correct: "Using astronomy to defend a Sun-centered cosmos",
    wrong: [
      "Explaining evolution through natural selection",
      "Revealing the double-helix structure of DNA",
      "Splitting the atom through nuclear physics",
    ],
  ),
  "newton": FamousForQuiz(
    correct: "Formulating the laws of motion and gravity",
    wrong: [
      "Uncovering radioactivity through chemical experiments",
      "Building the foundations of quantum mechanics",
      "Inventing the first practical telephone network",
    ],
  ),
  "darwin": FamousForQuiz(
    correct: "Explaining evolution through natural selection",
    wrong: [
      "Developing special and general relativity",
      "Isolating oxygen as a distinct chemical element",
      "Creating the first workable periodic table",
    ],
  ),
  "curie": FamousForQuiz(
    correct: "Pioneering the science of radioactivity",
    wrong: [
      "Describing universal gravitation and falling bodies",
      "Designing the first programmable computing machine",
      "Creating the first effective polio vaccine",
    ],
  ),
  "einstein": FamousForQuiz(
    correct: "Recasting physics with the theory of relativity",
    wrong: [
      "Inventing the compound microscope for science",
      "Revealing the double-helix structure of DNA",
      "Performing the first human heart transplant",
    ],
  ),
  "leonardo": FamousForQuiz(
    correct:
        "Creating Renaissance masterpieces while ranging across art and science",
    wrong: [
      "Composing landmark operas of the Classical era",
      "Charting the first European landfalls in Australia",
      "Engineering the steam engine for industrial use",
    ],
  ),
  "shakespeare": FamousForQuiz(
    correct: "Writing plays and sonnets that shaped English literature",
    wrong: [
      "Painting the ceiling of the Sistine Chapel",
      "Sailing the first successful circumnavigation of Earth",
      "Formulating the physics of special relativity",
    ],
  ),
  "mozart": FamousForQuiz(
    correct: "Composing landmark works of the Classical style",
    wrong: [
      "Perfecting movable type for mass printing",
      "Explaining continents through plate tectonics",
      "Ending apartheid through democratic leadership",
    ],
  ),
  "vangogh": FamousForQuiz(
    correct: "Painting vivid post-impressionist works such as Starry Night",
    wrong: [
      "Composing the Ninth Symphony for concert halls",
      "Discovering Neptune through mathematical astronomy",
      "Building republican institutions in ancient Rome",
    ],
  ),
  "kahlo": FamousForQuiz(
    correct: "Painting intense self-portraits rooted in Mexican identity",
    wrong: [
      "Inventing the technology behind motion pictures",
      "Opening Europe to the American continents",
      "Predicting black holes through modern cosmology",
    ],
  ),
  "owens": FamousForQuiz(
    correct: "Winning four gold medals at the 1936 Olympics",
    wrong: [
      "Setting the record for most tennis Grand Slam titles",
      "Claiming victory in the earliest Tour de France",
      "Inventing the rules of modern professional basketball",
    ],
  ),
  "ali": FamousForQuiz(
    correct: "Becoming an iconic heavyweight champion in boxing",
    wrong: [
      "Dominating the 100-meter sprint at world level",
      "Inventing the sport of indoor volleyball",
      "Collecting multiple Wimbledon singles titles",
    ],
  ),
  "pele": FamousForQuiz(
    correct: "Becoming one of football's greatest all-time stars",
    wrong: [
      "Dominating Olympic figure skating for a decade",
      "Inventing modern surfing as a competitive sport",
      "Winning multiple Formula 1 world championships",
    ],
  ),
  "jordan": FamousForQuiz(
    correct: "Becoming an NBA icon with the Chicago Bulls",
    wrong: [
      "Winning repeated Tour de France championships",
      "Collecting major titles in modern tennis",
      "Coaching Germany to a football world title",
    ],
  ),
  "serena": FamousForQuiz(
    correct: "Becoming one of the greatest players in tennis history",
    wrong: [
      "Winning Olympic gold across multiple swimming events",
      "Building a career as a world boxing champion",
      "Claiming repeated alpine skiing world titles",
    ],
  ),
  "churchill": FamousForQuiz(
    correct: "Leading Britain through the Second World War",
    wrong: [
      "Founding the NATO alliance after the war",
      "Negotiating India's independence from Britain",
      "Discovering radioactivity in laboratory research",
    ],
  ),
  "mandela": FamousForQuiz(
    correct: "Fighting apartheid and leading democratic South Africa",
    wrong: [
      "Unifying Germany after the Cold War divide",
      "Driving Napoleon's conquests across Europe",
      "Designing the first fully electronic computer",
    ],
  ),
  "gandhi": FamousForQuiz(
    correct: "Leading India's independence movement through nonviolence",
    wrong: [
      "Founding Pakistan as its first head of state",
      "Developing the physics of relativity",
      "Discovering insulin as a medical treatment",
    ],
  ),
  "roosevelt": FamousForQuiz(
    correct: "Guiding the United States through depression and world war",
    wrong: [
      "Ending the French monarchy during the Revolution",
      "Reaching the Americas on a transatlantic voyage",
      "Inventing the practical electric light bulb",
    ],
  ),
  "thatcher": FamousForQuiz(
    correct: "Transforming British politics as prime minister",
    wrong: [
      "Creating the euro as Europe's shared currency",
      "Conquering Egypt for the Roman Republic",
      "Inventing the World Wide Web for global use",
    ],
  ),
  "obama": FamousForQuiz(
    correct: "Serving as the forty-fourth president of the United States",
    wrong: [
      "Founding the European Union as a single state",
      "Discovering nuclear fission in atomic research",
      "Making the first ascent of Mount Everest",
    ],
  ),
  "tesla": FamousForQuiz(
    correct: "Advancing alternating current and electrical engineering",
    wrong: [
      "Explaining species change through evolution",
      "Developing movable type for printed books",
      "Carrying out the first successful heart surgery",
    ],
  ),
  "turing": FamousForQuiz(
    correct: "Laying foundations for computing and wartime codebreaking",
    wrong: [
      "Discovering penicillin in a medical laboratory",
      "Opening the age of crewed spaceflight",
      "Inventing the first silicon microchip",
    ],
  ),
  "lovelace": FamousForQuiz(
    correct: "Imagining early computer programming for analytical machines",
    wrong: [
      "Discovering radioactivity in modern chemistry",
      "Building the first telescope for astronomers",
      "Founding Microsoft as a software company",
    ],
  ),
  "hawking": FamousForQuiz(
    correct: "Exploring black holes and the origins of the cosmos",
    wrong: [
      "Discovering the electron in atomic experiments",
      "Inventing the telephone for long-distance speech",
      "Creating the first rabies vaccine in medicine",
    ],
  ),
  "franklin": FamousForQuiz(
    correct: "Providing key X-ray evidence for the structure of DNA",
    wrong: [
      "Discovering Uranus through telescope observation",
      "Inventing the first practical automobile engine",
      "Establishing plate tectonics in modern geology",
    ],
  ),
  "katherine_johnson": FamousForQuiz(
    correct: "Calculating trajectories for major NASA space missions",
    wrong: [
      "Inventing the internet as a digital network",
      "Designing the first atomic bomb project",
      "Discovering X-rays in experimental physics",
    ],
  ),
  "beethoven": FamousForQuiz(
    correct: "Composing major works that reshaped classical music",
    wrong: [
      "Inventing cinema as a visual storytelling medium",
      "Discovering the American continents for Europe",
      "Developing linear perspective in painting",
    ],
  ),
  "picasso": FamousForQuiz(
    correct: "Co-founding Cubism and remaking modern art",
    wrong: [
      "Composing the St Matthew Passion for church music",
      "Discovering heliocentrism through astronomy",
      "Conquering the Persian Empire in antiquity",
    ],
  ),
  "rembrandt": FamousForQuiz(
    correct: "Mastering portraiture in the Dutch Golden Age",
    wrong: [
      "Inventing photography as an artistic medium",
      "Composing The Four Seasons for violin",
      "Completing the first transatlantic airplane flight",
    ],
  ),
  "austen": FamousForQuiz(
    correct: "Writing novels such as Pride and Prejudice",
    wrong: [
      "Inventing the first practical typewriter design",
      "Discovering radium through chemical isolation",
      "Building the British Empire through naval conquest",
    ],
  ),
  "hemingway": FamousForQuiz(
    correct: "Writing novels in a spare and influential prose style",
    wrong: [
      "Discovering nuclear energy through physics research",
      "Composing major operas of the Baroque era",
      "Inventing television for household broadcasting",
    ],
  ),
  "michelangelo": FamousForQuiz(
    correct: "Creating Renaissance sculpture and the Sistine Chapel frescoes",
    wrong: [
      "Founding quantum physics as a modern science",
      "Discovering the deepest zones of the oceans",
      "Organizing the first Olympic Games in Greece",
    ],
  ),
  "bolt": FamousForQuiz(
    correct: "Setting world records in the 100 and 200 meters",
    wrong: [
      "Winning multiple world titles in heavyweight boxing",
      "Becoming a legendary champion in men's tennis",
      "Setting all-time records in the high jump",
    ],
  ),
  "messi": FamousForQuiz(
    correct: "Building one of the greatest careers in football history",
    wrong: [
      "Winning the Tour de France again and again",
      "Collecting Olympic gold medals in swimming",
      "Dominating Major League Baseball for decades",
    ],
  ),
  "ronaldo": FamousForQuiz(
    correct: "Becoming one of football's most prolific stars",
    wrong: [
      "Winning repeated world titles in boxing",
      "Collecting Formula 1 championships on the circuit",
      "Building a Hall of Fame career in basketball",
    ],
  ),
  "federer": FamousForQuiz(
    correct: "Becoming one of the greatest players in tennis history",
    wrong: [
      "Winning Olympic medals in elite rowing events",
      "Setting the standard in world sprint records",
      "Building a football career in top Spanish clubs",
    ],
  ),
  "biles": FamousForQuiz(
    correct: "Redefining gymnastics with extraordinary routines and titles",
    wrong: [
      "Collecting a record haul of Wimbledon trophies",
      "Winning world championships in Formula 1",
      "Setting long-standing records in marathon running",
    ],
  ),
  "comaneci": FamousForQuiz(
    correct: "Scoring the first perfect 10 in Olympic gymnastics",
    wrong: [
      "Breaking the two-hour barrier in women's marathon running",
      "Scoring the most goals ever at a football World Cup",
      "Inventing the modern discipline of artistic gymnastics",
    ],
  ),

  "washington": FamousForQuiz(
    correct:
        "Leading the American Revolution and becoming the first US president",
    wrong: [
      "Uniting France under Napoleon and reshaping Europe by conquest",
      "Leading the Soviet state through the upheaval of world war",
      "Founding a modern republic after the collapse of imperial China",
    ],
  ),
  "lenin": FamousForQuiz(
    correct: "Leading the Bolshevik Revolution and founding the Soviet state",
    wrong: [
      "Guiding the United States through the Civil War and emancipation",
      "Building the Fifth Republic after leading Free France in exile",
      "Creating a nonviolent independence movement against British rule",
    ],
  ),
  "mao": FamousForQuiz(
    correct: "Leading the Chinese Communist Revolution and founding the PRC",
    wrong: [
      "Uniting Germany through diplomacy and industrial modernization",
      "Leading nationalist forces in India to independence from Britain",
      "Driving the Russian Revolution from exile into a new Soviet regime",
    ],
  ),
  "degaulle": FamousForQuiz(
    correct:
        "Leading Free France in World War II and founding the Fifth Republic",
    wrong: [
      "Commanding the Red Army during the decisive battles of World War II",
      "Rebuilding Britain through social reform after the Victorian era",
      "Guiding the United States through depression and global war",
    ],
  ),
  "copernicus": FamousForQuiz(
    correct: "Placing the Sun at the center of the planetary system",
    wrong: [
      "Explaining gravity through universal laws of motion and force",
      "Revealing radioactivity through experiments on uranium compounds",
      "Discovering the structure of DNA with X-ray diffraction evidence",
    ],
  ),
  "kepler": FamousForQuiz(
    correct: "Formulating the laws of planetary motion around the Sun",
    wrong: [
      "Measuring the expansion of the universe through distant galaxies",
      "Developing the modern theory of natural selection and evolution",
      "Laying the foundations of electromagnetism through induction experiments",
    ],
  ),
  "pasteur": FamousForQuiz(
    correct: "Advancing germ theory, pasteurization, and early vaccines",
    wrong: [
      "Building the first workable theory of continental drift and oceans",
      "Discovering the electron and redefining the structure of the atom",
      "Creating the first programmable concepts for analytical machines",
    ],
  ),
  "faraday": FamousForQuiz(
    correct:
        "Transforming science with electromagnetism and electric induction",
    wrong: [
      "Developing the periodic table of the elements into modern form",
      "Explaining the inheritance of traits through pea plant experiments",
      "Inventing the transistor and opening the age of microelectronics",
    ],
  ),
  "monet": FamousForQuiz(
    correct: "Pioneering Impressionism with light-filled landscape painting",
    wrong: [
      "Defining Cubism through fractured forms and radical perspectives",
      "Painting surreal dreamscapes filled with melting clocks and symbols",
      "Creating grand Baroque frescoes across the ceilings of Europe",
    ],
  ),
  "dali": FamousForQuiz(
    correct: "Creating surrealist paintings filled with dreamlike symbolism",
    wrong: [
      "Launching Impressionism through shimmering outdoor studies of light",
      "Writing realist novels about Victorian poverty and social ambition",
      "Turning mass culture into Pop Art through celebrity imagery",
    ],
  ),
  "dickens": FamousForQuiz(
    correct: "Writing landmark novels about Victorian society and inequality",
    wrong: [
      "Composing operas and symphonies at the height of classical Vienna",
      "Painting water lilies and cathedrals in shifting natural light",
      "Transforming sculpture and fresco into icons of the Renaissance",
    ],
  ),
  "warhol": FamousForQuiz(
    correct: "Turning consumer culture and celebrity into Pop Art",
    wrong: [
      "Reinventing the modern novel through stream-of-consciousness prose",
      "Leading the Surrealist movement with dream imagery and distortion",
      "Building Impressionism through plein-air studies of atmosphere",
    ],
  ),
  "phelps": FamousForQuiz(
    correct: "Becoming the most decorated Olympian through swimming dominance",
    wrong: [
      "Winning more Formula 1 world titles than any driver before him",
      "Leading Argentina to football glory with genius and controversy",
      "Breaking sprint records over 100 and 200 meters on the track",
    ],
  ),
  "schumacher": FamousForQuiz(
    correct: "Winning seven Formula 1 world championships as a dominant driver",
    wrong: [
      "Collecting the largest medal haul in Olympic swimming history",
      "Revolutionizing tennis with record numbers of Grand Slam titles",
      "Becoming football's most dazzling playmaker of the twentieth century",
    ],
  ),
  "senna": FamousForQuiz(
    correct: "Becoming a legendary Formula 1 champion famed for raw speed",
    wrong: [
      "Dominating the Olympic pool with a record number of gold medals",
      "Setting a new standard for gymnastics with a perfect Olympic 10",
      "Winning football world titles as Brazil's most prolific striker",
    ],
  ),
  "maradona": FamousForQuiz(
    correct: "Captaining Argentina with genius to iconic football glory",
    wrong: [
      "Rewriting Formula 1 history with unmatched championship success",
      "Owning Olympic swimming with the biggest medal collection ever",
      "Transforming tennis through elegant all-court dominance for decades",
    ],
  ),

  "hatshepsut": FamousForQuiz(
    correct: "Ruling as a powerful female pharaoh during Egypt's New Kingdom",
    wrong: [
      "Leading Carthage against Rome by marching armies over the Alps",
      "Founding the Persian Empire through conquests across West Asia",
      "Defeating Napoleon and restoring conservative order in Europe",
    ],
  ),
  "elizabeth_i": FamousForQuiz(
    correct:
        "Ruling England through the Elizabethan age and the Spanish Armada",
    wrong: [
      "Uniting Castile and Aragon while sponsoring Columbus's voyages",
      "Building the Russian Empire through wide-ranging military expansion",
      "Leading France during revolution and crowning herself empress",
    ],
  ),
  "catherine_great": FamousForQuiz(
    correct:
        "Expanding and modernizing Russia as one of its greatest empresses",
    wrong: [
      "Defending Egypt against Caesar and Rome as the last Ptolemaic queen",
      "Guiding Germany through reunification after the Cold War decades",
      "Leading Britain in wartime speeches and coalition government",
    ],
  ),
  "suleiman": FamousForQuiz(
    correct: "Ruling the Ottoman Empire at the height of its power",
    wrong: [
      "Creating the first caliphate after the death of Muhammad",
      "Uniting Japan through shogunal rule after the Sengoku wars",
      "Conquering Persia and founding a new empire from Macedon",
    ],
  ),
  "ibn_sina": FamousForQuiz(
    correct: "Writing influential works on medicine and philosophy as Avicenna",
    wrong: [
      "Placing the Sun at the center of the planetary system",
      "Discovering penicillin and launching the antibiotic age",
      "Explaining radioactivity through experiments on uranium salts",
    ],
  ),
  "al_khwarizmi": FamousForQuiz(
    correct: "Laying foundations for algebra and the word algorithm",
    wrong: [
      "Creating the first accurate model of DNA's double helix structure",
      "Formulating the universal law of gravitation and motion",
      "Revealing black hole radiation through modern cosmology",
    ],
  ),
  "tu_youyou": FamousForQuiz(
    correct: "Discovering artemisinin and transforming malaria treatment",
    wrong: [
      "Inventing the first programmable computer for wartime codebreaking",
      "Developing the periodic table into a predictive chemical system",
      "Identifying the electron and reshaping atomic physics",
    ],
  ),
  "chien_shiung_wu": FamousForQuiz(
    correct: "Helping overturn parity conservation in experimental physics",
    wrong: [
      "Creating the first complete map of the human genome sequence",
      "Discovering planetary motion through careful telescope observations",
      "Founding microbiology with vaccines and pasteurization methods",
    ],
  ),
  "dante": FamousForQuiz(
    correct: "Writing The Divine Comedy, a cornerstone of world literature",
    wrong: [
      "Painting dreamlike surreal scenes with clocks and desert horizons",
      "Composing symphonies that defined the sound of classical Vienna",
      "Building Impressionism through water lilies and shifting light",
    ],
  ),
  "murasaki": FamousForQuiz(
    correct: "Writing The Tale of Genji in the court culture of Japan",
    wrong: [
      "Composing epic Sanskrit poems about war and sacred duty",
      "Leading Italian humanism through political treatises and satire",
      "Painting royal portraits that defined the Tudor image of power",
    ],
  ),
  "tagore": FamousForQuiz(
    correct: "Creating poetry and songs that made him a Nobel laureate",
    wrong: [
      "Reinventing modern theater with absurdist dialogue and silence",
      "Writing Victorian serial novels about debtors, orphans, and class",
      "Founding surrealism through manifestos and shocking exhibitions",
    ],
  ),
  "homer": FamousForQuiz(
    correct: "Being associated with the Iliad and the Odyssey",
    wrong: [
      "Writing courtly romances about Arthurian knights and quests",
      "Composing Greek tragedies about fate, kings, and prophecy",
      "Creating the Roman national epic that became the Aeneid",
    ],
  ),
  "marta": FamousForQuiz(
    correct: "Becoming one of the greatest players in women's football history",
    wrong: [
      "Winning repeated Olympic titles in figure skating with elegance",
      "Dominating marathon running with barefoot Olympic victories",
      "Collecting the most medals in Olympic swimming history",
    ],
  ),
  "yuna_kim": FamousForQuiz(
    correct: "Winning Olympic gold and redefining modern figure skating",
    wrong: [
      "Transforming women's football with unmatched World Cup scoring",
      "Becoming cricket's most revered batting icon over two decades",
      "Setting a new standard in long-distance running for Ethiopia",
    ],
  ),
  "tendulkar": FamousForQuiz(
    correct: "Becoming cricket's most celebrated batting legend",
    wrong: [
      "Leading Argentina to football glory with flair and controversy",
      "Winning multiple world titles as a Formula 1 driver from Brazil",
      "Rewriting swimming history with the largest Olympic medal haul",
    ],
  ),
  "abebe_bikila": FamousForQuiz(
    correct: "Winning Olympic marathons, including a famous barefoot victory",
    wrong: [
      "Dominating women's football with unmatched scoring records",
      "Turning figure skating into an era of near-perfect elegance",
      "Building cricket's most admired career with the bat",
    ],
  ),
  "alexander_great": FamousForQuiz(
    correct: "Conquering a vast empire from Greece to India at a young age",
    wrong: [
      "Uniting the Mongol tribes and creating the largest land empire in history",
      "Founding the Roman Empire as its first emperor after civil war",
      "Reforming Persia into a durable imperial bureaucracy",
    ],
  ),
  "genghis_khan": FamousForQuiz(
    correct:
        "Founding the Mongol Empire through conquest and tribal unification",
    wrong: [
      "Building a Hellenistic empire across the eastern Mediterranean",
      "Restoring Jerusalem to Muslim rule during the Crusades",
      "Creating the Yuan dynasty as ruler of all China",
    ],
  ),
  "augustus": FamousForQuiz(
    correct: "Becoming the first Roman emperor and stabilizing imperial rule",
    wrong: [
      "Overthrowing the Qin and building the Han dynasty in China",
      "Leading the conquests that spread Greek culture across Asia",
      "Codifying one of the earliest written legal systems in Babylon",
    ],
  ),
  "joan_of_arc": FamousForQuiz(
    correct: "Inspiring France in the Hundred Years' War as a teenage heroine",
    wrong: [
      "Leading England through naval victory over the Spanish Armada",
      "Defending Jerusalem as a queen during the Crusades",
      "Uniting Castile and Aragon under a shared monarchy",
    ],
  ),
  "mlk_jr": FamousForQuiz(
    correct: "Leading the American civil rights movement through nonviolence",
    wrong: [
      "Organizing the Cuban Revolution into a socialist state",
      "Negotiating South African democracy after apartheid rule",
      "Launching Indian independence through anti-colonial resistance",
    ],
  ),
  "alexander_fleming": FamousForQuiz(
    correct: "Discovering penicillin and opening the antibiotic era",
    wrong: [
      "Proving germs cause disease through vaccination research",
      "Describing the structure of DNA through X-ray evidence",
      "Explaining radioactivity with experiments on uranium salts",
    ],
  ),
  "bill_gates": FamousForQuiz(
    correct: "Co-founding Microsoft and shaping the personal computer age",
    wrong: [
      "Inventing the World Wide Web for the modern internet",
      "Building the first practical search engine for the web",
      "Designing the first social network to reach global scale",
    ],
  ),
  "grace_hopper": FamousForQuiz(
    correct:
        "Pioneering computer programming languages and software development",
    wrong: [
      "Revealing the structure of DNA through diffraction images",
      "Creating the first transistor for modern electronics",
      "Cracking Enigma and formalizing the Turing machine",
    ],
  ),
  "bruce_lee": FamousForQuiz(
    correct: "Becoming a martial arts icon and global action film star",
    wrong: [
      "Winning repeated world titles as a heavyweight boxing champion",
      "Popularizing skateboarding through gravity-defying tricks",
      "Dominating Formula 1 with unmatched speed in the wet",
    ],
  ),
  "ashoka": FamousForQuiz(
    correct: "Ruling the Maurya Empire and spreading Buddhism after conquest",
    wrong: [
      "Forging the Mughal Empire across northern India by force",
      "Driving the British from India through mass civil disobedience",
      "Founding the Delhi Sultanate through military invasion",
    ],
  ),
  "tim_berners_lee": FamousForQuiz(
    correct: "Inventing the World Wide Web and its core standards",
    wrong: [
      "Building the first mass-market personal computer operating system",
      "Co-founding the largest social media network of the 2000s",
      "Creating the earliest general-purpose search engine",
    ],
  ),
  "saladin": FamousForQuiz(
    correct: "Retaking Jerusalem and leading Muslim resistance in the Crusades",
    wrong: [
      "Launching the Mongol invasions that shattered Eurasian kingdoms",
      "Uniting England after the Norman conquest of 1066",
      "Driving Napoleon from Spain during the Peninsular War",
    ],
  ),
  "john_f_kennedy": FamousForQuiz(
    correct:
        "Serving as U.S. president during the Cold War and Cuban Missile Crisis",
    wrong: [
      "Leading the United States through the Great Depression and World War II",
      "Rebuilding Europe with the Marshall Plan after World War II",
      "Ending segregation through Supreme Court constitutional rulings",
    ],
  ),
  "malala": FamousForQuiz(
    correct:
        "Advocating girls' education worldwide after surviving extremist violence",
    wrong: [
      "Negotiating Pakistan's first democratic constitution after partition",
      "Leading Bangladesh to independence through wartime diplomacy",
      "Creating a global vaccination campaign through public health reform",
    ],
  ),
  "confucius": FamousForQuiz(
    correct: "Teaching a moral and political philosophy that shaped East Asia",
    wrong: [
      "Writing the military strategy classic The Art of War",
      "Founding Legalism as the doctrine of harsh state power",
      "Uniting China as its first emperor under the Qin",
    ],
  ),
  "johann_sebastian_bach": FamousForQuiz(
    correct: "Composing masterworks that defined the height of Baroque music",
    wrong: [
      "Revolutionizing opera in Vienna during the Classical era",
      "Writing symphonies that bridged Classicism and Romanticism",
      "Creating nationalist ballets for imperial Russia",
    ],
  ),
  "hammurabi": FamousForQuiz(
    correct: "Issuing one of the earliest famous written law codes",
    wrong: [
      "Founding the Persian Empire through conquest and tolerance",
      "Establishing Roman imperial rule after the fall of the Republic",
      "Writing Greek philosophy in the dialogues of Athens",
    ],
  ),
  "qin_shi_huang": FamousForQuiz(
    correct: "Unifying China as its first emperor under the Qin dynasty",
    wrong: [
      "Founding the Han dynasty after the collapse of Qin rule",
      "Leading Buddhist expansion across the Maurya Empire",
      "Turning Japanese warlords into a Tokugawa shogunate",
    ],
  ),
  "simon_bolivar": FamousForQuiz(
    correct: "Leading independence movements across much of South America",
    wrong: [
      "Uniting Italy through diplomacy and war in the nineteenth century",
      "Ending colonial rule in Mexico with agrarian revolution",
      "Driving the Ottomans from Greece in a nationalist uprising",
    ],
  ),
  "rosa_parks": FamousForQuiz(
    correct: "Becoming a symbol of civil rights by refusing bus segregation",
    wrong: [
      "Leading the suffrage movement to secure voting rights in Britain",
      "Organizing labor strikes that created the American weekend",
      "Breaking barriers as the first woman in space",
    ],
  ),
  "theodore_roosevelt": FamousForQuiz(
    correct:
        "Serving as a reforming U.S. president focused on conservation and trust-busting",
    wrong: [
      "Directing American strategy in World War II from the White House",
      "Launching the New Deal to combat economic collapse",
      "Writing the Constitution as the first U.S. chief justice",
    ],
  ),
  "alhazen": FamousForQuiz(
    correct:
        "Advancing optics and scientific inquiry in the medieval Islamic world",
    wrong: [
      "Founding algebra as a symbolic branch of mathematics",
      "Placing Earth among planets orbiting the Sun",
      "Explaining gravity and motion with universal laws",
    ],
  ),
  "hypatia": FamousForQuiz(
    correct: "Teaching mathematics and philosophy in late antique Alexandria",
    wrong: [
      "Writing Roman comedies for the public stage",
      "Defending Carthage against Rome in the Punic Wars",
      "Governing Egypt as the last active Ptolemaic queen",
    ],
  ),
  "george_orwell": FamousForQuiz(
    correct:
        "Writing political novels such as Animal Farm and Nineteen Eighty-Four",
    wrong: [
      "Creating modernist stream-of-consciousness through Mrs Dalloway",
      "Shaping Victorian fiction with Oliver Twist and Bleak House",
      "Defining magical realism in One Hundred Years of Solitude",
    ],
  ),
  "hayao_miyazaki": FamousForQuiz(
    correct: "Creating beloved animated films such as Spirited Away and Totoro",
    wrong: [
      "Reinventing live-action science fiction with 2001 and Alien",
      "Building Hollywood musicals around golden-age choreography",
      "Directing crime epics that defined the New Hollywood era",
    ],
  ),
  "cyrus_great": FamousForQuiz(
    correct:
        "Founding the Persian Empire through conquest and imperial statecraft",
    wrong: [
      "Unifying China under the first imperial dynasty of Qin",
      "Creating the Mongol Empire from the Eurasian steppe",
      "Defending Greece against Persian invasion at Thermopylae",
    ],
  ),
  "sun_tzu": FamousForQuiz(
    correct:
        "Being associated with The Art of War and enduring military strategy",
    wrong: [
      "Teaching ethics and government through the Analects",
      "Founding Taoist philosophy through the Tao Te Ching",
      "Designing the first Chinese imperial civil service exams",
    ],
  ),
  "amelia_earhart": FamousForQuiz(
    correct: "Breaking aviation barriers as a pioneering female pilot",
    wrong: [
      "Flying the first airplane at Kitty Hawk with her brother",
      "Crossing the Atlantic alone in the Spirit of St. Louis",
      "Launching the first woman-led space mission into orbit",
    ],
  ),
  'marco_polo': FamousForQuiz(
    correct:
        'Travelling to China and inspiring Europe with tales of the Far East',
    wrong: [
      'Discovering the sea route from Europe to India around Africa',
      'Leading the first expedition to circumnavigate the globe',
      'Charting the coasts of Australia and the Pacific for Britain',
    ],
  ),
  'columbus': FamousForQuiz(
    correct: 'Reaching the Americas in 1492 while sailing west for Spain',
    wrong: [
      'Completing the first circumnavigation of the Earth by sea',
      'Discovering the sea route to India around the Cape of Good Hope',
      'Mapping the Pacific and claiming Australia for the British crown',
    ],
  ),
  'magellan': FamousForQuiz(
    correct: 'Leading the first expedition to circumnavigate the globe',
    wrong: [
      'Reaching the Americas while sailing west from Spain',
      'Opening the sea route to Asia by rounding the Cape of Good Hope',
      'Charting the coasts of New Zealand and eastern Australia',
    ],
  ),
  'james_cook': FamousForQuiz(
    correct:
        'Charting the Pacific and making first European contact with eastern Australia',
    wrong: [
      'Reaching the Americas in the name of the Spanish crown',
      'Completing the first solo circumnavigation of the globe',
      'Mapping the trade routes to China overland from Venice',
    ],
  ),
  "fidel_castro": FamousForQuiz(
    correct: "Leading the Cuban Revolution and ruling Cuba for decades",
    wrong: [
      "Toppling apartheid and becoming South Africa's president",
      "Guiding Mexico after the revolution into constitutional reform",
      "Founding the People's Republic of China after civil war",
    ],
  ),
  "golda_meir": FamousForQuiz(
    correct:
        "Serving as one of Israel's early prime ministers during a tense era",
    wrong: [
      "Founding Pakistan as its first civilian female leader",
      "Leading India to victory in the Kargil conflict",
      "Becoming the first female president of postwar Germany",
    ],
  ),
  "greta_thunberg": FamousForQuiz(
    correct: "Becoming a global voice for climate activism as a teenager",
    wrong: [
      "Negotiating the Paris Agreement as a United Nations chief",
      "Inventing a low-cost solar panel for rural electrification",
      "Leading Greenpeace as its youngest-ever executive director",
    ],
  ),
  "elon_musk": FamousForQuiz(
    correct: "Leading companies such as Tesla and SpaceX in tech and space",
    wrong: [
      "Co-founding Microsoft and shaping the PC software era",
      "Inventing the World Wide Web for the internet age",
      "Building Amazon into a giant of retail and cloud computing",
    ],
  ),
  "erwin_schrodinger": FamousForQuiz(
    correct: "Helping shape quantum mechanics, including the wave equation",
    wrong: [
      "Discovering radioactivity through pioneering chemistry research",
      "Proving the heliocentric model through telescope observations",
      "Building modern genetics from inheritance experiments on peas",
    ],
  ),
  "hedy_lamarr": FamousForQuiz(
    correct:
        "Becoming a film star while co-inventing frequency-hopping technology",
    wrong: [
      "Designing the first programmable digital computer in wartime",
      "Inventing the transistor and launching modern electronics",
      "Building the Apollo guidance computer for lunar missions",
    ],
  ),
  "lebron": FamousForQuiz(
    correct: "Building one of the greatest careers in basketball history",
    wrong: [
      "Dominating football with World Cup wins and Ballon d'Or records",
      "Rewriting Olympic sprinting with world-record speed",
      "Collecting Grand Slam titles across two decades in tennis",
    ],
  ),
  "hitler": FamousForQuiz(
    correct: "Leading Nazi Germany and starting World War II in Europe",
    wrong: [
      "Founding the Soviet Union through the Bolshevik Revolution",
      "Ruling Italy as its fascist dictator during World War II",
      "Directing Japan's imperial expansion across the Pacific",
    ],
  ),
  "benazir_bhutto": FamousForQuiz(
    correct: "Serving as Pakistan's first female prime minister",
    wrong: [
      "Leading India through decades of post-independence politics",
      "Becoming Israel's first female head of government",
      "Founding Bangladesh and serving as its first leader",
    ],
  ),
  "antoine_lavoisier": FamousForQuiz(
    correct: "Naming oxygen and transforming chemistry into a modern science",
    wrong: [
      "Discovering radioactivity through experiments on uranium ore",
      "Building the first working steam engine for industry",
      "Explaining gravity through universal laws of motion",
    ],
  ),
  "averroes": FamousForQuiz(
    correct:
        "Commenting on Aristotle and bridging Islamic and European philosophy",
    wrong: [
      "Writing the foundational text of Islamic law and theology",
      "Discovering algebra and the concept of algorithms",
      "Building the heliocentric model of the solar system",
    ],
  ),
  "blaise_pascal": FamousForQuiz(
    correct:
        "Advancing probability theory and fluid mechanics in seventeenth-century France",
    wrong: [
      "Developing the laws of universal gravitation and motion",
      "Founding modern electromagnetism through induction experiments",
      "Creating the first periodic classification of the elements",
    ],
  ),
  "marcus_aurelius": FamousForQuiz(
    correct:
        "Ruling Rome as a philosopher-emperor and writing Stoic meditations",
    wrong: [
      "Establishing Rome as an empire after defeating Mark Antony",
      "Codifying the first great set of Roman laws and statutes",
      "Conquering the eastern Mediterranean from Macedon to Egypt",
    ],
  ),
  "carl_friedrich_gauss": FamousForQuiz(
    correct:
        "Making revolutionary contributions to mathematics across nearly every branch",
    wrong: [
      "Explaining planetary motion through elliptical orbit laws",
      "Founding modern chemistry by identifying oxygen and mass conservation",
      "Developing the periodic table as a system for all elements",
    ],
  ),
  "emmy_noether": FamousForQuiz(
    correct:
        "Transforming abstract algebra and connecting symmetry to conservation laws",
    wrong: [
      "Discovering radioactivity through experiments on pitchblende",
      "Proving the double helix structure of DNA with X-ray images",
      "Developing the germ theory of disease through vaccination research",
    ],
  ),
  "john_von_neumann": FamousForQuiz(
    correct:
        "Shaping modern computing, game theory, and mathematics as a polymath",
    wrong: [
      "Inventing the World Wide Web and its underlying protocols",
      "Laying the foundations of computer programming languages",
      "Discovering quantum electrodynamics through particle physics",
    ],
  ),
  "otto_von_bismarck": FamousForQuiz(
    correct:
        "Unifying Germany through diplomacy and war as the Iron Chancellor",
    wrong: [
      "Founding the Austro-Hungarian Empire through strategic marriages",
      "Leading unified Italy after driving out foreign powers",
      "Building the Second French Empire under Napoleon III",
    ],
  ),
  "sigmund_freud": FamousForQuiz(
    correct: "Founding psychoanalysis and exploring the unconscious mind",
    wrong: [
      "Defining behaviorism through experiments on stimulus and response",
      "Creating the first cognitive model of human memory and learning",
      "Discovering the chemical basis of nerve signals and synapses",
    ],
  ),
  "frederic_chopin": FamousForQuiz(
    correct: "Composing nocturnes, preludes, and études for the piano",
    wrong: [
      "Writing operas that defined the Romantic era of Italian music",
      "Completing the Ninth Symphony while deaf and in poor health",
      "Inventing jazz piano through improvisation in New Orleans",
    ],
  ),
  "aristotle": FamousForQuiz(
    correct:
        "Writing on philosophy, logic, science, and ethics in ancient Greece",
    wrong: [
      "Founding the Athenian democracy through constitutional reform",
      "Writing the Republic as the founding text of political philosophy",
      "Teaching the Stoic philosophy of reason and acceptance",
    ],
  ),
  "che_guevara": FamousForQuiz(
    correct: "Becoming a global icon of revolution through guerrilla warfare",
    wrong: [
      "Leading the Cuban Revolution alone from the Sierra Maestra",
      "Organizing the independence of Venezuela and Colombia",
      "Founding the Bolivarian Alliance as a socialist bloc",
    ],
  ),
  "mikhail_gorbachev": FamousForQuiz(
    correct:
        "Reforming the Soviet Union and overseeing the end of the Cold War",
    wrong: [
      "Founding the Soviet Union after the Bolshevik Revolution",
      "Leading Russia through the invasion of Afghanistan in 1979",
      "Creating the Warsaw Pact as a Soviet military alliance",
    ],
  ),
  "boudicca": FamousForQuiz(
    correct: "Leading a Celtic uprising against Roman occupation in Britain",
    wrong: [
      "Defending Carthage against Roman invasion in the Punic Wars",
      "Uniting the Scottish clans against English rule at Bannockburn",
      "Commanding Viking raids across northern Europe and beyond",
    ],
  ),
  "chandragupta_maurya": FamousForQuiz(
    correct:
        "Founding the Maurya Empire and unifying most of the Indian subcontinent",
    wrong: [
      "Spreading Buddhism across Asia after conquering much of India",
      "Founding the Mughal Empire after a victory at Panipat",
      "Driving the British from India through mass civil disobedience",
    ],
  ),
  "cicero": FamousForQuiz(
    correct:
        "Mastering Roman oratory and defending the Republic against tyranny",
    wrong: [
      "Writing the founding laws and constitution of the Roman Republic",
      "Commanding the armies of Rome during the Punic Wars",
      "Building Rome's infrastructure as the first emperor",
    ],
  ),
  "cleisthenes": FamousForQuiz(
    correct:
        "Laying the foundations of Athenian democracy through political reforms",
    wrong: [
      "Writing the Athenian code of law to replace blood feuds",
      "Teaching philosophy through the Socratic method in Athens",
      "Leading Athens to naval victory at the Battle of Salamis",
    ],
  ),
  "darius_i": FamousForQuiz(
    correct:
        "Expanding the Persian Empire and building its administrative system",
    wrong: [
      "Founding the Achaemenid Persian Empire through conquest",
      "Creating the first Persian legal code based on divine law",
      "Launching the final Persian invasion that destroyed Athens",
    ],
  ),
  "james_watt": FamousForQuiz(
    correct: "Improving the steam engine and driving the Industrial Revolution",
    wrong: [
      "Inventing the locomotive and laying the first railway tracks",
      "Discovering electricity through experiments with lightning",
      "Building the first factory system for textile production",
    ],
  ),
  "elvis_presley": FamousForQuiz(
    correct: "Defining rock and roll and becoming the King of Rock and Roll",
    wrong: [
      "Creating Motown soul music and launching a legendary label",
      "Inventing hip-hop through breakbeats and rap in the Bronx",
      "Writing the guitar riffs that launched the British Invasion",
    ],
  ),
  "friedrich_schiller": FamousForQuiz(
    correct: "Writing plays and poetry that shaped German Romantic literature",
    wrong: [
      "Writing Faust and defining German Weimar Classicism alone",
      "Composing the Romantic symphonies and lieder of Vienna",
      "Painting the battle scenes of the Napoleonic era",
    ],
  ),
  "fyodor_dostoevsky": FamousForQuiz(
    correct: "Writing psychological novels such as Crime and Punishment",
    wrong: [
      "Writing epic novels about Russian society like War and Peace",
      "Creating satirical plays and stories about Tsarist corruption",
      "Composing operas that defined nineteenth-century Russian music",
    ],
  ),
  "gabriel_garcia_marquez": FamousForQuiz(
    correct: "Creating magical realism with One Hundred Years of Solitude",
    wrong: [
      "Writing political poetry and love verse as a Chilean Nobel laureate",
      "Defining the Latin American boom with a comic novel of dictatorship",
      "Writing realist fiction about the violence of Colombian politics",
    ],
  ),
  "jk_rowling": FamousForQuiz(
    correct: "Creating the Harry Potter fantasy series beloved worldwide",
    wrong: [
      "Writing the His Dark Materials trilogy for young adult readers",
      "Creating the Narnia series as a Christian fantasy allegory",
      "Inventing the Discworld universe of satirical fantasy novels",
    ],
  ),
  "han_wudi": FamousForQuiz(
    correct: "Expanding Han China and establishing Silk Road trade connections",
    wrong: [
      "Founding the Han dynasty after the collapse of Qin rule",
      "Unifying China as its first emperor under a single dynasty",
      "Introducing Buddhism to China from the Indian subcontinent",
    ],
  ),
  "hannibal_barca": FamousForQuiz(
    correct:
        "Leading Carthage against Rome by crossing the Alps with war elephants",
    wrong: [
      "Defeating Hannibal at Zama to save Rome from destruction",
      "Founding Carthage and building its North African trade empire",
      "Commanding the Greek fleets against Persia at Salamis",
    ],
  ),
  "henry_viii": FamousForQuiz(
    correct:
        "Breaking from Rome to create the Church of England and ruling Tudor England",
    wrong: [
      "Translating the Bible into English and founding Protestantism",
      "Uniting the Wars of the Roses by founding the Tudor dynasty",
      "Defeating the Spanish Armada and making England a sea power",
    ],
  ),
  "ho_chi_minh": FamousForQuiz(
    correct:
        "Leading the Vietnamese independence movement against France and the United States",
    wrong: [
      "Unifying North and South Korea as a single nation",
      "Leading Cambodia through independence and into civil war",
      "Founding the Communist Party of China in the 1920s",
    ],
  ),
  "joseph_stalin": FamousForQuiz(
    correct:
        "Ruling the Soviet Union through industrialization, purges, and World War II",
    wrong: [
      "Leading the Bolshevik Revolution that ended Tsarist Russia",
      "Creating the Warsaw Pact and the Cold War military bloc",
      "Building the Berlin Wall to divide East and West Germany",
    ],
  ),
  "james_watson": FamousForQuiz(
    correct: "Co-discovering the double helix structure of DNA",
    wrong: [
      "Providing the X-ray crystallography evidence for DNA structure",
      "Decoding the human genome through the Human Genome Project",
      "Discovering the chemical signals that regulate gene expression",
    ],
  ),
  "jeff_bezos": FamousForQuiz(
    correct:
        "Founding Amazon and building it into a global e-commerce and tech giant",
    wrong: [
      "Co-founding Microsoft and shaping the PC software era",
      "Creating Google search and building the world's largest ad business",
      "Founding Tesla and leading the shift to electric vehicles",
    ],
  ),
  "immanuel_kant": FamousForQuiz(
    correct:
        "Writing foundational works on ethics, reason, and the limits of knowledge",
    wrong: [
      "Developing social contract theory as the basis of modern democracy",
      "Founding empiricist philosophy through natural observation",
      "Creating utilitarian ethics based on the greatest happiness",
    ],
  ),
  "jean_jacques_rousseau": FamousForQuiz(
    correct:
        "Developing social contract theory and inspiring the ideals of the French Revolution",
    wrong: [
      "Writing the foundational text of modern liberal economics",
      "Founding rationalist philosophy with the idea of the thinking self",
      "Creating Enlightenment satire to mock the Catholic Church",
    ],
  ),
  "goethe": FamousForQuiz(
    correct: "Writing Faust and shaping German literature in the Classical era",
    wrong: [
      "Composing Romantic symphonies that defined the Vienna circle",
      "Writing philosophical plays about freedom and moral duty",
      "Founding Impressionist poetry through emotional landscape verse",
    ],
  ),
  "kobe": FamousForQuiz(
    correct: "Winning five NBA championships with the Los Angeles Lakers",
    wrong: [
      "Leading the Chicago Bulls to six NBA titles with Michael Jordan",
      "Building a historic career in the NBA with the Boston Celtics",
      "Winning Olympic gold medals in basketball across three Games",
    ],
  ),
  "fibonacci": FamousForQuiz(
    correct:
        "Helping spread Hindu-Arabic numerals and his famous number sequence in Europe",
    wrong: [
      "Inventing algebra and introducing the concept of zero to Europe",
      "Creating the first mathematical tables of trigonometry",
      "Building the foundations of probability and statistics",
    ],
  ),
  "indira_gandhi": FamousForQuiz(
    correct:
        "Dominating Indian politics as prime minister through years of decisive rule",
    wrong: [
      "Leading India to independence from Britain through nonviolent resistance",
      "Founding Pakistan as the first independent Islamic republic",
      "Serving as India's first female president immediately after independence",
    ],
  ),
  "john_locke": FamousForQuiz(
    correct:
        "Developing liberal philosophy based on natural rights and government by consent",
    wrong: [
      "Founding empiricism through skepticism about the external world",
      "Creating utilitarian ethics focused on the greatest social happiness",
      "Developing rationalist philosophy through mathematics and doubt",
    ],
  ),
  "max_planck": FamousForQuiz(
    correct:
        "Founding quantum theory by discovering that energy comes in discrete quanta",
    wrong: [
      "Describing the quantum model of the atom with electron orbits",
      "Explaining quantum mechanics through the uncertainty principle",
      "Developing wave mechanics as an alternative to matrix formulations",
    ],
  ),
  "michael_jackson": FamousForQuiz(
    correct: "Becoming a global pop icon as the King of Pop",
    wrong: [
      "Inventing rock and roll as its first African American star",
      "Creating hip-hop culture through DJing and breakdancing",
      "Founding Motown Records and defining soul music for decades",
    ],
  ),
  "mike_tyson": FamousForQuiz(
    correct:
        "Becoming the youngest ferocious world heavyweight boxing champion",
    wrong: [
      "Winning multiple Olympic gold medals in amateur boxing",
      "Building a long career as a dominant light heavyweight champion",
      "Defeating the greatest names of the golden age of boxing",
    ],
  ),
  "neymar": FamousForQuiz(
    correct: "Starring as one of Brazil's most gifted and famous footballers",
    wrong: [
      "Winning the World Cup for Brazil as its greatest striker",
      "Becoming the first Brazilian to win the Ballon d'Or award",
      "Leading Argentina to multiple Copa América victories",
    ],
  ),
  "nicole_kidman": FamousForQuiz(
    correct:
        "Building an acclaimed Hollywood career with Oscar-winning performances",
    wrong: [
      "Becoming Australia's most successful singer and pop star",
      "Directing blockbuster films from the Marvel Cinematic Universe",
      "Founding a production company that changed Australian cinema",
    ],
  ),
  "niels_bohr": FamousForQuiz(
    correct:
        "Developing the atomic model and contributing to modern quantum physics",
    wrong: [
      "Founding quantum mechanics through the uncertainty principle",
      "Discovering the electron and the structure of the atom",
      "Building the first nuclear reactor during World War II",
    ],
  ),
  "djokovic": FamousForQuiz(
    correct:
        "Becoming the all-time record holder for Grand Slam singles titles in men's tennis",
    wrong: [
      "Winning the most consecutive Wimbledon titles in tennis history",
      "Dominating professional tennis through clay-court supremacy alone",
      "Building a legendary doubles partnership at the top of tennis",
    ],
  ),
  "pablo_neruda": FamousForQuiz(
    correct:
        "Writing love poetry and political verse as a Nobel Prize-winning Chilean poet",
    wrong: [
      "Creating magical realism in Colombian novels and short stories",
      "Writing epic poems of Aztec and Mayan history in Mexico",
      "Founding the Spanish surrealist poetry movement in the 1920s",
    ],
  ),
  "plato": FamousForQuiz(
    correct:
        "Writing philosophical dialogues that defined Western thought for centuries",
    wrong: [
      "Teaching through street dialogue and questioning in Athens",
      "Writing the founding political history of the Athenian republic",
      "Creating Stoic philosophy and the ethics of reason and duty",
    ],
  ),
  "queen_victoria": FamousForQuiz(
    correct: "Reigning over Britain and a vast empire for over sixty years",
    wrong: [
      "Founding the United Kingdom by uniting England and Scotland",
      "Leading Britain through two world wars into the modern era",
      "Opening the age of democracy by signing the Magna Carta",
    ],
  ),
  "richard_lionheart": FamousForQuiz(
    correct:
        "Leading the Third Crusade and becoming England's legendary warrior king",
    wrong: [
      "Signing the Magna Carta and limiting royal power in England",
      "Uniting England after the Norman Conquest in the eleventh century",
      "Retaking Jerusalem during the First Crusade for Christianity",
    ],
  ),
  "rene_descartes": FamousForQuiz(
    correct:
        "Founding modern rationalism and writing 'I think, therefore I am'",
    wrong: [
      "Creating the social contract as the basis of modern government",
      "Developing British empiricism through sense-based philosophy",
      "Writing the founding text of modern economic theory",
    ],
  ),
  "richard_feynman": FamousForQuiz(
    correct:
        "Advancing quantum electrodynamics and communicating physics with rare brilliance",
    wrong: [
      "Founding quantum mechanics through the uncertainty principle",
      "Developing the standard model of particle physics in the 1970s",
      "Explaining general relativity for a wide public audience",
    ],
  ),
  "tycho_brahe": FamousForQuiz(
    correct:
        "Making the most precise astronomical observations before the telescope era",
    wrong: [
      "Proposing that planets orbit the Sun in elliptical paths",
      "Building the first telescope and using it to study the Moon",
      "Explaining gravity as the force that governs planetary motion",
    ],
  ),
  "mark_zuckerberg": FamousForQuiz(
    correct:
        "Co-founding Facebook and building one of the world's largest social networks",
    wrong: [
      "Founding Twitter and shaping the era of social microblogging",
      "Co-founding Google and building the dominant search engine",
      "Creating YouTube as the first major online video platform",
    ],
  ),
  "leo_tolstoy": FamousForQuiz(
    correct:
        "Writing War and Peace and Anna Karenina as landmarks of world literature",
    wrong: [
      "Writing Crime and Punishment and The Brothers Karamazov",
      "Creating the short story form in Russian literature",
      "Founding socialist realism as a literary movement",
    ],
  ),
  "marilyn_monroe": FamousForQuiz(
    correct:
        "Becoming one of Hollywood's most iconic stars and a cultural phenomenon",
    wrong: [
      "Directing classic Hollywood musicals and dance films",
      "Building an Oscar-winning career in dramatic British cinema",
      "Pioneering the method acting style for film performances",
    ],
  ),
  "chris_hemsworth": FamousForQuiz(
    correct:
        "Starring in blockbuster films most notably as Thor in the Marvel universe",
    wrong: [
      "Playing Wolverine across multiple decades of Marvel films",
      "Playing James Bond across multiple franchise installments",
      "Directing action films for the DC Extended Universe",
    ],
  ),
  "hugh_jackman": FamousForQuiz(
    correct:
        "Starring as Wolverine in the X-Men franchise and performing on Broadway",
    wrong: [
      "Playing Thor in the Marvel Cinematic Universe films",
      "Building a career as Australia's most successful film director",
      "Playing Batman across multiple DC Extended Universe films",
    ],
  ),
  "nadal": FamousForQuiz(
    correct:
        "Winning a record number of Grand Slam titles with legendary clay-court dominance",
    wrong: [
      "Dominating Wimbledon through a decade of grass-court excellence alone",
      "Building the record for most Grand Slams solely on hard courts",
      "Winning the first calendar Grand Slam in modern men's tennis",
    ],
  ),
  "karl_grosse": FamousForQuiz(
    correct:
        "Unifying much of Europe as Charlemagne, the first Holy Roman Emperor",
    wrong: [
      "Founding the Viking age and raiding across medieval Europe",
      "Building the Byzantine Empire at the height of its power",
      "Launching the First Crusade to reclaim the Holy Land",
    ],
  ),
  "kim_il_sung": FamousForQuiz(
    correct: "Founding and ruling North Korea as its first supreme leader",
    wrong: [
      "Leading China through its communist revolution and founding the PRC",
      "Founding Vietnam and leading it through war with the United States",
      "Establishing the communist regime in Cambodia after independence",
    ],
  ),
  "kublai_khan": FamousForQuiz(
    correct: "Ruling the Mongol Empire and founding China's Yuan dynasty",
    wrong: [
      "Founding the Mongol Empire by uniting all the steppe tribes",
      "Conquering India for the Mongol Empire and creating a vassal state",
      "Creating the first unified code of Mongol law and governance",
    ],
  ),
  "laozi": FamousForQuiz(
    correct: "Being associated with Taoism through the Tao Te Ching",
    wrong: [
      "Writing the Analects and founding Confucian ethics",
      "Teaching the military strategy of The Art of War",
      "Writing Buddhist sutras and spreading meditation in China",
    ],
  ),
  "napoleon_iii": FamousForQuiz(
    correct:
        "Ruling France as emperor and modernizing Paris with sweeping urban changes",
    wrong: [
      "Founding the First French Republic after the revolution",
      "Leading France to victory over Prussia and uniting Germany",
      "Restoring the Bourbon monarchy after the Napoleonic Wars",
    ],
  ),
  "ronald_reagan": FamousForQuiz(
    correct:
        "Serving as US president and accelerating the decline of the Soviet Union",
    wrong: [
      "Creating the NATO alliance as a bulwark against Soviet expansion",
      "Directing American forces in the Vietnam War from the White House",
      "Building détente with the Soviet Union through arms control talks",
    ],
  ),
  "ronaldinho": FamousForQuiz(
    correct: "Dazzling football fans worldwide with creative genius and flair",
    wrong: [
      "Leading Brazil to the World Cup as its greatest finisher",
      "Winning multiple Ballon d'Or awards while playing for Argentina",
      "Becoming the first Brazilian player to captain a World Cup win",
    ],
  ),
  "ronaldo_nazario": FamousForQuiz(
    correct:
        "Becoming one of football's greatest strikers and winning two World Cups",
    wrong: [
      "Scoring the most goals in Champions League history",
      "Winning the most Ballon d'Or awards in the history of football",
      "Leading Portugal to European Championship and World Cup glory",
    ],
  ),
  "stanley_kubrick": FamousForQuiz(
    correct:
        "Directing visionary films such as 2001: A Space Odyssey and A Clockwork Orange",
    wrong: [
      "Creating the Star Wars universe as its original director",
      "Directing the Godfather trilogy that defined American cinema",
      "Building Hitchcock-style thrillers into a defining film legacy",
    ],
  ),
  "steve_jobs": FamousForQuiz(
    correct:
        "Co-founding Apple and transforming music, phones, and personal computing",
    wrong: [
      "Co-founding Microsoft and pioneering the PC software era",
      "Founding Amazon and reshaping global retail and cloud computing",
      "Inventing the World Wide Web and opening the internet age",
    ],
  ),
  "virginia_woolf": FamousForQuiz(
    correct: "Pioneering modernist fiction with novels such as Mrs Dalloway",
    wrong: [
      "Writing political dystopias such as Nineteen Eighty-Four",
      "Founding the feminist literary journal Spare Rib in London",
      "Creating gothic fiction through Wuthering Heights on the moors",
    ],
  ),
  "voltaire": FamousForQuiz(
    correct:
        "Championing reason, tolerance, and liberty as an Enlightenment satirist",
    wrong: [
      "Writing the social contract that underpinned the French Republic",
      "Founding empiricist philosophy through experiments and observation",
      "Creating the encyclopédie that catalogued all human knowledge",
    ],
  ),
  "otto_great": FamousForQuiz(
    correct:
        "Consolidating medieval German power as the first Holy Roman Emperor",
    wrong: [
      "Founding the Frankish kingdom that became medieval France",
      "Building the Viking trade networks across northern Europe",
      "Reuniting the eastern and western Roman churches under one rule",
    ],
  ),
  "pericles": FamousForQuiz(
    correct: "Leading Athens to its golden age of democracy and culture",
    wrong: [
      "Writing the Athenian constitution and founding democracy alone",
      "Commanding the fleet at Salamis against the Persian invasion",
      "Building the philosophical school that became the Platonic Academy",
    ],
  ),
  "tchaikovsky": FamousForQuiz(
    correct:
        "Composing beloved ballets and symphonies of the Russian Romantic era",
    wrong: [
      "Writing the operas that defined the Baroque era of European music",
      "Founding Russian folk music through nationalist compositions",
      "Composing the piano works that defined the Romantic era in Poland",
    ],
  ),
  "ramesses_ii": FamousForQuiz(
    correct: "Ruling Egypt for over sixty years and leaving monumental temples",
    wrong: [
      "Building the Great Pyramids as the first pharaoh of the Old Kingdom",
      "Ruling Egypt as one of its most powerful female pharaohs",
      "Launching Egypt's foreign conquests into Nubia and the Levant for the first time",
    ],
  ),
  "scipio_africanus": FamousForQuiz(
    correct:
        "Defeating Hannibal at Zama and securing Rome's victory in the Punic Wars",
    wrong: [
      "Founding the Roman Republic after overthrowing the last king",
      "Commanding Rome's legions against Julius Caesar in the civil war",
      "Leading Carthage across the Alps in the Second Punic War",
    ],
  ),
  "simone_de_beauvoir": FamousForQuiz(
    correct: "Writing The Second Sex and shaping modern feminist philosophy",
    wrong: [
      "Founding French structuralism with texts on language and myth",
      "Creating existentialist theater with absurdist plays in Paris",
      "Writing the manifesto that launched the second-wave feminist movement",
    ],
  ),
  "socrates": FamousForQuiz(
    correct:
        "Teaching through dialogue and laying the foundation of Western philosophy",
    wrong: [
      "Writing the Republic and founding the Platonic Academy in Athens",
      "Creating Stoic philosophy and the ethics of rational acceptance",
      "Teaching Alexander the Great and codifying all knowledge of the era",
    ],
  ),
  "spartacus": FamousForQuiz(
    correct: "Leading the largest slave revolt against the Roman Republic",
    wrong: [
      "Founding the tradition of gladiatorial combat in ancient Rome",
      "Leading the Celtic revolt against Roman occupation in Britain",
      "Commanding the slave armies of Carthage against Rome",
    ],
  ),
  "tokugawa_ieyasu": FamousForQuiz(
    correct:
        "Founding the Tokugawa shogunate and bringing centuries of peace to Japan",
    wrong: [
      "Uniting Japan for the first time through the Yamato dynasty",
      "Opening Japan to the West as the Meiji emperor",
      "Defeating the Mongol invasions that threatened medieval Japan",
    ],
  ),
  "thomas_aquinas": FamousForQuiz(
    correct:
        "Reconciling Christian theology with Aristotelian reason in Scholastic philosophy",
    wrong: [
      "Translating the Bible into Latin and founding Catholic doctrine",
      "Leading the Protestant Reformation against Catholic authority",
      "Writing the first systematic treatise on Islamic philosophy",
    ],
  ),
  "tiger_woods": FamousForQuiz(
    correct:
        "Dominating golf with record major championships and transforming the sport",
    wrong: [
      "Winning more Grand Slam titles than any player in tennis history",
      "Setting world records in sprint events across two Olympics",
      "Building the most successful Formula 1 career of all time",
    ],
  ),
  "walt_disney": FamousForQuiz(
    correct:
        "Creating Mickey Mouse and building the world's most beloved entertainment empire",
    wrong: [
      "Inventing the cinema camera and opening the age of film",
      "Producing the first feature-length animated film at Pixar",
      "Founding the Hollywood studio system with a major film company",
    ],
  ),
  "werner_heisenberg": FamousForQuiz(
    correct:
        "Formulating the uncertainty principle and developing quantum mechanics",
    wrong: [
      "Proving the heliocentric model of the solar system",
      "Discovering radioactivity through chemistry experiments",
      "Building the standard model of elementary particle physics",
    ],
  ),
  "xi_jinping": FamousForQuiz(
    correct: "Rising to become China's most powerful leader in a generation",
    wrong: [
      "Founding the People's Republic of China after the communist revolution",
      "Launching China's economic opening to the West in the 1970s",
      "Leading China's economic rise in the first decade of the 2000s",
    ],
  ),
  "zhang_qian": FamousForQuiz(
    correct: "Opening the Silk Road as a Han dynasty envoy and explorer",
    wrong: [
      "Founding the Silk Road trading city of Samarkand",
      "Leading Mongol caravans across Central Asia to Europe",
      "Writing the first map of China's trade routes to the West",
    ],
  ),
  'mansa_musa': FamousForQuiz(
    correct:
        'Ruling the Mali Empire as one of the wealthiest and most powerful rulers in history',
    wrong: [
      'Founding the Songhai Empire after the fall of Mali',
      'Leading the trans-Saharan gold trade as a Moroccan sultan',
      'Building the Kingdom of Kush into a rival of ancient Egypt',
    ],
  ),
  "zidane": FamousForQuiz(
    correct: "Leading France to World Cup glory with artistry and technique",
    wrong: [
      "Winning the most Ballon d'Or awards in football history",
      "Coaching Real Madrid to three straight Champions League titles",
      "Becoming the top scorer in the history of French football",
    ],
  ),
};
