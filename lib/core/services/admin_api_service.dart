import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, ApiService, sessionExpired;
import 'package:hms_mobile/core/models/json_value.dart';
import 'package:hms_mobile/features/admin/models/admin_models.dart';

/// JSON client for the administrator's endpoints — mirrors
/// app/Http/Controllers/Api/AdminController.php and its three siblings.
///
/// Everything else an admin opens in the app (patients, wards, billing,
/// pharmacy, the lab) goes through the clinical roles' own services; only
/// what has no clinical owner is here.
class AdminApiService {
  static String get baseUrl => ApiService.baseUrl;

  final http.Client _client;
  AdminApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  dynamic _decode(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection and try again.');
    }

    if (response.statusCode == 200 || response.statusCode == 201) return body;

    if (response.statusCode == 422) {
      final errors = (body as Map<String, dynamic>?)?['errors'] as Map<String, dynamic>?;
      final first = errors?.values.first;
      throw ApiException(first is List && first.isNotEmpty
          ? first.first.toString()
          : (body?['message']?.toString() ?? 'Invalid request.'));
    }
    if (response.statusCode == 401) throw sessionExpired();
    if (response.statusCode == 403) {
      throw ApiException((body is Map ? body['message']?.toString() : null) ?? 'You are not allowed to do that.');
    }
    throw ApiException((body is Map ? body['message']?.toString() : null) ?? 'Something went wrong (${response.statusCode}).');
  }

  Future<Map<String, dynamic>> _get(String token, String path, [Map<String, String>? query]) async {
    final clean = query == null ? null : {for (final e in query.entries) if (e.value.isNotEmpty) e.key: e.value};
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: (clean?.isEmpty ?? true) ? null : clean);
    return _decode(await _client.get(uri, headers: _headers(token))) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(String token, String path, Map<String, dynamic> body) async =>
      _decode(await _client.post(Uri.parse('$baseUrl$path'), headers: _headers(token), body: jsonEncode(body)))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> _put(String token, String path, [Map<String, dynamic> body = const {}]) async =>
      _decode(await _client.put(Uri.parse('$baseUrl$path'), headers: _headers(token), body: jsonEncode(body)))
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> _delete(String token, String path) async =>
      _decode(await _client.delete(Uri.parse('$baseUrl$path'), headers: _headers(token))) as Map<String, dynamic>;

  static List<Map<String, dynamic>> _rows(Map<String, dynamic> json, String key) =>
      ((json[key] as List?) ?? const []).map((e) => (e as Map).cast<String, dynamic>()).toList();

  static List<String> _strings(Map<String, dynamic> json, String key) =>
      ((json[key] as List?) ?? const []).map((e) => e.toString()).toList();

  // ----------------------------------------------------------- dashboard

  Future<AdminDashboard> dashboard(String token) async =>
      AdminDashboard.fromJson(await _get(token, '/admin/dashboard'));

  // ------------------------------------------------------------- reports

  Future<AdminReport<AdminPatientReportRow>> patientReport(String token, {String? from, String? to, String? type}) async {
    final json = await _get(token, '/admin/reports/patients',
        {'from_date': from ?? '', 'to_date': to ?? '', 'patient_type': type ?? ''});
    return AdminReport.fromJson(
      {'totals': {'total': json['total']}, 'patients': json['patients']},
      'patients',
      AdminPatientReportRow.fromJson,
    );
  }

  Future<AdminReport<AdminBillingReportRow>> billingReport(String token, {String? from, String? to, String? status}) async {
    final json = await _get(token, '/admin/reports/billing',
        {'from_date': from ?? '', 'to_date': to ?? '', 'status': status ?? ''});
    return AdminReport.fromJson(json, 'invoices', AdminBillingReportRow.fromJson);
  }

  Future<AdminReport<AdminInventoryReportRow>> inventoryReport(String token, {bool lowStockOnly = false}) async {
    final json = await _get(token, '/admin/reports/inventory', {'low_stock_only': lowStockOnly ? '1' : ''});
    return AdminReport.fromJson(json, 'drugs', AdminInventoryReportRow.fromJson);
  }

  // ------------------------------------------------------------- doctors

  Future<({List<AdminDoctor> doctors, AdminUsage usage})> doctors(String token, {String? search, String? status}) async {
    final json = await _get(token, '/admin/doctors', {'search': search ?? '', 'status': status ?? ''});
    return (
      doctors: _rows(json, 'doctors').map(AdminDoctor.fromJson).toList(),
      usage: AdminUsage.fromJson((json['usage'] as Map?)?.cast<String, dynamic>()),
    );
  }

  Future<void> doctorStore(String token, Map<String, dynamic> body) => _post(token, '/admin/doctors', body);
  Future<void> doctorUpdate(String token, int id, Map<String, dynamic> body) => _put(token, '/admin/doctors/$id', body);
  Future<void> doctorDestroy(String token, int id) => _delete(token, '/admin/doctors/$id');

  // --------------------------------------------------------------- users

  Future<({List<AdminUser> users, List<String> roles, AdminUsage usage})> users(
      String token, {String? search, String? role}) async {
    final json = await _get(token, '/admin/users', {'search': search ?? '', 'role': role ?? ''});
    return (
      users: _rows(json, 'users').map(AdminUser.fromJson).toList(),
      roles: _strings(json, 'roles'),
      usage: AdminUsage.fromJson((json['usage'] as Map?)?.cast<String, dynamic>()),
    );
  }

  Future<void> userStore(String token, Map<String, dynamic> body) => _post(token, '/admin/users', body);
  Future<void> userUpdate(String token, int id, Map<String, dynamic> body) => _put(token, '/admin/users/$id', body);
  Future<void> userResetPassword(String token, int id, String password) =>
      _put(token, '/admin/users/$id/password', {'password': password, 'password_confirmation': password});
  Future<void> userDestroy(String token, int id) => _delete(token, '/admin/users/$id');

  // --------------------------------------------------------------- staff

  Future<({List<AdminUser> staff, Map<String, int> byRole})> staff(String token, {String? search, String? role}) async {
    final json = await _get(token, '/admin/staff', {'search': search ?? '', 'role': role ?? ''});
    final raw = (json['by_role'] as Map?)?.cast<String, dynamic>() ?? const {};
    return (
      staff: _rows(json, 'staff').map(AdminUser.fromJson).toList(),
      byRole: {for (final e in raw.entries) e.key: int.tryParse(e.value.toString()) ?? 0},
    );
  }

  // ----------------------------------------------------------- inventory

  Future<({List<AdminInventoryItem> items, Map<String, num> totals, List<String> categories})> inventory(
      String token, {String? search, String? category, bool lowStockOnly = false}) async {
    final json = await _get(token, '/admin/inventory',
        {'search': search ?? '', 'category': category ?? '', 'low_stock_only': lowStockOnly ? '1' : ''});
    final raw = (json['totals'] as Map?)?.cast<String, dynamic>() ?? const {};
    return (
      items: _rows(json, 'items').map(AdminInventoryItem.fromJson).toList(),
      totals: {for (final e in raw.entries) e.key: num.tryParse(e.value.toString()) ?? 0},
      categories: _strings(json, 'categories'),
    );
  }

  Future<void> inventoryStore(String token, Map<String, dynamic> body) => _post(token, '/admin/inventory', body);
  Future<void> inventoryUpdate(String token, int id, Map<String, dynamic> body) => _put(token, '/admin/inventory/$id', body);
  Future<void> inventoryDestroy(String token, int id) => _delete(token, '/admin/inventory/$id');

  // ----------------------------------------------------- purchase orders

  Future<({List<AdminPurchaseOrder> orders, Map<String, num> totals})> purchaseOrders(
      String token, {String? status}) async {
    final json = await _get(token, '/admin/purchase-orders', {'status': status ?? ''});
    final raw = (json['totals'] as Map?)?.cast<String, dynamic>() ?? const {};
    return (
      orders: _rows(json, 'orders').map(AdminPurchaseOrder.fromJson).toList(),
      totals: {for (final e in raw.entries) e.key: num.tryParse(e.value.toString()) ?? 0},
    );
  }

  Future<void> purchaseOrderStore(String token, Map<String, dynamic> body) =>
      _post(token, '/admin/purchase-orders', body);
  Future<void> purchaseOrderReceive(String token, int id) => _put(token, '/admin/purchase-orders/$id/receive');
  Future<void> purchaseOrderDestroy(String token, int id) => _delete(token, '/admin/purchase-orders/$id');

  // ------------------------------------------------------------ services

  Future<({List<AdminService> services, List<String> categories})> services(
      String token, {String? search, String? category}) async {
    final json = await _get(token, '/admin/services', {'search': search ?? '', 'category': category ?? ''});
    return (
      services: _rows(json, 'services').map(AdminService.fromJson).toList(),
      categories: _strings(json, 'categories'),
    );
  }

  Future<void> serviceStore(String token, Map<String, dynamic> body) => _post(token, '/admin/services', body);
  Future<void> serviceUpdate(String token, int id, Map<String, dynamic> body) => _put(token, '/admin/services/$id', body);
  Future<void> serviceDestroy(String token, int id) => _delete(token, '/admin/services/$id');

  // ---------------------------------------------------------- attendance

  Future<({List<AdminAttendanceRow> rows, Map<String, int> totals, String date})> attendance(
      String token, {String? date, String? status}) async {
    final json = await _get(token, '/admin/attendance', {'date': date ?? '', 'status': status ?? ''});
    final raw = (json['totals'] as Map?)?.cast<String, dynamic>() ?? const {};
    return (
      rows: _rows(json, 'attendance').map(AdminAttendanceRow.fromJson).toList(),
      totals: {for (final e in raw.entries) e.key: int.tryParse(e.value.toString()) ?? 0},
      date: json['date']?.toString() ?? '',
    );
  }

  Future<void> attendanceStore(String token, Map<String, dynamic> body) => _post(token, '/admin/attendance', body);
  Future<void> attendanceUpdate(String token, int id, Map<String, dynamic> body) =>
      _put(token, '/admin/attendance/$id', body);

  // --------------------------------------------------------------- leave

  Future<({List<AdminLeave> leaves, Map<String, int> totals})> leaves(String token, {String? status}) async {
    final json = await _get(token, '/admin/leaves', {'status': status ?? ''});
    final raw = (json['totals'] as Map?)?.cast<String, dynamic>() ?? const {};
    return (
      leaves: _rows(json, 'leaves').map(AdminLeave.fromJson).toList(),
      totals: {for (final e in raw.entries) e.key: int.tryParse(e.value.toString()) ?? 0},
    );
  }

  Future<void> leaveStore(String token, Map<String, dynamic> body) => _post(token, '/admin/leaves', body);
  Future<void> leaveApprove(String token, int id, {String? remarks}) =>
      _put(token, '/admin/leaves/$id/approve', {if (remarks != null) 'remarks': remarks});
  Future<void> leaveReject(String token, int id, String remarks) =>
      _put(token, '/admin/leaves/$id/reject', {'remarks': remarks});
  Future<void> leaveDestroy(String token, int id) => _delete(token, '/admin/leaves/$id');

  // --------------------------------------------------------- wards & beds

  Future<({Map<String, int> stats, List<AdminWard> wards})> wards(String token) async {
    final json = await _get(token, '/admin/wards');
    return (
      stats: ((json['stats'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', asIntOr(v))),
      wards: _rows(json, 'wards').map(AdminWard.fromJson).toList(),
    );
  }

  Future<AdminWardDetail> ward(String token, int id) async =>
      AdminWardDetail.fromJson(await _get(token, '/admin/wards/$id'));

  Future<void> wardStore(String token, Map<String, dynamic> body) => _post(token, '/admin/wards', body);
  Future<void> wardUpdate(String token, int id, Map<String, dynamic> body) => _put(token, '/admin/wards/$id', body);
  Future<void> wardDestroy(String token, int id) => _delete(token, '/admin/wards/$id');

  Future<void> bedStore(String token, int wardId, Map<String, dynamic> body) =>
      _post(token, '/admin/wards/$wardId/beds', body);
  Future<void> bedUpdate(String token, int id, Map<String, dynamic> body) => _put(token, '/admin/beds/$id', body);
  Future<void> bedDestroy(String token, int id) => _delete(token, '/admin/beds/$id');

  // ------------------------------------------------------- notifications

  Future<({List<AdminNotificationEntry> logs, Map<String, int> totals})> notifications(
      String token, {String? channel, String? status}) async {
    final json = await _get(token, '/admin/notifications', {'channel': channel ?? '', 'status': status ?? ''});
    final raw = (json['totals'] as Map?)?.cast<String, dynamic>() ?? const {};
    return (
      logs: _rows(json, 'logs').map(AdminNotificationEntry.fromJson).toList(),
      totals: {for (final e in raw.entries) e.key: int.tryParse(e.value.toString()) ?? 0},
    );
  }

  Future<List<AdminTemplate>> templates(String token) async =>
      _rows(await _get(token, '/admin/notification-templates'), 'templates').map(AdminTemplate.fromJson).toList();

  Future<void> templateStore(String token, Map<String, dynamic> body) =>
      _post(token, '/admin/notification-templates', body);
  Future<void> templateUpdate(String token, int id, Map<String, dynamic> body) =>
      _put(token, '/admin/notification-templates/$id', body);

  // ------------------------------------------------ settings / log / dept

  Future<AdminSettings?> settings(String token) async {
    final json = await _get(token, '/admin/settings');
    final row = (json['settings'] as Map?)?.cast<String, dynamic>();
    return row == null ? null : AdminSettings.fromJson(row);
  }

  Future<void> updateSettings(String token, Map<String, dynamic> body) => _put(token, '/admin/settings', body);

  Future<List<AdminDepartment>> departments(String token) async =>
      _rows(await _get(token, '/admin/departments'), 'departments').map(AdminDepartment.fromJson).toList();

  Future<void> departmentStore(String token, Map<String, dynamic> body) => _post(token, '/admin/departments', body);
  Future<void> departmentUpdate(String token, int id, Map<String, dynamic> body) =>
      _put(token, '/admin/departments/$id', body);
  Future<void> departmentDestroy(String token, int id) => _delete(token, '/admin/departments/$id');

  Future<({List<AdminActivityEntry> logs, List<String> modules})> activityLog(
      String token, {String? module, String? search}) async {
    final json = await _get(token, '/admin/activity-log', {'module': module ?? '', 'search': search ?? ''});
    return (
      logs: _rows(json, 'logs').map(AdminActivityEntry.fromJson).toList(),
      modules: _strings(json, 'modules'),
    );
  }
}
