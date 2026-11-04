import 'package:hms_mobile/core/models/json_value.dart';

/// Payloads for the administrator's own endpoints
/// (app/Http/Controllers/Api/Admin*Controller.php).
///
/// Money and counts arrive as numbers from MySQL but as strings through
/// some driver/serialiser combinations, so every numeric field goes
/// through the shared readers rather than a bare cast.

// ------------------------------------------------------------- dashboard

class AdminDashboard {
  final int patientsTotal;
  final int patientsActive;
  final int patientsOp;
  final int patientsIp;

  final int appointmentsTotal;
  final int appointmentsToday;
  final int appointmentsScheduled;
  final int appointmentsCompleted;
  final int appointmentsCancelled;

  final double revenueTotal;
  final double revenueToday;
  final double outstanding;
  final int pendingBills;

  final int doctors;
  final int availableBeds;
  final int labOrders;
  final int pendingLabOrders;
  final int lowStockDrugs;
  final int nearExpiryDrugs;

  final List<AdminMonthPoint> monthly;

  const AdminDashboard({
    required this.patientsTotal,
    required this.patientsActive,
    required this.patientsOp,
    required this.patientsIp,
    required this.appointmentsTotal,
    required this.appointmentsToday,
    required this.appointmentsScheduled,
    required this.appointmentsCompleted,
    required this.appointmentsCancelled,
    required this.revenueTotal,
    required this.revenueToday,
    required this.outstanding,
    required this.pendingBills,
    required this.doctors,
    required this.availableBeds,
    required this.labOrders,
    required this.pendingLabOrders,
    required this.lowStockDrugs,
    required this.nearExpiryDrugs,
    required this.monthly,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    final p = (json['patients'] as Map?)?.cast<String, dynamic>() ?? const {};
    final a = (json['appointments'] as Map?)?.cast<String, dynamic>() ?? const {};
    final r = (json['revenue'] as Map?)?.cast<String, dynamic>() ?? const {};
    final c = (json['capacity'] as Map?)?.cast<String, dynamic>() ?? const {};

    return AdminDashboard(
      patientsTotal: asIntOr(p['total']),
      patientsActive: asIntOr(p['active']),
      patientsOp: asIntOr(p['op']),
      patientsIp: asIntOr(p['ip']),
      appointmentsTotal: asIntOr(a['total']),
      appointmentsToday: asIntOr(a['today']),
      appointmentsScheduled: asIntOr(a['scheduled']),
      appointmentsCompleted: asIntOr(a['completed']),
      appointmentsCancelled: asIntOr(a['cancelled']),
      revenueTotal: asDoubleOr(r['total']),
      revenueToday: asDoubleOr(r['today']),
      outstanding: asDoubleOr(r['outstanding']),
      pendingBills: asIntOr(r['pending_bills']),
      doctors: asIntOr(c['doctors']),
      availableBeds: asIntOr(c['available_beds']),
      labOrders: asIntOr(c['lab_orders']),
      pendingLabOrders: asIntOr(c['pending_lab_orders']),
      lowStockDrugs: asIntOr(c['low_stock_drugs']),
      nearExpiryDrugs: asIntOr(c['near_expiry_drugs']),
      monthly: ((json['monthly'] as List?) ?? const [])
          .map((m) => AdminMonthPoint.fromJson((m as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class AdminMonthPoint {
  final String month;
  final int patients;
  final double revenue;

  const AdminMonthPoint({required this.month, required this.patients, required this.revenue});

  factory AdminMonthPoint.fromJson(Map<String, dynamic> json) => AdminMonthPoint(
        month: json['month']?.toString() ?? '',
        patients: asIntOr(json['patients']),
        revenue: asDoubleOr(json['revenue']),
      );
}

// --------------------------------------------------------------- reports

class AdminPatientReportRow {
  final int id;
  final String? mrn;
  final String name;
  final String? gender;
  final String? patientType;
  final String? status;
  final String? registeredOn;

  const AdminPatientReportRow({
    required this.id,
    this.mrn,
    required this.name,
    this.gender,
    this.patientType,
    this.status,
    this.registeredOn,
  });

  factory AdminPatientReportRow.fromJson(Map<String, dynamic> j) => AdminPatientReportRow(
        id: asIntOr(j['id']),
        mrn: j['mrn']?.toString(),
        name: j['name']?.toString() ?? '—',
        gender: j['gender']?.toString(),
        patientType: j['patient_type']?.toString(),
        status: j['status']?.toString(),
        registeredOn: j['registered_on']?.toString(),
      );
}

class AdminBillingReportRow {
  final int id;
  final String? invoiceNo;
  final String? patientName;
  final String? invoiceDate;
  final String? status;
  final double total;
  final double paid;
  final double balance;

  const AdminBillingReportRow({
    required this.id,
    this.invoiceNo,
    this.patientName,
    this.invoiceDate,
    this.status,
    required this.total,
    required this.paid,
    required this.balance,
  });

  factory AdminBillingReportRow.fromJson(Map<String, dynamic> j) => AdminBillingReportRow(
        id: asIntOr(j['id']),
        invoiceNo: j['invoice_no']?.toString(),
        patientName: j['patient_name']?.toString(),
        invoiceDate: j['invoice_date']?.toString(),
        status: j['status']?.toString(),
        total: asDoubleOr(j['total']),
        paid: asDoubleOr(j['paid_amount']),
        balance: asDoubleOr(j['balance']),
      );
}

class AdminInventoryReportRow {
  final int id;
  final String drugName;
  final String? category;
  final int currentStock;
  final int minStockLevel;
  final double unitPrice;
  final String? expiryDate;

  const AdminInventoryReportRow({
    required this.id,
    required this.drugName,
    this.category,
    required this.currentStock,
    required this.minStockLevel,
    required this.unitPrice,
    this.expiryDate,
  });

  factory AdminInventoryReportRow.fromJson(Map<String, dynamic> j) => AdminInventoryReportRow(
        id: asIntOr(j['id']),
        drugName: j['drug_name']?.toString() ?? '—',
        category: j['category']?.toString(),
        currentStock: asIntOr(j['current_stock']),
        minStockLevel: asIntOr(j['min_stock_level']),
        unitPrice: asDoubleOr(j['unit_price']),
        expiryDate: j['expiry_date']?.toString(),
      );
}

/// A report is a few totals plus its rows; the three differ only in what
/// a row is, so they share one envelope.
class AdminReport<T> {
  final Map<String, num> totals;
  final List<T> rows;

  const AdminReport({required this.totals, required this.rows});

  factory AdminReport.fromJson(
    Map<String, dynamic> json,
    String rowsKey,
    T Function(Map<String, dynamic>) row, {
    String totalsKey = 'totals',
  }) {
    final raw = (json[totalsKey] as Map?)?.cast<String, dynamic>() ?? const {};
    return AdminReport(
      totals: {
        for (final e in raw.entries)
          if (e.value is num || num.tryParse(e.value.toString()) != null)
            e.key: asDoubleOr(e.value),
      },
      rows: ((json[rowsKey] as List?) ?? const [])
          .map((r) => row((r as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

// --------------------------------------------------------------- people

class AdminDoctor {
  final int id;
  final String? doctorId;
  final String name;
  final String? email;
  final String? phone;
  final String? specialization;
  final String? department;
  final double consultationFee;
  final String? status;

  const AdminDoctor({
    required this.id,
    this.doctorId,
    required this.name,
    this.email,
    this.phone,
    this.specialization,
    this.department,
    required this.consultationFee,
    this.status,
  });

  factory AdminDoctor.fromJson(Map<String, dynamic> j) => AdminDoctor(
        id: asIntOr(j['id']),
        doctorId: j['doctor_id']?.toString(),
        name: j['name']?.toString() ?? '—',
        email: j['email']?.toString(),
        phone: j['phone']?.toString(),
        specialization: j['specialization']?.toString(),
        department: j['department']?.toString(),
        consultationFee: asDoubleOr(j['consultation_fee']),
        status: j['status']?.toString(),
      );
}

class AdminUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? role;

  const AdminUser({required this.id, required this.name, required this.email, this.phone, this.role});

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: asIntOr(j['id']),
        name: j['name']?.toString() ?? '—',
        email: j['email']?.toString() ?? '',
        phone: j['phone']?.toString(),
        role: j['role']?.toString(),
      );
}

/// How many of a plan's seats are used. `limit` is null on an unlimited
/// plan, which is not the same as zero.
class AdminUsage {
  final int used;
  final int? limit;

  const AdminUsage({required this.used, this.limit});

  factory AdminUsage.fromJson(Map<String, dynamic>? j) =>
      AdminUsage(used: asIntOr(j?['used']), limit: j?['limit'] == null ? null : asIntOr(j?['limit']));

  bool get isUnlimited => limit == null;
  String get label => isUnlimited ? '$used used' : '$used of $limit used';
}

// ------------------------------------------------------------ inventory

class AdminInventoryItem {
  final int id;
  final String? itemCode;
  final String itemName;
  final String? category;
  final String? unit;
  final int currentStock;
  final int minStockLevel;
  final double unitPrice;
  final String? supplier;
  final String? location;
  final String? status;
  final bool isLowStock;

  const AdminInventoryItem({
    required this.id,
    this.itemCode,
    required this.itemName,
    this.category,
    this.unit,
    required this.currentStock,
    required this.minStockLevel,
    required this.unitPrice,
    this.supplier,
    this.location,
    this.status,
    required this.isLowStock,
  });

  factory AdminInventoryItem.fromJson(Map<String, dynamic> j) => AdminInventoryItem(
        id: asIntOr(j['id']),
        itemCode: j['item_code']?.toString(),
        itemName: j['item_name']?.toString() ?? '—',
        category: j['category']?.toString(),
        unit: j['unit']?.toString(),
        currentStock: asIntOr(j['current_stock']),
        minStockLevel: asIntOr(j['min_stock_level']),
        unitPrice: asDoubleOr(j['unit_price']),
        supplier: j['supplier']?.toString(),
        location: j['location']?.toString(),
        status: j['status']?.toString(),
        isLowStock: j['is_low_stock'] == true,
      );
}

class AdminPurchaseOrder {
  final int id;
  final String? poNo;
  final String? supplier;
  final String? status;
  final String? orderDate;
  final String? expectedDate;
  final String? receivedDate;
  final double totalAmount;
  final int itemCount;

  const AdminPurchaseOrder({
    required this.id,
    this.poNo,
    this.supplier,
    this.status,
    this.orderDate,
    this.expectedDate,
    this.receivedDate,
    required this.totalAmount,
    required this.itemCount,
  });

  factory AdminPurchaseOrder.fromJson(Map<String, dynamic> j) => AdminPurchaseOrder(
        id: asIntOr(j['id']),
        poNo: j['po_no']?.toString(),
        supplier: j['supplier']?.toString(),
        status: j['status']?.toString(),
        orderDate: j['order_date']?.toString(),
        expectedDate: j['expected_date']?.toString(),
        receivedDate: j['received_date']?.toString(),
        totalAmount: asDoubleOr(j['total_amount']),
        itemCount: asIntOr(j['item_count']),
      );

  bool get isReceived => status == 'received';
}

class AdminService {
  final int id;
  final String? serviceCode;
  final String serviceName;
  final String? category;
  final double price;
  final String? description;
  final String? status;

  const AdminService({
    required this.id,
    this.serviceCode,
    required this.serviceName,
    this.category,
    required this.price,
    this.description,
    this.status,
  });

  factory AdminService.fromJson(Map<String, dynamic> j) => AdminService(
        id: asIntOr(j['id']),
        serviceCode: j['service_code']?.toString(),
        serviceName: j['service_name']?.toString() ?? '—',
        category: j['category']?.toString(),
        price: asDoubleOr(j['price']),
        description: j['description']?.toString(),
        status: j['status']?.toString(),
      );
}

// ------------------------------------------------------------------- hr

class AdminAttendanceRow {
  final int id;
  final int userId;
  final String? userName;
  final String? shift;
  final String? checkIn;
  final String? checkOut;
  final String? status;
  final String? notes;

  const AdminAttendanceRow({
    required this.id,
    required this.userId,
    this.userName,
    this.shift,
    this.checkIn,
    this.checkOut,
    this.status,
    this.notes,
  });

  factory AdminAttendanceRow.fromJson(Map<String, dynamic> j) => AdminAttendanceRow(
        id: asIntOr(j['id']),
        userId: asIntOr(j['user_id']),
        userName: j['user_name']?.toString(),
        shift: j['shift']?.toString(),
        checkIn: j['check_in']?.toString(),
        checkOut: j['check_out']?.toString(),
        status: j['status']?.toString(),
        notes: j['notes']?.toString(),
      );
}

class AdminLeave {
  final int id;
  final int userId;
  final String? userName;
  final String? leaveType;
  final String? fromDate;
  final String? toDate;
  final int days;
  final String? reason;
  final String? status;
  final String? remarks;

  const AdminLeave({
    required this.id,
    required this.userId,
    this.userName,
    this.leaveType,
    this.fromDate,
    this.toDate,
    required this.days,
    this.reason,
    this.status,
    this.remarks,
  });

  factory AdminLeave.fromJson(Map<String, dynamic> j) => AdminLeave(
        id: asIntOr(j['id']),
        userId: asIntOr(j['user_id']),
        userName: j['user_name']?.toString(),
        leaveType: j['leave_type']?.toString(),
        fromDate: j['from_date']?.toString(),
        toDate: j['to_date']?.toString(),
        days: asIntOr(j['days']),
        reason: j['reason']?.toString(),
        status: j['status']?.toString(),
        remarks: j['remarks']?.toString(),
      );

  bool get isPending => status == 'pending';
}

// ------------------------------------------------- settings / log / notes

class AdminActivityEntry {
  final int id;
  final String? userName;
  final String? action;
  final String? module;
  final String? description;
  final String? ipAddress;
  final String? at;

  const AdminActivityEntry({
    required this.id,
    this.userName,
    this.action,
    this.module,
    this.description,
    this.ipAddress,
    this.at,
  });

  factory AdminActivityEntry.fromJson(Map<String, dynamic> j) => AdminActivityEntry(
        id: asIntOr(j['id']),
        userName: j['user_name']?.toString(),
        action: j['action']?.toString(),
        module: j['module']?.toString(),
        description: j['description']?.toString(),
        ipAddress: j['ip_address']?.toString(),
        at: j['at']?.toString(),
      );
}

class AdminNotificationEntry {
  final int id;
  final String? channel;
  final String? recipient;
  final String? template;
  final String? status;
  final String? errorMessage;
  final String? sentAt;

  const AdminNotificationEntry({
    required this.id,
    this.channel,
    this.recipient,
    this.template,
    this.status,
    this.errorMessage,
    this.sentAt,
  });

  factory AdminNotificationEntry.fromJson(Map<String, dynamic> j) => AdminNotificationEntry(
        id: asIntOr(j['id']),
        channel: j['channel']?.toString(),
        recipient: j['recipient']?.toString(),
        template: j['template']?.toString(),
        status: j['status']?.toString(),
        errorMessage: j['error_message']?.toString(),
        sentAt: j['sent_at']?.toString(),
      );
}

class AdminTemplate {
  final int id;
  final String name;
  final String? title;
  final String? sms;
  final String? whatsapp;
  final String? email;
  final bool isActive;

  const AdminTemplate({
    required this.id,
    required this.name,
    this.title,
    this.sms,
    this.whatsapp,
    this.email,
    required this.isActive,
  });

  factory AdminTemplate.fromJson(Map<String, dynamic> j) => AdminTemplate(
        id: asIntOr(j['id']),
        name: j['name']?.toString() ?? '—',
        title: j['title']?.toString(),
        sms: j['sms_template']?.toString(),
        whatsapp: j['whatsapp_template']?.toString(),
        email: j['email_template']?.toString(),
        isActive: j['is_active'] == true,
      );
}

class AdminSettings {
  final String hospitalName;
  final String? address;
  final String? city;
  final String? phone;
  final String? email;
  final String? website;
  final String? currency;
  final int lowStockThreshold;
  final int nearExpiryDays;
  final int roundAlertHours;

  const AdminSettings({
    required this.hospitalName,
    this.address,
    this.city,
    this.phone,
    this.email,
    this.website,
    this.currency,
    required this.lowStockThreshold,
    required this.nearExpiryDays,
    required this.roundAlertHours,
  });

  factory AdminSettings.fromJson(Map<String, dynamic> j) => AdminSettings(
        hospitalName: j['hospital_name']?.toString() ?? '',
        address: j['address']?.toString(),
        city: j['city']?.toString(),
        phone: j['phone']?.toString(),
        email: j['email']?.toString(),
        website: j['website']?.toString(),
        currency: j['currency']?.toString(),
        lowStockThreshold: asIntOr(j['low_stock_threshold']),
        nearExpiryDays: asIntOr(j['near_expiry_days']),
        roundAlertHours: asIntOr(j['round_alert_hours']),
      );
}

class AdminDepartment {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final String? status;

  const AdminDepartment({required this.id, required this.name, this.code, this.description, this.status});

  factory AdminDepartment.fromJson(Map<String, dynamic> j) => AdminDepartment(
        id: asIntOr(j['id']),
        name: j['name']?.toString() ?? '—',
        code: j['code']?.toString(),
        description: j['description']?.toString(),
        status: j['status']?.toString(),
      );
}
