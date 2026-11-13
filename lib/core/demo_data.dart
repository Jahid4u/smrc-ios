import '../models/club_event.dart';
import '../models/member.dart';
import '../models/member_tier.dart';

/// Exact port of the simulator's defaultDB(). Used as fallback/demo data so
/// every screen renders identically to the HTML even before the API is live.
class DemoData {
  DemoData._();

  static final List<ClubEvent> events = [
    ClubEvent(
      id: 'ev1',
      type: EventType.weekly,
      title: 'The Midnight Salon',
      dateLabel: "Fri 14. 9 PM. Members' Floor",
      endDate: DateTime(2026, 8, 14),
      location: "Members' Floor",
      coverImageUrl: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800&q=80',
      description:
          'An intimate evening of conversation, a live quartet and a tasting menu by our resident chef.',
      basePrice: 75,
      featured: true,
    ),
    ClubEvent(
      id: 'ev2',
      type: EventType.big,
      title: 'The Rooftop Gala',
      dateLabel: 'Sat 22. 10 PM. The Terrace',
      endDate: DateTime(2026, 8, 22),
      location: 'The Terrace',
      coverImageUrl: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&q=80',
      description:
          "The season's headline night on The Terrace, with a live set, dinner service and a champagne reception.",
      basePrice: 180,
    ),
    ClubEvent(
      id: 'ev3',
      type: EventType.trip,
      title: 'Lake Como Weekend',
      dateLabel: 'May 9 to 11. 3 days. Italy',
      endDate: DateTime(2026, 9, 11),
      location: 'Italy',
      coverImageUrl: 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800&q=80',
      description:
          'Three days on the lake, a private villa, curated dinners and a boat day. Limited to twenty members.',
      basePrice: 1500,
      discounts: const [EventDiscount(appliesTo: 'amb', percent: 20)],
    ),
    ClubEvent(
      id: 'ev4',
      type: EventType.weekly,
      title: 'The Riviera Sunset Party',
      dateLabel: 'Fri 8. 8 PM. Poolside',
      endDate: DateTime(2026, 5, 8),
      location: 'Poolside',
      coverImageUrl: 'https://images.unsplash.com/photo-1533104816931-20fa691ff6ca?w=800&q=80',
      description: 'A golden-hour gathering by the pool with a live DJ set and a frozen cocktail bar.',
      basePrice: 65,
    ),
    ClubEvent(
      id: 'ev5',
      type: EventType.big,
      title: "Founders' Night Gala",
      dateLabel: 'Sat 18. 9 PM. The Grand Salon',
      endDate: DateTime(2026, 4, 18),
      location: 'The Grand Salon',
      coverImageUrl: 'https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?w=800&q=80',
      description:
          "An evening honouring the Circle's founding members, with a seated dinner and string quartet.",
      basePrice: 220,
    ),
    ClubEvent(
      id: 'ev6',
      type: EventType.trip,
      title: 'Marrakech Retreat',
      dateLabel: 'Mar 12 to 15. 4 days. Morocco',
      endDate: DateTime(2026, 3, 15),
      location: 'Morocco',
      coverImageUrl: 'https://images.unsplash.com/photo-1489749798305-4fea3ae63d43?w=800&q=80',
      description:
          'Four days in the medina with a private riad, a hammam evening and a desert dinner under the stars.',
      basePrice: 1850,
      discounts: const [EventDiscount(appliesTo: 'amb', percent: 15)],
    ),
  ];

  static final Member you = Member(
    id: 'M-0005',
    name: 'John Doe',
    gender: Gender.man,
    tier: MemberTier.gold,
    avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&q=80',
    isYou: true,
    joinedAt: DateTime(2026, 1, 14),
    email: 'you@example.com',
    bio: 'Creative director, collector of quiet places.',
    location: 'City, Country',
    industry: 'Design & Architecture',
    instagram: '@danielhart',
    memberNo: 'No. 0148',
  );

  static final List<Member> directory = [
    Member(
        id: 'm1',
        memberNo: 'M-0001',
        name: 'Marcus Vale',
        gender: Gender.man,
        tier: MemberTier.blackDiamond,
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=120&q=80',
        joinedAt: DateTime(2026)),
    Member(
        id: 'm3',
        memberNo: 'M-0003',
        name: 'Jasper Lyne',
        gender: Gender.man,
        tier: MemberTier.silver,
        avatarUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=120&q=80',
        joinedAt: DateTime(2026)),
    Member(
        id: 'm4',
        memberNo: 'M-0004',
        name: 'Ava Lindholm',
        gender: Gender.woman,
        tier: MemberTier.ambassador,
        avatarUrl: 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=120&q=80',
        joinedAt: DateTime(2026)),
    Member(
        id: 'm5',
        memberNo: 'M-0005',
        name: 'John Doe',
        gender: Gender.man,
        tier: MemberTier.gold,
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&q=80',
        joinedAt: DateTime(2026)),
  ];

  static const announcements = [
    (
      tag: 'Society Update',
      date: 'Jun 12',
      title: 'A new chapter in Lisbon',
      description:
          'Our seventh sister club opens this autumn. Members will receive reciprocal access from day one.',
      by: 'The Founders',
      featured: true
    ),
    (
      tag: 'Important Notice',
      date: 'Jun 9',
      title: 'House code reminder',
      description: "Phones away on the Members' Floor. Discretion is the first courtesy of the Circle.",
      by: '',
      featured: false
    ),
    (
      tag: 'Club News',
      date: 'Jun 4',
      title: 'Resident chef announced',
      description: 'The kitchen welcomes a two-star talent for the summer season.',
      by: '',
      featured: false
    ),
  ];

  static const ambassadorBenefits = [
    (title: 'Free Membership', subtitle: 'No annual dues, demo'),
    (title: 'Free Event Access', subtitle: 'RSVP to weekly parties and big events, demo'),
    (title: 'Priority Seating', subtitle: 'Front tables held, demo'),
    (title: 'Trip Discount', subtitle: '20% off every trip, demo'),
    (title: 'Ambassador Network', subtitle: 'Private peer chat, demo'),
  ];

  static const tierBenefits = [
    (label: 'SM Royal Circle app access', silver: 'yes', gold: 'yes', diamond: 'yes'),
    (label: 'Community feed & member chat', silver: 'yes', gold: 'yes', diamond: 'yes'),
    (label: 'Weekly social parties', silver: 'yes', gold: 'yes', diamond: 'yes'),
    (label: 'Partner benefits & exclusive offers', silver: 'yes', gold: 'yes', diamond: 'yes'),
    (label: 'Member trips & experiences', silver: 'yes', gold: 'yes', diamond: 'yes'),
    (label: 'Priority ticket access', silver: 'Standard', gold: 'Before Silver', diamond: 'First access'),
    (label: 'Priority seating where available', silver: 'no', gold: 'yes', diamond: 'yes'),
    (label: 'Gold networking events', silver: 'no', gold: 'yes', diamond: 'yes'),
    (label: 'VIP ticket options where available', silver: 'no', gold: 'yes', diamond: 'yes'),
    (label: 'Black Diamond exclusive events', silver: 'no', gold: 'no', diamond: 'yes'),
    (label: 'The Secret Society', silver: 'no', gold: 'no', diamond: 'yes'),
    (label: 'Concierge-style member support', silver: 'no', gold: 'no', diamond: 'yes'),
    (label: 'Flagship events & premium trips', silver: 'no', gold: 'no', diamond: 'First access'),
  ];

  static const tiers = [
    (id: 'silver', name: 'Silver', price: 299, tag: '', showTag: false),
    (id: 'gold', name: 'Gold', price: 699, tag: 'Popular', showTag: true),
    (id: 'diamond', name: 'Black Diamond', price: 2500, tag: 'Founding Price', showTag: true),
  ];

  /// Full per-tier "what's included" copy for the membership detail screen.
  /// Backend-updatable later; these are the launch defaults from the spec.
  static const tierDetails = [
    (
      id: 'silver',
      name: 'Silver',
      price: 299,
      tagline: 'For members who want access to the SM Royal Circle community.',
      inheritNote: '',
      includes: [
        'Access to the SM Royal Circle app',
        'Community feed and member chat',
        'Access to weekly social parties (men purchase tickets; women may receive complimentary admission where applicable)',
        'Priority access to purchase tickets for public events',
        'Access to partner benefits and exclusive offers',
        'Access to member trips and experiences',
        'Exclusive media and community content',
      ],
    ),
    (
      id: 'gold',
      name: 'Gold',
      price: 699,
      tagline: 'Everything in Silver, plus elevated priority and access.',
      inheritNote: 'Everything in Silver, plus:',
      includes: [
        'Priority access to all event tickets before Silver Members',
        'Priority seating where available',
        'Access to exclusive Gold networking events',
        'Access to VIP ticket options where available',
        'Priority booking for trips and special experiences',
      ],
    ),
    (
      id: 'diamond',
      name: 'Black Diamond',
      price: 2500,
      tagline: 'Our most exclusive community. Founding price.',
      inheritNote: 'Everything in Gold, plus:',
      includes: [
        'Access to exclusive Black Diamond events',
        'Access to the Secret Society',
        'Concierge-style member support',
        'Highest level of partner benefits',
        'First access to premium trips and flagship events',
        "Membership in SM Royal Circle's most exclusive community",
      ],
    ),
  ];

  static const pastTickets = [
    (
      title: 'The Rooftop Gala',
      sub: 'Sat 22. VIP',
      price: r'$180.00',
      image: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=120&q=80'
    ),
    (
      title: "Chef's Table No. 9",
      sub: 'Thu 20. Standard',
      price: r'$95.00',
      image: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=120&q=80'
    ),
    (
      title: 'The Midnight Salon',
      sub: 'Fri 14. VIP',
      price: r'$150.00',
      image: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=120&q=80'
    ),
  ];

  static const billingHistory = [
    (title: 'Gold Tier Renewal', date: '14 Mar 2026', amount: r'$999.00'),
    (title: 'The Midnight Salon', date: '14 Feb 2026', amount: r'$75.00'),
    (title: 'The Rooftop Gala', date: '22 Jan 2026', amount: r'$180.00'),
  ];

  static const supportTickets = [
    (
      refNo: '#2041',
      category: 'Membership',
      subject: 'Question about Gold tier upgrade',
      status: 'Open',
      lastUpdate: 'Concierge replied. 2h ago'
    ),
    (
      refNo: '#2036',
      category: 'Events',
      subject: "Dietary note for Chef's Table",
      status: 'Awaiting you',
      lastUpdate: 'Updated. 1d ago'
    ),
    (
      refNo: '#1990',
      category: 'Payments',
      subject: 'Receipt for Salon ticket',
      status: 'Closed',
      lastUpdate: 'Closed. 6d ago'
    ),
  ];

  static const ticketThread = [
    (sender: 'member', text: 'Could you tell me what Black Diamond adds over my current tier?', time: '09:12'),
    (
      sender: 'concierge',
      text:
          'Of course. Black Diamond includes free events, priority seating and concierge on request. I will send the full comparison now.',
      time: '09:31'
    ),
  ];

  static const supportChatThread = [
    (sender: 'concierge', text: 'Good evening. How can I help you tonight?', time: '9:02 PM'),
    (sender: 'member', text: 'Could I add a guest to my Saturday reservation?', time: '9:04 PM'),
    (sender: 'concierge', text: 'Of course. I have added a second seat to your table. Anything else?', time: '9:05 PM'),
  ];

  static const myQuestions = [
    (
      question: 'Is the dress code different for the rooftop nights?',
      answer: 'Yes, smart elegant on the rooftop, no trainers. Black tie only applies to the Salon.',
      status: 'Answered',
      when: 'Yesterday'
    ),
    (
      question: "Can I bring a guest to the Chef's Table?",
      answer: '',
      status: 'Pending',
      when: '3 days ago'
    ),
  ];
}
