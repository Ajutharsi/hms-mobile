import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/admin/models/admin_models.dart';
import 'package:hms_mobile/features/admin/viewmodels/admin_section_view_model.dart';
import 'package:hms_mobile/features/admin/widgets/admin_ui.dart';

typedef DoctorsPayload = ({List<AdminDoctor> doctors, AdminUsage usage});

class AdminDoctorsViewModel extends AdminSectionViewModel<DoctorsPayload> {
  String status = '';

  @override
  Future<DoctorsPayload> fetch(String token) => api.doctors(token, status: status);

  void setStatus(String value) {
    status = value;
    load();
  }
}

/// The doctor register. Photos, licences and certificates stay on the web
/// — nobody uploads a PDF from a phone, and the API deliberately has no
/// path for it.
class AdminDoctorsScreen extends StatelessWidget {
  const AdminDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminDoctorsViewModel(),
      child: const CareTheme(child: _DoctorsView()),
    );
  }
}

class _DoctorsView extends StatelessWidget {
  const _DoctorsView();

  List<AdminField> _fields([AdminDoctor? doctor]) => [
        AdminField('name', 'Full name', initial: doctor?.name, required: true, icon: Icons.person_outline),
        AdminField('email', 'Email', initial: doctor?.email, required: true,
            keyboard: TextInputType.emailAddress, icon: Icons.mail_outline),
        AdminField('phone', 'Phone', initial: doctor?.phone, keyboard: TextInputType.phone, icon: Icons.phone_outlined),
        AdminField('specialization', 'Specialization', initial: doctor?.specialization, required: true,
            icon: Icons.medical_services_outlined),
        AdminField('department', 'Department', initial: doctor?.department, icon: Icons.apartment_outlined),
        const AdminField('qualification', 'Qualification', initial: null, icon: Icons.school_outlined),
        AdminField('consultation_fee', 'Consultation fee',
            initial: doctor?.consultationFee.toStringAsFixed(0), keyboard: TextInputType.number,
            icon: Icons.payments_outlined),
        AdminField('status', 'Status', initial: doctor?.status ?? 'active', options: const ['active', 'inactive'],
            icon: Icons.toggle_on_outlined),
      ];

  Future<void> _addOrEdit(BuildContext context, AdminDoctorsViewModel viewModel, [AdminDoctor? doctor]) async {
    final values = await adminFormSheet(context,
        title: doctor == null ? 'Add doctor' : 'Edit doctor', fields: _fields(doctor));
    if (values == null || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => doctor == null
        ? api.doctorStore(token, values)
        : api.doctorUpdate(token, doctor.id, values));
    if (context.mounted) {
      adminSnack(context, error ?? (doctor == null ? 'Doctor added.' : 'Doctor updated.'), isError: error != null);
    }
  }

  Future<void> _delete(BuildContext context, AdminDoctorsViewModel viewModel, AdminDoctor doctor) async {
    final yes = await adminConfirm(context,
        title: 'Remove ${doctor.name}?',
        message: 'Their appointments and consultations stay on record. This only removes them from the register.');
    if (!yes || !context.mounted) return;

    final error = await viewModel.mutate((api, token) => api.doctorDestroy(token, doctor.id));
    if (context.mounted) adminSnack(context, error ?? 'Doctor removed.', isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<AdminDoctorsViewModel>();
    final doctors = viewModel.data?.doctors ?? const <AdminDoctor>[];
    final usage = viewModel.data?.usage;

    return AdminSectionScaffold(
      title: 'Doctors',
      isLoading: viewModel.isLoading,
      error: viewModel.loadError,
      itemCount: doctors.length,
      onRefresh: viewModel.load,
      createLabel: 'Add doctor',
      onCreate: () => _addOrEdit(context, viewModel),
      emptyIcon: Icons.medical_services_outlined,
      emptyTitle: 'No doctors on the register',
      emptyMessage: 'Doctors you add here can be booked for appointments.',
      header: Column(
        children: [
          if (usage != null)
            AdminStatRow(stats: [
              AdminStat(value: '${doctors.length}', label: 'Listed'),
              AdminStat(value: usage.isUnlimited ? '∞' : '${usage.limit}', label: 'Plan seats'),
              AdminStat(value: '${usage.used}', label: 'Used'),
            ]),
          AdminFilterChips(
            value: viewModel.status,
            onChanged: viewModel.setStatus,
            options: const [
              (value: '', label: 'All'),
              (value: 'active', label: 'Active'),
              (value: 'inactive', label: 'Inactive'),
            ],
          ),
        ],
      ),
      itemBuilder: (context, i) {
        final doctor = doctors[i];
        final inactive = doctor.status == 'inactive';
        return AdminCard(
          title: doctor.name,
          subtitle: [doctor.specialization, doctor.department].where((s) => s != null && s.isNotEmpty).join(' · '),
          detail: [
            if (doctor.doctorId != null) doctor.doctorId,
            if (doctor.email != null) doctor.email,
            '₹${doctor.consultationFee.toStringAsFixed(0)}',
          ].join(' · '),
          badge: inactive ? 'inactive' : 'active',
          badgeColor: inactive ? kMuted : kSuccessFg,
          badgeBg: inactive ? kCareNeutralBg : kSuccessBg,
          onTap: () => _addOrEdit(context, viewModel, doctor),
          actions: [
            (label: 'Edit', icon: Icons.edit_outlined, onTap: () => _addOrEdit(context, viewModel, doctor), destructive: false),
            (label: 'Remove', icon: Icons.delete_outline, onTap: () => _delete(context, viewModel, doctor), destructive: true),
          ],
        );
      },
    );
  }
}
