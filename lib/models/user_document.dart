class UserDocument {
  const UserDocument({
    required this.id,
    required this.label,
    required this.storagePath,
    required this.uploadedAt,
  });

  final String id;
  final String label;
  final String storagePath;
  final DateTime uploadedAt;
}
