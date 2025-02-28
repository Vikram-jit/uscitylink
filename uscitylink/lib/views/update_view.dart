import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'dart:io';

class UpdateView extends StatelessWidget {
  UpdateView({super.key});
  final String androidAppId =
      "com.uscitylink.app"; // Replace with your Android package name
  final String iosAppId = "6737588933"; // Replace with your App Store ID

  Future<void> openStore() async {
    String url;

    if (Platform.isAndroid) {
      url = "https://play.google.com/store/apps/details?id=$androidAppId";
    } else if (Platform.isIOS) {
      url = "https://apps.apple.com/app/id$iosAppId";
    } else {
      return;
    }

    // Check if URL can be launched and then open it
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw "Could not open the store link.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: TDeviceUtils.getScreenHeight() * 0.6,
            child: Image.asset(
              "assets/images/update.webp",
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "New update is available",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 28),
            child: Text(
              "The current version of this application is no longer supported.We apologize for any inconvenience we may have caused you.",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontSize: 18),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          InkWell(
            onTap: openStore,
            child: Container(
              height: 40,
              width: TDeviceUtils.getScreenWidth(context) * 0.8,
              decoration: BoxDecoration(color: Colors.cyanAccent),
              child: Center(
                child: Text(
                  "Update Now",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
