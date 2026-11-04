import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hms_mobile/core/theme/app_style.dart';
import 'package:hms_mobile/core/theme/care_text.dart';
import 'package:hms_mobile/core/theme/care_ui.dart';
import 'package:hms_mobile/features/nurse/models/ward.dart';
import 'package:hms_mobile/features/nurse/viewmodels/ward_view_model.dart';

class WardScreen extends StatelessWidget {
  const WardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => WardListViewModel(),
      child: const _WardListView(),
    );
  }
}

class _WardListView extends StatelessWidget {
  const _WardListView();

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<WardListViewModel>();

    return CareTheme(child: Scaffold(
      appBar: carePageAppBar(context, 'Ward'),
      body: RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: _buildBody(context, viewModel),
      ),
    ));
  }

  Widget _buildBody(BuildContext context, WardListViewModel viewModel) {
    if (viewModel.isLoading && viewModel.wards.isEmpty) {
      return const CareStateView.loading();
    }

    if (viewModel.loadError != null && viewModel.wards.isEmpty) {
      return CareStateView.error(viewModel.loadError!);
    }

    if (viewModel.wards.isEmpty) {
      return const CareStateView(icon: Icons.holiday_village_outlined, title: 'No wards found');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: viewModel.wards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _WardCard(ward: viewModel.wards[index]),
    );
  }
}

class _WardCard extends StatelessWidget {
  final Ward ward;
  const _WardCard({required this.ward});

  static const _typeColors = {
    'general': (kInfoFg, kInfoBg),
    'private': (kSuccessFg, kSuccessBg),
    'semi_private': (kInfoFg, kInfoBg),
    'icu': (kDangerFg, kDangerBg),
    'nicu': (kWarningFg, kWarningBg),
    'emergency': (kDangerFg, kDangerBg),
  };

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final (fg, bg) = _typeColors[ward.type] ?? (kMuted, kCareBg);
    final occupied = ward.totalBeds - ward.availableBeds;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WardDetailScreen(wardId: ward.id, wardName: ward.name))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kCareBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(ward.name, style: CareText.titleXl)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    ward.type.replaceAll('_', ' ').toUpperCase(),
                    style: CareText.chip(fg),
                  ),
                ),
              ],
            ),
            if ((ward.floor ?? '').isNotEmpty || (ward.building ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                [if ((ward.floor ?? '').isNotEmpty) 'Floor ${ward.floor}', if ((ward.building ?? '').isNotEmpty) ward.building!].join(' · '),
                style: CareText.mutedSm,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.bed_outlined, size: 15, color: kMuted),
                const SizedBox(width: 6),
                Text('$occupied / ${ward.totalBeds} beds occupied', style: CareText.mutedSm),
                const Spacer(),
                Text('₹${ward.chargePerDay.toStringAsFixed(0)}/day', style: CareText.mutedSmMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WardDetailScreen extends StatelessWidget {
  final int wardId;
  final String wardName;
  const WardDetailScreen({super.key, required this.wardId, required this.wardName});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    return ChangeNotifierProvider(
      create: (_) => WardDetailViewModel(wardId: wardId),
      child: _WardDetailView(wardName: wardName),
    );
  }
}

class _WardDetailView extends StatelessWidget {
  final String wardName;
  const _WardDetailView({required this.wardName});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final viewModel = context.watch<WardDetailViewModel>();

    return CareTheme(child: Scaffold(
      appBar: carePageAppBar(context, wardName),
      body: RefreshIndicator(
        color: kCare,
        onRefresh: viewModel.load,
        child: _buildBody(viewModel),
      ),
    ));
  }

  Widget _buildBody(WardDetailViewModel viewModel) {
    if (viewModel.isLoading && viewModel.detail == null) {
      return const CareStateView.loading();
    }

    if (viewModel.loadError != null && viewModel.detail == null) {
      return CareStateView.error(viewModel.loadError!);
    }

    final detail = viewModel.detail!;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: detail.beds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _BedTile(bed: detail.beds[index]),
    );
  }
}

class _BedTile extends StatelessWidget {
  final Bed bed;
  const _BedTile({required this.bed});

  @override
  Widget build(BuildContext context) {
    watchCarePalette(context);
    final available = bed.isAvailable;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kCareBorder)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: available ? kSuccessBg : kCareBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.bed_outlined, color: available ? kSuccessFg : kMuted, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bed.bedNo, style: CareText.titleMd),
                if (bed.patientName != null)
                  Text(bed.patientName!, style: CareText.mutedSm)
                else if ((bed.type ?? '').isNotEmpty)
                  Text(bed.type!, style: CareText.mutedSm),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: available ? kSuccessBg : kCareBg, borderRadius: BorderRadius.circular(8)),
            child: Text(
              available ? 'Available' : 'Occupied',
              style: TextStyle(color: available ? kSuccessFg : kMuted, fontSize: CareText.xs, fontWeight: CareText.bold),
            ),
          ),
        ],
      ),
    );
  }
}
