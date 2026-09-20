import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/patient/models/doctor.dart';
import 'package:hms_mobile/features/patient/viewmodels/book_appointment_view_model.dart';

class BookAppointmentScreen extends StatelessWidget {
  const BookAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookAppointmentViewModel(),
      child: const CareTheme(child: _BookAppointmentView()),
    );
  }
}

class _BookAppointmentView extends StatelessWidget {
  const _BookAppointmentView();

  Future<void> _submit(BuildContext context, BookAppointmentViewModel viewModel) async {
    final tokenNumber = await viewModel.submit();
    if (tokenNumber == null || !context.mounted) return;

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kCareDark,
        content: Text(tokenNumber > 0 ? 'Appointment booked — token #$tokenNumber.' : 'Appointment booked.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookAppointmentViewModel>();
    final today = DateUtils.dateOnly(DateTime.now());

    return Scaffold(
      appBar: carePageAppBar(context, 'Book Appointment'),
      body: viewModel.loadingDoctors
          ? const Center(child: CircularProgressIndicator(color: kCare))
          : ListView(
              padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
              children: [
                if (viewModel.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: authErrorBanner(viewModel.errorMessage!),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: CareSectionTitle(title: 'Select Doctor'),
                ),
                const SizedBox(height: 12),
                if (viewModel.doctors.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('No doctors available right now.', style: TextStyle(color: kMuted)),
                  )
                else
                  SizedBox(
                    height: 158,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      itemCount: viewModel.doctors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final doctor = viewModel.doctors[index];
                        return _DoctorCard(
                          doctor: doctor,
                          selected: viewModel.selectedDoctor?.id == doctor.id,
                          onTap: () => viewModel.selectDoctor(doctor),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 22),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: CareSectionTitle(title: 'Select Date'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CareCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: CalendarDatePicker(
                      initialDate: viewModel.selectedDate ?? today,
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 60)),
                      onDateChanged: viewModel.selectDate,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: CareSectionTitle(title: 'Select Time'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SlotsSection(viewModel: viewModel),
                ),
                const SizedBox(height: 22),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: CareSectionTitle(title: 'Visit Type'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      for (final (value, label) in const [('op', 'Walk-in (OP)'), ('consult', 'Consult'), ('followup', 'Follow-up')]) ...[
                        if (value != 'op') const SizedBox(width: 10),
                        Expanded(
                          child: CareChoicePill(
                            label: label,
                            selected: viewModel.visitType == value,
                            onTap: () => viewModel.selectVisitType(value),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: viewModel.notesController,
                    maxLines: 3,
                    style: const TextStyle(color: kInk, fontSize: 14.5),
                    decoration: careFieldDecoration('Notes (optional)', hint: 'Anything the doctor should know beforehand', icon: Icons.notes_rounded),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: viewModel.loadingDoctors
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: CarePrimaryButton(
                  label: 'Book Appointment',
                  icon: Icons.check_circle_outline_rounded,
                  loading: viewModel.isBooking,
                  onPressed: () => _submit(context, viewModel),
                ),
              ),
            ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final bool selected;
  final VoidCallback onTap;

  const _DoctorCard({required this.doctor, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 124,
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
        decoration: BoxDecoration(
          color: selected ? kCareSoft : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? kCare : kCareBorder, width: selected ? 1.8 : 1),
          boxShadow: kCareShadow,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                CareAvatar(name: doctor.name, imageUrl: doctor.photoUrl, radius: 28),
                const SizedBox(height: 10),
                Text(
                  doctor.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kInk, height: 1.2),
                ),
                const SizedBox(height: 3),
                Text(
                  (doctor.specialization ?? '').isEmpty ? 'General' : doctor.specialization!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: kMuted),
                ),
              ],
            ),
            if (selected)
              const Positioned(
                top: -6,
                right: -2,
                child: Icon(Icons.check_circle_rounded, color: kCare, size: 22),
              ),
          ],
        ),
      ),
    );
  }
}

class _SlotsSection extends StatelessWidget {
  final BookAppointmentViewModel viewModel;
  const _SlotsSection({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.selectedDoctor == null) {
      return const Text('Choose a doctor above to see available times.', style: TextStyle(color: kMuted, fontSize: 13.5));
    }
    if (viewModel.loadingSlots) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(color: kCare)),
      );
    }
    if (viewModel.slots.isEmpty) {
      return const Text('No slots available that day — try another date.', style: TextStyle(color: kMuted, fontSize: 13.5));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final slot in viewModel.slots)
              SizedBox(
                width: width,
                child: CareChoicePill(
                  label: slot.time,
                  selected: viewModel.selectedTime == slot.time,
                  enabled: slot.available,
                  onTap: () => viewModel.selectTime(slot.time),
                ),
              ),
          ],
        );
      },
    );
  }
}
