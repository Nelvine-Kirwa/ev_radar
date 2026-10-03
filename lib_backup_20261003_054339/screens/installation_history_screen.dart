import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../providers/installation_provider.dart';

class InstallationHistoryScreen extends StatelessWidget {
  const InstallationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstallationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Installation History',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: provider.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C853)),
              )
            : provider.history.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: provider.history.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _historyCard(provider.history[i]),
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, color: Color(0xFF4A5568), size: 48),
          SizedBox(height: 16),
          Text(
            'No past installations',
            style: TextStyle(
                color: Color(0xFF8892B0),
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Completed and cancelled bookings will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF4A5568), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(Booking b) {
    final isCompleted = b.status == 'COMPLETED';
    final statusColor =
        isCompleted ? const Color(0xFF00C853) : const Color(0xFF8892B0);
    final statusBg = isCompleted
        ? const Color(0x1A00C853)
        : const Color(0x1A8892B0);
    final statusBorder = isCompleted
        ? const Color(0x6600C853)
        : const Color(0x668892B0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.equipmentName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      b.equipmentCategory,
                      style: const TextStyle(
                          color: Color(0xFF8892B0), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusBorder),
                ),
                child: Text(
                  b.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF1F2937), height: 1),
          const SizedBox(height: 12),
          _row('Electrician', b.electricianName),
          const SizedBox(height: 6),
          _row('Address', b.address),
          const SizedBox(height: 6),
          _row('Price', 'KSh ${b.equipmentPriceKsh}'),
          const SizedBox(height: 6),
          _row(
            'Date',
            _formatDate(b.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFF8892B0), fontSize: 11)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '--';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}