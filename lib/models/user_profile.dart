class UserProfile {
  final int id;
  final String name;
  final String username;
  final String biography;
  final bool isPublic;
  final int publicationCount;
  final int photoCount;
  final int videoCount;

  const UserProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.biography,
    required this.isPublic,
    required this.publicationCount,
    required this.photoCount,
    required this.videoCount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    if (json['Id'] is! int ||
        (json['Id'] as int) <= 0 ||
        json['Name'] is! String ||
        (json['Name'] as String).trim().isEmpty ||
        json['Username'] is! String ||
        (json['Username'] as String).trim().isEmpty ||
        (json['Biography'] != null && json['Biography'] is! String) ||
        (json['IsPublic'] != null && json['IsPublic'] is! bool) ||
        !_isCount(json['PublicationCount']) ||
        !_isCount(json['PhotoCount']) ||
        !_isCount(json['VideoCount'])) {
      throw const FormatException('Dados do perfil inválidos.');
    }
    return UserProfile(
      id: json['Id'] as int,
      name: json['Name'] as String,
      username: json['Username'] as String,
      // O OutSystems pode omitir atributos com valores vazios ou por defeito.
      biography: json['Biography'] as String? ?? '',
      isPublic: json['IsPublic'] as bool? ?? false,
      publicationCount: json['PublicationCount'] as int? ?? 0,
      photoCount: json['PhotoCount'] as int? ?? 0,
      videoCount: json['VideoCount'] as int? ?? 0,
    );
  }

  static bool _isCount(dynamic value) =>
      value == null || (value is int && value >= 0);
}
