import 'package:flutter/material.dart';
import 'package:uscitylink/utils/device/device_utility.dart';

class StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final List<Color> gradientColors; // List of colors for gradient

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Container(
        // Apply the gradient to the container
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          gradient: LinearGradient(
            colors: gradientColors, // Gradient colors passed to the constructor
            begin: Alignment.topLeft, // Direction of the gradient
            end: Alignment.bottomRight, // Direction of the gradient
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Color(0XFFd5d5d5),
                    borderRadius: BorderRadius.circular(5)),
                width: 45,
                height: 45,
                child: Icon(icon),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$value',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
