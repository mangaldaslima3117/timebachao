import 'dart:async';

import 'package:bookmyservice/core/presentation/customer/customer_welcome_page.dart';
import 'package:bookmyservice/core/presentation/customer/map_address_selection.dart';
import 'package:bookmyservice/services/authentication_provider.dart';
import 'package:bookmyservice/services/customer_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/customer_model.dart';
import '../../../models/address_model.dart';

class CustomerDetailsPage extends ConsumerStatefulWidget {
  final CustomerModel customer;
  const CustomerDetailsPage({super.key, required this.customer});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends ConsumerState<CustomerDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  final countryController = TextEditingController();
  final landController = TextEditingController();
  final areaController = TextEditingController();
  final houseController = TextEditingController();

  String gender = 'Male';

  @override
  void initState() {
    super.initState();
    phoneController.text = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    nameController.text = widget.customer.name;
    emailController.text = widget.customer.email;
    gender =
        widget.customer.gender.isNotEmpty ? widget.customer.gender : 'Male';
    houseController.text = widget.customer.address.houseNumber;
    areaController.text = widget.customer.address.areaName;
    landController.text = widget.customer.address.landmark;
    cityController.text = widget.customer.address.city;
    pincodeController.text = widget.customer.address.pinCode;
    stateController.text = _defaultStateIfEmpty(widget.customer.address.state);
    countryController.text =
        _defaultCountryIfEmpty(widget.customer.address.country);
  }

  String _defaultStateIfEmpty(String value) {
    return value.trim().isEmpty ? AddressModel.defaultState : value;
  }

  String _defaultCountryIfEmpty(String value) {
    return value.trim().isEmpty ? AddressModel.defaultCountry : value;
  }

  Future<void> _saveCustomerData() async {
    final customerP = ref.read(customerProvider.notifier);
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final customer = CustomerModel(
      id: widget.customer.id.isNotEmpty
          ? widget.customer.id
          : phoneController.text.trim(),
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim().substring(3),
      userId: uid,
      gender: gender,
      address: AddressModel(
        houseNumber: houseController.text.trim(),
        areaName: areaController.text.trim(),
        landmark: landController.text.trim(),
        city: cityController.text.trim(),
        pinCode: pincodeController.text.trim(),
        state: stateController.text.trim(),
        country: countryController.text.trim(),
      ),
      appAccountId: '',
      profileImageUrl: '',
      fcmToken:
          widget.customer.fcmToken!.isNotEmpty ? widget.customer.fcmToken : '',
    );

    if (widget.customer.id.isNotEmpty) {
      // Update existing customer
      await customerP.updateCustomer(customer);
    } else {
      // Add new customer
      await customerP.addCustomer(customer);
    }
    customerP.addCustomer(customer);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Details saved successfully')),
    );

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return const CustomerWelcomePage();
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.teal,
        title: const Text(
          'Information',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            25,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await authService.signOut();
            },
            icon: const Icon(
              Icons.logout,
              size: 20,
              color: Colors.white,
            ),
            //label: const Text("Filter"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(phoneController, 'Phone', enabled: false),
              _buildTextField(nameController, 'Name'),
              _buildTextField(
                emailController,
                'Email',
                inputType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              //const Text('Gender'),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: DropdownButtonFormField<String>(
                  value: gender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        15,
                      ),
                    ),
                  ),
                  onChanged: (value) => setState(() => gender = value!),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                ),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Address',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapAddressSelectorScreen(),
                          )).then((dynamic selectedAddress) {
                        debugPrint(
                            'Selected address In Detail: ${selectedAddress.toString()}');
                        if (selectedAddress.houseNumber.isNotEmpty) {
                          // Assuming selectedAddress is a string with the address
                          //streetController.text = selectedAddress;
                          setState(() {
                            houseController.text = selectedAddress.houseNumber;
                            areaController.text = selectedAddress.areaName;
                            landController.text = selectedAddress.landmark;
                            cityController.text = selectedAddress.city;
                            pincodeController.text = selectedAddress.pinCode;
                            stateController.text = selectedAddress.state;
                            countryController.text = selectedAddress.country;
                          });
                        }
                      } as FutureOr Function(dynamic value));
                    },
                    icon: const Icon(
                      Icons.pin_drop,
                    ),
                    tooltip: 'Select on Map',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(houseController, "House / Building No."),
              _buildTextField(areaController, "Area Name"),
              _buildTextField(landController, "Landmark"),
              _buildTextField(cityController, "City"),
              _buildTextField(pincodeController, "Pin Code",
                  inputType: TextInputType.number),
              _buildTextField(stateController, "State"),
              _buildTextField(countryController, "Country"),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, // 🔵 Button background color
                  foregroundColor: Colors.white,
                ),
                onPressed: _saveCustomerData,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool enabled = true, TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}
