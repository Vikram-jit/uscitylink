import 'package:flutter/material.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';

class InternetExceptionsWidget extends StatefulWidget {
  const InternetExceptionsWidget({super.key});

  @override
  State<InternetExceptionsWidget> createState() =>
      _InternetExceptionsWidgetState();
}

class _InternetExceptionsWidgetState extends State<InternetExceptionsWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: TDeviceUtils.getScreenHeight() * .15,
          ),
          const Icon(Icons.cloud_off, color: Colors.red),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 30),
              child: const Text(
                "We're unable to show results.\n Please check your data\nconnection",
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            height: TDeviceUtils.getScreenHeight() * .05,
          ),
          Container(
            height: 44,
            width: 160,
            decoration: BoxDecoration(
                color: TColors.primary,
                borderRadius: BorderRadius.circular(50)),
            child: Center(
              child: Text(
                'Retry',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }
}
