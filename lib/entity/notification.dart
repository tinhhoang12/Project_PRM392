class NotificationEntity {
	final int? id;
	final String title;
	final String body;
	final int? userId;
	final bool isRead;
	final String createdAt;

	NotificationEntity({
		this.id,
		required this.title,
		required this.body,
		this.userId,
		this.isRead = false,
		required this.createdAt,
	});

	factory NotificationEntity.fromMap(Map<String, dynamic> map) {
		return NotificationEntity(
			id: map['id'] as int?,
			title: map['title'] ?? '',
			body: map['body'] ?? '',
			userId: map['user_id'] as int?,
			isRead: (map['is_read'] ?? 0) == 1,
			createdAt: map['created_at'] ?? '',
		);
	}

	Map<String, dynamic> toMap() {
		return {
			'id': id,
			'title': title,
			'body': body,
			'user_id': userId,
			'is_read': isRead ? 1 : 0,
			'created_at': createdAt,
		};
	}
}
