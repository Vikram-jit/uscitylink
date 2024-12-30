import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/widgets/custom_button.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  _AccountViewState createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  final loginController = Get.put(LoginController());
  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  File? pickedImage;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _nameController.text = loginController.userProfile.isNotEmpty
        ? loginController.userProfile.first.username!
        : "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColors.primary,
        centerTitle: true,
        title: const Text(
          "Account",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {
                    _pickerOption();
                  },
                  child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: pickedImage != null
                          ? FileImage(pickedImage!)
                          : const AssetImage('assets/images/placeholder.png')
                              as ImageProvider,
                      child: pickedImage == null
                          ? const Icon(Icons.camera_alt,
                              size: 40, color: Colors.white)
                          : null),
                ),
              ),
              const SizedBox(height: 20),

              // Name Text Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),

              // Email Text Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Phone Text Field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // Save Button
              CustomButton(
                onPressed: () {
                  // Save logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated!')),
                  );
                },
                label: "Update",
              ),
            ],
          ),
        ),
      ),
    );
  }

  _pickerOption() {
    showAdaptiveActionSheet(
      context: context,
      actions: <BottomSheetAction>[
        BottomSheetAction(
          title: const Text(
            'Camera',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
          ),
          onPressed: (_) {
            Navigator.of(context).pop();
            _pickImage(ImageSource.camera);
          },
        ),
        BottomSheetAction(
          title: const Text(
            'Gallery',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
          ),
          onPressed: (_) {
            Navigator.of(context).pop();
            _pickImage(ImageSource.gallery);
          },
        ),
      ],
    );
  }

  _pickImage(ImageSource source) async {
    try {
      final photo = await ImagePicker().pickImage(source: source);

      if (photo == null) return;

      final tempImage = File(photo.path);

      setState(() {
        pickedImage = tempImage;
      });
    } catch (e) {
      return ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
