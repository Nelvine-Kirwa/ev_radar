import 'package:flutter/material.dart';
import '../services/technician_service.dart';

/// Full list of approved technicians (users where role == 'technician').
/// Shows name, EPRA license, rating, and count of completed installations.
class AllTechniciansScreen extends StatefulWidget {
  const AllTechniciansScreen({super.key});

  @override
  State<AllTechniciansScreen> createState() => _AllTechniciansScreenState();
}

class _AllTechniciansScreenState extends State<AllTechniciansScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _techs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await TechnicianService().loadApprovedWithCounts();
      if (!mounted) return;
      setState(() {
        _techs = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        title: const Text(
          'All Technicians',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C853)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: ' + _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFD32F2F))),
                  ),
                )
              : _techs.isEmpty
                  ? const Center(
                      child: Text(
                        'No approved technicians yet',
                        style: TextStyle(color: Color(0xFF8892B0)),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF00C853),
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _techs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) =>
                            _techCard(_techs[i]),
                      ),
                    ),
    );
  }

  Widget _techCard(Map<String, dynamic> t) {
    final name = (t['name'] ?? '').toString();
    final license = (t['license'] ?? '').toString();
    final rating = (t['rating'] as num?)?.toDouble() ?? 5.0;
    final installs = t['installs'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1A),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: const Icon(Icons.person_outline,
                color: Color(0xFF8892B0), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  (license.isEmpty ? 'EPRA pending' : license) +
                      '  Â·  ' +
                      installs.toString() +
                      ' installations',
                  style: const TextStyle(
                      color: Color(0xFF8892B0), fontSize: 11),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star,
                  color: Color(0xFF00C853), size: 14),
              const SizedBox(width: 2),
              Text(rating.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
