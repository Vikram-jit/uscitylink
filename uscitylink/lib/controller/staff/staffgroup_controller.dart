import 'package:get/get.dart';

class StaffgroupController extends GetxController {
  var innerTabIndex = 0.obs;

  void setInnerTabIndex(int index) {
    innerTabIndex.value = index;
  }
}
