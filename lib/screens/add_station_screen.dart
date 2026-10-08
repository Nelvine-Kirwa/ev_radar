import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/location_service.dart';

const List<String> _chargerTypes = [
  'Type 1 AC',
  'Type 2 AC',
  'CCS DC',
  'CHAdeMO',
  'Type 1 + Type 2',
  'Type 2 + CCS',
  'Type 2 + CHAdeMO',
];

const List<String> _allAmenities = [
  'Parking',
  '24/7 Access',
  'Security',
  'Restroom',
  'Cafe',
  'WiFi',
  'Shopping',
  'ATM',
  'Car Wash',
  'Convenience Store',
];

/// Operator-only: register a new station. Submits to `stations` with
/// `status: 'pending'` for admin approval.
class AddStationScreen extends StatefulWidget {
  const AddStationScreen({super.key});

  @override
  State<AddStationScreen> createState() => _AddStationScreenState();
}

class _AddStationScreenState extends State<AddStationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stationName = TextEditingController();
  final _companyName = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _permit = TextEditingController();
  final _building = TextEditingController();
  final _street = TextEditingController();
  final _county = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _capturing = false;
  bool _submitting = false;

  final List<Map<String, dynamic>> _chargers = [];
  final Set<String> _selectedAmenities = {};

  @override
  void dispose() {
    _stationName.dispose();
    _companyName.dispose();
    _contact.dispose();
    _email.dispose();
    _permit.dispose();
    _building.dispose();
    _street.dispose();
    _county.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() => _capturing = true);
    try {
      final pos = await LocationService().getCurrentLocation();
      if (!mounted) return;
      if (pos == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
      } else {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location error: $e')),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _addCharger() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final available = _chargerTypes
            .where((t) => !_chargers.any((c) => c['type'] == t))
            .toList();

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Add Charger Type',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (available.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('All charger types added',
                          style: TextStyle(color: Color(0xFF8892B0))),
                    )
                  else
                    ...available.map(
                      (t) => ListTile(
                        title: Text(t,
                            style: const TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                          _promptPorts(t);
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _promptPorts(String chargerType) {
    final portsCtrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text(chargerType,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: portsCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Number of ports',
            labelStyle: TextStyle(color: Color(0xFF8892B0)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8892B0))),
          ),
          TextButton(
            onPressed: () {
              final n = int.tryParse(portsCtrl.text);
              if (n == null || n < 1) return;
              setState(() {
                _chargers.add({'type': chargerType, 'ports': n});
              });
              Navigator.pop(context);
            },
            child: const Text('Add',
                style: TextStyle(color: Color(0xFF00C853))),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    // Ask the user to confirm before we hit Firestore.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text(
          'Confirm Submission',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Do you want to submit your application?',
          style: TextStyle(color: Color(0xFFB8C7DA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8892B0)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes',
              style: TextStyle(color: Color(0xFF00C853)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture your location first')),
      );
      return;
    }
    if (_chargers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one charger type')),
      );
      return;
    }
    if (_selectedAmenities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one amenity')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);

    try {
      // Build connectorType string from chargers list
      final types = _chargers.map((c) => c['type'] as String).toList();
      final connectorType = types.join(' + ');
      final totalPorts = _chargers.fold<int>(
          0, (sum, c) => sum + ((c['ports'] as int?) ?? 0));

      // Address line
      final addrParts = <String>[
        if (_building.text.trim().isNotEmpty) _building.text.trim(),
        _street.text.trim(),
        _county.text.trim(),
      ]..removeWhere((s) => s.isEmpty);
      final address = addrParts.join(', ');

      await FirebaseFirestore.instance.collection('stations').add({
        'name': _stationName.text.trim(),
        'operator': _companyName.text.trim(),
        'operatorId': user.uid,
        'operatorContact': _contact.text.trim(),
        'operatorEmail': _email.text.trim(),
        'businessPermitNumber': _permit.text.trim(),
        'address': address,
        'building': _building.text.trim(),
        'street': _street.text.trim(),
        'county': _county.text.trim(),
        'neighborhood': _county.text.trim(),
        'lat': _latitude,
        'lng': _longitude,
        'connectorType': connectorType,
        'chargers': _chargers,
        'powerKw': 22.0,
        'portsTotal': totalPorts > 0 ? totalPorts : 2,
        'portsAvailable': totalPorts > 0 ? totalPorts : 2,
        'status': 'pending',
        'amenities': _selectedAmenities.toList(),
        'chargerImage': 'assets/images/chargers/type2_ac.jpg',
        'operatingHours': '24 hours',
        'phone': _contact.text.trim(),
        'pricePerKwhKsh': 28,
        'source': 'Operator Submission',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: const Text('Station Submitted',
              style: TextStyle(color: Colors.white)),
          content: const Text(
            'Your station is pending admin verification. '
            'It will appear on the map once approved.',
            style: TextStyle(color: Color(0xFF8892B0)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to Operator Dashboard
              },
              child: const Text('OK',
                  style: TextStyle(color: Color(0xFF00C853))),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        title: const Text('Register New Station',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Fill in your details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),

                _sectionLabel('STATION'),
                const SizedBox(height: 10),
                _field(_stationName, 'Station Name', Icons.ev_station),
                const SizedBox(height: 24),

                _sectionLabel('COMPANY'),
                const SizedBox(height: 10),
                _field(_companyName, 'Company Name', Icons.business),
                const SizedBox(height: 14),
                _field(_contact, 'Company Contact (Phone)', Icons.phone,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 14),
                _field(_email, 'Company Email', Icons.email,
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _field(_permit, 'Business Permit Number', Icons.badge),
                const SizedBox(height: 24),

                _sectionLabel('LOCATION'),
                const SizedBox(height: 10),
                _locationCaptureRow(),
                const SizedBox(height: 14),
                _field(_building, 'Building Name (optional)', Icons.apartment,
                    required: false),
                const SizedBox(height: 14),
                _field(_street, 'Street / Road', Icons.add_road),
                const SizedBox(height: 14),
                _field(_county, 'County', Icons.location_city),
                const SizedBox(height: 24),

                _sectionLabel('CHARGERS'),
                const SizedBox(height: 10),
                _chargersList(),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addCharger,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Charger Type'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00C853),
                    side: const BorderSide(color: Color(0xFF00C853)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),

                _sectionLabel('AMENITIES'),
                const SizedBox(height: 10),
                _amenitiesChips(),
                const SizedBox(height: 28),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text('Submit Application',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFB8C7DA),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _locationCaptureRow() {
    final hasLocation = _latitude != null && _longitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _capturing ? null : _captureLocation,
          icon: _capturing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF00C853)),
                )
              : const Icon(Icons.my_location, size: 18),
          label: Text(
            hasLocation
                ? 'Recapture Location'
                : 'Share Current Location Coordinates',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF00C853),
            side: const BorderSide(color: Color(0xFF00C853)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (hasLocation) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _coordChip('Lat', _latitude!.toStringAsFixed(5)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _coordChip('Lng', _longitude!.toStringAsFixed(5)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _coordChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1A00C853),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x6600C853)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: Color(0xFF00C853), size: 14),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(
                  color: Color(0xFF8892B0), fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _chargersList() {
    if (_chargers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No charger types added yet',
          style: TextStyle(color: Color(0xFF4A5568), fontSize: 12),
        ),
      );
    }
    return Column(
      children: _chargers.map((c) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1F2937)),
          ),
          child: Row(
            children: [
              const Icon(Icons.ev_station,
                  color: Color(0xFF00C853), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c['type'] as String,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Text('${c['ports']} ports',
                  style: const TextStyle(
                      color: Color(0xFF8892B0), fontSize: 12)),
              IconButton(
                onPressed: () => setState(() => _chargers.remove(c)),
                icon: const Icon(Icons.close,
                    color: Color(0xFF8892B0), size: 16),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _amenitiesChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allAmenities.map((a) {
        final selected = _selectedAmenities.contains(a);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedAmenities.remove(a);
              } else {
                _selectedAmenities.add(a);
              }
            });
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF00C853)
                  : const Color(0xFF111827),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? const Color(0xFF00C853)
                    : const Color(0xFF1F2937),
              ),
            ),
            child: Text(
              a,
              style: TextStyle(
                color: selected ? Colors.black : const Color(0xFF8892B0),
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      validator: (v) {
        if (!required) return null;
        return v == null || v.isEmpty ? 'Required' : null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8892B0)),
        prefixIcon: Icon(icon, color: const Color(0xFF8892B0), size: 20),
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2937)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C853), width: 1.5),
        ),
      ),
    );
  }
}