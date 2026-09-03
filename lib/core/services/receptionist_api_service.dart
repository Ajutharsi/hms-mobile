import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:hms_mobile/core/services/api_service.dart' show ApiException, ApiService;
import 'package:hms_mobile/features/receptionist/models/insurance_claim.dart';
import 'package:hms_mobile/features/receptionist/models/invoice.dart';
import 'package:hms_mobile/features/receptionist/models/ipd_deposit.dart';
import 'package:hms_mobile/features/receptionist/models/opd_token.dart';
import 'package:hms_mobile/features/receptionist/models/radiology_order.dart';
import 'package:hms_mobile/features/receptionist/models/reception_appointment.dart';
import 'package:hms_mobile/features/receptionist/models/reception_dashboard_stats.dart';
import 'package:hms_mobile/features/receptionist/models/reception_patient.dart';
import 'package:hms_mobile/features/receptionist/models/reception_profile.dart';
import 'package:hms_mobile/features/receptionist/models/referral.dart';
import 'package:hms_mobile/features/receptionist/models/scheme_billing.dart';

/// JSON client for the Flutter receptionist app — mirrors
/// app/Http/Controllers/Api/ReceptionistController.php and
/// app/Http/Controllers/Api/BillingController.php. Ward/Admissions/Consent
/// Forms/ER/Lab Tests/Lab Orders reuse NurseApiService/LabApiService
/// instead (same shared backend routes, see NurseController's
/// authNurseOrReceptionist()).
class ReceptionistApiService {
  static String get baseUrl => ApiService.baseUrl;

  final http.Client _client;
  ReceptionistApiService({http.Client? client}) : _client = client ?? http.Client();

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

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body;
    }
    if (response.statusCode == 422) {
      final errors = (body as Map<String, dynamic>?)?['errors'] as Map<String, dynamic>?;
      final firstError = errors?.values.first;
      final message = firstError is List && firstError.isNotEmpty
          ? firstError.first.toString()
          : (body?['message']?.toString() ?? 'Invalid request.');
      throw ApiException(message);
    }
    if (response.statusCode == 401) {
      throw ApiException('Your session has expired. Please log in again.');
    }
    if (response.statusCode == 403) {
      throw ApiException((body is Map ? body['message']?.toString() : null) ?? 'You are not allowed to do that.');
    }

    throw ApiException((body is Map ? body['message']?.toString() : null) ?? 'Something went wrong (${response.statusCode}).');
  }

  Future<Map<String, dynamic>> _get(String token, String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _headers(token));
    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(String token, String path, Map<String, dynamic> body) async {
    final response = await _client.post(Uri.parse('$baseUrl$path'), headers: _headers(token), body: jsonEncode(body));
    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _put(String token, String path, [Map<String, dynamic> body = const {}]) async {
    final response = await _client.put(Uri.parse('$baseUrl$path'), headers: _headers(token), body: jsonEncode(body));
    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _postMultipart(String token, String path, Map<String, String> fields, {String? fileField, Uint8List? fileBytes, String? fileName}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token'
      ..fields.addAll(fields);
    if (fileField != null && fileBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName ?? 'photo.jpg'));
    }
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _delete(String token, String path) async {
    final response = await _client.delete(Uri.parse('$baseUrl$path'), headers: _headers(token));
    return _decode(response) as Map<String, dynamic>;
  }

  // Dashboard

  Future<(ReceptionDashboardStats, List<ReceptionDashboardAppointment>, List<ReceptionDashboardPatient>)> dashboard(String token) async {
    final json = await _get(token, '/receptionist/dashboard');
    return (
      ReceptionDashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
      (json['today_appointments'] as List).map((a) => ReceptionDashboardAppointment.fromJson(a as Map<String, dynamic>)).toList(),
      (json['recent_patients'] as List).map((p) => ReceptionDashboardPatient.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }

  // Patients

  Future<List<ReceptionPatient>> patients(String token, {String? q, String? type}) async {
    final json = await _get(token, '/receptionist/patients', {if (q != null && q.isNotEmpty) 'q': q, if (type != null) 'type': type});
    return (json['patients'] as List).map((p) => ReceptionPatient.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<ReceptionPatientDetail> patientDetail(String token, int id) async {
    final json = await _get(token, '/receptionist/patients/$id');
    return ReceptionPatientDetail.fromJson(json);
  }

  Future<void> patientStore(String token, Map<String, String> fields, {Uint8List? photoBytes, String? photoFilename}) =>
      _postMultipart(token, '/receptionist/patients', fields, fileField: 'photo', fileBytes: photoBytes, fileName: photoFilename);

  Future<void> patientUpdate(String token, int id, Map<String, String> fields, {Uint8List? photoBytes, String? photoFilename}) =>
      _postMultipart(token, '/receptionist/patients/$id', fields, fileField: 'photo', fileBytes: photoBytes, fileName: photoFilename);

  // Appointments

  Future<List<ReceptionAppointment>> appointments(String token, {String? status, String? date}) async {
    final json = await _get(token, '/receptionist/appointments', {if (status != null) 'status': status, if (date != null) 'date': date});
    return (json['appointments'] as List).map((a) => ReceptionAppointment.fromJson(a as Map<String, dynamic>)).toList();
  }

  Future<void> appointmentStore(String token, Map<String, dynamic> fields) => _post(token, '/receptionist/appointments', fields);

  Future<void> appointmentUpdate(String token, int id, Map<String, dynamic> fields) => _put(token, '/receptionist/appointments/$id', fields);

  Future<List<AppointmentSlot>> appointmentSlots(String token, {required int doctorId, required String date}) async {
    final json = await _get(token, '/receptionist/appointments/slots', {'doctor_id': '$doctorId', 'date': date});
    return (json['slots'] as List).map((s) => AppointmentSlot.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<List<ReceptionDoctor>> doctors(String token) async {
    final json = await _get(token, '/receptionist/doctors');
    return (json['doctors'] as List).map((d) => ReceptionDoctor.fromJson(d as Map<String, dynamic>)).toList();
  }

  // Referrals

  Future<List<Referral>> referrals(String token, {String? status}) async {
    final json = await _get(token, '/receptionist/referrals', {if (status != null) 'status': status});
    return (json['referrals'] as List).map((r) => Referral.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<void> referralStore(String token, Map<String, dynamic> fields) => _post(token, '/receptionist/referrals', fields);

  Future<void> referralUpdateStatus(String token, int id, String status) => _put(token, '/receptionist/referrals/$id/status', {'status': status});

  Future<void> referralDestroy(String token, int id) => _delete(token, '/receptionist/referrals/$id');

  // OPD Queue

  Future<(OpdQueueStats, List<OpdToken>)> opdQueue(String token) async {
    final json = await _get(token, '/receptionist/opd-queue');
    return (
      OpdQueueStats.fromJson(json['stats'] as Map<String, dynamic>),
      (json['tokens'] as List).map((t) => OpdToken.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }

  Future<void> opdQueueStore(String token, {required int patientId, required int doctorId, String? notes}) =>
      _post(token, '/receptionist/opd-queue', {'patient_id': patientId, 'doctor_id': doctorId, if (notes != null) 'notes': notes});

  Future<void> opdQueueCallNext(String token, int doctorId) => _put(token, '/receptionist/opd-queue/call-next/$doctorId');

  Future<void> opdQueueUpdateStatus(String token, int tokenId, String status) => _put(token, '/receptionist/opd-queue/$tokenId/status', {'status': status});

  Future<void> opdQueueDestroy(String token, int tokenId) => _delete(token, '/receptionist/opd-queue/$tokenId');

  // Radiology

  Future<(RadiologyStats, List<RadiologyOrder>)> radiologyOrders(String token, {int? patientId}) async {
    final json = await _get(token, '/receptionist/radiology', {if (patientId != null) 'patient_id': '$patientId'});
    return (
      RadiologyStats.fromJson(json['stats'] as Map<String, dynamic>),
      (json['orders'] as List).map((o) => RadiologyOrder.fromJson(o as Map<String, dynamic>)).toList(),
    );
  }

  Future<void> radiologyStore(String token, Map<String, dynamic> fields) => _post(token, '/receptionist/radiology', fields);

  Future<RadiologyOrder> radiologyDetail(String token, int id) async {
    final json = await _get(token, '/receptionist/radiology/$id');
    return RadiologyOrder.fromJson(json);
  }

  Future<void> radiologyUpdate(String token, int id, Map<String, dynamic> fields) => _put(token, '/receptionist/radiology/$id', fields);

  Future<void> radiologyEnterFindings(String token, int id, Map<String, dynamic> fields) => _put(token, '/receptionist/radiology/$id/findings', fields);

  Future<void> radiologyDestroy(String token, int id) => _delete(token, '/receptionist/radiology/$id');

  // Billing — Invoices

  Future<InvoiceStats> invoicesStats(String token) async {
    final json = await _get(token, '/receptionist/billing/invoices/stats');
    return InvoiceStats.fromJson(json);
  }

  Future<List<Invoice>> invoices(String token, {String? status, String? q}) async {
    final json = await _get(token, '/receptionist/billing/invoices', {if (status != null) 'status': status, if (q != null && q.isNotEmpty) 'q': q});
    return (json['invoices'] as List).map((i) => Invoice.fromJson(i as Map<String, dynamic>)).toList();
  }

  Future<List<BillingServiceItem>> invoiceServices(String token) async {
    final json = await _get(token, '/receptionist/billing/invoices/services');
    return (json['services'] as List).map((s) => BillingServiceItem.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<(int, String)> invoiceStore(String token, Map<String, dynamic> fields) async {
    final json = await _post(token, '/receptionist/billing/invoices', fields);
    return (json['id'] as int, json['invoice_no']?.toString() ?? '');
  }

  Future<InvoiceDetail> invoiceDetail(String token, int id) async {
    final json = await _get(token, '/receptionist/billing/invoices/$id');
    return InvoiceDetail.fromJson(json);
  }

  Future<void> invoiceAddPayment(String token, int id, {required double amount, required String paymentMethod, String? referenceNo, String? notes}) =>
      _post(token, '/receptionist/billing/invoices/$id/payment', {
        'amount': amount,
        'payment_method': paymentMethod,
        if (referenceNo != null) 'reference_no': referenceNo,
        if (notes != null) 'notes': notes,
      });

  // Billing — Insurance Claims

  Future<(InsuranceClaimStats, List<InsuranceClaim>)> insuranceClaims(String token, {int? patientId}) async {
    final json = await _get(token, '/receptionist/billing/insurance-claims', {if (patientId != null) 'patient_id': '$patientId'});
    return (
      InsuranceClaimStats.fromJson(json['stats'] as Map<String, dynamic>),
      (json['claims'] as List).map((c) => InsuranceClaim.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }

  Future<void> insuranceClaimStore(String token, Map<String, dynamic> fields) => _post(token, '/receptionist/billing/insurance-claims', fields);

  Future<InsuranceClaim> insuranceClaimDetail(String token, int id) async {
    final json = await _get(token, '/receptionist/billing/insurance-claims/$id');
    return InsuranceClaim.fromJson(json);
  }

  Future<void> insuranceClaimUpdate(String token, int id, Map<String, dynamic> fields) => _put(token, '/receptionist/billing/insurance-claims/$id', fields);

  Future<void> insuranceClaimUpdateStatus(String token, int id, Map<String, dynamic> fields) => _put(token, '/receptionist/billing/insurance-claims/$id/status', fields);

  Future<void> insuranceClaimDestroy(String token, int id) => _delete(token, '/receptionist/billing/insurance-claims/$id');

  // Billing — IPD Deposits

  Future<(IpdDepositStats, List<IpdDeposit>)> ipdDeposits(String token, {int? patientId}) async {
    final json = await _get(token, '/receptionist/billing/ipd-deposits', {if (patientId != null) 'patient_id': '$patientId'});
    return (
      IpdDepositStats.fromJson(json['stats'] as Map<String, dynamic>),
      (json['deposits'] as List).map((d) => IpdDeposit.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }

  Future<void> ipdDepositStore(String token, {required int patientId, required double amount, required String paymentMethod, String? referenceNo, String? notes}) =>
      _post(token, '/receptionist/billing/ipd-deposits', {
        'patient_id': patientId,
        'amount': amount,
        'payment_method': paymentMethod,
        if (referenceNo != null) 'reference_no': referenceNo,
        if (notes != null) 'notes': notes,
      });

  Future<void> ipdDepositRefund(String token, int depositId, {required double amount, required String paymentMethod, String? notes}) =>
      _post(token, '/receptionist/billing/ipd-deposits/$depositId/refund', {
        'amount': amount,
        'payment_method': paymentMethod,
        if (notes != null) 'notes': notes,
      });

  // Billing — Scheme Billing

  Future<(SchemeBillingStats, List<SchemeBilling>)> schemeBillings(String token) async {
    final json = await _get(token, '/receptionist/billing/scheme-billing');
    return (
      SchemeBillingStats.fromJson(json['stats'] as Map<String, dynamic>),
      (json['bills'] as List).map((b) => SchemeBilling.fromJson(b as Map<String, dynamic>)).toList(),
    );
  }

  Future<void> schemeBillingStore(String token, Map<String, dynamic> fields) => _post(token, '/receptionist/billing/scheme-billing', fields);

  Future<SchemeBilling> schemeBillingDetail(String token, int id) async {
    final json = await _get(token, '/receptionist/billing/scheme-billing/$id');
    return SchemeBilling.fromJson(json);
  }

  Future<void> schemeBillingUpdate(String token, int id, Map<String, dynamic> fields) => _put(token, '/receptionist/billing/scheme-billing/$id', fields);

  Future<void> schemeBillingUpdateStatus(String token, int id, Map<String, dynamic> fields) => _put(token, '/receptionist/billing/scheme-billing/$id/status', fields);

  Future<void> schemeBillingDestroy(String token, int id) => _delete(token, '/receptionist/billing/scheme-billing/$id');

  // Profile

  Future<ReceptionProfile> profile(String token) async {
    final json = await _get(token, '/receptionist/profile');
    return ReceptionProfile.fromJson(json);
  }

  Future<ReceptionProfile> updateProfile(
    String token, {
    required String name,
    required String email,
    String? phone,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
    Uint8List? photoBytes,
    String? photoFilename,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/receptionist/profile'))
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = name
      ..fields['email'] = email;

    if (phone != null && phone.isNotEmpty) request.fields['phone'] = phone;
    if (password != null && password.isNotEmpty) {
      request.fields['password'] = password;
      request.fields['password_confirmation'] = passwordConfirmation ?? '';
      request.fields['current_password'] = currentPassword ?? '';
    }
    if (photoBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('profile_photo', photoBytes, filename: photoFilename ?? 'profile_photo.jpg'));
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    return ReceptionProfile.fromJson(_decode(response) as Map<String, dynamic>);
  }
}
