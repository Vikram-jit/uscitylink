import 'package:flutter/widgets.dart';
import 'package:uscitylink/utils/constant/image_strings.dart';
import 'package:uscitylink/utils/device/device_utility.dart';

class LogoWidgets extends StatelessWidget {
  final double? height;
  const LogoWidgets({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      TImages.logo,
      fit: BoxFit.cover,
      height: height ?? TDeviceUtils.getScreenHeight() * 0.3,
    );
  }
}
