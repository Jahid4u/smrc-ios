/// Models for backend payloads that don't map to Member/ClubEvent.
library;

import 'package:flutter/material.dart';

class Announcement {
  final int id;
  final String tag, title, description, signedBy, dateLabel;
  final bool featured;
  const Announcement({
    required this.id,
    required this.tag,
    required this.title,
    required this.description,
    required this.signedBy,
    required this.dateLabel,
    required this.featured,
  });

  factory Announcement.fromApi(Map<String, dynamic> j) => Announcement(
        id: int.tryParse('${j['id']}') ?? 0,
        tag: (j['tag'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        signedBy: (j['signed_by'] ?? '') as String,
        dateLabel: (j['date_label'] ?? '') as String,
        featured: j['featured'] == true || j['featured'] == 1 || j['featured'] == '1',
      );
}

class BenefitItem {
  final String title, subtitle, image, badge, off, appliesTo, icon;
  const BenefitItem(
      {required this.title,
      required this.subtitle,
      required this.image,
      required this.badge,
      required this.off,
      this.appliesTo = 'all',
      this.icon = 'tag'});

  /// Human labels of the tiers this benefit targets ('' when it's for everyone).
  List<String> get tierLabels {
    if (appliesTo.isEmpty || appliesTo == 'all') return const [];
    const names = {
      'silver': 'Silver',
      'gold': 'Gold',
      'diamond': 'Black Diamond',
      'amb': 'Ambassador',
    };
    return appliesTo.split(',').map((s) => names[s.trim()] ?? s.trim()).toList();
  }

  factory BenefitItem.fromApi(Map<String, dynamic> j) => BenefitItem(
        title: (j['title'] ?? '') as String,
        subtitle: (j['subtitle'] ?? '') as String,
        image: (j['image'] ?? '') as String,
        badge: (j['badge'] ?? '') as String,
        off: (j['off'] ?? '') as String,
        appliesTo: (j['applies_to'] ?? j['appliesTo'] ?? 'all') as String? ?? 'all',
        icon: (j['icon'] ?? 'tag') as String? ?? 'tag',
      );

  /// Maps the admin icon key to a Material icon shown on list rows.
  IconData get iconData => benefitIconFor(icon);
}

/// Shared benefit icon map — keys must match the admin panel's BENEFIT_ICONS.
IconData benefitIconFor(String key) {
  switch (key) {
    case 'dining':
      return Icons.restaurant_outlined;
    case 'travel':
      return Icons.public_outlined;
    case 'wellness':
      return Icons.favorite_border;
    case 'hotel':
      return Icons.hotel_outlined;
    case 'spa':
      return Icons.spa_outlined;
    case 'fitness':
      return Icons.fitness_center_outlined;
    case 'shopping':
      return Icons.shopping_bag_outlined;
    case 'gift':
      return Icons.card_giftcard_outlined;
    case 'car':
      return Icons.directions_car_outlined;
    case 'drink':
      return Icons.local_bar_outlined;
    case 'ticket':
      return Icons.confirmation_num_outlined;
    case 'star':
      return Icons.star_border;
    case 'diamond':
      return Icons.diamond_outlined;
    case 'crown':
      return Icons.workspace_premium_outlined;
    case 'tag':
    default:
      return Icons.local_offer_outlined;
  }
}

class BenefitCategory {
  final String name, icon, style;
  final List<BenefitItem> items;
  const BenefitCategory({required this.name, required this.icon, required this.style, required this.items});

  factory BenefitCategory.fromApi(Map<String, dynamic> j) => BenefitCategory(
        name: (j['name'] ?? '') as String,
        icon: (j['icon'] ?? '') as String,
        style: (j['style'] ?? 'list') as String,
        items: ((j['items'] ?? []) as List)
            .map((e) => BenefitItem.fromApi((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class AmbassadorBenefit {
  final String title, description;
  const AmbassadorBenefit({required this.title, required this.description});
  factory AmbassadorBenefit.fromApi(Map<String, dynamic> j) => AmbassadorBenefit(
        title: (j['title'] ?? '') as String,
        description: (j['description'] ?? '') as String,
      );
}

class BenefitsPayload {
  final List<BenefitCategory> categories;
  final List<AmbassadorBenefit> ambassador;
  const BenefitsPayload({required this.categories, required this.ambassador});

  factory BenefitsPayload.fromApi(Map<String, dynamic> j) => BenefitsPayload(
        categories: ((j['categories'] ?? []) as List)
            .map((e) => BenefitCategory.fromApi((e as Map).cast<String, dynamic>()))
            .toList(),
        ambassador: ((j['ambassador_benefits'] ?? []) as List)
            .map((e) => AmbassadorBenefit.fromApi((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class TierInfo {
  final String tierKey, name, tag, colorHex;
  final double price;
  final bool showTag;
  const TierInfo(
      {required this.tierKey,
      required this.name,
      required this.tag,
      required this.colorHex,
      required this.price,
      required this.showTag});

  factory TierInfo.fromApi(Map<String, dynamic> j) => TierInfo(
        tierKey: (j['tier_key'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        tag: (j['tag'] ?? '') as String,
        colorHex: (j['color_hex'] ?? '') as String,
        price: double.tryParse('${j['price']}') ?? 0,
        showTag: j['show_tag'] == true || j['show_tag'] == 1 || j['show_tag'] == '1',
      );
}

class TierBenefitRow {
  final String label;
  final Map<String, dynamic> values; // {silver: 'yes'|'no'|'2', gold: ..., diamond: ...}
  const TierBenefitRow({required this.label, required this.values});

  factory TierBenefitRow.fromApi(Map<String, dynamic> j) => TierBenefitRow(
        label: (j['label'] ?? '') as String,
        values: ((j['values'] ?? {}) as Map).cast<String, dynamic>(),
      );
}

class TiersPayload {
  final List<TierInfo> tiers;
  final List<TierBenefitRow> rows;
  const TiersPayload({required this.tiers, required this.rows});

  factory TiersPayload.fromApi(Map<String, dynamic> j) => TiersPayload(
        tiers: ((j['tiers'] ?? []) as List)
            .map((e) => TierInfo.fromApi((e as Map).cast<String, dynamic>()))
            .toList(),
        rows: ((j['benefit_rows'] ?? []) as List)
            .map((e) => TierBenefitRow.fromApi((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class QuestionItem {
  final int id;
  final String question, answer, status, createdAt, answeredAt;
  const QuestionItem(
      {required this.id,
      required this.question,
      required this.answer,
      required this.status,
      required this.createdAt,
      required this.answeredAt});

  bool get answered => status == 'answered' || answer.isNotEmpty;

  factory QuestionItem.fromApi(Map<String, dynamic> j) => QuestionItem(
        id: int.tryParse('${j['id']}') ?? 0,
        question: (j['question'] ?? '') as String,
        answer: (j['answer'] ?? '') as String? ?? '',
        status: (j['status'] ?? '') as String,
        createdAt: (j['created_at'] ?? '') as String,
        answeredAt: (j['answered_at'] ?? '') as String? ?? '',
      );
}

class ChatMsg {
  final int id;
  final String senderType, senderName, message, createdAt, imageUrl;
  const ChatMsg(
      {required this.id,
      required this.senderType,
      required this.senderName,
      required this.message,
      required this.createdAt,
      this.imageUrl = ''});

  bool get fromMember => senderType == 'member';

  factory ChatMsg.fromApi(Map<String, dynamic> j) => ChatMsg(
        id: int.tryParse('${j['id']}') ?? 0,
        senderType: (j['sender_type'] ?? '') as String,
        senderName: (j['sender_name'] ?? '') as String,
        message: (j['message'] ?? '') as String,
        createdAt: (j['created_at'] ?? '') as String,
        imageUrl: (j['image_url'] ?? '') as String? ?? '',
      );
}

class SupportThread {
  final int conversationId;
  final String status;
  final String? mutedUntil;
  final List<ChatMsg> messages;
  const SupportThread(
      {required this.conversationId, this.status = 'open', required this.mutedUntil, required this.messages});

  bool get closed => status == 'closed';

  factory SupportThread.fromApi(Map<String, dynamic> j) => SupportThread(
        conversationId: int.tryParse('${j['conversation_id']}') ?? 0,
        status: (j['status'] ?? 'open') as String,
        mutedUntil: j['muted_until'] as String?,
        messages: ((j['messages'] ?? []) as List)
            .map((e) => ChatMsg.fromApi((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class GroupMsg {
  final int id;
  final String senderType, senderName, message, createdAt, avatar, tier, imageUrl;
  final bool mine;
  const GroupMsg(
      {required this.id,
      required this.senderType,
      required this.senderName,
      required this.message,
      required this.createdAt,
      required this.avatar,
      required this.tier,
      required this.mine,
      this.imageUrl = ''});

  factory GroupMsg.fromApi(Map<String, dynamic> j) => GroupMsg(
        id: int.tryParse('${j['id']}') ?? 0,
        senderType: (j['sender_type'] ?? '') as String,
        senderName: (j['sender_name'] ?? '') as String,
        message: (j['message'] ?? '') as String,
        createdAt: (j['created_at'] ?? '') as String,
        avatar: (j['avatar'] ?? '') as String? ?? '',
        tier: (j['tier'] ?? '') as String? ?? '',
        mine: j['mine'] == true,
        imageUrl: (j['image_url'] ?? '') as String? ?? '',
      );
}

class TicketReply {
  final int id;
  final String senderType, message, createdAt;
  const TicketReply(
      {required this.id, required this.senderType, required this.message, required this.createdAt});

  bool get fromMember => senderType == 'member';

  factory TicketReply.fromApi(Map<String, dynamic> j) => TicketReply(
        id: int.tryParse('${j['id']}') ?? 0,
        senderType: (j['sender_type'] ?? '') as String,
        message: (j['message'] ?? '') as String,
        createdAt: (j['created_at'] ?? '') as String,
      );
}

class TicketItem {
  final int id;
  final String refNo, subject, category, body, status, createdAt, updatedAt;
  final List<TicketReply> replies;
  const TicketItem(
      {required this.id,
      required this.refNo,
      required this.subject,
      required this.category,
      required this.body,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      required this.replies});

  bool get open => status == 'open';

  factory TicketItem.fromApi(Map<String, dynamic> j) => TicketItem(
        id: int.tryParse('${j['id']}') ?? 0,
        refNo: (j['ref_no'] ?? '') as String,
        subject: (j['subject'] ?? '') as String,
        category: (j['category'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        status: (j['status'] ?? '') as String,
        createdAt: (j['created_at'] ?? '') as String,
        updatedAt: (j['updated_at'] ?? '') as String,
        replies: ((j['replies'] ?? []) as List)
            .map((e) => TicketReply.fromApi((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class GroupChatPayload {
  final String pinned;
  final List<GroupMsg> messages;
  const GroupChatPayload({required this.pinned, required this.messages});
}

class EventTicket {
  final int id;
  final String ticketNo, title, eventType, dateLabel, location, eventImage, status;
  final int eventId;
  final bool isPast;

  const EventTicket({
    required this.id, required this.ticketNo, required this.title,
    required this.eventType, required this.dateLabel, required this.location,
    required this.eventImage, required this.status, required this.eventId,
    this.isPast = false,
  });

  factory EventTicket.fromApi(Map<String, dynamic> j) => EventTicket(
    id: (j['id'] as num?)?.toInt() ?? 0,
    ticketNo: (j['ticket_no'] ?? '') as String,
    title: (j['title'] ?? '') as String,
    eventType: (j['event_type'] ?? '') as String,
    dateLabel: (j['date_label'] ?? '') as String,
    location: (j['location'] ?? '') as String,
    eventImage: (j['event_image'] ?? '') as String,
    status: (j['status'] ?? 'active') as String,
    eventId: (j['event_id'] as num?)?.toInt() ?? 0,
    isPast: j['is_past'] == true || j['is_past'] == 1,
  );
}

/// A single membership billing/payment transaction.
class BillingEntry {
  final String title;
  final String date;
  final String amount;
  const BillingEntry({required this.title, required this.date, required this.amount});

  factory BillingEntry.fromApi(Map<String, dynamic> j) => BillingEntry(
        title: (j['title'] ?? '') as String,
        date: (j['date'] ?? '') as String,
        amount: (j['amount'] ?? '') as String,
      );
}

/// An active complimentary benefit offer granted by an admin.
class BenefitOffer {
  final int id;
  final String tier;
  final String tierName;
  final int durationDays;
  final String note;
  final String endsAt;
  final String title;
  final String message;
  final String screenTitle;
  final String screenBody;
  final bool seen;
  final bool accepted;
  const BenefitOffer({
    required this.id,
    required this.tier,
    required this.tierName,
    required this.durationDays,
    required this.note,
    required this.endsAt,
    required this.title,
    required this.message,
    required this.screenTitle,
    required this.screenBody,
    required this.seen,
    required this.accepted,
  });

  factory BenefitOffer.fromApi(Map<String, dynamic> j) => BenefitOffer(
        id: (j['id'] as num?)?.toInt() ?? 0,
        tier: (j['tier'] ?? '') as String,
        tierName: (j['tierName'] ?? '') as String,
        durationDays: (j['durationDays'] as num?)?.toInt() ?? 0,
        note: (j['note'] ?? '') as String,
        endsAt: (j['endsAt'] ?? '') as String,
        title: (j['title'] ?? 'A gift for you') as String,
        message: (j['message'] ?? '') as String,
        screenTitle: (j['screenTitle'] as String?)?.trim().isNotEmpty == true
            ? j['screenTitle'] as String
            : 'Founding Members. Silver',
        screenBody: (j['screenBody'] as String?)?.trim().isNotEmpty == true
            ? j['screenBody'] as String
            : 'As one of our first founding members, your Silver membership is complimentary for 6 months. Events, benefits, photos and the whole SM Society are included.',
        seen: j['seen'] == true,
        accepted: j['accepted'] == true,
      );
}

/// A single in-app notification.
class AppNotification {
  final int id;
  final String category;
  final String title;
  final String body;
  final String icon;
  final String link;
  final bool isRead;
  final String time;
  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.icon,
    required this.link,
    required this.isRead,
    required this.time,
  });

  factory AppNotification.fromApi(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] as num?)?.toInt() ?? 0,
        category: (j['category'] ?? 'General') as String,
        title: (j['title'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        icon: (j['icon'] ?? 'bell') as String,
        link: (j['link'] ?? '') as String,
        isRead: j['isRead'] == true,
        time: (j['time'] ?? '') as String,
      );
}
