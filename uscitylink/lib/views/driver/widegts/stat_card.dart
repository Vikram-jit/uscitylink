import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final dynamic value;
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
                    color: const Color(0XFFd5d5d5),
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
                    style: TextStyle(
                        fontSize: title != "U S CITYLINK INC"
                            ? title == "TRAILERS" || title == "My Information"
                                ? 12
                                : 10
                            : 22,
                        fontWeight: FontWeight.bold),
                  ),
                  if (title == "TRUCK")
                    SizedBox(
                      height: 6,
                    ),
                  if (value != 0)
                    Expanded(
                      child: Text(
                        '$value',
                        style: TextStyle(
                            fontSize: title == "TRUCK" ? 12 : 18,
                            fontWeight: FontWeight.bold),
                      ),
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
