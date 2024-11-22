import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/views/widgets/custom_button.dart';
import 'package:uscitylink/views/widgets/logo_widgets.dart'; // For navigation (if using GetX)

class OtpView extends StatefulWidget {
  final String email;

  const OtpView({super.key, required this.email});
  @override
  _OtpViewState createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  final TextEditingController _otpController = TextEditingController();
  final int _otpLength = 6; // Adjust the OTP length as needed

  void _submitOtp() {
    // Handle OTP submission
    String otp = _otpController.text;
    if (otp.length == _otpLength) {
      // Navigate to the next screen or validate the OTP
      Get.toNamed('/nextScreen'); // Adjust route as necessary
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(), // Go back to the previous screen
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const LogoWidgets(),
            const Text(
              'Verification Code',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: TDeviceUtils.getScreenHeight() * 0.01,
            ),
            Text(
              'Please enter the OTP sent to your phone.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const OtpInputField(),
            SizedBox(
              height: TDeviceUtils.getScreenHeight() * 0.02,
            ),
            CustomButton(
                label: "Submit",
                onPressed: () {
                  Get.offNamed(AppRoutes.driverDashboard);
                }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  // Resend OTP logic
                },
                child: const Text('Resend OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpInputField extends StatefulWidget {
  const OtpInputField({super.key});

  @override
  _OtpInputFieldState createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  final int _otpLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());

  void _onChanged(String value, int index) {
    if (value.length == 1) {
      // Move to the next input field when a character is entered
      if (index < _otpLength - 1) {
        FocusScope.of(context).nextFocus();
      }
    } else if (value.isEmpty) {
      // Move back to the previous input field when the user deletes a character
      if (index > 0) {
        FocusScope.of(context).previousFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_otpLength, (index) {
        return SizedBox(
          width: 50,
          child: TextField(
            controller: _controllers[index],
            maxLength: 1,
            onChanged: (value) => _onChanged(value, index),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.grey)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        );
      }),
    );
  }
}
