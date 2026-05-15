import 'dart:io';

import 'package:bookmyservice/services/app_account_provider.dart';
import 'package:bookmyservice/services/maids_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/address_model.dart';
import '../../models/maid_model.dart';
import 'edit_address_dialog.dart';
import 'profie_picture_widget.dart';

class MaidsAccount extends ConsumerStatefulWidget {
  final MaidModel? maid;

  const MaidsAccount({this.maid, super.key});

  @override
  ConsumerState<MaidsAccount> createState() => _MaidsAccountState();
}

class _MaidsAccountState extends ConsumerState<MaidsAccount> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController name,
      email,
      phone,
      gender,
      address,
      commission,
      aadhar,
      pan,
      bankAccount,
      ifsc,
      bankName,
      bankBranch,
      accountHolder,
      profilePicture,
      username,
      password;

  List<String> skills = [];
  XFile? pickedImage;
  String? profileImageUrl;
  bool isSaving = false;
  AddressModel? addressModel;
  bool _passwordVisibility = true;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.maid?.name ?? '');
    email = TextEditingController(text: widget.maid?.email ?? '');
    phone = TextEditingController(text: widget.maid?.phone ?? '');
    gender = TextEditingController(text: widget.maid?.gender ?? 'Female');
    addressModel = widget.maid != null
        ? widget.maid?.address
        : AddressModel(
            houseNumber: '',
            areaName: '',
            landmark: '',
            city: '',
            pinCode: '',
            state: '',
            country: '',
          );
    address = TextEditingController(
        text: widget.maid?.address
            .toString()); // Customize as per your AddressModel
    commission = TextEditingController(
        text: widget.maid?.commissionPercentage.toString() ?? '');

    aadhar = TextEditingController(text: widget.maid?.aadharNumber ?? '');
    pan = TextEditingController(text: widget.maid?.panNumber ?? '');
    bankAccount =
        TextEditingController(text: widget.maid?.bankAccountNumber ?? '');
    ifsc = TextEditingController(text: widget.maid?.bankIfscCode ?? '');
    bankName = TextEditingController(text: widget.maid?.bankName ?? '');
    bankBranch = TextEditingController(text: widget.maid?.bankBranch ?? '');
    accountHolder =
        TextEditingController(text: widget.maid?.bankAccountHolderName ?? '');
    profilePicture =
        TextEditingController(text: widget.maid?.profilePictureUrl ?? '');
    username = TextEditingController(text: widget.maid?.userName ?? '');
    password = TextEditingController(text: widget.maid?.password ?? '');

    skills = List<String>.from(widget.maid?.skills ?? []);
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    gender.dispose();
    address.dispose();
    commission.dispose();
    aadhar.dispose();
    pan.dispose();
    bankAccount.dispose();
    ifsc.dispose();
    bankName.dispose();
    bankBranch.dispose();
    accountHolder.dispose();
    profilePicture.dispose();
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool isNumber = false, bool validate = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: validate
            ? (value) => value == null || value.isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  void save(WidgetRef ref, BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      debugPrint("IS IMAGE NULL: ${pickedImage == null}");
      setState(() {
        isSaving = true;
      });
      if (pickedImage != null) {
        profileImageUrl = await uploadImage(pickedImage!);
        debugPrint("Image URL: $profileImageUrl");
      }

      // Create a new MaidModel or update the existing one
      final maidData = (widget.maid != null
          ? widget.maid!.copyWith(
              name: name.text,
              email: email.text,
              phone: phone.text,
              gender: gender.text,
              address: addressModel ?? widget.maid!.address,
              commissionPercentage: double.parse(commission.text),
              aadharNumber: aadhar.text,
              panNumber: pan.text,
              bankAccountNumber: bankAccount.text,
              bankIfscCode: ifsc.text,
              bankName: bankName.text,
              bankBranch: bankBranch.text,
              bankAccountHolderName: accountHolder.text,
              profilePictureUrl: profileImageUrl,
              userName: username.text,
              password: password.text,
              skills: skills,
            )
          : MaidModel(
              id: DateTime.now().toIso8601String(), // generate this yourself
              name: name.text,
              email: email.text,
              phone: phone.text,
              gender: gender.text,
              userId: '', // or assign if needed
              isAvailable: true,
              appAccountId: ref.read(appAccountProvider)?.appAccountId ?? '',
              totalEarnings: 0.0,
              commissionPercentage: double.parse(commission.text),
              address: addressModel!,
              aadharNumber: aadhar.text,
              panNumber: pan.text,
              bankAccountNumber: bankAccount.text,
              bankIfscCode: ifsc.text,
              bankName: bankName.text,
              bankBranch: bankBranch.text,
              bankAccountHolderName: accountHolder.text,
              profilePictureUrl: profileImageUrl,
              userName: username.text,
              password: password.text,
              skills: skills,
              createdAt: DateTime.now().toIso8601String(),
            ));

      if (widget.maid != null) {
        ref.read(maidAccountProvider.notifier).updateMaid(maidData);
      } else {
        ref.read(maidAccountProvider.notifier).addMaid(maidData);
        setState(() {
          isSaving = false;
        });
      }
      Navigator.pop(context, maidData);
    }
  }

  Future<String?> uploadImage(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final fileName = imageFile.path;
      final ref = FirebaseStorage.instance.ref().child('maids/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Image upload failed: $e");
      return null;
    }
  }

  _showEditAddressDialog(
      BuildContext context, WidgetRef ref, AddressModel currentAddress) {
    showDialog(
      context: context,
      builder: (context) => EditAddressDialog(
        initialAddress: currentAddress,
        onSave: (updatedAddress) {
          setState(() {
            address.text = updatedAddress.toString();
            addressModel = updatedAddress;
          });
        },
      ),
    );
  }

  void _toggleVisibility() {
    setState(() {
      _passwordVisibility = !_passwordVisibility;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Maid Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  ProfilePictureWidget(
                    initialUrl: widget.maid?.profilePictureUrl,
                    onImagePicked: (file) => setState(() => pickedImage = file),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  buildTextField('Name', name),
                  buildTextField('Email', email),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                          return 'Enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: gender.text,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Male', 'Female', 'Other']
                        .map(
                          (gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        gender.text = value!;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select gender' : null,
                  ),
                  buildTextField(
                    'Commission %',
                    commission,
                    isNumber: true,
                    validate: false,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextFormField(
                      readOnly: true,
                      controller: address,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                      onTap: () {
                        _showEditAddressDialog(
                            context,
                            ref,
                            widget.maid != null
                                ? widget.maid!.address
                                : addressModel!);
                      },
                    ),
                  ),
                  buildTextField(
                    'Aadhar Number',
                    aadhar,
                    validate: false,
                    isNumber: true,
                  ),
                  buildTextField(
                    'PAN Number',
                    pan,
                    validate: false,
                  ),
                  buildTextField(
                    'Bank Account No.',
                    bankAccount,
                    validate: false,
                    isNumber: true,
                  ),
                  buildTextField(
                    'IFSC Code',
                    ifsc,
                    validate: false,
                  ),
                  buildTextField(
                    'Bank Name',
                    bankName,
                    validate: false,
                  ),
                  buildTextField(
                    'Bank Branch',
                    bankBranch,
                    validate: false,
                  ),
                  buildTextField(
                    'Account Holder Name',
                    accountHolder,
                    validate: false,
                  ),
                  buildTextField(
                    'Username',
                    username,
                    validate: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextFormField(
                      obscureText: _passwordVisibility,
                      controller: password,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Passsword',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisibility
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.teal,
                          ),
                          onPressed: _toggleVisibility,
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.07,
                  ),
                ],
              ),
            ),
          ),
          if (isSaving)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 50,
        child: FloatingActionButton.extended(
          onPressed: isSaving
              ? null
              : () {
                  save(ref, context);
                }, // Your save function
          label: const SizedBox(
            width: 60,
            child: Center(
              child: Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ),

          backgroundColor: Colors.teal, // Use primary color
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
