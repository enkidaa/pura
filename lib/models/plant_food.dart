import '../l10n/app_strings.dart';

enum PlantCategory {
  frutta,
  verdura,
  legumi,
  cerealiIntegrali,
  fruttaSecca,
  semi,
  erbe,
  spezie,
  bevandeVegetali,
}

String plantCategoryLabel(PlantCategory category, AppStrings strings) {
  switch (category) {
    case PlantCategory.frutta:
      return strings.plantFrutta;
    case PlantCategory.verdura:
      return strings.plantVerdura;
    case PlantCategory.legumi:
      return strings.plantLegumi;
    case PlantCategory.cerealiIntegrali:
      return strings.plantCerealiIntegrali;
    case PlantCategory.fruttaSecca:
      return strings.plantFruttaSecca;
    case PlantCategory.semi:
      return strings.plantSemi;
    case PlantCategory.erbe:
      return strings.plantErbe;
    case PlantCategory.spezie:
      return strings.plantSpezie;
    case PlantCategory.bevandeVegetali:
      return strings.plantBevandeVegetali;
  }
}

class PlantFood {
  const PlantFood(this.name, this.category);
  final String name;
  final PlantCategory category;
}

/// Curated vocabulary of plants that actually count toward microbiome
/// diversity — free-typed entries get matched against this list (case
/// insensitive) and rejected otherwise (see plant_diversity_screen.dart).
const plantVocabulary = <PlantFood>[
  // Frutta
  PlantFood('Mela', PlantCategory.frutta),
  PlantFood('Pera', PlantCategory.frutta),
  PlantFood('Banana', PlantCategory.frutta),
  PlantFood('Arancia', PlantCategory.frutta),
  PlantFood('Mandarino', PlantCategory.frutta),
  PlantFood('Pompelmo', PlantCategory.frutta),
  PlantFood('Limone', PlantCategory.frutta),
  PlantFood('Lime', PlantCategory.frutta),
  PlantFood('Uva', PlantCategory.frutta),
  PlantFood('Kiwi', PlantCategory.frutta),
  PlantFood('Ananas', PlantCategory.frutta),
  PlantFood('Mango', PlantCategory.frutta),
  PlantFood('Papaya', PlantCategory.frutta),
  PlantFood('Fragole', PlantCategory.frutta),
  PlantFood('Mirtilli', PlantCategory.frutta),
  PlantFood('Lamponi', PlantCategory.frutta),
  PlantFood('More', PlantCategory.frutta),
  PlantFood('Ribes', PlantCategory.frutta),
  PlantFood('Uva spina', PlantCategory.frutta),
  PlantFood('Ciliegie', PlantCategory.frutta),
  PlantFood('Pesche', PlantCategory.frutta),
  PlantFood('Nettarine', PlantCategory.frutta),
  PlantFood('Albicocche', PlantCategory.frutta),
  PlantFood('Prugne', PlantCategory.frutta),
  PlantFood('Melograno', PlantCategory.frutta),
  PlantFood('Fichi', PlantCategory.frutta),
  PlantFood('Cachi', PlantCategory.frutta),
  PlantFood('Melone', PlantCategory.frutta),
  PlantFood('Anguria', PlantCategory.frutta),
  PlantFood('Avocado', PlantCategory.frutta),
  PlantFood('Datteri', PlantCategory.frutta),
  PlantFood('Fichi d\'India', PlantCategory.frutta),
  PlantFood('Nespole', PlantCategory.frutta),
  PlantFood('Litchi', PlantCategory.frutta),
  PlantFood('Cocco', PlantCategory.frutta),
  // Verdura
  PlantFood('Spinaci', PlantCategory.verdura),
  PlantFood('Cavolo riccio', PlantCategory.verdura),
  PlantFood('Bietola', PlantCategory.verdura),
  PlantFood('Lattuga', PlantCategory.verdura),
  PlantFood('Rucola', PlantCategory.verdura),
  PlantFood('Radicchio', PlantCategory.verdura),
  PlantFood('Indivia', PlantCategory.verdura),
  PlantFood('Broccoli', PlantCategory.verdura),
  PlantFood('Cavolfiore', PlantCategory.verdura),
  PlantFood('Cavolo cappuccio', PlantCategory.verdura),
  PlantFood('Cavolini di Bruxelles', PlantCategory.verdura),
  PlantFood('Carota', PlantCategory.verdura),
  PlantFood('Barbabietola', PlantCategory.verdura),
  PlantFood('Rapa', PlantCategory.verdura),
  PlantFood('Ravanello', PlantCategory.verdura),
  PlantFood('Sedano', PlantCategory.verdura),
  PlantFood('Finocchio', PlantCategory.verdura),
  PlantFood('Zucchine', PlantCategory.verdura),
  PlantFood('Zucca', PlantCategory.verdura),
  PlantFood('Melanzana', PlantCategory.verdura),
  PlantFood('Peperone', PlantCategory.verdura),
  PlantFood('Pomodoro', PlantCategory.verdura),
  PlantFood('Cetriolo', PlantCategory.verdura),
  PlantFood('Cipolla', PlantCategory.verdura),
  PlantFood('Porro', PlantCategory.verdura),
  PlantFood('Aglio', PlantCategory.verdura),
  PlantFood('Scalogno', PlantCategory.verdura),
  PlantFood('Asparagi', PlantCategory.verdura),
  PlantFood('Carciofo', PlantCategory.verdura),
  PlantFood('Funghi', PlantCategory.verdura),
  PlantFood('Patata dolce', PlantCategory.verdura),
  PlantFood('Patata', PlantCategory.verdura),
  PlantFood('Mais', PlantCategory.verdura),
  PlantFood('Piselli', PlantCategory.verdura),
  PlantFood('Fagiolini', PlantCategory.verdura),
  // Legumi
  PlantFood('Lenticchie', PlantCategory.legumi),
  PlantFood('Lenticchie rosse', PlantCategory.legumi),
  PlantFood('Ceci', PlantCategory.legumi),
  PlantFood('Fagioli neri', PlantCategory.legumi),
  PlantFood('Fagioli borlotti', PlantCategory.legumi),
  PlantFood('Fagioli cannellini', PlantCategory.legumi),
  PlantFood('Fagioli rossi', PlantCategory.legumi),
  PlantFood('Fave', PlantCategory.legumi),
  PlantFood('Edamame', PlantCategory.legumi),
  PlantFood('Soia', PlantCategory.legumi),
  PlantFood('Arachidi', PlantCategory.legumi),
  PlantFood('Piselli secchi', PlantCategory.legumi),
  // Cereali integrali
  PlantFood('Avena', PlantCategory.cerealiIntegrali),
  PlantFood('Quinoa', PlantCategory.cerealiIntegrali),
  PlantFood('Grano saraceno', PlantCategory.cerealiIntegrali),
  PlantFood('Riso integrale', PlantCategory.cerealiIntegrali),
  PlantFood('Riso nero', PlantCategory.cerealiIntegrali),
  PlantFood('Riso rosso', PlantCategory.cerealiIntegrali),
  PlantFood('Segale', PlantCategory.cerealiIntegrali),
  PlantFood('Orzo', PlantCategory.cerealiIntegrali),
  PlantFood('Farro', PlantCategory.cerealiIntegrali),
  PlantFood('Miglio', PlantCategory.cerealiIntegrali),
  PlantFood('Bulgur', PlantCategory.cerealiIntegrali),
  PlantFood('Polenta integrale', PlantCategory.cerealiIntegrali),
  // Frutta secca
  PlantFood('Mandorle', PlantCategory.fruttaSecca),
  PlantFood('Noci', PlantCategory.fruttaSecca),
  PlantFood('Pistacchi', PlantCategory.fruttaSecca),
  PlantFood('Nocciole', PlantCategory.fruttaSecca),
  PlantFood('Anacardi', PlantCategory.fruttaSecca),
  PlantFood('Noci pecan', PlantCategory.fruttaSecca),
  PlantFood('Noci del Brasile', PlantCategory.fruttaSecca),
  PlantFood('Noci macadamia', PlantCategory.fruttaSecca),
  PlantFood('Pinoli', PlantCategory.fruttaSecca),
  PlantFood('Castagne', PlantCategory.fruttaSecca),
  // Semi
  PlantFood('Semi di lino', PlantCategory.semi),
  PlantFood('Semi di chia', PlantCategory.semi),
  PlantFood('Semi di zucca', PlantCategory.semi),
  PlantFood('Semi di girasole', PlantCategory.semi),
  PlantFood('Sesamo', PlantCategory.semi),
  PlantFood('Semi di canapa', PlantCategory.semi),
  PlantFood('Semi di papavero', PlantCategory.semi),
  PlantFood('Semi di psillio', PlantCategory.semi),
  // Erbe
  PlantFood('Basilico', PlantCategory.erbe),
  PlantFood('Prezzemolo', PlantCategory.erbe),
  PlantFood('Rosmarino', PlantCategory.erbe),
  PlantFood('Menta', PlantCategory.erbe),
  PlantFood('Timo', PlantCategory.erbe),
  PlantFood('Origano', PlantCategory.erbe),
  PlantFood('Salvia', PlantCategory.erbe),
  PlantFood('Coriandolo', PlantCategory.erbe),
  PlantFood('Erba cipollina', PlantCategory.erbe),
  PlantFood('Dragoncello', PlantCategory.erbe),
  PlantFood('Alloro', PlantCategory.erbe),
  PlantFood('Maggiorana', PlantCategory.erbe),
  // Spezie
  PlantFood('Curcuma', PlantCategory.spezie),
  PlantFood('Zenzero', PlantCategory.spezie),
  PlantFood('Cannella', PlantCategory.spezie),
  PlantFood('Pepe nero', PlantCategory.spezie),
  PlantFood('Cumino', PlantCategory.spezie),
  PlantFood('Paprika', PlantCategory.spezie),
  PlantFood('Noce moscata', PlantCategory.spezie),
  PlantFood('Chiodi di garofano', PlantCategory.spezie),
  PlantFood('Cardamomo', PlantCategory.spezie),
  PlantFood('Anice stellato', PlantCategory.spezie),
  PlantFood('Peperoncino', PlantCategory.spezie),
  PlantFood('Zafferano', PlantCategory.spezie),
  // Bevande vegetali
  PlantFood('Tè verde', PlantCategory.bevandeVegetali),
  PlantFood('Tè nero', PlantCategory.bevandeVegetali),
  PlantFood('Tè bianco', PlantCategory.bevandeVegetali),
  PlantFood('Matcha', PlantCategory.bevandeVegetali),
  PlantFood('Caffè', PlantCategory.bevandeVegetali),
  PlantFood('Cacao', PlantCategory.bevandeVegetali),
  PlantFood('Tisana', PlantCategory.bevandeVegetali),
  PlantFood('Rooibos', PlantCategory.bevandeVegetali),
];

PlantCategory? categoryForPlant(String name) {
  final normalized = name.trim().toLowerCase();
  for (final food in plantVocabulary) {
    if (food.name.toLowerCase() == normalized) return food.category;
  }
  return null;
}
