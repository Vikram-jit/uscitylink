import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomDrawerController extends GetxController {
  // Create a GlobalKey to control the scaffold state
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // Method to open the drawer
  void openDrawer() {
    if (scaffoldKey.currentState != null) {
      scaffoldKey.currentState?.openDrawer();
    }
  }

  // Method to close the drawer
  void closeDrawer() {
    if (scaffoldKey.currentState != null) {
      scaffoldKey.currentState?.closeDrawer();
    }
  }
}
