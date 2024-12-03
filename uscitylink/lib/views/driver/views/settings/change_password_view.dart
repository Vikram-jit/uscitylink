import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/widgets/custom_button.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  _ChangePasswordViewState createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  // Controllers for text fields
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  File? pickedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColors.primary,
        centerTitle: true,
        title: const Text(
          "Update Password",
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
              const SizedBox(height: 20),

              // Name Text Field
              TextFormField(
                obscureText: true,
                controller: _oldPasswordController,
                decoration: InputDecoration(
                  hintText: 'Old Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.password),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              // Email Text Field
              TextFormField(
                obscureText: true,
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.password),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              // Phone Text Field
              TextFormField(
                obscureText: true,
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  hintText: 'Confirm Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.password),
                ),
                keyboardType: TextInputType.text,
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
                label: "Save",
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
      print(e.toString());
      return ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
