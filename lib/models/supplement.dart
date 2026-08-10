enum SupplementCategory { natural, scientific }

class Supplement {
  const Supplement({required this.id, required this.name, required this.category});

  final String id;
  final String name;
  final SupplementCategory category;
}
