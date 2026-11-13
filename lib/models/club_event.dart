import 'member.dart';
import 'member_tier.dart';

enum EventType { weekly, big, trip }

extension EventTypeX on EventType {
  String get label {
    switch (this) {
      case EventType.weekly:
        return 'Weekly Party';
      case EventType.big:
        return 'Big Event';
      case EventType.trip:
        return 'Trip';
    }
  }
}

/// Per-tier discount from the backend: {appliesTo: silver|gold|diamond|amb,
/// amount: 50|null, percent: 15|null}
class EventDiscount {
  final String appliesTo;
  final double? amount;
  final double? percent;
  const EventDiscount({required this.appliesTo, this.amount, this.percent});

  factory EventDiscount.fromApi(Map<String, dynamic> j) => EventDiscount(
        appliesTo: (j['appliesTo'] ?? '') as String,
        amount: j['amount'] == null ? null : double.tryParse('${j['amount']}'),
        percent: j['percent'] == null ? null : double.tryParse('${j['percent']}'),
      );
}

class ClubEvent {
  final String id;
  final String title;
  final String? coverImageUrl;
  final EventType type;
  final DateTime? endDate;
  final String dateLabel; // e.g. "Every Friday · 10 PM · Members' Floor"
  final double basePrice;
  final String location;
  final String description;
  final bool featured;
  final String galleryLink;
  final String footageLink;
  final List<EventDiscount> discounts;

  const ClubEvent({
    required this.id,
    required this.title,
    this.coverImageUrl,
    required this.type,
    this.endDate,
    this.dateLabel = '',
    required this.basePrice,
    required this.location,
    required this.description,
    this.featured = false,
    this.galleryLink = '',
    this.footageLink = '',
    this.discounts = const [],
  });

  /// Past events leave Events and appear in Gallery/Footage pickers.
  /// The end date is INCLUSIVE — the event stays live through that whole day.
  bool get isPast {
    if (endDate == null) return false;
    final lastMoment = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
    return lastMoment.isBefore(DateTime.now());
  }

  String _tierKey(MemberTier t) {
    switch (t) {
      case MemberTier.gold:
        return 'gold';
      case MemberTier.blackDiamond:
        return 'diamond';
      case MemberTier.ambassador:
        return 'amb';
      case MemberTier.admin:
        return 'admin';
      case MemberTier.silver:
        return 'silver';
    }
  }

  /// Club pricing rules — exact backend behaviour:
  ///  - Weekly: women & ambassadors ride free; everyone else pays base.
  ///  - Big: ambassadors free; everyone else pays base.
  ///  - Trip: everyone pays; per-tier discounts (amount or percent) apply.
  ///  - Admin previews at base price.
  double priceFor(Member member) {
    switch (type) {
      case EventType.weekly:
        if (member.gender == Gender.woman || member.tier == MemberTier.ambassador) return 0;
        break;
      case EventType.big:
        if (member.tier == MemberTier.ambassador) return 0;
        break;
      case EventType.trip:
        break;
    }
    var price = basePrice;
    final key = _tierKey(member.tier);
    for (final d in discounts) {
      if (d.appliesTo != key) continue;
      if (d.percent != null) price -= price * (d.percent! / 100);
      if (d.amount != null) price -= d.amount!;
    }
    return price < 0 ? 0 : price;
  }

  bool isFreeFor(Member member) => priceFor(member) == 0;

  /// Discount summary line for the pricing card, e.g. "Ambassador price. 15% off".
  String? discountNoteFor(Member member) {
    final key = _tierKey(member.tier);
    for (final d in discounts) {
      if (d.appliesTo != key) continue;
      if (d.percent != null) return '${d.percent!.toStringAsFixed(0)}% off \$${basePrice.toStringAsFixed(0)}';
      if (d.amount != null) return '\$${d.amount!.toStringAsFixed(0)} off \$${basePrice.toStringAsFixed(0)}';
    }
    return null;
  }

  /// Backend row from GET /app/events.
  factory ClubEvent.fromApi(Map<String, dynamic> j) => ClubEvent(
        id: '${j['id']}',
        title: (j['title'] ?? '') as String,
        coverImageUrl: (j['image'] ?? '') == '' ? null : j['image'] as String,
        type: EventType.values.firstWhere((t) => t.name == j['type'], orElse: () => EventType.weekly),
        endDate: DateTime.tryParse('${j['end_date'] ?? ''}'),
        dateLabel: (j['date_label'] ?? '') as String,
        basePrice: double.tryParse('${j['member_price'] ?? 0}') ?? 0,
        location: (j['location'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        featured: j['featured'] == true || j['featured'] == 1 || j['featured'] == '1',
        galleryLink: (j['gallery_link'] ?? '') as String? ?? '',
        footageLink: (j['footage_link'] ?? '') as String? ?? '',
        discounts: ((j['discounts'] ?? []) as List)
            .map((e) => EventDiscount.fromApi((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}
