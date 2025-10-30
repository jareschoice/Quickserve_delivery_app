enum UserRole { consumer, vendor, rider, admin }

UserRole? roleFromString(String? value) {
  switch (value) {
    case 'consumer': return UserRole.consumer;
    case 'vendor': return UserRole.vendor;
    case 'rider': return UserRole.rider;
    case 'admin': return UserRole.admin;
    default: return null;
  }
}

String roleToString(UserRole role) {
  switch (role) {
    case UserRole.consumer: return 'consumer';
    case UserRole.vendor: return 'vendor';
    case UserRole.rider: return 'rider';
    case UserRole.admin: return 'admin';
  }
}
