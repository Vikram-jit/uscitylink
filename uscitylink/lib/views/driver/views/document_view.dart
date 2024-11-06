import 'package:flutter/material.dart';
import 'package:uscitylink/utils/constant/colors.dart';

class DocumentView extends StatelessWidget {
  const DocumentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Column(
          children: [
            AppBar(
              title: Text(
                "Documents",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Container(
              height: 1.0,
              color: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}
