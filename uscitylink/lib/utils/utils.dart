import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:uscitylink/utils/constant/colors.dart';

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
}
