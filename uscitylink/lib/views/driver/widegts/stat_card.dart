import 'package:flutter/material.dart';
import 'package:uscitylink/utils/device/device_utility.dart';

class StatCard extends StatelessWidget {
  final String title;
  final int value;
  final List<Color> gradientColors; // List of colors for gradient

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        // Apply the gradient to the container
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          gradient: LinearGradient(
            colors: gradientColors, // Gradient colors passed to the constructor
            begin: Alignment.topLeft, // Direction of the gradient
            end: Alignment.bottomRight, // Direction of the gradient
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.white),
              ),
              SizedBox(height: TDeviceUtils.getAppBarHeight() * 0.30),
              Text(
                '$value',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
