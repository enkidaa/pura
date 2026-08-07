class MixRecipe {
  const MixRecipe({
    required this.name,
    required this.description,
    required this.ingredients,
  });

  final String name;
  final String description;
  final List<String> ingredients;
}

const allMixRecipes = [
  MixRecipe(
    name: 'Golden milk',
    description:
        "Latte caldo + curcuma + pepe nero + miele. Il pepe aumenta l'assorbimento della curcumina ~2000%.",
    ingredients: ['curcuma', 'pepe nero', 'latte', 'miele'],
  ),
  MixRecipe(
    name: 'Acqua mattutina con sale',
    description:
        'Acqua filtrata + un pizzico di sale marino + limone. Al risveglio, a digiuno.',
    ingredients: ['acqua', 'sale marino', 'limone'],
  ),
  MixRecipe(
    name: 'Tonico ACV pre-pasto',
    description:
        '1 cucchiaio di aceto di mele in acqua, 10 min prima dei pasti principali.',
    ingredients: ['aceto di mele', 'acqua'],
  ),
  MixRecipe(
    name: 'Matcha latte lento',
    description: "Matcha cerimoniale sbattuto in acqua a 70°C, poi latte caldo. Senza zucchero.",
    ingredients: ['matcha', 'latte'],
  ),
  MixRecipe(
    name: 'Bowl probiotica',
    description: 'Kefir + mirtilli freschi + lino macinato + miele grezzo + polline d\'api.',
    ingredients: ['kefir', 'mirtilli', 'semi di lino', 'miele grezzo', 'polline d\'api'],
  ),
  MixRecipe(
    name: 'Brodo di collagene',
    description: 'Ossa di manzo + aceto di mele + sale marino, cotti 12h. Bevuto caldo.',
    ingredients: ['ossa di manzo', 'aceto di mele', 'sale marino', 'acqua'],
  ),
  MixRecipe(
    name: 'Calma serale',
    description: 'Acqua tiepida + magnesio glicinato + una goccia di miele grezzo. 60 min prima di dormire.',
    ingredients: ['magnesio glicinato', 'acqua', 'miele grezzo'],
  ),
  MixRecipe(
    name: 'Stack funghi focus',
    description: "Lion's mane + reishi in cacao o matcha caldo. Mattino o primo pomeriggio.",
    ingredients: ["lion's mane", 'reishi', 'matcha'],
  ),
  MixRecipe(
    name: 'Shot verde alla clorofilla',
    description: '1 cucchiaino di spirulina in acqua + limone. Buttato giù, poi acqua.',
    ingredients: ['spirulina', 'acqua', 'limone'],
  ),
  MixRecipe(
    name: 'Complesso delle api',
    description: "1 cucchiaino di miele grezzo + ½ di polline + un velo di pappa reale. Sotto la lingua.",
    ingredients: ['miele grezzo', "polline d'api", 'pappa reale'],
  ),
];
