import 'package:flutter/material.dart';

class PdfPreviewWidget extends StatelessWidget {
  final String url;

  const PdfPreviewWidget({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.open_in_new),
          label: const Text("Open PDF"),
        ),
      ],
    );
  }
}
