import 'package:flutter/material.dart';

import 'package:hms_mobile/core/services/api_service.dart';
import 'package:hms_mobile/core/services/auth_storage.dart';
import 'package:hms_mobile/core/services/nurse_api_service.dart';
import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/features/nurse/models/shift_handover.dart';

class ShiftHandoverDetailScreen extends StatefulWidget {
  final int handoverId;
  const ShiftHandoverDetailScreen({super.key, required this.handoverId});

  @override
  State<ShiftHandoverDetailScreen> createState() => _ShiftHandoverDetailScreenState();
}

class _ShiftHandoverDetailScreenState extends State<ShiftHandoverDetailScreen> {
  final _api = NurseApiService();
  final _authApi = ApiService();
  final _authStorage = AuthStorage();

  bool _isLoading = true;
  String? _loadError;
  ShiftHandoverDetail? _detail;
  String? _currentUserName;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final token = await _authStorage.readToken();
      final results = await guardNetworkErrors(() => Future.wait([
            _api.handoverDetail(token!, widget.handoverId),
            _currentUserName == null ? _authApi.me(token).then((u) => u.name) : Future.value(_currentUserName),
          ]));
      if (!mounted) return;
      setState(() {
        _detail = results[0] as ShiftHandoverDetail;
        _currentUserName = results[1] as String?;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _act(Future<void> Function(String token) action, {required String successMessage}) async {
    setState(() => _isActing = true);
    try {
      final token = await _authStorage.readToken();
      await guardNetworkErrors(() => action(token!));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: kTealDark, content: Text(successMessage)));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject handover'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Reason for rejecting (required)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Reject', style: TextStyle(color: Color(0xFFB3261E))),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    await _act((token) => _api.handoverReject(token, widget.handoverId, reason), successMessage: 'Handover rejected.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Handover Detail')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _detail == null) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }
    if (_loadError != null && _detail == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
          const SizedBox(height: 12),
          Text(_loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
        ],
      );
    }

    final detail = _detail!;
    final isOutgoing = _currentUserName != null && detail.outgoingNurseName == _currentUserName;
    final isIncoming = _currentUserName != null && detail.incomingNurseName == _currentUserName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kFieldFill)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail.wardName ?? 'Ward', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 4),
              Text(
                '${detail.currentShift.toUpperCase()} → ${detail.nextShift.toUpperCase()} · ${detail.handoverDate ?? ''}',
                style: const TextStyle(fontSize: 13, color: kMuted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.arrow_upward_rounded, size: 14, color: kMuted),
                  const SizedBox(width: 4),
                  Text('Outgoing: ${detail.outgoingNurseName ?? '—'}', style: const TextStyle(fontSize: 12.5, color: kMuted)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.arrow_downward_rounded, size: 14, color: kMuted),
                  const SizedBox(width: 4),
                  Text('Incoming: ${detail.incomingNurseName ?? '—'}', style: const TextStyle(fontSize: 12.5, color: kMuted)),
                ],
              ),
              if ((detail.shiftSummary ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: kFieldFill),
                const SizedBox(height: 12),
                Text(detail.shiftSummary!, style: const TextStyle(fontSize: 13.5, color: kInk)),
              ],
              if ((detail.rejectionReason ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kDangerBg, borderRadius: BorderRadius.circular(10)),
                  child: Text('Rejection reason: ${detail.rejectionReason}', style: const TextStyle(color: kDangerFg, fontSize: 12.5)),
                ),
              ],
            ],
          ),
        ),
        if (detail.status == 'draft' && isOutgoing) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isActing ? null : () => _act((token) => _api.handoverSubmit(token, widget.handoverId), successMessage: 'Handover submitted.'),
              style: FilledButton.styleFrom(backgroundColor: kTealDark),
              child: const Text('Submit for acceptance'),
            ),
          ),
        ],
        if (detail.status == 'pending_acceptance' && isIncoming) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isActing ? null : _reject,
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB3261E), side: const BorderSide(color: Color(0xFFB3261E))),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isActing ? null : () => _act((token) => _api.handoverAccept(token, widget.handoverId), successMessage: 'Handover accepted.'),
                  style: FilledButton.styleFrom(backgroundColor: kTealDark),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Text('Patients (${detail.patients.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
        const SizedBox(height: 10),
        for (final p in detail.patients) ...[
          _PatientCard(card: p),
          const SizedBox(height: 10),
        ],
        if (detail.tasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Tasks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kFieldFill)),
            child: Column(
              children: [
                for (final t in detail.tasks) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(t.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: t.isCompleted ? kSuccessFg : kMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.taskDescription, style: const TextStyle(fontSize: 13.5, color: kInk)),
                            if (t.patientName != null) Text(t.patientName!, style: const TextStyle(fontSize: 11.5, color: kMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (t != detail.tasks.last) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: kFieldFill)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PatientCard extends StatelessWidget {
  final HandoverPatientCard card;
  const _PatientCard({required this.card});

  static const _conditionColors = {
    'stable': (kSuccessFg, kSuccessBg),
    'improving': (kInfoFg, kInfoBg),
    'critical': (kDangerFg, kDangerBg),
    'observation': (kWarningFg, kWarningBg),
  };

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _conditionColors[card.condition] ?? (kMuted, kFieldFill);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: card.isHighPriority ? kDangerFg : kFieldFill, width: card.isHighPriority ? 1.4 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk)),
                    Text('${card.mrn} · Bed ${card.bedNo}', style: const TextStyle(fontSize: 11.5, color: kMuted)),
                  ],
                ),
              ),
              if (card.isHighPriority) ...[
                const Icon(Icons.priority_high_rounded, color: kDangerFg, size: 16),
                const SizedBox(width: 4),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                child: Text(card.condition, style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _tag('Meds: ${card.medicationStatus ?? card.suggestedMedStatus}'),
              if (card.ivFluidStatus != null) _tag('IV: ${card.ivFluidStatus}'),
            ],
          ),
          if ((card.doctorInstructions ?? '').isNotEmpty) _line('Doctor: ${card.doctorInstructions}'),
          if ((card.pendingProcedures ?? '').isNotEmpty) _line('Pending procedures: ${card.pendingProcedures}'),
          if ((card.pendingLabReports ?? '').isNotEmpty) _line('Pending labs: ${card.pendingLabReports}'),
          if ((card.pendingImaging ?? '').isNotEmpty) _line('Pending imaging: ${card.pendingImaging}'),
          if ((card.specialNotes ?? '').isNotEmpty) _line('Notes: ${card.specialNotes}'),
        ],
      ),
    );
  }

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: kFieldFill, borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
      );

  Widget _line(String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text, style: const TextStyle(fontSize: 12, color: kMuted)),
      );
}
