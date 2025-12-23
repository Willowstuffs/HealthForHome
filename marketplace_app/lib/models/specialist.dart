class Specialist {
  final String id;
  final String name;
  final String profession;
  final double rating;
  final int reviews;
  final double distance;
  final String imageUrl;
  final List<String> certificates;
  final List<String> specialties;
  final bool isAvailable;

  Specialist({
    required this.id,
    required this.name,
    required this.profession,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.imageUrl,
    required this.certificates,
    required this.specialties,
    required this.isAvailable,
  });
}
