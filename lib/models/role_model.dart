class RoleModel {
  final bool canRead;
  final bool canWrite;
  final bool isSuperAdmin; // full access
  final String roleType; // e.g., "admin", "user", "maid" etc.

  RoleModel({
    required this.canRead,
    required this.canWrite,
    required this.isSuperAdmin,
    required this.roleType,
  });

  factory RoleModel.fromMap(Map<String, dynamic> map) {
    return RoleModel(
      canRead: map['canRead'] ?? false,
      canWrite: map['canWrite'] ?? false,
      isSuperAdmin: map['isSuperAdmin'] ?? false,
      roleType: map['roleType'] ?? 'admin', // Default to 'user' if not provided
    );
  }

  Map<String, dynamic> toMap() => {
        'canRead': canRead,
        'canWrite': canWrite,
        'isSuperAdmin': isSuperAdmin,
        'roleType': roleType,
      };
}
