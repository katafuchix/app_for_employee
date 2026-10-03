class AppVersionModel {
  final String ownerVersion2;

  AppVersionModel({required this.ownerVersion2});

  factory AppVersionModel.fromMap(Map<String, dynamic> map) {
    return AppVersionModel(
      ownerVersion2: map['version2'] as String? ?? '',
    );
  }
}