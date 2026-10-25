import '../../models/connection_request.dart';
import '../../models/expressed_interest.dart';
import '../../models/funding_round.dart';
import '../../models/list_entries.dart';
import '../../models/investor_profile.dart';
import '../../models/program.dart';
import '../../models/startup.dart';
import '../../models/startup_activity.dart';
import '../../models/startup_enums.dart';
import '../../models/team_member.dart';

/// The prototype's demo content (docs/07 §4): the startups, investors and
/// programs the Hub, Explore and Support Channels show, plus sample requests,
/// interests and activity. Discovery runs on this data (there is no public
/// directory in Firestore yet); a founder's *own* startups always come from
/// Firestore. Ids of sample startups start with `mock-`.
class PrototypeSeed {
  /// SAMPLE accounts for the sample team members: email -> (uid, name).
  /// Used by the team e-mail lookup until it searches real accounts.
  static const Map<String, (String, String)> sampleAccounts = {
    'faisal.alkhaldi@gmail.com': ('sample-faisal', 'Faisal Alkhaldi'),
    'nora.alharbi@gmail.com': ('sample-nora', 'Nora Alharbi'),
  };

  PrototypeSeed._();

  /// True for the built-in sample startups (ids start with "mock-").
  static bool isSampleStartup(String id) => id.startsWith('mock-');

  static StartupLocation _loc(String label) {
    for (final c in StartupLocation.values) {
      if (c.label == label) return c;
    }
    return StartupLocation.custom(label);
  }

  static Sector _sector(String label) =>
      Sector.fromLabel(label) ?? Sector.other;

  static StartupStage _stage(String label) {
    for (final s in StartupStage.values) {
      if (s.label == label) return s;
    }
    return StartupStage.preSeed;
  }

  static BusinessModel _model(String short) {
    for (final m in BusinessModel.values) {
      if (m.shortLabel == short) return m;
    }
    return BusinessModel.other;
  }

  static LookingFor _look(String label) {
    for (final l in LookingFor.values) {
      if (l.label == label) return l;
    }
    return LookingFor.other;
  }

  static Startup _startup({
    required String id,
    required String founderId,
    required String name,
    required String tagline,
    required String about,
    required String sector,
    required String stage,
    required String city,
    required String model,
    required int founded,
    required List<String> looking,
    int? funding,
    String website = '',
    bool isPublic = true,
    String problem = '',
    String solution = '',
    String customers = '',
    String advantage = '',
    int? tam,
    int? sam,
    int? som,
    List<TeamMember> team = const [],
    String growth = '',
    int? capital,
    int? rev1,
    int? rev2,
    int? rev3,
    int? valuation,
    bool? wantsLead,
  }) => Startup(
    id: id,
    founderId: founderId,
    name: name,
    tagline: tagline,
    description: about,
    sector: _sector(sector),
    stage: _stage(stage),
    businessModel: _model(model),
    location: _loc(city),
    foundedYear: founded,
    websiteUrl: website.isEmpty ? null : website,
    lookingFor: {for (final l in looking) _look(l)},
    fundingRequirement: funding,
    isPublic: isPublic,
    problem: problem,
    solution: solution,
    customers: customers,
    advantage: advantage,
    tam: tam,
    sam: sam,
    som: som,
    team: team,
    growth: growth,
    capital: capital,
    revenueYear1: rev1,
    revenueYear2: rev2,
    revenueYear3: rev3,
    valuation: valuation,
    wantsLeadInvestor: wantsLead,
  );

  // ------------------------------------------------------------ startups

  static final rafeeq = _startup(
    id: 'mock-rafeeq',
    founderId: 'mock-founder-1',
    name: 'Rafeeq Health',
    tagline: 'Home nursing visits booked in minutes. Licensed nurses and transparent pricing.',
    about: 'Rafeeq Health connects families in Riyadh with licensed home nurses. Families book a visit in minutes from the app, choose the type of care they need, and see the full price before they confirm. Every nurse is licensed by the Saudi Commission for Health Specialties and checked by our team. After each visit, families get a short care report and can rebook the same nurse in one tap. We started with elderly care and post-surgery visits, and we work with two private clinics that refer patients to us.',
    sector: 'HealthTech',
    stage: 'Pre-seed',
    city: 'Riyadh',
    model: 'B2C',
    founded: 2024,
    looking: ['Funding', 'Talent'],
    funding: 500000,
    website: 'rafeeqhealth.sa',
    problem: 'Families in Riyadh struggle to find licensed home nurses quickly. Prices are unclear and bookings happen over phone calls and WhatsApp.',
    solution: 'An app that books a vetted, licensed nurse in minutes, shows the full price upfront, and keeps visit notes and care plans in one place.',
    customers: 'Families caring for elderly parents or recovering patients at home, starting in Riyadh.',
    advantage: 'Every nurse is licensed and background-checked, prices are fixed upfront, and we partner directly with two hospital groups for referrals.',
    tam: 2400000000,
    sam: 600000000,
    som: 24000000,
    team: const [
      // SAMPLE team members (kept): the founder first, then a co-founder.
      TeamMember(
        name: 'Shahad Alabdulkarim',
        email: 'shahad@gmail.com',
        role: 'CEO',
        contribution: 'Ran home-care operations for a Riyadh hospital group for six years.',
        isFounder: true,
      ),
      TeamMember(
        name: 'Faisal Alkhaldi',
        email: 'faisal.alkhaldi@gmail.com',
        role: 'CTO',
        contribution:
            'Built booking platforms used by more than 200,000 patients.',
        coFounder: true,
        uid: 'sample-faisal',
      ),
    ],
    growth: 'Expand to Jeddah and Dammam in year 2 and reach 40,000 monthly visits by year 3.',
    capital: 350000,
    rev1: 1200000,
    rev2: 3800000,
    rev3: 9000000,
    valuation: 6000000,
    wantsLead: true,
  );

  static final daftar = _startup(
    id: 'mock-daftar',
    founderId: 'mock-founder-1',
    name: 'Daftar',
    tagline: 'Bookkeeping and e-invoicing for micro businesses.',
    about: 'Daftar gives micro businesses simple bookkeeping and ZATCA-ready e-invoicing from their phone. Shop owners record sales and expenses in Arabic or English, send compliant invoices by WhatsApp, and see a clear monthly summary of what they earned and spent. No accounting background is needed, and owners can share access with their accountant when it is time to file.',
    sector: 'Fintech',
    stage: 'Pre-seed',
    city: 'Jeddah',
    model: 'B2B',
    founded: 2024,
    looking: ['Partnership'],
    website: 'daftar.sa',
    wantsLead: false,
    isPublic: false,
  );

  static final naql = _startup(
    id: 'mock-naql',
    founderId: 'mock-founder-3',
    name: 'Naql',
    tagline: 'Shared last-mile delivery for small shops, pooling routes to cut costs.',
    about: 'Naql pools deliveries from small shops into shared routes, cutting delivery costs for merchants across Riyadh. Shops add orders through a simple dashboard, and our routing groups nearby drops so one driver covers several shops in a single trip. Merchants pay per delivery with no monthly fee, and customers get live tracking and a delivery window they can trust.',
    sector: 'Logistics',
    stage: 'Seed',
    city: 'Riyadh',
    model: 'B2B',
    founded: 2022,
    looking: ['Funding'],
    funding: 1200000,
    website: 'naql.sa',
  );

  static final mizan = _startup(
    id: 'mock-mizan',
    founderId: 'mock-founder-2',
    name: 'Mizan Learn',
    tagline:
        'Tutoring marketplace connecting K-12 students with verified tutors.',
    about: 'Mizan Learn connects K-12 students with vetted tutors for live one-to-one lessons, with progress reports for parents. Tutors are interviewed and tested before they join, and lessons follow the Saudi curriculum. Parents can book, pay and follow progress in one place, and each lesson ends with a short summary of what was covered and what to practise next.',
    sector: 'EdTech',
    stage: 'Seed',
    city: 'Jeddah',
    model: 'Other',
    founded: 2023,
    looking: ['Talent'],
    website: 'mizanlearn.sa',
  );

  static final sanabil = _startup(
    id: 'mock-sanabil',
    founderId: 'mock-founder-5',
    name: 'Sanabil Agri',
    tagline: 'Smart irrigation and crop advice for small farms.',
    about: 'Sanabil Agri helps small farms in Qassim save water with smart irrigation and simple crop advice. Low-cost soil sensors tell farmers when and how much to water, and the app sends clear daily tips based on the crop and the weather. Early pilot farms cut their water use by about a third while keeping the same harvest.',
    sector: 'AgriTech',
    stage: 'Pre-seed',
    city: 'Qassim',
    model: 'B2B',
    founded: 2025,
    looking: ['Mentorship'],
    website: 'sanabil.sa',
  );

  /// `[id, name, sector, city, tagline]`: the extra startups that fill the
  /// Trending list up to 30.
  static const _extraStartups = <List<String>>[
    [
      'wasel',
      'Wasel Pay',
      'Fintech',
      'Riyadh',
      'QR payments that settle to small merchants the same day.',
    ],
    [
      'bayt',
      'Bayt Care',
      'HealthTech',
      'Jeddah',
      'Elderly care coordination for families and home carers.',
    ],
    [
      'sahm',
      'Sahm Analytics',
      'SaaS',
      'Riyadh',
      'Sales dashboards for retail chains, set up in a day.',
    ],
    [
      'nakhla',
      'Nakhla Foods',
      'E-commerce',
      'Qassim',
      'Premium dates shipped direct from farms across the Kingdom.',
    ],
    [
      'rihla',
      'Rihla Travel',
      'Tourism',
      'Al-Ula',
      'Guided local trips booked with verified Saudi guides.',
    ],
    [
      'darb',
      'Darb Fleet',
      'Logistics',
      'Dammam',
      'Fleet tracking and fuel savings for delivery companies.',
    ],
    [
      'qimma',
      'Qimma Tutors',
      'EdTech',
      'Riyadh',
      'University exam prep with top-scoring student tutors.',
    ],
    [
      'tamr',
      'Tamr Market',
      'E-commerce',
      'Madinah',
      'An online souq for local food producers.',
    ],
    [
      'manzil',
      'Manzil Homes',
      'PropTech',
      'Riyadh',
      'Rent payments in monthly instalments for tenants.',
    ],
    [
      'siraj',
      'Siraj Energy',
      'CleanTech',
      'Tabuk',
      'Rooftop solar on subscription for homes and shops.',
    ],
    [
      'bunyan',
      'Bunyan Build',
      'PropTech',
      'Jeddah',
      'Construction project tracking for contractors.',
    ],
    [
      'hisab',
      'Hisab Books',
      'Fintech',
      'Riyadh',
      'Payroll and GOSI filing for small teams.',
    ],
    [
      'sanad',
      'Sanad Legal',
      'SaaS',
      'Riyadh',
      'Contract templates and e-signing in Arabic and English.',
    ],
    [
      'majlis',
      'Majlis Events',
      'Tourism',
      'Jeddah',
      'Venue booking and planning for weddings and events.',
    ],
    [
      'khutwa',
      'Khutwa Fitness',
      'HealthTech',
      'Khobar',
      'Women-only fitness classes booked by the session.',
    ],
    [
      'nabd',
      'Nabd Clinics',
      'HealthTech',
      'Riyadh',
      'Online appointments and follow-ups for private clinics.',
    ],
    [
      'masar',
      'Masar Careers',
      'EdTech',
      'Riyadh',
      'Career coaching and job matching for fresh graduates.',
    ],
    [
      'zad',
      'Zad Kitchens',
      'E-commerce',
      'Riyadh',
      'Shared cloud kitchens for home-grown food brands.',
    ],
    [
      'thimar',
      'Thimar Farms',
      'AgriTech',
      'Al Kharj',
      'Greenhouse vegetables grown with less water.',
    ],
    [
      'faseel',
      'Faseel Cloud',
      'SaaS',
      'Riyadh',
      'Local cloud hosting that keeps data in the Kingdom.',
    ],
    [
      'lamsa',
      'Lamsa Beauty',
      'E-commerce',
      'Jeddah',
      'Home beauty services booked in minutes.',
    ],
    [
      'waha',
      'Waha Water',
      'CleanTech',
      'Riyadh',
      'Smart water meters that catch leaks early.',
    ],
    [
      'noor',
      'Noor Optics',
      'HealthTech',
      'Dammam',
      'Eye tests and glasses delivered to your door.',
    ],
    [
      'rawabi',
      'Rawabi Rides',
      'Logistics',
      'Abha',
      'Shared rides between cities in the south.',
    ],
    [
      'raqeeb',
      'Raqeeb Security',
      'SaaS',
      'Riyadh',
      'Cybersecurity checks made simple for small businesses.',
    ],
  ];

  static const _stageCycle = [
    'Pre-seed',
    'Seed',
    'Pre-seed',
    'Series A',
    'Seed',
  ];
  static const _fundingCycle = [750000, 300000, 1500000, 400000, 2000000];

  /// Every sample startup, in the order the Hub lists them (the five detailed
  /// ones first, then the trending extras).
  static final List<Startup> startups = List.unmodifiable([
    rafeeq,
    daftar,
    naql,
    mizan,
    sanabil,
    for (var n = 0; n < _extraStartups.length; n++)
      _startup(
        id: 'mock-${_extraStartups[n][0]}',
        founderId: 'mock-founder-x${n + 1}',
        name: _extraStartups[n][1],
        tagline: _extraStartups[n][4],
        about: _extraStartups[n][4],
        sector: _extraStartups[n][2],
        stage: _stageCycle[n % 5],
        city: _extraStartups[n][3],
        model: n.isOdd ? 'B2B' : 'B2C',
        founded: 2021 + n % 4,
        looking: n % 3 != 0 ? ['Funding'] : ['Funding', 'Talent'],
        funding: _fundingCycle[n % 5],
      ),
  ]);

  /// Sample founders by `founderId` (a real startup's founder name is not
  /// loaded on its profile).
  static const founderNames = {
    'mock-founder-1': 'Shahad Alabdulkarim',
    'mock-founder-2': 'Noura Alsubaie',
    'mock-founder-3': 'Faisal Alotaibi',
    'mock-founder-5': 'Khalid Alharbi',
  };

  /// Match shown on the Matches tab for an investor: percent and reason.
  static const startupMatches = <String, (int, String)>{
    'mock-rafeeq': (94, 'Same sector, stage and region'),
    'mock-daftar': (86, 'Same sector and stage'),
    'mock-naql': (71, 'Same stage and region'),
  };

  /// "Joined ..." lines on the "New on Start.sa" rail.
  static const joined = <String, String>{
    'mock-sanabil': 'Joined today',
    'mock-mizan': 'Joined 2 days ago',
    'mock-naql': 'Joined 4 days ago',
    'mock-daftar': 'Joined this week',
    'nora': 'Joined yesterday',
    'omar': 'Joined 3 days ago',
    'sara': 'Joined this week',
  };

  // ----------------------------------------------------------- investors

  static InvestorProfile _investor({
    required String id,
    required String name,
    required String title,
    required String city,
    required List<String> sectors,
    required List<String> stages,
    required String ticket,
    required String about,
    required String bio,
    int? match,
    String? reason,
    String? linkedin,
    String? give,
    String? gain,
  }) => InvestorProfile(
    id: id,
    name: name,
    title: title,
    city: city,
    sectors: sectors,
    stages: stages,
    ticketRange: ticket,
    locations: [city],
    about: about,
    bio: bio,
    matchPercent: match,
    matchReason: reason,
    linkedin: linkedin,
    valueOffered: give,
    hopeToGain: gain,
    joinedLabel: joined[id],
  );

  static final ahmad = _investor(
    id: 'ahmad',
    name: 'Ahmad Hassan',
    title: 'Angel Investor',
    city: 'Riyadh',
    sectors: const ['HealthTech', 'Fintech'],
    stages: const ['Pre-seed', 'Seed'],
    ticket: 'SAR 100K – 500K',
    about: 'Backing early-stage health and fintech founders building for Saudi families and small businesses.',
    bio: 'Ahmad is an angel investor based in Riyadh with ten years in healthcare operations. He backs pre-seed and seed founders in health and fintech, and is happy to open doors to hospitals and banks.',
    match: 92,
    reason: 'Same sector and stage',
    linkedin: 'linkedin.com/in/ahmad-hassan',
    give: 'Introductions to hospital groups and banks, plus ten years of healthcare operations experience.',
    gain: 'Early access to health and fintech startups and founders I can mentor over the long term.',
  );

  static final sara = _investor(
    id: 'sara',
    name: 'Sara Al-Mohsen',
    title: 'VC Associate',
    city: 'Jeddah',
    sectors: const ['EdTech', 'SaaS'],
    stages: const ['Seed', 'Series A'],
    ticket: 'SAR 500K – 2M',
    about: 'Looking for EdTech and SaaS teams with early traction and a clear path to Seed.',
    bio: 'Sara works on the early-stage team of a Jeddah venture fund. She looks for EdTech and SaaS teams with paying customers and a clear path to a Seed round.',
    match: 81,
    reason: 'Same sector',
    linkedin: 'linkedin.com/in/sara-almohsen',
    give: 'A path to our fund’s Seed round, and help with go-to-market for schools and SMEs.',
    gain: 'EdTech and SaaS teams with real traction that can grow into our portfolio.',
  );

  static final omar = _investor(
    id: 'omar',
    name: 'Omar Khalid',
    title: 'Angel Investor',
    city: 'Riyadh',
    sectors: const ['Logistics', 'E-commerce'],
    stages: const ['Pre-seed'],
    ticket: 'SAR 50K – 200K',
    about: 'Interested in startups solving last-mile delivery in the Kingdom.',
    bio: 'Omar is a former supply-chain executive turned angel investor. He invests small tickets in logistics and e-commerce startups that make delivery cheaper and faster across the Kingdom.',
    match: 74,
    reason: 'Same region',
    give: 'Supply-chain know-how and introductions to courier and warehouse partners across the Kingdom.',
    gain: 'Small tickets in logistics teams solving last-mile delivery.',
  );

  static final nora = _investor(
    id: 'nora',
    name: 'Nora Alqahtani',
    title: 'Angel Investor',
    city: 'Dammam',
    sectors: const ['AgriTech', 'CleanTech'],
    stages: const ['Seed', 'Series A'],
    ticket: 'SAR 300K – 1M',
    about: 'Supporting AgriTech and CleanTech teams that save water and energy across the Eastern Province.',
    bio: 'Nora is an angel investor in Dammam with a background in renewable energy projects. She backs AgriTech and CleanTech founders at Seed and Series A who can show measurable savings.',
    linkedin: 'linkedin.com/in/nora-alqahtani',
    give: 'Renewable-energy experience and links to farms and utilities in the Eastern Province.',
    gain: 'AgriTech and CleanTech startups that save water and energy.',
  );

  static final layan = _investor(
    id: 'layan',
    name: 'Layan Alsaab',
    title: 'Investor',
    city: 'Riyadh',
    sectors: const ['HealthTech', 'Fintech', 'EdTech'],
    stages: const ['Pre-seed', 'Seed'],
    ticket: 'SAR 100K – 1M',
    about: 'Angel investor backing early-stage HealthTech and Fintech founders in the Kingdom.',
    bio: 'Angel investor backing early-stage HealthTech and Fintech founders in the Kingdom.',
    linkedin: 'linkedin.com/in/layan-alsaab',
    give: 'Connections with venture capital firms in Riyadh, and hands-on help with fundraising decks and financial models.',
    gain: 'Early access to promising HealthTech and Fintech teams, and a long-term stake in founders I can grow with.',
  );

  /// `[id, name, sector, city]` for the extra investors that fill Trending.
  static const _extraInvestors = <List<String>>[
    ['khalid', 'Khalid Al-Otaibi', 'Fintech', 'Riyadh'],
    ['reem', 'Reem Al-Harbi', 'EdTech', 'Jeddah'],
    ['faisal', 'Faisal Al-Qahtani', 'HealthTech', 'Riyadh'],
    ['hessa', 'Hessa Al-Dosari', 'E-commerce', 'Dammam'],
    ['turki', 'Turki Al-Shehri', 'Logistics', 'Abha'],
    ['lama', 'Lama Al-Zahrani', 'SaaS', 'Jeddah'],
    ['abdullah', 'Abdullah Al-Ghamdi', 'PropTech', 'Riyadh'],
    ['mona', 'Mona Al-Sulaiman', 'HealthTech', 'Riyadh'],
    ['yazeed', 'Yazeed Al-Mutairi', 'Fintech', 'Khobar'],
    ['dana', 'Dana Al-Rashid', 'EdTech', 'Riyadh'],
    ['majed', 'Majed Al-Anazi', 'AgriTech', 'Qassim'],
    ['nouf', 'Nouf Al-Shammari', 'CleanTech', 'Hail'],
    ['saud', 'Saud Al-Subaie', 'Fintech', 'Riyadh'],
    ['rana', 'Rana Al-Juhani', 'Tourism', 'Madinah'],
    ['bandar', 'Bandar Al-Malki', 'Logistics', 'Jeddah'],
    ['ghada', 'Ghada Al-Ahmadi', 'HealthTech', 'Riyadh'],
    ['waleed', 'Waleed Al-Harthi', 'SaaS', 'Taif'],
    ['lujain', 'Lujain Al-Omari', 'E-commerce', 'Riyadh'],
    ['ziyad', 'Ziyad Al-Khalaf', 'PropTech', 'Dammam'],
    ['asma', 'Asma Al-Hazmi', 'EdTech', 'Jeddah'],
    ['hamad', 'Hamad Al-Yami', 'Fintech', 'Najran'],
    ['shahd', 'Shahd Al-Mansour', 'HealthTech', 'Riyadh'],
    ['talal', 'Talal Al-Fahad', 'CleanTech', 'Riyadh'],
    ['wejdan', 'Wejdan Al-Saleh', 'AgriTech', 'Qassim'],
    ['muath', 'Muath Al-Jabri', 'SaaS', 'Khobar'],
    ['sultana', 'Sultana Al-Amri', 'Tourism', 'Abha'],
  ];

  /// Every sample investor except the demo user [layan]: the five detailed
  /// ones first, then the trending extras.
  static final List<InvestorProfile> investors = List.unmodifiable([
    ahmad,
    sara,
    omar,
    nora,
    for (var n = 0; n < _extraInvestors.length; n++)
      _investor(
        id: _extraInvestors[n][0],
        name: _extraInvestors[n][1],
        title: n % 3 != 0 ? 'Angel Investor' : 'VC Partner',
        city: _extraInvestors[n][3],
        sectors: [_extraInvestors[n][2]],
        stages: n.isOdd
            ? const ['Pre-seed', 'Seed']
            : const ['Seed', 'Series A'],
        ticket: n.isOdd ? 'SAR 100K – 500K' : 'SAR 500K – 2M',
        about:
            'Investing in ${_extraInvestors[n][2]} startups across the Kingdom.',
        bio:
            '${_extraInvestors[n][1]} invests in early-stage ${_extraInvestors[n][2]} startups across the Kingdom.',
      ),
  ]);

  /// Which investors are approved associations of which sample startups
  /// (used when a startup has no accepted request).
  static const associations = <String, List<String>>{
    'mock-rafeeq': ['ahmad'],
    'mock-daftar': ['sara', 'layan'],
    'mock-naql': ['omar'],
    'mock-mizan': ['sara', 'layan'],
    'mock-sanabil': ['nora'],
  };

  // ------------------------------------------------------------ programs

  static const programs = <Program>[
    Program(
      id: 'taqadam',
      name: 'TAQADAM by KAUST',
      type: ProgramType.accelerator,
      city: 'Thuwal',
      duration: '6 months',
      sinceYear: 2017,
      about: "TAQADAM is KAUST's flagship startup accelerator, supporting early-stage tech startups with mentorship, funding, and workspace.",
      focusSectors: ['HealthTech', 'DeepTech', 'CleanTech', 'AI'],
      summary: 'University startup accelerator run by KAUST.',
      focus: 'University and deep-tech startups',
      logoText: 'T',
      websiteUrl: 'taqadam.kaust.edu.sa',
    ),
    Program(
      id: 'badir',
      name: 'Badir Program',
      type: ProgramType.incubator,
      city: 'Riyadh',
      duration: '12 months',
      sinceYear: 2008,
      about: 'Badir supports technology startups with incubation, workspace and access to a network of partners.',
      focusSectors: ['Fintech', 'EdTech', 'Logistics'],
      summary: 'Technology incubator supporting early-stage startups.',
      focus: 'Early-stage tech',
      logoText: 'B',
      websiteUrl: 'badir.com.sa',
    ),
    Program(
      id: 'bim',
      name: 'BIM Ventures',
      type: ProgramType.studio,
      city: 'Riyadh',
      duration: '9 months',
      sinceYear: 2019,
      about: 'BIM Ventures is a startup studio that builds companies together with founders.',
      focusSectors: ['E-commerce', 'SaaS'],
      summary: 'Startup studio that co-builds new companies with founders.',
      focus: 'Co-building startups',
      logoText: 'BV',
      websiteUrl: 'bimventures.com',
    ),
  ];

  // ------------------------------------------------- requests / interests

  static const requests = <ConnectionRequest>[
    ConnectionRequest(
      id: 'r1',
      startupId: 'mock-rafeeq',
      investorId: 'omar',
      message: 'I like the traction in Riyadh. I’d like to invest and help with logistics partners.',
      amount: 300000,
      equityPercent: 15,
      status: RequestStatus.pending,
      whenLabel: '2h ago',
    ),
    ConnectionRequest(
      id: 'r2',
      startupId: 'mock-rafeeq',
      investorId: 'ahmad',
      message: 'Happy to back you and open doors to two hospital groups.',
      amount: 200000,
      equityPercent: 8,
      status: RequestStatus.accepted,
      whenLabel: '3d ago',
    ),
  ];

  static const interests = <ExpressedInterest>[
    ExpressedInterest(
      id: 'i1',
      startupId: 'mock-rafeeq',
      name: 'Noura Alharbi',
      roleLine: 'Registered nurse',
      message: 'Would love to join as a part-time nurse.',
      whenLabel: '1h ago',
    ),
    ExpressedInterest(
      id: 'i2',
      startupId: 'mock-rafeeq',
      name: 'Fahad Saleh',
      roleLine: 'Startup seeker',
      message: 'Interested in partnering on home-care supplies.',
      whenLabel: '1d ago',
    ),
    ExpressedInterest(
      id: 'i3',
      startupId: 'mock-rafeeq',
      name: 'Reem Almutairi',
      roleLine: 'Product designer',
      message: 'Open to helping with your app design.',
      seenByFounder: true,
      whenLabel: '4d ago',
    ),
  ];

  // ------------------------------------------------------------ activity

  static const activity = <ActivityRange, StartupActivity>{
    ActivityRange.today: StartupActivity(
      range: ActivityRange.today,
      views: ActivityFigure('14', '+3'),
      bookmarks: ActivityFigure('2', '+1'),
      requests: ActivityFigure('1', '+1'),
      series: [2, 5, 9, 4, 6, 12, 8, 10, 14, 7, 3, 6],
      axis: ['9am', '12pm', '3pm', '6pm', '9pm'],
    ),
    ActivityRange.week: StartupActivity(
      range: ActivityRange.week,
      views: ActivityFigure('128', '+18%'),
      bookmarks: ActivityFigure('14', '+4'),
      requests: ActivityFigure('3', '+1'),
      series: [30, 45, 35, 60, 50, 75, 100],
      axis: ['Sat', 'Mon', 'Wed', 'Fri'],
    ),
    ActivityRange.month: StartupActivity(
      range: ActivityRange.month,
      views: ActivityFigure('512', '+22%'),
      bookmarks: ActivityFigure('47', '+12'),
      requests: ActivityFigure('9', '+3'),
      series: [40, 52, 48, 66, 60, 74, 70, 88, 82, 95, 100],
      axis: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
    ),
    ActivityRange.year: StartupActivity(
      range: ActivityRange.year,
      views: ActivityFigure('4,860', '+64%'),
      bookmarks: ActivityFigure('402', '+150'),
      requests: ActivityFigure('61', '+38'),
      series: [10, 14, 20, 18, 26, 30, 34, 42, 50, 58, 66, 80],
      axis: ['Nov', 'Feb', 'May', 'Aug', 'Oct'],
    ),
  };

  // --------------------------------------------- list screens (interface)

  /// MOCKUP DATA for My Startups (interface only): one startup where the
  /// user is a co-founder (Naql) and one where they are a team member
  /// (Mizan Learn). The founder's own startups still
  /// come from the existing startup loading. Replace by the real memberships
  /// when the backend is connected.
  static final List<MyStartupEntry> sampleTeamStartups = [
    MyStartupEntry(
      startup: naql,
      role: StartupRole.coFounder,
      addedAt: DateTime(2026, 10, 14),
    ),
    MyStartupEntry(
      startup: mizan,
      role: StartupRole.member,
      addedAt: DateTime(2026, 9, 2),
    ),
  ];

  /// MOCKUP DATA for Manage -> Rounds (interface only): Round 2 (Seed) is open
  /// and Round 1 (Pre-seed) is closed. The same sample shows for every
  /// startup. Replace by the real rounds when the backend is connected.
  static final List<FundingRound> sampleRounds = [
    FundingRound(
      number: 2,
      type: StartupStage.seed,
      amount: 500000,
      raised: 200000,
      start: DateTime(2026, 8, 1),
      investors: [ahmad],
    ),
    FundingRound(
      number: 1,
      type: StartupStage.preSeed,
      amount: 250000,
      raised: 250000,
      start: DateTime(2026, 1, 1),
      end: DateTime(2026, 6, 30),
      investors: [layan],
    ),
  ];
}
