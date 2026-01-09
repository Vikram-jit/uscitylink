import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfPreviewWidget extends StatelessWidget {
  final String url;
  const PdfPreviewWidget({super.key, required this.url});

  @override
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(children: [PdfViewer.uri(Uri.parse(url))]),
    );
  }
}
