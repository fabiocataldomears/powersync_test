class UserModel {
  final String id;
  final String firstName;
  final String createdAt;
  final String userId;
  final String? favoriteColor;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.createdAt,
    required this.userId,
    this.favoriteColor,
  });

  /// Convenience getter used by the UI.
  String get name => firstName;

  factory UserModel.fromRow(Map<String, dynamic> row) {
    return UserModel(
      id: row['id'] as String,
      firstName: row['first_name'] as String? ?? '',
      createdAt: row['created_at'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      favoriteColor: row['favorite_color'] as String?,
    );
  }

  @override
  String toString() =>
      'User(id: $id, firstName: $firstName, userId: $userId, favoriteColor: $favoriteColor)';
}
