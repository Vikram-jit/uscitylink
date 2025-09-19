import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/views/widgets/logo_widgets.dart';

// ignore: must_be_immutable
class SelectOption extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String phone_number;
  SelectOption(
      {super.key,
      required this.email,
      required this.phone_number,
      required this.name,
      required this.role});
  LoginController _loginController = Get.put(LoginController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Otp'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => {Get.back()},
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                  child: const LogoWidgets(
                    height: 200,
                  ),
                  alignment: Alignment.topCenter),
              SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Text(
                    "Welcome ${role.isNotEmpty ? '${role[0].toUpperCase()}${role.substring(1).toLowerCase()}' : ''},",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              Text(
                "$name",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(
                height: 30,
              ),
              Text(
                "Choose an email address or phone number to receive your OTP securely.",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Obx(() {
                    return Checkbox(
                        value: _loginController.checkedEmailOtp.value,
                        onChanged: (value) {
                          _loginController.checkedEmailOtp.value =
                              value ?? false;
                        });
                  }),
                  Text(
                    "${email.trim()}",
                    style: Theme.of(context).textTheme.bodyLarge,
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Obx(() {
                    return Checkbox(
                        value: _loginController.checkedPhoneNumberOtp.value,
                        onChanged: (value) {
                          _loginController.checkedPhoneNumberOtp.value =
                              value ?? false;
                        });
                  }),
                  Text(
                    "${phone_number.toString().trim() ?? ""}",
                    style: Theme.of(context).textTheme.bodyLarge,
                  )
                ],
              ),
              SizedBox(
                height: 30,
              ),
              SizedBox(
                width: TDeviceUtils.getScreenWidth(context),
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    _loginController.sendOtp(
                        context,
                        email,
                        phone_number,
                        _loginController.checkedEmailOtp.value,
                        _loginController.checkedPhoneNumberOtp.value);
                  },
                  child: const Text(
                    "Send OTP",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
