import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/pharmacy/models/dispensing.dart';
import 'package:hms_mobile/features/pharmacy/screens/dispensing_create_screen.dart';
import 'package:hms_mobile/features/pharmacy/viewmodels/dispensing_view_model.dart';

/// Shared between the pharmacist app (canCreate: true) and the receptionist
/// app (canCreate: false — receptionist can view dispensing but not create
/// new ones, matching the web's role:...|pharmacist middleware on dispensing
/// creation vs the wider view access both roles share).
class DispensingScreen extends StatelessWidget {
  final bool canCreate;
  const DispensingScreen({super.key, this.canCreate = true});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => DispensingListViewModel(),
      child: _DispensingView(canCreate: canCreate),
    );
  }
}

class _DispensingView extends StatelessWidget {
  final bool canCreate;
  const _DispensingView({required this.canCreate});

  Future<void> _create(BuildContext context, DispensingListViewModel viewModel) async {
    final created = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DispensingCreateScreen()));
    if (created != null) viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<DispensingListViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, 'Dispensing'),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _create(context, viewModel),
              backgroundColor: kCareDark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New dispensing', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: RefreshIndicator(color: kCare, onRefresh: viewModel.load, child: _buildBody(context, viewModel)),
    ));
  }

  Widget _buildBody(BuildContext context, DispensingListViewModel viewModel) {
    if (viewModel.isLoading && viewModel.dispensings.isEmpty) {
      return Center(child: CircularProgressIndicator(color: kCare));
    }
    if (viewModel.loadError != null && viewModel.dispensings.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }
    if (viewModel.dispensings.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: const [
        SizedBox(height: 80),
        Icon(Icons.local_pharmacy_outlined, color: kMuted, size: 40),
        SizedBox(height: 12),
        Text('No dispensing records yet', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: viewModel.dispensings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final d = viewModel.dispensings[index];
        return _DispensingCard(
          dispensing: d,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _DispensingDetailScreen(id: d.id))),
        );
      },
    );
  }
}

class _DispensingCard extends StatelessWidget {
  final Dispensing dispensing;
  final VoidCallback onTap;
  const _DispensingCard({required this.dispensing, required this.onTap});

  static const _statusColors = {
    'dispensed': (kSuccessFg, kSuccessBg),
    'pending': (kWarningFg, kWarningBg),
    'partial': (kInfoFg, kInfoBg),
  };

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final (fg, bg) = _statusColors[dispensing.status] ?? (kMuted, kCareBg);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kCareBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(dispensing.patientName ?? 'Patient', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                  child: Text(dispensing.status, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(dispensing.patientMrn ?? '', style: const TextStyle(fontSize: 12, color: kMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(dispensing.dispensingNo ?? '', style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${dispensing.itemsCount} items', style: const TextStyle(fontSize: 12, color: kMuted)),
                const SizedBox(width: 10),
                Text('₹${dispensing.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 12.5, color: kCareDark, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DispensingDetailScreen extends StatelessWidget {
  final int id;
  const _DispensingDetailScreen({required this.id});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => DispensingDetailViewModel(dispensingId: id),
      child: const _DispensingDetailView(),
    );
  }
}

class _DispensingDetailView extends StatelessWidget {
  const _DispensingDetailView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<DispensingDetailViewModel>();

    return CareTheme(child: Scaffold(
      backgroundColor: kCareBg,
      appBar: carePageAppBar(context, viewModel.detail?.dispensingNo ?? 'Dispensing'),
      body: _buildBody(viewModel),
    ));
  }

  Widget _buildBody(DispensingDetailViewModel viewModel) {
    if (viewModel.isLoading && viewModel.detail == null) {
      return Center(child: CircularProgressIndicator(color: kCare));
    }
    if (viewModel.loadError != null && viewModel.detail == null) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.wifi_off_rounded, color: kMuted, size: 40),
        const SizedBox(height: 12),
        Text(viewModel.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
      ]);
    }

    final d = viewModel.detail!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kCareBg, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.patientName ?? 'Patient', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
              Text(d.patientMrn ?? '', style: const TextStyle(fontSize: 12.5, color: kMuted)),
              const SizedBox(height: 8),
              if ((d.prescriptionNo ?? '').isNotEmpty) Text('Prescription: ${d.prescriptionNo}', style: const TextStyle(fontSize: 12.5, color: kMuted)),
              Text('Dispensed ${d.dispensedDate ?? ''}${d.dispensedByName != null ? ' by ${d.dispensedByName}' : ''}', style: const TextStyle(fontSize: 12.5, color: kMuted)),
              if ((d.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(d.notes!, style: const TextStyle(fontSize: 12.5, color: kMuted)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
        const SizedBox(height: 10),
        for (final item in d.items) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kCareBorder)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.medicineName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kInk)),
                      Text('Qty: ${item.quantityDispensed}${item.quantityPrescribed != null ? ' / ${item.quantityPrescribed} prescribed' : ''}', style: const TextStyle(fontSize: 12, color: kMuted)),
                    ],
                  ),
                ),
                Text('₹${item.totalPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kCareDark)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
              const Spacer(),
              Text('₹${d.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kCareDark)),
            ],
          ),
        ),
      ],
    );
  }
}
