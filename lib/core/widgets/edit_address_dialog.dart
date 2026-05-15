import 'package:flutter/material.dart';
import '../../models/address_model.dart';

class EditAddressDialog extends StatefulWidget {
  final AddressModel initialAddress;
  final void Function(AddressModel updatedAddress) onSave;

  const EditAddressDialog({
    Key? key,
    required this.initialAddress,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditAddressDialog> createState() => _EditAddressDialogState();
}

class _EditAddressDialogState extends State<EditAddressDialog> {
  late final TextEditingController _houseController;
  late final TextEditingController _areaController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _cityController;
  late final TextEditingController _pinCodeController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    final a = widget.initialAddress;
    _houseController = TextEditingController(text: a.houseNumber);
    _areaController = TextEditingController(text: a.areaName);
    _landmarkController = TextEditingController(text: a.landmark);
    _cityController = TextEditingController(text: a.city);
    _pinCodeController = TextEditingController(text: a.pinCode);
    _stateController = TextEditingController(text: a.state);
    _countryController = TextEditingController(text: a.country);
  }

  @override
  void dispose() {
    _houseController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = AddressModel(
      houseNumber: _houseController.text.trim(),
      areaName: _areaController.text.trim(),
      landmark: _landmarkController.text.trim(),
      city: _cityController.text.trim(),
      pinCode: _pinCodeController.text.trim(),
      state: _stateController.text.trim(),
      country: _countryController.text.trim(),
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Address"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            _buildTextField(_houseController, "House / Building No."),
            _buildTextField(_areaController, "Area Name"),
            _buildTextField(_landmarkController, "Landmark"),
            _buildTextField(_cityController, "City"),
            _buildTextField(_pinCodeController, "Pin Code",
                inputType: TextInputType.number),
            _buildTextField(_stateController, "State"),
            _buildTextField(_countryController, "Country"),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        ElevatedButton(onPressed: _save, child: const Text("Save")),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
