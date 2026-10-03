class Equipment {
  final String name;
  final String category;
  final String imagePath;
  final List<String> features;
  final String priceLabel;
  final int priceKsh;

  const Equipment({
    required this.name,
    required this.category,
    required this.imagePath,
    required this.features,
    required this.priceLabel,
    required this.priceKsh,
  });
}