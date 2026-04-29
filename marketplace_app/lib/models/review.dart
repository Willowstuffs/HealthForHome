class Review {
  final String id;
  final String appointmentId;
  final String clientId;
  final String specialistId;
  final int rating;
  final String? comment;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    required this.id,
    required this.appointmentId,
    required this.clientId,
    required this.specialistId,
    required this.rating,
    this.comment,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      appointmentId: json['appointmentId'],
      clientId: json['clientId'],
      specialistId: json['specialistId'],
      rating: json['rating'],
      comment: json['comment'],
      isVerified: json['isVerified'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'clientId': clientId,
      'specialistId': specialistId,
      'rating': rating,
      'comment': comment,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Rating toRating() {
    return Rating(rating: rating, comment: comment ?? '');
  }
}

class Rating {
  final int rating;
  final String? comment;

  Rating({required this.rating, this.comment});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(rating: json['rating'], comment: json['comment']);
  }

  Map<String, dynamic> toJson() => {'rating': rating, 'comment': comment};
}
