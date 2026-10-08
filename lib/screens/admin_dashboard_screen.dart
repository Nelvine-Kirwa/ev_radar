import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Admin dashboard with three tabs:
///   - Applications: pending operator + technician signups (approve/decline)
///   - Users: normal users (role == 'fleet' or missing)
///   - Staff: approved operators + technicians
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

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
            'Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFF00C853),
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFF8892B0),
            tabs: [
              Tab(text: 'Applications'),
              Tab(text: 'Users'),
              Tab(text: 'Staff'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ApplicationsTab(),
            _UsersTab(),
            _StaffTab(),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// Shared placeholder
// =============================================================
Widget _emptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      const SizedBox(height: 120),
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
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF8892B0), fontSize: 13),
        ),
      ),
    ],
  );
}

// =============================================================
// TAB 1 — Applications
// =============================================================
class _ApplicationsTab extends StatefulWidget {
  const _ApplicationsTab();

  @override
  State<_ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<_ApplicationsTab> {
  bool _loading = true;
  String? _error;
  List<_PendingApp> _items = [];

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
      final db = FirebaseFirestore.instance;

      final opSnap = await db
          .collection('operator_applications')
          .where('status', isEqualTo: 'pending')
          .get();
      final tecSnap = await db
          .collection('technician_applications')
          .where('status', isEqualTo: 'pending')
          .get();

      final apps = <_PendingApp>[];
      for (final d in opSnap.docs) {
        apps.add(_PendingApp.fromDoc(d, 'operator'));
      }
      for (final d in tecSnap.docs) {
        apps.add(_PendingApp.fromDoc(d, 'technician'));
      }

      // Sort by submittedAt desc (nulls last)
      apps.sort((a, b) {
        final aMs = a.submittedAt?.millisecondsSinceEpoch ?? 0;
        final bMs = b.submittedAt?.millisecondsSinceEpoch ?? 0;
        return bMs.compareTo(aMs);
      });

      if (!mounted) return;
      setState(() {
        _items = apps;
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

  Future<void> _approve(_PendingApp app) async {
    final confirmed = await _confirm(
      'Approve Application',
      'Approve ' +
          app.fullName +
          ' as ' +
          (app.kind == 'operator' ? 'an operator?' : 'a technician?'),
    );
    if (confirmed != true) return;

    try {
      final db = FirebaseFirestore.instance;
      // Copy identifiers from the application onto the user doc so the
      // approved technician/operator appears correctly elsewhere.
      final userPatch = <String, dynamic>{
        'role': app.kind == 'operator' ? 'operator' : 'technician',
        'name': app.fullName,
        'phone': app.phone,
      };
      if (app.idNumber.isNotEmpty) {
        userPatch['idNumber'] = app.idNumber;
      }
      if (app.kind == 'technician' && app.permitOrLicense.isNotEmpty) {
        userPatch['epraLicense'] = app.permitOrLicense;
      }
      if (app.kind == 'operator' && app.permitOrLicense.isNotEmpty) {
        userPatch['businessPermitNumber'] = app.permitOrLicense;
      }
      await db.collection('users').doc(app.uid).set(
        userPatch,
        SetOptions(merge: true),
      );
      await app.ref.update({'status': 'approved'});
      await NotificationService().createNotification(
        recipientId: app.uid,
        type: 'APPLICATION_APPROVED',
        title: 'Application Approved',
        body: 'Your ' +
            app.kind +
            ' application has been approved. Open the gear menu on Profile to access your dashboard.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved ' + app.fullName)),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approval failed: ' + e.toString())),
      );
    }
  }

  Future<void> _decline(_PendingApp app) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Decline Application',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Decline ' + app.fullName + '\u2019s application?',
                style: const TextStyle(color: Color(0xFFB8C7DA))),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Reason (will be sent to the applicant)',
                labelStyle: TextStyle(color: Color(0xFF8892B0)),
                filled: true,
                fillColor: Color(0xFF0A0E1A),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8892B0))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Decline',
                style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final reason = reasonCtrl.text.trim();
    try {
      await app.ref.update({
        'status': 'declined',
        'declineReason': reason,
      });
      await NotificationService().createNotification(
        recipientId: app.uid,
        type: 'APPLICATION_REJECTED',
        title: 'Application Declined',
        body: reason.isEmpty
            ? 'Your ' + app.kind + ' application was declined.'
            : 'Your ' + app.kind + ' application was declined. Reason: ' + reason,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Declined ' + app.fullName)),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Decline failed: ' + e.toString())),
      );
    }
  }

  Future<bool?> _confirm(String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(body, style: const TextStyle(color: Color(0xFFB8C7DA))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8892B0))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm',
                style: TextStyle(color: Color(0xFF00C853))),
          ),
        ],
      ),
    );
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
    if (_items.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF00C853),
        onRefresh: _load,
        child: _emptyState(
          icon: Icons.assignment_outlined,
          title: 'No Pending Applications',
          subtitle:
              'Operator and technician applications will appear here.',
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF00C853),
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _applicationCard(_items[i]),
      ),
    );
  }

  Widget _applicationCard(_PendingApp app) {
    final isOperator = app.kind == 'operator';
    final badgeColor =
        isOperator ? const Color(0xFF00C853) : const Color(0xFF4FA3E8);

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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withOpacity(0.5)),
                ),
                child: Text(
                  isOperator ? 'OPERATOR' : 'TECHNICIAN',
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _timeAgo(app.submittedAt),
                style: const TextStyle(
                    color: Color(0xFF4A5568), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            app.fullName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          _row('ID Number', app.idNumber),
          if (isOperator) _row('Business Permit', app.permitOrLicense),
          if (!isOperator) _row('EPRA License', app.permitOrLicense),
          _row('Phone', app.phone),
          _row('Email', app.email),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _decline(app),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD32F2F),
                  side: const BorderSide(color: Color(0xFFD32F2F)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('DECLINE',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _approve(app),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  elevation: 0,
                ),
                child: const Text('APPROVE',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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

  String _timeAgo(DateTime? d) {
    if (d == null) return 'just now';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _PendingApp {
  final String uid;
  final String kind; // 'operator' | 'technician'
  final String fullName;
  final String idNumber;
  final String permitOrLicense;
  final String phone;
  final String email;
  final DateTime? submittedAt;
  final DocumentReference<Map<String, dynamic>> ref;

  _PendingApp({
    required this.uid,
    required this.kind,
    required this.fullName,
    required this.idNumber,
    required this.permitOrLicense,
    required this.phone,
    required this.email,
    required this.submittedAt,
    required this.ref,
  });

  factory _PendingApp.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> d, String kind) {
    final m = d.data();
    return _PendingApp(
      uid: (m['uid'] ?? '') as String,
      kind: kind,
      fullName: (m['fullName'] ?? m['name'] ?? 'Unknown') as String,
      idNumber: (m['idNumber'] ?? '') as String,
      permitOrLicense: (m['businessPermitNumber'] ??
              m['epraLicense'] ??
              '') as String,
      phone: (m['phone'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      submittedAt: (m['submittedAt'] as Timestamp?)?.toDate(),
      ref: d.reference,
    );
  }
}

// =============================================================
// TAB 2 — Users (role 'fleet' or missing)
// =============================================================
class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  bool _loading = true;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').get();
      final filtered = snap.docs.where((d) {
        final role = (d.data()['role'] ?? 'fleet').toString();
        return role == 'fleet' || role.isEmpty;
      }).toList();
      if (!mounted) return;
      setState(() {
        _users = filtered;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00C853)));
    }
    if (_users.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF00C853),
        onRefresh: _load,
        child: _emptyState(
          icon: Icons.people_outline,
          title: 'No Users',
          subtitle: 'Normal users will appear here.',
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF00C853),
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final u = _users[i].data();
          return _userCard(
            name: (u['name'] ?? 'Unnamed').toString(),
            email: (u['email'] ?? '').toString(),
            phone: (u['phone'] ?? '').toString(),
            role: 'fleet',
          );
        },
      ),
    );
  }
}

// =============================================================
// TAB 3 — Staff (role 'operator' or 'technician')
// =============================================================
class _StaffTab extends StatefulWidget {
  const _StaffTab();

  @override
  State<_StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<_StaffTab> {
  bool _loading = true;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _staff = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').get();
      final filtered = snap.docs.where((d) {
        final role = (d.data()['role'] ?? '').toString();
        return role == 'operator' || role == 'technician';
      }).toList();
      if (!mounted) return;
      setState(() {
        _staff = filtered;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00C853)));
    }
    if (_staff.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF00C853),
        onRefresh: _load,
        child: _emptyState(
          icon: Icons.badge_outlined,
          title: 'No Staff Yet',
          subtitle: 'Approved operators and technicians will appear here.',
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF00C853),
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _staff.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final u = _staff[i].data();
          final role = (u['role'] ?? '').toString();
          return _userCard(
            name: (u['name'] ?? 'Unnamed').toString(),
            email: (u['email'] ?? '').toString(),
            phone: (u['phone'] ?? '').toString(),
            role: role,
          );
        },
      ),
    );
  }
}

// =============================================================
// Shared user card
// =============================================================
Widget _userCard({
  required String name,
  required String email,
  required String phone,
  required String role,
}) {
  Color c;
  String label;
  switch (role) {
    case 'operator':
      c = const Color(0xFF00C853);
      label = 'OPERATOR';
      break;
    case 'technician':
      c = const Color(0xFF4FA3E8);
      label = 'TECHNICIAN';
      break;
    case 'admin':
      c = const Color(0xFFE91E63);
      label = 'ADMIN';
      break;
    default:
      c = const Color(0xFF8892B0);
      label = 'USER';
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
              child: Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.withOpacity(0.5)),
              ),
              child: Text(label,
                  style: TextStyle(
                      color: c,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (email.isNotEmpty)
          Text(email,
              style: const TextStyle(
                  color: Color(0xFF8892B0), fontSize: 12)),
        if (phone.isNotEmpty)
          Text(phone,
              style: const TextStyle(
                  color: Color(0xFF8892B0), fontSize: 12)),
      ],
    ),
  );
}