import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class TStyle {
  static final heading = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
  static final sidebarItem = GoogleFonts.poppins(
    fontSize: 14,
    color: AppColors.white70,
    fontWeight: FontWeight.w500,
  );
  static final channelTitle = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
  static final chatHeader = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static final message = GoogleFonts.poppins(
    fontSize: 15,
    height: 1.4,
    color: AppColors.textPrimary,
  );
}
