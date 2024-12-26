import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uscitylink/model/login_model.dart';

class UserPreferenceController extends GetxController {
  Future<bool> storeToken(LoginWithPasswordModel loginModel) async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    sp.setString('token', loginModel.access_token!);

    return true;
  }

  Future<bool> storeRole(LoginWithPasswordModel loginModel) async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    sp.setString('role', loginModel.profiles!.role!.name!);

    return true;
  }

  Future<dynamic> getToken() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    String? token = sp.getString('token');

    return token;
  }

  Future<dynamic> getRole() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    String? role = sp.getString('role');

    return role;
  }

  Future<dynamic> removeStore() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    sp.remove('token');

    return true;
  }
}
