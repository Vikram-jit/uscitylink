import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommonSearchField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;
  final String hintText;
  final Color textColor;
  final Color fillColor;

  const CommonSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = "Search...",
    this.textColor = Colors.white,
    this.fillColor = const Color.fromRGBO(255, 255, 255, 0.3),
  });

  @override
  State<CommonSearchField> createState() => _CommonSearchFieldState();
}

class _CommonSearchFieldState extends State<CommonSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  void _refresh() {
    setState(() {}); // update suffix icon
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      //  controller: widget.controller,
      onChanged: widget.onChanged,
      style: GoogleFonts.poppins(color: widget.textColor, fontSize: 14),
      cursorColor: widget.textColor,
      decoration: InputDecoration(
        filled: true,
        fillColor: widget.fillColor,
        prefixIcon: Icon(Icons.search, color: widget.textColor, size: 18),

        hintText: widget.hintText,
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: widget.textColor),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
