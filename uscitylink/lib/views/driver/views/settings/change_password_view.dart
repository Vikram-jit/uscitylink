import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/login_controller.dart';
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

  LoginController _loginController = Get.put(LoginController());

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
                  _loginController.changePassword(
                      context,
                      _oldPasswordController.value.text,
                      _passwordController.value.text,
                      _confirmPasswordController.value.text);
                },
                label: "Update",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
