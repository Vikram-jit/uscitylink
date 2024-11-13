import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:intl/intl.dart';

class Utils {
  static void fieldFocusChange(
      BuildContext context, FocusNode current, FocusNode nextFocus) {
    current.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  static toastMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        backgroundColor: TColors.black,
        gravity: ToastGravity.BOTTOM);
  }

  static snackBar(String title, String message) {
    Get.snackbar(title, message);
  }

  static showLoader() {
    Get.dialog(
      FractionallySizedBox(
        alignment: Alignment.center,
        widthFactor: 0.35,
        heightFactor: 0.15,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black.withOpacity(0.5),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static hideLoader() {
    if (Get.isDialogOpen == true) Get.back();
  }

  static String formatUtcTime(String? utcTimeString) {
    // Step 1: Check if the string is null or empty
    if (utcTimeString != null && utcTimeString.isNotEmpty) {
      try {
        // Step 2: Parse the input string into a DateTime object
        DateTime utcTime = DateTime.parse(
            utcTimeString); // "2024-11-13 07:17:49" in ISO format

        // Step 3: Convert it to local time (if necessary)
        DateTime localTime = utcTime.toLocal(); // Convert UTC to local time

        // Step 4: Format the DateTime object to a human-readable 12-hour format with AM/PM
        String formattedTime = DateFormat('hh:mm a')
            .format(localTime); // 'hh:mm a' means 12-hour format with AM/PM

        return formattedTime; // Returns time in format like '07:17 AM'
      } catch (e) {
        // Handle error if the date format is invalid or any other exception occurs
        return 'Invalid date format';
      }
    }
    return ''; // Return empty string if input is null or empty
  }

  static String formatUtcDateTime(String? utcDateTimeString) {
    // Step 1: Check if the string is null or empty
    if (utcDateTimeString != null && utcDateTimeString.isNotEmpty) {
      try {
        // Step 2: Parse the input string into a DateTime object
        DateTime utcDateTime = DateTime.parse(utcDateTimeString); // ISO format

        // Step 3: Convert it to local time (if necessary)
        DateTime localDateTime =
            utcDateTime.toLocal(); // Convert UTC to local time

        // Step 4: Format the DateTime object to a human-readable date and time
        String formattedDateTime =
            DateFormat('MMM dd, yyyy hh:mm a').format(localDateTime);

        return formattedDateTime; // Returns date and time in format like 'Nov 13, 2024 07:17 AM'
      } catch (e) {
        // Handle error if the date format is invalid or any other exception occurs
        return 'Invalid date format';
      }
    }
    return ''; // Return empty string if input is null or empty
  }
}
