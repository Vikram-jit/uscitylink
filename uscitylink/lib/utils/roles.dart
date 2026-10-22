/// Admins are staff with extra rights (the server treats them the same way), so everywhere the app
/// asks "is this a staff member?" an admin counts too and gets the staff screens.
bool isStaffRole(String? role) {
  final r = role?.trim().toLowerCase();
  return r == 'staff' || r == 'admin';
}
