import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_station_screen.dart';

/// Three tabs:
///   - Recent Bookings: bookings at the operator's stations
///   - My Stations:     stations the operator has registered
///   - Applications:    pending/declined station registrations + CTA
class OperatorDashboardScreen extends StatelessWidget {
  const OperatorDashboardScreen({super.key});

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
            'Operator Dashboard',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFF00C853),
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFF8892B0),
            tabs: [
              Tab(text: 'Bookings'),
              Tab(text: 'Stations'),
              Tab(text: 'Applications'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BookingsTab(),
            _StationsTab(),
            _ApplicationsTab(),
          ],
        ),
      ),
    );
  }
}

class _BookingsTab extends StatefulWidget {
  const _BookingsTab();

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  bool _loading = true;
  String? _error;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _bookings = [];

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
        setState(() {
          _loading = false;
          _error = 'Sign in required';
        });
        return;
      }

      // Step 1: get operator's station ids
      final stationsSnap = await FirebaseFirestore.instance
          .collection('stations')
          .where('operatorId', isEqualTo: user.uid)
          .get();
      final stationIds = stationsSnap.docs.map((d) => d.id).toList();

      if (stationIds.isEmpty) {
        setState(() {
          _loading = false;
          _bookings = [];
        });
        return;
      }

      // Step 2: chunk station ids (whereIn limit is 30)
      final chunks = <List<String>>[];
      for (var i = 0; i < stationIds.length; i += 30) {
        chunks.add(stationIds.sublist(
            i, i + 30 > stationIds.length ? stationIds.length : i + 30));
      }

      final all = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final chunk in chunks) {
        final snap = await FirebaseFirestore.instance
            .collection('station_bookings')
            .where('stationId', whereIn: chunk)
            .get();
        all.addAll(snap.docs);
      }

      // Sort by startTime descending in memory
      all.sort((a, b) {
        final ta = a.data()['startTime'];
        final tb = b.data()['startTime'];
        if (ta is! Timestamp || tb is! Timestamp) return 0;
        return tb.compareTo(ta);
      });

      if (!mounted) return;
      setState(() {
        _bookings = all;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C853)),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error: ' + _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFD32F2F)),
          ),
        ),
      );
    }
    if (_bookings.isEmpty) {
      return _placeholder(
        icon: Icons.event_note,
        title: 'No Bookings Yet',
        subtitle:
            'Bookings at your stations will appear here once customers start reserving slots.',
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF00C853),
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _bookingRow(_bookings[i]),
      ),
    );
  }

  Widget _bookingRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final start = (d['startTime'] as Timestamp?)?.toDate();
    final end = (d['endTime'] as Timestamp?)?.toDate();
    final status = (d['status'] ?? 'CONFIRMED').toString();

    Color c;
    switch (status) {
      case 'CANCELLED':
      case 'EXPIRED':
        c = const Color(0xFF8892B0);
        break;
      case 'CONFIRMED':
      default:
        c = const Color(0xFF00C853);
    }

    String fmt(DateTime? t) {
      if (t == null) return '--';
      final dd = t.day.toString().padLeft(2, '0');
      final mo = t.month.toString().padLeft(2, '0');
      final hh = t.hour.toString().padLeft(2, '0');
      final mn = t.minute.toString().padLeft(2, '0');
      return dd + '/' + mo + ' ' + hh + ':' + mn;
    }

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
                  (d['stationName'] ?? 'Station').toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.withOpacity(0.5)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: c,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            fmt(start) + '  to  ' + fmt(end),
            style: const TextStyle(color: Color(0xFF8892B0), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            (d['userEmail'] ?? '').toString(),
            style: const TextStyle(color: Color(0xFF4A5568), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StationsTab extends StatelessWidget {
  const _StationsTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Sign in required',
            style: TextStyle(color: Color(0xFF8892B0))),
      );
    }

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('stations')
                .where('operatorId', isEqualTo: user.uid)
                .where('status', whereIn: ['Operational', 'Busy', 'Offline', 'approved'])
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text('Error: ${snap.error}',
                      style: const TextStyle(color: Color(0xFFD32F2F))),
                );
              }
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00C853)),
                );
              }

              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return _placeholder(
                  icon: Icons.ev_station,
                  title: 'No Stations Yet',
                  subtitle:
                      'Register your first station from the Applications tab.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final d = docs[i].data();
                  final status = (d['status'] ?? 'pending').toString();
                  return _stationCard(context, docs[i].reference, d, status);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Tapping "Manage" opens a bottom sheet to switch the station status.
  Future<void> _showManageSheet(
    BuildContext context,
    DocumentReference ref,
    String current,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Station Availability',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
            _manageOption(ctx, 'Operational', Icons.check_circle,
                const Color(0xFF00C853), current),
            _manageOption(ctx, 'Busy', Icons.access_time,
                const Color(0xFFFFA000), current),
            _manageOption(ctx, 'Offline', Icons.cancel,
                const Color(0xFF8892B0), current),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (choice == null || choice == current) return;
    try {
      await ref.update({'status': choice});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Station marked as ' + choice)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ' + e.toString())),
        );
      }
    }
  }

  Widget _manageOption(
      BuildContext ctx, String value, IconData icon, Color color, String current) {
    final isSelected = value == current;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(value, style: const TextStyle(color: Colors.white)),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF00C853))
          : null,
      onTap: () => Navigator.pop(ctx, value),
    );
  }

  Widget _stationCard(BuildContext context, DocumentReference ref,
      Map<String, dynamic> d, String status) {
    Color c;
    switch (status) {
      case 'Busy':
        c = const Color(0xFFFFA000);
        break;
      case 'Offline':
        c = const Color(0xFF8892B0);
        break;
      case 'Operational':
      case 'approved':
      default:
        c = const Color(0xFF00C853);
    }

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
                  (d['name'] ?? 'Unnamed Station').toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showManageSheet(context, ref, status),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, color: c, size: 12),
                      const SizedBox(width: 4),
                      Text('MANAGE',
                          style: TextStyle(
                              color: c,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            (d['address'] ?? '').toString(),
            style:
                const TextStyle(color: Color(0xFF8892B0), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ApplicationsTab extends StatelessWidget {
  const _ApplicationsTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Sign in required',
            style: TextStyle(color: Color(0xFF8892B0))),
      );
    }

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('stations')
                .where('operatorId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF00C853)),
                );
              }

              final docs = snap.data!.docs.where((doc) {
                final s = (doc.data()['status'] ?? 'pending').toString();
                return s == 'pending' || s == 'declined';
              }).toList();

              if (docs.isEmpty) {
                return _placeholder(
                  icon: Icons.assignment_outlined,
                  title: 'No Pending Applications',
                  subtitle:
                      'Register a new station using the button below.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final d = docs[i].data();
                  final status = (d['status'] ?? 'pending').toString();
                  return _applicationRow(d, status);
                },
              );
            },
          ),
        ),

        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddStationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text(
                  'Register New Station',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _applicationRow(Map<String, dynamic> d, String status) {
    final isPending = status == 'pending';
    final c =
        isPending ? const Color(0xFFFFA000) : const Color(0xFFD32F2F);
    final label = isPending ? 'PENDING' : 'DECLINED';

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
                  (d['name'] ?? 'Unnamed Station').toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.withOpacity(0.5)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: c,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            (d['address'] ?? '').toString(),
            style:
                const TextStyle(color: Color(0xFF8892B0), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Shared placeholder widget
Widget _placeholder({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF4A5568), size: 56),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8892B0),
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}
