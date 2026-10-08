import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Technician dashboard — visible to users with role == 'technician'.
/// Three tabs:
///   - Bookings: NEW jobs (SCHEDULED) assigned to me → START
///   - Ongoing: jobs in progress (IN_PROGRESS) → MARK DONE
///   - Completed: full history (COMPLETED)
class TechnicianDashboardScreen extends StatelessWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0E1A),
          elevation: 0,
          title: const Text(
            'Technician Dashboard',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFF00C853),
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFF8892B0),
            tabs: [
              Tab(text: 'Bookings'),
              Tab(text: 'Ongoing'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TechJobsTab(mode: _JobMode.newJobs),
            _TechJobsTab(mode: _JobMode.ongoing),
            _TechJobsTab(mode: _JobMode.completed),
          ],
        ),
      ),
    );
  }
}

enum _JobMode { newJobs, ongoing, completed }

class _TechJobsTab extends StatefulWidget {
  final _JobMode mode;
  const _TechJobsTab({required this.mode});

  @override
  State<_TechJobsTab> createState() => _TechJobsTabState();
}

class _TechJobsTabState extends State<_TechJobsTab> {
  bool _loading = true;
  String? _error;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _jobs = [];
  String _techName = '';

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      // Read the technician's name — we use it to match bookings.
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final name = (userDoc.data()?['name'] ?? '').toString();

      if (name.isEmpty) {
        if (!mounted) return;
        setState(() {
          _techName = '';
          _jobs = [];
          _loading = false;
        });
        return;
      }

      // Which status belongs to which tab.
      final wantedStatuses = switch (widget.mode) {
        _JobMode.newJobs => ['SCHEDULED'],
        _JobMode.ongoing => ['IN_PROGRESS'],
        _JobMode.completed => ['COMPLETED'],
      };

      // Query ONLY this technician's bookings so the read matches
      // the Firestore rule (which allows reading bookings where
      // electricianName == myName).
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('electricianName', isEqualTo: name)
          .get();

      final mine = snap.docs.where((d) {
        final status = (d.data()['status'] ?? '').toString();
        return wantedStatuses.contains(status);
      }).toList();

      // Sort newest-first in memory.
      mine.sort((a, b) {
        final ta = a.data()['createdAt'];
        final tb = b.data()['createdAt'];
        final aMs = ta is Timestamp ? ta.millisecondsSinceEpoch : 0;
        final bMs = tb is Timestamp ? tb.millisecondsSinceEpoch : 0;
        return bMs.compareTo(aMs);
      });

      if (!mounted) return;
      setState(() {
        _techName = name;
        _jobs = mine;
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

  Future<void> _startJob(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    try {
      await doc.reference.update({'status': 'IN_PROGRESS'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job marked as IN PROGRESS')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ' + e.toString())),
      );
    }
  }

  Future<void> _markDone(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Mark as Completed?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Confirm that this installation is complete. It will move to the Completed tab.',
          style: TextStyle(color: Color(0xFFB8C7DA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8892B0))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark Done',
                style: TextStyle(color: Color(0xFF00C853))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await doc.reference.update({
        'status': 'COMPLETED',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Notify the customer that their installation is done.
      try {
        final bookingData = doc.data();
        final customerUid = (bookingData['userId'] ?? '').toString();
        final equipment = (bookingData['equipmentName'] ?? 'installation').toString();
        final techName = (bookingData['electricianName'] ?? 'your technician').toString();
        if (customerUid.isNotEmpty) {
          await NotificationService().createNotification(
            recipientId: customerUid,
            type: 'INSTALLATION_COMPLETED',
            title: 'Installation Completed',
            body: 'Your ' +
                equipment +
                ' installation has been completed by ' +
                techName +
                '.',
            relatedBookingId: doc.id,
          );
        }
      } catch (_) {
        // Silent — the status update itself succeeded.
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking marked as COMPLETED')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ' + e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00C853)));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: ' + _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD32F2F))),
        ),
      );
    }
    if (_jobs.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF00C853),
        onRefresh: _load,
        child: _emptyState(widget.mode, _techName),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF00C853),
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _jobCard(_jobs[i]),
      ),
    );
  }

  Widget _jobCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final mode = widget.mode;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (d['equipmentName'] ?? 'Installation').toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ),
              if (mode != _JobMode.newJobs)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(mode).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _statusColor(mode).withOpacity(0.5)),
                  ),
                  child: Text(
                    mode == _JobMode.ongoing ? 'ONGOING' : 'COMPLETED',
                    style: TextStyle(
                        color: _statusColor(mode),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _row('Customer', (d['userEmail'] ?? '').toString()),
          _row('Phone', (d['userPhone'] ?? '').toString()),
          _row('Address', (d['address'] ?? '').toString()),
          _row('Fee', 'KSh ' + ((d['bookingFeeKsh'] ?? 0).toString())),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (mode == _JobMode.newJobs)
                ElevatedButton(
                  onPressed: () => _startJob(doc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FA3E8),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    minimumSize: const Size(0, 34),
                    elevation: 0,
                  ),
                  child: const Text('START',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              if (mode == _JobMode.ongoing)
                ElevatedButton(
                  onPressed: () => _markDone(doc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    minimumSize: const Size(0, 34),
                    elevation: 0,
                  ),
                  child: const Text('MARK DONE',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(_JobMode mode) {
    switch (mode) {
      case _JobMode.newJobs:
        return const Color(0xFFFFA000);
      case _JobMode.ongoing:
        return const Color(0xFF4FA3E8);
      case _JobMode.completed:
        return const Color(0xFF00C853);
    }
  }

  Widget _row(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF8892B0), fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(_JobMode mode, String techName) {
    String title;
    String subtitle;
    switch (mode) {
      case _JobMode.newJobs:
        title = 'No New Bookings';
        subtitle = techName.isEmpty
            ? 'Add your name so we can assign you jobs.'
            : 'New installation requests will appear here.';
        break;
      case _JobMode.ongoing:
        title = 'No Ongoing Jobs';
        subtitle = 'Start a job from Bookings to see it here.';
        break;
      case _JobMode.completed:
        title = 'No Completed Installations Yet';
        subtitle = 'Your finished installations will appear here.';
        break;
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.construction_outlined,
            color: Color(0xFF4A5568), size: 56),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: Color(0xFF8892B0), fontSize: 13),
          ),
        ),
      ],
    );
  }
}