import 'package:hms_mobile/core/models/json_value.dart';

/// One day on the staff member's own attendance sheet.
class AttendanceDay {
  final int id;
  final String date;
  final String? shift;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final double hoursWorked;
  final String? notes;

  const AttendanceDay({
    required this.id,
    required this.date,
    this.shift,
    this.checkIn,
    this.checkOut,
    required this.status,
    required this.hoursWorked,
    this.notes,
  });

  factory AttendanceDay.fromJson(Map<String, dynamic> j) => AttendanceDay(
        id: asIntOr(j['id']),
        date: j['date']?.toString() ?? '',
        shift: j['shift']?.toString(),
        checkIn: j['check_in']?.toString(),
        checkOut: j['check_out']?.toString(),
        status: j['status']?.toString() ?? 'present',
        hoursWorked: asDoubleOr(j['hours_worked']),
        notes: j['notes']?.toString(),
      );

  /// "09:00 — 17:30", or whichever half was recorded.
  String get hours => [checkIn, checkOut].where((t) => (t ?? '').isNotEmpty).join(' — ');
}

class MyAttendance {
  final String month;
  final Map<String, num> summary;
  final List<AttendanceDay> days;

  const MyAttendance({required this.month, required this.summary, required this.days});

  factory MyAttendance.fromJson(Map<String, dynamic> j) => MyAttendance(
        month: j['month']?.toString() ?? '',
        summary: ((j['summary'] as Map?) ?? const {})
            .map((k, v) => MapEntry('$k', (v is num) ? v : asDoubleOr(v))),
        days: ((j['days'] as List?) ?? const [])
            .map((d) => AttendanceDay.fromJson((d as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class MyLeave {
  final int id;
  final String leaveType;
  final String fromDate;
  final String toDate;
  final int days;
  final String reason;
  final String status;
  final String? remarks;

  const MyLeave({
    required this.id,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.days,
    required this.reason,
    required this.status,
    this.remarks,
  });

  factory MyLeave.fromJson(Map<String, dynamic> j) => MyLeave(
        id: asIntOr(j['id']),
        leaveType: j['leave_type']?.toString() ?? 'casual',
        fromDate: j['from_date']?.toString() ?? '',
        toDate: j['to_date']?.toString() ?? '',
        days: asIntOr(j['days']),
        reason: j['reason']?.toString() ?? '',
        status: j['status']?.toString() ?? 'pending',
        remarks: j['remarks']?.toString(),
      );

  bool get isPending => status == 'pending';

  String get span => fromDate == toDate ? fromDate : '$fromDate → $toDate';
}

class MyLeaves {
  final Map<String, int> summary;
  final List<MyLeave> leaves;

  const MyLeaves({required this.summary, required this.leaves});

  factory MyLeaves.fromJson(Map<String, dynamic> j) => MyLeaves(
        summary: ((j['summary'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', asIntOr(v))),
        leaves: ((j['leaves'] as List?) ?? const [])
            .map((l) => MyLeave.fromJson((l as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// A message the hospital sent to this person.
class InboxMessage {
  final int id;
  final String channel;
  final String? template;
  final String message;
  final String status;
  final String? sentAt;
  final bool read;

  const InboxMessage({
    required this.id,
    required this.channel,
    this.template,
    required this.message,
    required this.status,
    this.sentAt,
    required this.read,
  });

  factory InboxMessage.fromJson(Map<String, dynamic> j) => InboxMessage(
        id: asIntOr(j['id']),
        channel: j['channel']?.toString() ?? 'sms',
        template: j['template']?.toString(),
        message: j['message']?.toString() ?? '',
        status: j['status']?.toString() ?? 'sent',
        sentAt: j['sent_at']?.toString(),
        read: j['read'] == true,
      );

  /// "Appointment reminder" out of "appointment_reminder".
  String get title {
    final raw = (template ?? '').replaceAll('_', ' ').trim();
    if (raw.isEmpty) return 'Message';
    return raw[0].toUpperCase() + raw.substring(1);
  }
}

class Inbox {
  final int unread;
  final List<InboxMessage> messages;

  const Inbox({required this.unread, required this.messages});

  factory Inbox.fromJson(Map<String, dynamic> j) => Inbox(
        unread: asIntOr(j['unread']),
        messages: ((j['notifications'] as List?) ?? const [])
            .map((n) => InboxMessage.fromJson((n as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// One hit from the search box: a patient, an appointment or an invoice.
class SearchHit {
  final String type;
  final int id;
  final String title;
  final String subtitle;

  const SearchHit({required this.type, required this.id, required this.title, required this.subtitle});

  factory SearchHit.fromJson(Map<String, dynamic> j) => SearchHit(
        type: j['type']?.toString() ?? '',
        id: asIntOr(j['id']),
        title: j['title']?.toString() ?? '',
        subtitle: j['subtitle']?.toString() ?? '',
      );
}
