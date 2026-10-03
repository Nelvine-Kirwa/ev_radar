import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../models/user_vehicle.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/vehicle_picker_sheet.dart';

class VehiclePickerScreen extends StatefulWidget {
  const VehiclePickerScreen({super.key});

  @override
  State<VehiclePickerScreen> createState() => _VehiclePickerScreenState();
}

class _VehiclePickerScreenState extends State<VehiclePickerScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vp = context.read<VehicleProvider>();
      if (vp.availableCars.isEmpty) {
        await vp.loadAvailableCars();
      }
      // Retry once if still empty
      if (vp.availableCars.isEmpty && mounted) {
        await Future.delayed(const Duration(seconds: 2));
        if (vp.availableCars.isEmpty && mounted) {
          await vp.loadAvailableCars();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openSheet(Car car) async {
    final vehicleProvider = context.read<VehicleProvider>();
    final authProvider = context.read<AuthProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => VehiclePickerSheet(
        car: car,
        onSave: (plate, nickname) async {
          final newVehicle = UserVehicle(
            carId: car.id,
            plate: plate,
            nickname: nickname,
          );
          vehicleProvider.addUserVehicle(newVehicle);
          await authProvider.saveVehicles(
            vehicleProvider.userVehicles,
            vehicleProvider.currentVehicleIndex,
          );
        },
      ),
    );
  }

  Future<void> _removeVehicle(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Remove vehicle?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'This vehicle will be removed from your account.',
          style: TextStyle(color: Color(0xFF8892B0), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8892B0))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove',
                style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final vp = context.read<VehicleProvider>();
    final auth = context.read<AuthProvider>();
    vp.removeUserVehicle(index);
    await auth.saveVehicles(vp.userVehicles, vp.currentVehicleIndex);
  }

  Future<void> _switchTo(int index) async {
    final vp = context.read<VehicleProvider>();
    final auth = context.read<AuthProvider>();
    vp.switchVehicle(index);
    await auth.saveVehicles(vp.userVehicles, vp.currentVehicleIndex);
  }

  List<Car> _filteredCatalog(VehicleProvider vp) {
    if (_query.isEmpty) return vp.availableCars;
    final q = _query.toLowerCase();
    return vp.availableCars.where((c) {
      return c.displayName.toLowerCase().contains(q) ||
          c.make.toLowerCase().contains(q) ||
          c.model.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VehicleProvider>();
    final catalog = _filteredCatalog(vp);

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
          'My Vehicles',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF1F2937)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search car model...',
                    hintStyle: TextStyle(
                        color: Color(0xFF4A5568), fontSize: 14),
                    prefixIcon: Icon(Icons.search,
                        color: Color(0xFF8892B0), size: 20),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  _sectionLabel('YOUR VEHICLES'),
                  const SizedBox(height: 10),
                  if (vp.userVehicles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No vehicles saved yet',
                        style: TextStyle(
                            color: Color(0xFF4A5568), fontSize: 13),
                      ),
                    )
                  else
                    ...List.generate(vp.userVehicles.length, (i) {
                      return _savedVehicleRow(vp, i);
                    }),
                  const SizedBox(height: 20),
                  _sectionLabel('VEHICLES'),
                  const SizedBox(height: 10),
                  if (vp.loadingCatalog)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00C853)),
                      ),
                    )
                  else if (catalog.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No cars match your search',
                        style: TextStyle(
                            color: Color(0xFF4A5568), fontSize: 13),
                      ),
                    )
                  else
                    ...catalog.map((c) => _catalogCard(c)),
                ],
              ),
            ),
          ],
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

  Widget _savedVehicleRow(VehicleProvider vp, int index) {
    final uv = vp.userVehicles[index];
    final car = vp.availableCars.firstWhere(
      (c) => c.id == uv.carId,
      orElse: () => const Car(
        id: '',
        make: '',
        model: '',
        displayName: 'Unknown',
        batteryKwh: 0,
        rangeKm: 0,
        consumptionKwhPer100km: 0,
        maxChargeKw: 0,
        connectorTypes: [],
      ),
    );
    final isCurrent = index == vp.currentVehicleIndex;

    return GestureDetector(
      onTap: () => _switchTo(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent
                ? const Color(0xFF00C853)
                : const Color(0xFF1F2937),
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x1A00C853),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x6600C853)),
              ),
              child: const Icon(Icons.directions_car,
                  color: Color(0xFF00C853), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    uv.nickname?.isNotEmpty == true
                        ? uv.nickname!
                        : car.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    car.displayName,
                    style: const TextStyle(
                        color: Color(0xFF8892B0), fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        uv.plate,
                        style: const TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x1A00C853),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0x6600C853)),
                          ),
                          child: const Text('Active',
                              style: TextStyle(
                                  color: Color(0xFF00C853),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Color(0xFFD32F2F), size: 20),
              onPressed: () => _removeVehicle(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catalogCard(Car car) {
    return GestureDetector(
      onTap: () => _openSheet(car),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1F2937)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: const Icon(Icons.electric_car,
                  color: Color(0xFF00C853), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${car.rangeKm} km  -  ${car.batteryKwh.toStringAsFixed(0)} kWh  -  ${car.maxChargeKw} kW',
                    style: const TextStyle(
                        color: Color(0xFF8892B0), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline,
                color: Color(0xFF00C853), size: 20),
          ],
        ),
      ),
    );
  }
}