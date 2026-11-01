import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppText {
  static TextStyle title = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle heading = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle body = GoogleFonts.poppins(
    fontSize: 16,
    color: Colors.white70,
  );

  static TextStyle button = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Colors.white,
  );
}