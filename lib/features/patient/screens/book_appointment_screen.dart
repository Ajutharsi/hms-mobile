import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/patient/viewmodels/book_appointment_view_model.dart';

class BookAppointmentScreen extends StatelessWidget {
  const BookAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookAppointmentViewModel(),
      child: const _BookAppointmentView(),
    );
  }
}

class _BookAppointmentView extends StatelessWidget {
  const _BookAppointmentView();

  Future<void> _pickDate(BuildContext context, BookAppointmentViewModel viewModel) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: kTeal)),
        child: child!,
      ),
    );
    if (picked != null) viewModel.selectDate(picked);
  }

  Future<void> _submit(BuildContext context, BookAppointmentViewModel viewModel) async {
    final tokenNumber = await viewModel.submit();
    if (tokenNumber == null || !context.mounted) return;

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kTealDark,
        content: Text(tokenNumber > 0 ? 'Appointment booked — token #$tokenNumber.' : 'Appointment booked.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookAppointmentViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kInk,
        elevation: 0,
        title: const Text('Book appointment', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: viewModel.loadingDoctors
            ? const Center(child: CircularProgressIndicator(color: kTeal))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (viewModel.errorMessage != null) ...[
                      authErrorBanner(viewModel.errorMessage!),
                      const SizedBox(height: 18),
                    ],
                    const Text('Doctor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField(
                      initialValue: viewModel.selectedDoctor,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: kFieldFill,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      hint: const Text('Choose a doctor'),
                      items: viewModel.doctors
                          .map((d) => DropdownMenuItem(value: d, child: Text(d.label, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: viewModel.selectDoctor,
                    ),
                    const SizedBox(height: 22),
                    const Text('Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickDate(context, viewModel),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18, color: kMuted),
                            const SizedBox(width: 10),
                            Text(
                              viewModel.selectedDate == null
                                  ? 'Choose a date'
                                  : BookAppointmentViewModel.formatDate(viewModel.selectedDate!),
                              style: TextStyle(
                                color: viewModel.selectedDate == null ? const Color(0xFFAEB8B6) : kInk,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (viewModel.selectedDoctor != null && viewModel.selectedDate != null) ...[
                      const Text('Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
                      const SizedBox(height: 8),
                      if (viewModel.loadingSlots)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator(color: kTeal)),
                        )
                      else if (viewModel.slots.isEmpty)
                        const Text('No slots available that day.', style: TextStyle(color: kMuted, fontSize: 13.5))
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: viewModel.slots.map((slot) {
                            final selected = viewModel.selectedTime == slot.time;
                            return GestureDetector(
                              onTap: slot.available ? () => viewModel.selectTime(slot.time) : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? kTeal : (slot.available ? kFieldFill : const Color(0xFFF0F0F0)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  slot.time,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : (slot.available ? kInk : const Color(0xFFBFC5C3)),
                                    decoration: slot.available ? null : TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 22),
                    ],
                    const Text('Visit type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _VisitTypeOption(label: 'Walk-in (OP)', value: 'op', selected: viewModel.visitType, onChanged: viewModel.selectVisitType),
                        const SizedBox(width: 10),
                        _VisitTypeOption(label: 'Consult', value: 'consult', selected: viewModel.visitType, onChanged: viewModel.selectVisitType),
                        const SizedBox(width: 10),
                        _VisitTypeOption(label: 'Follow-up', value: 'followup', selected: viewModel.visitType, onChanged: viewModel.selectVisitType),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text('Notes (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: viewModel.notesController,
                      maxLines: 3,
                      style: const TextStyle(color: kInk, fontSize: 14.5),
                      decoration: InputDecoration(
                        hintText: 'Anything the doctor should know beforehand',
                        hintStyle: const TextStyle(color: Color(0xFFAEB8B6), fontSize: 14),
                        filled: true,
                        fillColor: kFieldFill,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: viewModel.isBooking ? null : () => _submit(context, viewModel),
                        style: FilledButton.styleFrom(
                          backgroundColor: kTealDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: viewModel.isBooking
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                              )
                            : const Text('Confirm booking', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _VisitTypeOption extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onChanged;

  const _VisitTypeOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? kTeal : kFieldFill,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : kMuted,
            ),
          ),
        ),
      ),
    );
  }
}
