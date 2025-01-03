import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/login_controller.dart';
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
  final loginController = Get.put(LoginController());

  late Timer _timer;
  int _remainingTime = 30; // 10 minutes = 600 seconds

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        if (mounted) {
          setState(() {
            _remainingTime--;
          });
        }
      } else {
        _resendOtp();
        _timer.cancel();
      }
    });
  }

  void _resendOtp() {
    loginController.resendOtp(context, widget.email);

    if (mounted) {
      setState(() {
        _remainingTime = 30;
      });
    }

    // Restart the timer after reset
    _startTimer();
  }

  void _submitOtp(String otp) {
    // Handle OTP submission
    if (otp.length == 6) {
      loginController.loginWithOtp(context, widget.email, otp);
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => {Get.back()},
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
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
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  children: [
                    const TextSpan(
                      text: 'Please enter the OTP sent to ',
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text: '.',
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OtpInputField(onOtpChanged: _submitOtp),
              SizedBox(
                height: TDeviceUtils.getScreenHeight() * 0.02,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _remainingTime == 0
                      ? _resendOtp
                      : null, // Disable button if timer is running
                  child: _remainingTime == 0
                      ? const Text('Please waiting re-send otp...')
                      : Text('Resend OTP in ${_formatTime(_remainingTime)}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpInputField extends StatefulWidget {
  final Function(String) onOtpChanged; // Callback to notify when OTP changes

  const OtpInputField({super.key, required this.onOtpChanged});

  @override
  _OtpInputFieldState createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  final int _otpLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());

  // Method to get OTP value from all controllers
  String getOtpValue() {
    return _controllers.map((controller) => controller.text).join('');
  }

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

    // Notify the parent widget (OtpView) whenever the OTP changes
    widget.onOtpChanged(getOtpValue());
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
