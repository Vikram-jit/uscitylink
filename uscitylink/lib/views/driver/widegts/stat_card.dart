import 'package:flutter/material.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/constant/image_strings.dart';
import 'package:uscitylink/utils/device/device_utility.dart';

class StatCard extends StatelessWidget {
  final String title;
  final dynamic value;
  final IconData icon;
  final bool isDocumentExpired;
  final List<Color> gradientColors; // List of colors for gradient

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
    this.isDocumentExpired = false,
  });

  List<Color> getGradientColors(String title) {
    if (title == "PAY SUMMARY" || title == "TOTAL DRIVERS") {
      return [
        Color(0xFFeb3349), // Reddish
        Color(0xFFf45c43), // Light Orange
      ];
    } else if (title == "TRUCKS" || title == "TOTAL TEMPLATES") {
      return [
        Color(0xFF56ab2f), // Reddish
        Color(0xFFa8e063), // Light Orange
      ];
    } else if (title == "U S CITYLINK INC") {
      return [
        Color(0xFFECE9E6), // Reddish
        Color(0xFFFFFFFF), // Light Orange
      ];
    } else if (title == "UNREAD MESSAGE" || title == "UNREAD MESSAGES") {
      return [
        Color(0xFF00c6ff), // Reddish
        Color(0xFF0072ff), // Light Orange
      ];
    } else if (title == "MY INFORMATION" || title == "TOTAL TRUCK GROUPS") {
      return [
        Color(0xFF50C9C3), // Reddish
        Color(0xFF96DEDA), // Light Orange
      ];
    }
    return [
      // Reddish
      Color(0xFF000428),
      Color(0xFF004e92),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (title == "U S CITYLINK INC") {
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
              colors: getGradientColors(title),
              begin: Alignment.topLeft,
              end: Alignment.topRight, // Direction of the gradient
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                if (title != "U S CITYLINK INC")
                  Container(
                    decoration: BoxDecoration(
                      // gradient: LinearGradient(
                      //   colors: getGradientColors(title),
                      //   begin: Alignment.centerLeft,
                      //   end: Alignment.centerRight,
                      // ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    width: 45,
                    height: 45,
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          colors: [
                            Colors.white, Colors.white
                            // if (title == "Pay Summary")
                            //   Color(0xFFEB3349), // Hex: #ff7eb3 (Pinkish)
                            // Color(0xFFF45C43),
                            // if (title == "Truck")
                            //   Color(0xFFDD5E89), // Hex: #ff7eb3 (Pinkish)
                            // Color(0xFFF7BB97),
                          ], // Gradient colors
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: Icon(
                        icon,
                        size: 30, // Adjust size if needed
                        color:
                            Colors.white, // Keep it white to apply the gradient
                      ),
                    ),
                  ),
                if (title == "U S CITYLINK INC")
                  Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: getGradientColors(title),
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(5)),
                    width: 100,
                    height: 65,
                    child: Image.asset(
                      TImages.logo,
                      fit: BoxFit.cover,
                    ),
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
                              ? (title == "TRAILERS" ||
                                      title == "MY INFORMATION")
                                  ? 12
                                  : title == "PAY SUMMARY" || title == "TRUCK"
                                      ? 14
                                      : 10
                              : 22,
                          fontWeight: FontWeight.bold,
                          color: title == "U S CITYLINK INC"
                              ? Colors.black
                              : Colors.white),
                    ),
                    if (title == "TRUCK")
                      SizedBox(
                        height: 6,
                      ),
                    if (value != 0)
                      Expanded(
                        child: Text(
                          '${value ?? 0} ',
                          style: TextStyle(
                              fontSize: title == "TRUCK" ? 12 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    if (value == 0 && title == "TOTAL TEMPLATES")
                      Expanded(
                        child: Text(
                          '$value',
                          style: TextStyle(
                              fontSize: title == "TRUCK" ? 12 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    if (value == 0 && title == "TOTAL TRUCK GROUPS")
                      Expanded(
                        child: Text(
                          '$value',
                          style: TextStyle(
                              fontSize: title == "TRUCK" ? 12 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    if (value == 0 && title == "MY INFORMATION")
                      Expanded(
                        child: Text(
                          '$value',
                          style: TextStyle(
                              fontSize: title == "TRUCK" ? 12 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Container(
        width: TDeviceUtils.getScreenWidth(context) * 0.425,
        height: TDeviceUtils.getScreenHeight() * 0.15,
        // Apply the gradient to the container
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.topRight, // Direction of the gradient
          ),
        ),
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: getGradientColors(title),
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  width: 45,
                  height: 45,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        colors: [
                          Colors.white, Colors.white
                          // if (title == "Pay Summary")
                          //   Color(0xFFEB3349), // Hex: #ff7eb3 (Pinkish)
                          // Color(0xFFF45C43),
                          // if (title == "Truck")
                          //   Color(0xFFDD5E89), // Hex: #ff7eb3 (Pinkish)
                          // Color(0xFFF7BB97),
                        ], // Gradient colors
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: Icon(
                      icon,
                      size: 30, // Adjust size if needed
                      color:
                          Colors.white, // Keep it white to apply the gradient
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: title == "U S CITYLINK INC"
                          ? Colors.black
                          : (value is int &&
                                  value > 0 &&
                                  title == "UNREAD MESSAGE")
                              ? Colors.red
                              : Colors.black),
                ),
                if (value != 0 && (title != "UNREAD MESSAGE"))
                  Text(
                    '$value',
                    style: TextStyle(
                        fontSize: title == "TRUCKS"
                            ? 12
                            : value is int &&
                                    value > 0 &&
                                    (title == "UNREAD MESSAGES")
                                ? 28
                                : 18,
                        fontWeight: FontWeight.bold,
                        color: value is int &&
                                value > 0 &&
                                (title == "UNREAD MESSAGES")
                            ? Colors.red
                            : Colors.black),
                  ),
                if (value is int && value > 0 && (title == "UNREAD MESSAGE"))
                  Text(
                    '$value',
                    style: TextStyle(
                        fontSize: title == "TRUCKS" ? 12 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                if (isDocumentExpired)
                  Text(
                    'Document Expired',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
              ],
            )),
      ),
    );
  }
}
