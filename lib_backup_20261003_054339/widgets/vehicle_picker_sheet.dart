import 'package:flutter/material.dart';
import '../models/car.dart';

class VehiclePickerSheet extends StatefulWidget {
  final Car car;
  final Future<void> Function(String plate, String? nickname) onSave;

  const VehiclePickerSheet({
    super.key,
    required this.car,
    required this.onSave,
  });

  @override
  State<VehiclePickerSheet> createState() => _VehiclePickerSheetState();
}

class _VehiclePickerSheetState extends State<VehiclePickerSheet> {
  final _plateCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _plateCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final plate = _plateCtrl.text.trim().toUpperCase();
    if (plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a plate number')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final nickname = _nicknameCtrl.text.trim();
      await widget.onSave(plate, nickname.isEmpty ? null : nickname);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF4A5568),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0x1A00C853),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x6600C853)),
                ),
                child: const Icon(Icons.directions_car,
                    color: Color(0xFF00C853), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.car.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.car.rangeKm} km range  -  ${widget.car.batteryKwh.toStringAsFixed(0)} kWh  -  ${widget.car.maxChargeKw} kW max',
                      style: const TextStyle(
                          color: Color(0xFF8892B0), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'NUMBER PLATE',
            style: TextStyle(
              color: Color(0xFF8892B0),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _plateCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _inputDecoration('e.g. KDA 123A'),
          ),
          const SizedBox(height: 14),
          const Text(
            'NICKNAME (OPTIONAL)',
            style: TextStyle(
              color: Color(0xFF8892B0),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _inputDecoration('e.g. Family car'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.black),
                    )
                  : const Text(
                      'Save Vehicle',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF0A0E1A),
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
    );
  }
}