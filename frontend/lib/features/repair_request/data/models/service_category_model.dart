class ServiceCategoryModel {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String icon;
  final String color;
  final double basePrice;
  final List<String> commonIssues;
  final bool isActive;
  final int sortOrder;

  const ServiceCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.icon = 'home_repair_service',
    this.color = '#2563EB',
    this.basePrice = 150000,
    this.commonIssues = const [],
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'home_repair_service',
      color: json['color'] ?? '#2563EB',
      basePrice: (json['basePrice'] is num)
          ? (json['basePrice'] as num).toDouble()
          : 150000.0,
      commonIssues: json['commonIssues'] != null
          ? List<String>.from(json['commonIssues'])
          : const [],
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'color': color,
      'basePrice': basePrice,
      'commonIssues': commonIssues,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  String get basePriceFormatted {
    final str = basePrice.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$formatted đ';
  }
}
