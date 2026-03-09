class RepairRequestModel {
  final String id;
  final String userId;
  final String description;
  final String status;
  final String createdAt;

  const RepairRequestModel({
    required this.id,
    required this.userId,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory RepairRequestModel.fromRow(Map<String, dynamic> row) {
    return RepairRequestModel(
      id: row['id'] as String,
      userId: row['user_id'] as String? ?? '',
      description: row['description'] as String? ?? '',
      status: row['status'] as String? ?? 'pending',
      createdAt: row['created_at'] as String? ?? '',
    );
  }

  @override
  String toString() =>
      'RepairRequest(id: $id, userId: $userId, description: $description, status: $status)';
}
