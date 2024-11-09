import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/loading_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/constant/image_strings.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:uscitylink/views/auth/otp_view.dart';
import 'package:uscitylink/views/widgets/custom_button.dart';
import 'package:uscitylink/views/widgets/logo_widgets.dart';

class PasswordView extends StatefulWidget {
  final String email;
  final String role;

  PasswordView({Key? key, required this.email, required this.role})
      : super(key: key);

  @override
  _PasswordViewState createState() => _PasswordViewState();
}

class _PasswordViewState extends State<PasswordView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  // final LoadingController loadingController = Get.find();

  final loginController = Get.put(LoginController());
  @override
  void initState() {
    super.initState();
    // loadData();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward(); // Start the animation
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Password'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(), // Go back to the previous screen
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const LogoWidgets(),
              SizedBox(
                height: TDeviceUtils.getScreenHeight() * 0.01,
              ),
              TextField(
                readOnly: true, // Make the TextField read-only
                controller: TextEditingController(
                    text: widget.email?.toString()), // Set the initial value
                decoration: const InputDecoration(
                  hintText:
                      "Email Address", // Change hint text to reflect email
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  border: OutlineInputBorder(), // Optional: Add a border
                ),
              ),
              SizedBox(
                height: TDeviceUtils.getScreenHeight() * 0.01,
              ),
              TextField(
                controller: loginController.passwordController.value,
                focusNode: loginController.passwordFoucsNode.value,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Enter Password",
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                height: TDeviceUtils.getScreenHeight() * 0.03,
              ),
              CustomButton(
                  label: "Submit",
                  onPressed: () {
                    loginController.loginWithPassword(
                        context, widget.email, widget.role);
                  }),
              SizedBox(
                height: TDeviceUtils.getScreenHeight() * 0.01,
              ),
              _buildDividerWithText("or"),
              SizedBox(
                height: TDeviceUtils.getScreenHeight() * 0.01,
              ),
              CustomButton(
                label: "Send OTP",
                onPressed: () {
                  Get.to(() => OtpView(email: 'user@example.com'));
                },
                backgroundColor: TColors.white,
                textColor: TColors.primary,
              ),
              // Obx(() {
              //   return loadingController.isLoading.value
              //       ? Center(child: CircularProgressIndicator())
              //       : SizedBox.shrink();
              // }),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildDividerWithText(String text) {
  return Row(
    children: [
      const Expanded(
        child: Divider(thickness: 1),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const Expanded(
        child: Divider(thickness: 1),
      ),
    ],
  );
}
