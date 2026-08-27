import 'package:flutter/widgets.dart';

import 'app_locale.dart';

/// Installed once around the routed content (see main.dart) so any widget
/// below rebuilds when the language changes, without each screen wiring
/// its own listener.
class LocaleScope extends InheritedNotifier<ValueNotifier<AppLocale>> {
  const LocaleScope({super.key, required super.notifier, required super.child});
}

/// Covers Oggi + the Ritual orbit end to end. Other screens (Lab, Scopri,
/// Pratiche, Profilo) are still Italian-only — next content pass.
class AppStrings {
  const AppStrings(this.locale);

  final AppLocale locale;

  static AppStrings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    final locale = scope?.notifier?.value ?? appLocaleNotifier.value;
    return AppStrings(locale);
  }

  String t(String it, String en, String fr) {
    switch (locale) {
      case AppLocale.en:
        return en;
      case AppLocale.fr:
        return fr;
      case AppLocale.it:
        return it;
    }
  }

  // Errors
  String get impossibileSalvareRiprova =>
      t('Impossibile salvare, riprova', 'Could not save, try again', 'Impossible d’enregistrer, réessayez');
  String get impossibileSalvareFotoRiprova => t('Impossibile salvare la foto, riprova',
      'Could not save the photo, try again', 'Impossible d’enregistrer la photo, réessayez');
  String get impossibileGenerareConsiglio => t('Impossibile generare il consiglio, riprova',
      'Could not generate the suggestion, try again', 'Impossible de générer le conseil, réessayez');
  String get permessoSaluteNegato =>
      t('Permesso Salute negato', 'Health permission denied', 'Autorisation Santé refusée');
  String get nessunDatoSonnoInSalute => t('Nessun dato sonno trovato in Salute',
      'No sleep data found in Health', 'Aucune donnée de sommeil trouvée dans Santé');
  String get impossibileAprireLink =>
      t('Impossibile aprire il link', 'Could not open the link', 'Impossible d’ouvrir le lien');

  // Common actions
  String get annulla => t('Annulla', 'Cancel', 'Annuler');
  String get aggiungi => t('Aggiungi', 'Add', 'Ajouter');
  String get salva => t('Salva', 'Save', 'Enregistrer');
  String get chiudi => t('Chiudi', 'Close', 'Fermer');

  // Dialogs
  String get aggiungiUnaPianta => t('Aggiungi una pianta', 'Add a plant', 'Ajouter une plante');
  String get esBroccoli => t('Es. broccoli', 'E.g. broccoli', 'Ex. brocoli');
  String get aCheOraSeiAndatoALetto =>
      t('A che ora sei andato a letto?', 'What time did you go to bed?', 'A quelle heure êtes-vous allé vous coucher ?');
  String get aCheOraTiSeiSvegliato =>
      t('A che ora ti sei svegliato?', 'What time did you wake up?', 'A quelle heure vous êtes-vous réveillé ?');
  String get linkPerOggi => t('Link per oggi', 'Link for today', 'Lien du jour');
  String get linkSpotifyEcc => t('Link Spotify, Apple Music o podcast', 'Spotify, Apple Music, or podcast link',
      'Lien Spotify, Apple Music ou podcast');
  String get finestraDiDigiuno => t('Finestra di digiuno', 'Fasting window', 'Fenêtre de jeûne');
  String get segnaUltimoPasto => t('Segna ultimo pasto', 'Mark last meal', 'Marquer le dernier repas');
  String get segnaPrimoPasto => t('Segna primo pasto', 'Mark first meal', 'Marquer le premier repas');

  // Oggi
  String get todayEyebrow => t('Pura · Oggi', 'Pura · Today', 'Pura · Aujourd’hui');
  String greeting(int hour) {
    if (hour < 6) return t('Buonanotte', 'Good night', 'Bonne nuit');
    if (hour < 12) return t('Buongiorno', 'Good morning', 'Bonjour');
    if (hour < 18) return t('Buon pomeriggio', 'Good afternoon', 'Bon après-midi');
    return t('Buonasera', 'Good evening', 'Bonsoir');
  }

  String get focusDelGiorno => t('Focus del giorno', 'Focus of the day', 'Focus du jour');
  String get ritual => t('Ritual', 'Ritual', 'Rituel');
  String get cicloMestruale => t('Ciclo mestruale', 'Menstrual cycle', 'Cycle menstruel');
  String get prodottiSkincare => t('Prodotti skincare', 'Skincare products', 'Produits skincare');

  String get ancoraNessunConsiglio =>
      t('Ancora nessun consiglio per oggi.', 'No suggestion yet today.', 'Encore aucun conseil aujourd’hui.');
  String get generaConsiglio => t('Genera consiglio', 'Generate suggestion', 'Générer un conseil');
  String get affidabilita => t('affidabilità', 'confidence', 'fiabilité');
  String get evidenza => t('evidenza', 'evidence', 'preuve');
  String get fonti => t('fonti', 'sources', 'sources');

  String get sonno => t('Sonno', 'Sleep', 'Sommeil');
  String get obiettivo9h => t('obiettivo 9h', 'goal 9h', 'objectif 9h');
  String svegliaVariabileDi(String duration, int days) => t(
        'obiettivo 9h · sveglia variabile di $duration negli ultimi $days giorni tracciati',
        'goal 9h · wake time varies by $duration over the last $days tracked days',
        'objectif 9h · réveil variable de $duration sur les $days derniers jours suivis',
      );
  String get importaDaSalute => t('Importa da Salute', 'Import from Health', 'Importer depuis Santé');

  String get diversitaVegetale => t('Diversità vegetale', 'Plant diversity', 'Diversité végétale');
  String get daLunedi => t('da lunedì', 'since Monday', 'depuis lundi');

  String get suonoDiOggi => t('Suono di oggi', 'Today’s sound', 'Son du jour');
  String get nessunLink => t('Nessun link', 'No link', 'Aucun lien');
  String get linkSalvato => t('Link salvato', 'Link saved', 'Lien enregistré');
  String get aggiungiUnLinkPerOggi =>
      t('aggiungi un link per oggi', 'add a link for today', 'ajoutez un lien pour aujourd’hui');
  String get riproduci => t('Riproduci', 'Play', 'Lire');

  String get digiuno => t('Digiuno', 'Fasting', 'Jeûne');
  String get obiettivo16h => t('obiettivo 16h', 'goal 16h', 'objectif 16h');

  String get cicloNonTracciato =>
      t('Ciclo — non ancora tracciato', 'Cycle — not tracked yet', 'Cycle — pas encore suivi');
  String giornoFase(int day, String phase) =>
      t('Giorno $day · fase $phase', 'Day $day · phase $phase', 'Jour $day · phase $phase');
  String prossimoCiclo(String date, int avgDays) => t(
        'Prossimo ciclo stimato: $date (ciclo medio ${avgDays}gg)',
        'Next cycle estimated: $date (average cycle ${avgDays}d)',
        'Prochain cycle estimé : $date (cycle moyen ${avgDays}j)',
      );
  String get segnaInizioCicloOggi =>
      t('Segna inizio ciclo oggi', 'Log period start today', 'Marquer le début des règles');
  String get faseMestruale => t('mestruale', 'menstrual', 'menstruelle');
  String get faseFollicolare => t('follicolare', 'follicular', 'folliculaire');
  String get faseOvulazione => t('ovulazione', 'ovulation', 'ovulation');
  String get faseLuteale => t('luteale', 'luteal', 'lutéale');

  String get mattino => t('Mattino', 'Morning', 'Matin');
  String get sera => t('Sera', 'Evening', 'Soir');

  // Ritual orbit
  String get completi => t('COMPLETI', 'DONE', 'TERMINÉS');
  String get doppioTapSegna =>
      t('Doppio tap sul cerchio per segnare come fatto', 'Double-tap the circle to mark it done', 'Double-tapez le cercle pour le marquer comme fait');
  String get fattoDoppioTapAnnulla => t(
        'Fatto — doppio tap per annullare',
        'Done — double-tap to undo',
        'Fait — double-tapez pour annuler',
      );

  // Auth
  String get email => t('Email', 'Email', 'E-mail');
  String get password => t('Password', 'Password', 'Mot de passe');
  String get nicknameOpzionale => t('Nickname (opzionale)', 'Nickname (optional)', 'Surnom (facultatif)');
  String get passwordAlmeno8Caratteri =>
      t('Almeno 8 caratteri.', 'At least 8 characters.', 'Au moins 8 caractères.');
  String get passwordRequisiti => t(
        'Almeno una lettera e un numero o carattere speciale.',
        'At least one letter and a number or special character.',
        'Au moins une lettre et un chiffre ou caractère spécial.',
      );
  String get passwordValida => t('Password valida.', 'Valid password.', 'Mot de passe valide.');
  String get registrati => t('Registrati', 'Sign up', 'S’inscrire');
  String get accedi => t('Accedi', 'Log in', 'Se connecter');
  String get haiGiaUnAccountAccedi => t(
        'Hai già un account? Accedi',
        'Already have an account? Log in',
        'Vous avez déjà un compte ? Connectez-vous',
      );
  String get nonHaiUnAccountRegistrati => t(
        'Non hai un account? Registrati',
        'Don’t have an account? Sign up',
        'Vous n’avez pas de compte ? Inscrivez-vous',
      );

  // Lab (Integratori)
  String get spazioDiLavoro => t('Spazio di lavoro', 'Workspace', 'Espace de travail');
  String get integratori => t('Integratori', 'Supplements', 'Compléments');
  String get integratoriSottotitolo => t(
        'Naturali e mirati/da ricerca, monitorati nel tempo — non un consiglio medico.',
        'Natural and targeted/research-backed, tracked over time — not medical advice.',
        'Naturels et ciblés/issus de la recherche, suivis dans le temps — pas un avis médical.',
      );
  String get iTuoiIntegratori => t('I tuoi integratori', 'Your supplements', 'Vos compléments');
  String get nessunIntegratoreInRoutine => t(
        'Non hai ancora aggiunto integratori alla tua routine. Esplorali qui sotto.',
        'You haven’t added any supplements to your routine yet. Explore them below.',
        'Vous n’avez pas encore ajouté de compléments à votre routine. Explorez-les ci-dessous.',
      );
  String get consigliatiPerTe => t('Consigliati per te', 'Recommended for you', 'Recommandés pour vous');
  String perche(String reason) => t('Perché: $reason', 'Why: $reason', 'Pourquoi : $reason');
  String get siAllineaAlTuoApproccio =>
      t('si allinea al tuo approccio', 'it matches your approach', 'cela correspond à votre approche');
  String get esploraTutti => t('Esplora tutti', 'Explore all', 'Explorer tout');
  String get cercaUnIntegratore =>
      t('Cerca un integratore...', 'Search a supplement...', 'Rechercher un complément...');
  String get oggi => t('Oggi', 'Today', 'Aujourd’hui');
  String get approccioNaturale => t('naturale', 'natural', 'naturel');
  String get approccioBilanciato => t('bilanciato', 'balanced', 'équilibré');
  String get approccioScientifico => t('scientifico', 'scientific', 'scientifique');

  // Nav bar
  String get navOggi => t('Oggi', 'Today', 'Aujourd’hui');
  String get navLab => t('Lab', 'Lab', 'Labo');
  String get navPratiche => t('Pratiche', 'Practices', 'Pratiques');
  String get navScopri => t('Scopri', 'Discover', 'Découvrir');
  String get navProfilo => t('Profilo', 'Profile', 'Profil');

  // Practice categories
  String get catSonnoRecupero => t('Sonno e recupero', 'Sleep and recovery', 'Sommeil et récupération');
  String get catRespirazione => t('Respirazione', 'Breathing', 'Respiration');
  String get catMeditazioneStress =>
      t('Meditazione e stress', 'Meditation and stress', 'Méditation et stress');
  String get catMovimento => t('Movimento', 'Movement', 'Mouvement');
  String get catEsposizioneLuce =>
      t('Esposizione alla luce', 'Light exposure', 'Exposition à la lumière');
  String get catAlimentazione => t('Alimentazione', 'Nutrition', 'Alimentation');
  String get catDigiuno => t('Digiuno', 'Fasting', 'Jeûne');
  String get catRecupero => t('Recupero', 'Recovery', 'Récupération');
  String get catIgieneOrale => t('Igiene orale', 'Oral hygiene', 'Hygiène bucco-dentaire');
  String get catPelleCapelli => t('Pelle e capelli', 'Skin and hair', 'Peau et cheveux');
  String get catMonitoraggioBiomarcatori => t(
        'Monitoraggio e biomarcatori',
        'Monitoring and biomarkers',
        'Suivi et biomarqueurs',
      );
  String get catAltro => t('Altre pratiche', 'Other practices', 'Autres pratiques');

  // Evidence levels
  String get evidenzaAlta => t('Alta', 'High', 'Élevée');
  String get evidenzaModerata => t('Moderata', 'Moderate', 'Modérée');
  String get evidenzaLimitata => t('Limitata', 'Limited', 'Limitée');
  String get evidenzaPreliminare => t('Preliminare', 'Preliminary', 'Préliminaire');
  String get evidenzaDaVerificare => t('Da verificare', 'To verify', 'À vérifier');
  String evidenzaLabel(String level) => t('Evidenza: $level', 'Evidence: $level', 'Preuve : $level');

  // Practices screen
  String get laLibreria => t('La libreria', 'The library', 'La bibliothèque');
  String get pratiche => t('Pratiche', 'Practices', 'Pratiques');
  String get pratichesottotitolo => t(
        'Abitudini e protocolli da conoscere, approfondire e — se vuoi — aggiungere alla tua routine.',
        'Habits and protocols to learn about, explore, and — if you want — add to your routine.',
        'Habitudes et protocoles à découvrir, approfondir et — si vous le souhaitez — ajouter à votre routine.',
      );
  String get cercaUnaPratica => t('Cerca una pratica...', 'Search a practice...', 'Rechercher une pratique...');
  String get tutte => t('Tutte', 'All', 'Toutes');
  String get nessunaPraticaTrovata =>
      t('Nessuna pratica trovata.', 'No practices found.', 'Aucune pratique trouvée.');
  String get allineatoAlTuoApproccio =>
      t('Allineato al tuo approccio', 'Matches your approach', 'Correspond à votre approche');

  // Practice detail
  String get nellaMiaRoutine => t('Nella mia routine', 'In my routine', 'Dans ma routine');
  String get descrizione => t('DESCRIZIONE', 'DESCRIPTION', 'DESCRIPTION');
  String get obiettivo => t('OBIETTIVO', 'GOAL', 'OBJECTIF');
  String get beneficiPossibili => t('BENEFICI POSSIBILI', 'POSSIBLE BENEFITS', 'BÉNÉFICES POSSIBLES');
  String get comeIniziare => t('COME INIZIARE', 'HOW TO START', 'COMMENT COMMENCER');
  String get rischiEControindicazioni =>
      t('RISCHI E CONTROINDICAZIONI', 'RISKS AND CONTRAINDICATIONS', 'RISQUES ET CONTRE-INDICATIONS');
  String get fontiScientifiche => t('FONTI SCIENTIFICHE', 'SCIENTIFIC SOURCES', 'SOURCES SCIENTIFIQUES');
  String get nessunaFonteVerificataAncora => t(
        'Nessuna fonte verificata ancora per questa pratica specifica — il livello di evidenza sopra riflette questo.',
        'No verified source yet for this specific practice — the evidence level above reflects that.',
        'Aucune source vérifiée pour l’instant pour cette pratique spécifique — le niveau de preuve ci-dessus le reflète.',
      );
  String get leTueFonti => t('LE TUE FONTI', 'YOUR SOURCES', 'VOS SOURCES');
  String get nessunaFonteAncora => t(
        'Nessuna fonte ancora. Aggiungine una qui sotto — è solo per te.',
        'No sources yet. Add one below — it’s just for you.',
        'Aucune source pour l’instant. Ajoutez-en une ci-dessous — c’est juste pour vous.',
      );
  String get aggiungiUnaFonte => t('Aggiungi una fonte...', 'Add a source...', 'Ajouter une source...');
  String get notePersonali => t('NOTE PERSONALI', 'PERSONAL NOTES', 'NOTES PERSONNELLES');
  String get leTueNote => t('Le tue note...', 'Your notes...', 'Vos notes...');

  // Fasting detail
  String get finestraDiDigiunoEyebrow => t('DIGIUNO', 'FASTING', 'JEÛNE');
  String get obiettivo16hChip => t('Obiettivo 16h', 'Goal 16h', 'Objectif 16h');
  String get mostraFinestraDigiunoInOggi =>
      t('Mostra la finestra di digiuno in Oggi', 'Show the fasting window in Today', 'Afficher la fenêtre de jeûne dans Aujourd’hui');
  String inDigiunoDa(String duration) =>
      t('In digiuno da $duration', 'Fasting for $duration', 'En jeûne depuis $duration');
  String get info => t('INFO', 'INFO', 'INFO');
  String get digiunoSpiegazione => t(
        'Finestra 16:8 — mangi in una fascia di 8 ore, digiuni per le restanti 16. '
            'Segna l\'ultimo pasto di ieri e il primo di oggi per tracciare la finestra.',
        'A 16:8 window — you eat within an 8-hour span, and fast for the remaining 16. '
            'Mark yesterday\'s last meal and today\'s first to track the window.',
        'Fenêtre 16:8 — vous mangez sur une plage de 8 heures et jeûnez pour les 16 restantes. '
            'Marquez le dernier repas d\'hier et le premier d\'aujourd\'hui pour suivre la fenêtre.',
      );

  // Supplement detail
  String get integratoriEyebrow => t('INTEGRATORI', 'SUPPLEMENTS', 'COMPLÉMENTS');
  String minuti(int minutes) => t('$minutes min', '$minutes min', '$minutes min');
  String get presoOggi => t('Preso oggi', 'Taken today', 'Pris aujourd’hui');
  String get impostaPromemoria => t('Imposta promemoria', 'Set reminder', 'Définir un rappel');
  String get salvataggioInCorso => t('Salvataggio...', 'Saving...', 'Enregistrement...');
  String get benefici => t('BENEFICI', 'BENEFITS', 'BÉNÉFICES');
  List<String> get weekdayLettersMonToSun => t('LMMGVSD', 'MTWTFSS', 'LMMJVSD').split('');

  // Routine step detail
  String get ilRituale => t('IL RITUALE', 'THE RITUAL', 'LE RITUEL');
  String get fattoOggi => t('Fatto oggi', 'Done today', 'Fait aujourd’hui');

  // Plant categories
  String get plantFrutta => t('Frutta', 'Fruit', 'Fruits');
  String get plantVerdura => t('Verdura', 'Vegetables', 'Légumes');
  String get plantLegumi => t('Legumi', 'Legumes', 'Légumineuses');
  String get plantCerealiIntegrali => t('Cereali integrali', 'Whole grains', 'Céréales complètes');
  String get plantFruttaSecca => t('Frutta secca', 'Nuts', 'Fruits à coque');
  String get plantSemi => t('Semi', 'Seeds', 'Graines');
  String get plantErbe => t('Erbe', 'Herbs', 'Herbes');
  String get plantSpezie => t('Spezie', 'Spices', 'Épices');
  String get plantBevandeVegetali => t('Bevande vegetali', 'Plant beverages', 'Boissons végétales');

  // Plant diversity screen
  String get questaSettimana => t('Questa settimana', 'This week', 'Cette semaine');
  String get punti30Piante => t('30 Punti Piante', '30 Plant Points', '30 Points Plantes');
  String get puntiPianteSottotitolo => t(
        'Traccia la diversità vegetale, non le calorie. Ogni pianta unica conta un punto.',
        'Track plant diversity, not calories. Each unique plant counts as one point.',
        'Suivez la diversité végétale, pas les calories. Chaque plante unique compte un point.',
      );
  String get diversitaSettimanale => t('DIVERSITÀ SETTIMANALE', 'WEEKLY DIVERSITY', 'DIVERSITÉ HEBDOMADAIRE');
  String obiettivoN(int n) => t('Obiettivo $n', 'Goal $n', 'Objectif $n');
  String suGoalPiante(int goal) => t(' / $goal piante', ' / $goal plants', ' / $goal plantes');
  String get obiettivoRaggiuntoSettimana =>
      t('Obiettivo raggiunto questa settimana.', 'Goal reached this week.', 'Objectif atteint cette semaine.');
  String ancoraNPianteObiettivo(int n) => t(
        'Ancora $n piante per raggiungere l\'obiettivo.',
        '$n more plants to reach the goal.',
        'Encore $n plantes pour atteindre l\'objectif.',
      );
  String get perche30 => t('PERCHÉ 30?', 'WHY 30?', 'POURQUOI 30 ?');
  String get spiegazionePerche30 => t(
        'Studi sul microbioma (American Gut Project) mostrano che chi consuma '
            '30+ piante diverse a settimana ha una diversità batterica intestinale '
            'significativamente più ricca. Fibre, polifenoli e fitonutrienti diversi '
            'nutrono ceppi batterici diversi.',
        'Microbiome studies (American Gut Project) show that people who eat '
            '30+ different plants a week have significantly richer gut bacterial '
            'diversity. Different fibers, polyphenols, and phytonutrients feed '
            'different bacterial strains.',
        'Des études sur le microbiome (American Gut Project) montrent que les personnes '
            'consommant 30+ plantes différentes par semaine ont une diversité bactérienne '
            'intestinale significativement plus riche. Fibres, polyphénols et phytonutriments '
            'variés nourrissent des souches bactériennes différentes.',
      );
  String get aggiungiRapidamente => t('AGGIUNGI RAPIDAMENTE', 'QUICK ADD', 'AJOUT RAPIDE');
  String get cercaOScriviUnaPianta =>
      t('Cerca o scrivi una pianta...', 'Search or type a plant...', 'Rechercher ou écrire une plante...');
  String get mostraMeno => t('Mostra meno', 'Show less', 'Afficher moins');
  String mostraTuttiN(int n) => t('Mostra tutti ($n)', 'Show all ($n)', 'Afficher tout ($n)');
  String consumateQuestaSettimana(int count) => t(
        'CONSUMATE QUESTA SETTIMANA · $count',
        'EATEN THIS WEEK · $count',
        'CONSOMMÉES CETTE SEMAINE · $count',
      );
  String get nessunaPiantaAnnotataAncora => t(
        'Nessuna pianta annotata ancora. Inizia con la colazione.',
        'No plants logged yet. Start with breakfast.',
        'Aucune plante notée pour l\'instant. Commencez par le petit-déjeuner.',
      );
  String get perGruppo => t('PER GRUPPO', 'BY GROUP', 'PAR GROUPE');
  String get pianteNonInElenco => t(
        'non è nel nostro elenco di piante — scegline una dalle categorie qui sotto.',
        'isn\'t in our plant list — pick one from the categories below.',
        'ne figure pas dans notre liste de plantes — choisissez-en une dans les catégories ci-dessous.',
      );
  String get impossibileRimuovereRiprova =>
      t('Impossibile rimuovere, riprova', 'Could not remove, try again', 'Impossible de supprimer, réessayez');

  // Profile screen
  String get tuoSoloSeVuoi => t('Tuo, solo se vuoi', 'Yours, only if you want', 'À vous, si vous le voulez');
  String get profilo => t('Profilo', 'Profile', 'Profil');
  String profiloSottotitolo(String email) => t(
        'Tutto qui è opzionale. Più segnali = suggerimenti più rilevanti — ma non devi nulla.\n$email',
        'Everything here is optional. More signals = more relevant suggestions — but you owe nothing.\n$email',
        'Tout ici est facultatif. Plus de signaux = suggestions plus pertinentes — mais vous ne devez rien.\n$email',
      );
  String get nickname => t('NICKNAME', 'NICKNAME', 'SURNOM');
  String get nicknameSpiegazione => t(
        'Usato per il saluto in Oggi — "Buongiorno, [nickname]".',
        'Used for the greeting in Today — "Good morning, [nickname]".',
        'Utilisé pour la salutation dans Aujourd’hui — « Bonjour, [surnom] ».',
      );
  String get esEnkida => t('Es. Enkida', 'E.g. Alex', 'Ex. Alex');
  String get aspetto => t('ASPETTO', 'APPEARANCE', 'APPARENCE');
  String get aspettoSpiegazione => t(
        'Automatico segue l\'ora in una curva continua: luce al risveglio, '
            'sospeso nel pomeriggio, notte la sera.',
        'Automatic follows the time of day on a continuous curve: light at wake-up, '
            'suspended in the afternoon, night in the evening.',
        'Automatique suit l\'heure sur une courbe continue : lumière au réveil, '
            'suspendu l\'après-midi, nuit le soir.',
      );
  String get chiaro => t('Chiaro', 'Light', 'Clair');
  String get scuro => t('Scuro', 'Dark', 'Sombre');
  String get auto => t('Auto', 'Auto', 'Auto');
  String get approccioAlBenessere => t('APPROCCIO AL BENESSERE', 'WELLNESS APPROACH', 'APPROCHE DU BIEN-ÊTRE');
  String get approccioSpiegazione => t(
        'Pesa i consigli dell\'AI: più naturale (es. zenzero, EVOO, golden milk) '
            'o più mirato/da ricerca (es. integratori specifici come NAD+).',
        'Weighs the AI\'s suggestions: more natural (e.g. ginger, EVOO, golden milk) '
            'or more targeted/research-backed (e.g. specific supplements like NAD+).',
        'Pondère les conseils de l\'IA : plus naturel (ex. gingembre, huile d\'olive, golden milk) '
            'ou plus ciblé/issu de la recherche (ex. compléments spécifiques comme le NAD+).',
      );
  String get naturale => t('Naturale', 'Natural', 'Naturel');
  String get bilanciato => t('Bilanciato', 'Balanced', 'Équilibré');
  String get scientifico => t('Scientifico', 'Scientific', 'Scientifique');
  String get sesso => t('SESSO', 'SEX', 'SEXE');
  String get sessoSpiegazione => t(
        'Opzionale — decide solo se mostrare il tracking del ciclo mestruale in Oggi.',
        'Optional — only decides whether to show menstrual cycle tracking in Today.',
        'Facultatif — décide seulement d\'afficher ou non le suivi du cycle menstruel dans Aujourd’hui.',
      );
  String get nonSpecificato => t('Non specificato', 'Not specified', 'Non spécifié');
  String get donna => t('Donna', 'Woman', 'Femme');
  String get uomo => t('Uomo', 'Man', 'Homme');
  String get digiunoLabel => t('DIGIUNO', 'FASTING', 'JEÛNE');
  String get digiunoSettingSpiegazione => t(
        'Opzionale — mostra il tracking del digiuno in Oggi solo se attivato.',
        'Optional — shows fasting tracking in Today only if enabled.',
        'Facultatif — affiche le suivi du jeûne dans Aujourd’hui seulement si activé.',
      );
  String get tracciaDigiuno => t('Traccia digiuno', 'Track fasting', 'Suivre le jeûne');
  String get linguaLabel => t('LINGUA', 'LANGUAGE', 'LANGUE');
  String get linguaSpiegazione => t(
        'Per ora traduce Oggi e il Ritual — il resto arriva a breve.',
        'For now it translates Today and the Ritual — the rest is coming soon.',
        'Pour l\'instant, cela traduit Aujourd’hui et le Rituel — le reste arrive bientôt.',
      );
  String get ritualeSerale => t('RITUALE SERALE', 'EVENING RITUAL', 'RITUEL DU SOIR');
  String get ritualeSeraleSpiegazione => t(
        'Suggerisce quando iniziare la routine serale in Oggi.',
        'Suggests when to start the evening routine in Today.',
        'Suggère quand commencer la routine du soir dans Aujourd’hui.',
      );
  String get impostaOrario => t('Imposta orario', 'Set time', 'Définir l\'heure');
  String suggerisciDopoLe(String time) =>
      t('Suggerisci dopo le $time', 'Suggest after $time', 'Suggérer après $time');
  String get suggerisciIlRitualeSeraleDopoLe =>
      t('Suggerisci il rituale serale dopo le', 'Suggest the evening ritual after', 'Suggérer le rituel du soir après');
  String get dataDiNascitaLabel => t('DATA DI NASCITA', 'DATE OF BIRTH', 'DATE DE NAISSANCE');
  String get dataDiNascitaSpiegazione => t(
        'Opzionale — serve solo per calcolare l\'età biologica stimata (PhenoAge) da un referto '
            'del sangue caricato qui sotto. Senza data di nascita, quella stima non può essere calcolata.',
        'Optional — only used to calculate the estimated biological age (PhenoAge) from a blood '
            'test uploaded below. Without a date of birth, that estimate can\'t be calculated.',
        'Facultatif — sert uniquement à calculer l\'âge biologique estimé (PhenoAge) à partir d\'un '
            'bilan sanguin téléchargé ci-dessous. Sans date de naissance, cette estimation ne peut pas être calculée.',
      );
  String get dataDiNascitaPicker => t('Data di nascita', 'Date of birth', 'Date de naissance');
  String get impostaDataDiNascita => t('Imposta data di nascita', 'Set date of birth', 'Définir la date de naissance');
  String get documentiPerLai => t('DOCUMENTI PER L\'AI', 'DOCUMENTS FOR THE AI', 'DOCUMENTS POUR L\'IA');
  String get documentiSpiegazione => t(
        'PDF o foto (es. referto nutrizionale o del sangue) che il Focus del giorno può leggere.',
        'PDFs or photos (e.g. a nutrition or blood test report) the Focus of the day can read.',
        'PDF ou photos (ex. bilan nutritionnel ou sanguin) que le Focus du jour peut lire.',
      );
  String get caricaDocumento => t('Carica documento', 'Upload document', 'Télécharger un document');
  String get esci => t('Esci', 'Log out', 'Se déconnecter');
  String get impossibileCaricareRiprova =>
      t('Impossibile caricare, riprova', 'Could not upload, try again', 'Impossible de télécharger, réessayez');
  String get impossibileEliminareRiprova =>
      t('Impossibile eliminare, riprova', 'Could not delete, try again', 'Impossible de supprimer, réessayez');

  // Common actions (continued)
  String get fatto => t('Fatto', 'Done', 'Fait');

  // Weekday / month names
  List<String> get weekdayHeadersMonToSun => t('LMMGVSD', 'MTWTFSS', 'LMMJVSD').split('');
  List<String> get monthNames => t(
        'Gennaio,Febbraio,Marzo,Aprile,Maggio,Giugno,Luglio,Agosto,Settembre,Ottobre,Novembre,Dicembre',
        'January,February,March,April,May,June,July,August,September,October,November,December',
        'Janvier,Février,Mars,Avril,Mai,Juin,Juillet,Août,Septembre,Octobre,Novembre,Décembre',
      ).split(',');

  // Cycle calendar sheet
  String get selezionaGiorni => t('Seleziona giorni', 'Select days', 'Sélectionner les jours');
  String get toccaIlPrimoGiornoDiMestruazione =>
      t('Tocca il primo giorno di mestruazione.', 'Tap the first day of your period.', 'Touchez le premier jour de vos règles.');
  String mestruazioneDiNGiorni(int n) => t(
        'Mestruazione di $n giorni.',
        '$n-day period.',
        'Règles de $n jours.',
      );

  // Schedule types
  String get scheduleOgniGiorno => t('Ogni giorno', 'Every day', 'Chaque jour');
  String get scheduleNVolteASettimana => t('N volte a settimana', 'N times a week', 'N fois par semaine');
  String get scheduleGiorniSpecifici => t('Giorni specifici', 'Specific days', 'Jours spécifiques');
  String get scheduleCiclico =>
      t('Ciclico (giorni attivi / pausa)', 'Cyclic (on days / off days)', 'Cyclique (jours actifs / pause)');

  // Schedule editor
  String get programmazione => t('PROGRAMMAZIONE', 'SCHEDULE', 'PROGRAMMATION');
  String nVolteASettimana(int n) => t('$n volte a settimana', '$n times a week', '$n fois par semaine');
  String giorniAutoDistribuiti(String days) =>
      t('Giorni auto-distribuiti: $days', 'Auto-distributed days: $days', 'Jours auto-répartis : $days');
  String get giorniAttivi => t('Giorni attivi', 'Active days', 'Jours actifs');
  String get giorniPausa => t('Giorni pausa', 'Off days', 'Jours de pause');
  String daOggiCiclico(int onDays, int offDays) => t(
        'Da oggi: $onDays giorni attivi, poi $offDays di pausa, a ciclo.',
        'From today: $onDays active days, then $offDays off, on a cycle.',
        'À partir d\'aujourd\'hui : $onDays jours actifs, puis $offDays de pause, en cycle.',
      );

  // Time budget prompt
  String get quantoTempoHaiEyebrow => t('QUANTO TEMPO HAI?', 'HOW MUCH TIME DO YOU HAVE?', 'COMBIEN DE TEMPS AVEZ-VOUS ?');
  String get quantoTempoHai => t('Quanto tempo hai?', 'How much time do you have?', 'Combien de temps avez-vous ?');
  String get timeBudgetSpiegazione => t(
        'Pura costruisce il rituale attorno al tuo tempo. Niente streak, niente pressione.',
        'Pura builds the ritual around your time. No streaks, no pressure.',
        'Pura construit le rituel autour de votre temps. Pas de séries, pas de pression.',
      );
  String get saltaPerOra => t('SALTA PER ORA', 'SKIP FOR NOW', 'PASSER POUR L\'INSTANT');

  // Sleep screen
  String get salute => t('Salute', 'Health', 'Santé');
  String get notteScorsa => t('Notte scorsa', 'Last night', 'Nuit dernière');
  String get registraManualmente => t('Registra manualmente', 'Log manually', 'Enregistrer manuellement');
  String get daSalute => t('Da Salute', 'From Health', 'Depuis Santé');
  String get ultime7Notti => t('ULTIME 7 NOTTI', 'LAST 7 NIGHTS', '7 DERNIÈRES NUITS');
  String get media7Notti => t('Media 7 notti', '7-night average', 'Moyenne 7 nuits');
  String get variabilitaSveglia => t('Variabilità sveglia', 'Wake time variability', 'Variabilité du réveil');
  String get nessunDatoSonnoAncora => t(
        'Nessun dato ancora — registra la notte scorsa per iniziare.',
        'No data yet — log last night to get started.',
        'Aucune donnée pour l\'instant — enregistrez la nuit dernière pour commencer.',
      );
  String importatoDa(String source) =>
      t('Importato da: $source', 'Imported from: $source', 'Importé depuis : $source');

  // Cycle screen
  String get ciclo => t('Ciclo', 'Cycle', 'Cycle');
  String get registraUnCicloPassato =>
      t('Registra un ciclo passato', 'Log a past period', 'Enregistrer un cycle passé');
  String get nessunDatoCicloTrovatoInSalute => t(
        'Nessun dato ciclo trovato in Salute.',
        'No cycle data found in Health.',
        'Aucune donnée de cycle trouvée dans Santé.',
      );
  String get iTuoiCicli => t('I TUOI CICLI', 'YOUR CYCLES', 'VOS CYCLES');
  String get nessunCicloRegistratoAncora =>
      t('Nessun ciclo registrato ancora.', 'No cycle logged yet.', 'Aucun cycle enregistré pour l\'instant.');
  String get disclaimerStimeCiclo => t(
        'Le stime di durata mestruale e finestra fertile sono indicative, non '
            'misurate — quest\'app registra solo la data di inizio. Non usarle come '
            'metodo contraccettivo.',
        'Period length and fertile window estimates are indicative, not '
            'measured — this app only logs the start date. Don\'t use them as a '
            'contraceptive method.',
        'Les estimations de durée des règles et de fenêtre fertile sont indicatives, non '
            'mesurées — cette application n\'enregistre que la date de début. Ne les utilisez pas '
            'comme méthode contraceptive.',
      );
  String cicloCorrenteIniziatoIl(String date, int days) => t(
        'Ciclo corrente: iniziato il $date ($days giorni)',
        'Current cycle: started on $date ($days days)',
        'Cycle en cours : commencé le $date ($days jours)',
      );
  String nGiorniIntervallo(int days, String from, String to) =>
      t('$days giorni: $from - $to', '$days days: $from - $to', '$days jours : $from - $to');
  String mestruazioneStimataDiNGiorni(int n) => t(
        'Mestruazione stimata di $n giorni',
        'Estimated $n-day period',
        'Règles estimées à $n jours',
      );
  String mestruazioneDiNGiorniSenzaPunto(int n) =>
      t('Mestruazione di $n giorni', '$n-day period', 'Règles de $n jours');
  String cicloMedioNGiorni(int n) => t('Ciclo medio: $n giorni', 'Average cycle: $n days', 'Cycle moyen : $n jours');
  List<String> get monthNamesShort => t(
        'gen,feb,mar,apr,mag,giu,lug,ago,set,ott,nov,dic',
        'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec',
        'janv,févr,mars,avr,mai,juin,juill,août,sept,oct,nov,déc',
      ).split(',');

  // Discover screen
  String get questoMese => t('Questo mese', 'This month', 'Ce mois-ci');
  String get scopri => t('Scopri', 'Discover', 'Découvrir');
  String get ingredienteDelMese => t('INGREDIENTE DEL MESE', 'INGREDIENT OF THE MONTH', 'INGRÉDIENT DU MOIS');
  String get pepeNeroCurcumina => t('Pepe nero × Curcumina', 'Black Pepper × Turmeric', 'Poivre noir × Curcuma');
  String get pepeNeroSpiegazione => t(
        'Insieme alla curcumina, la piperina aumenta la biodisponibilità di circa '
            'il 2000%. Lo stesso cucchiaino di curcuma diventa una molecola '
            'significativamente diversa. Vanno sempre abbinati.',
        'Combined with curcumin, piperine increases bioavailability by about '
            '2000%. The same teaspoon of turmeric becomes a significantly '
            'different molecule. They should always be paired.',
        'Associée à la curcumine, la pipérine augmente la biodisponibilité d\'environ '
            '2000%. La même cuillère de curcuma devient une molécule '
            'significativement différente. Elles doivent toujours être associées.',
      );
  String get sfideDaProvare => t('SFIDE DA PROVARE', 'CHALLENGES TO TRY', 'DÉFIS À ESSAYER');
  String get soleNegliOcchiTitolo => t('Sole negli occhi — 7 mattine', 'Sunlight in your eyes — 7 mornings', 'Soleil dans les yeux — 7 matins');
  String get soleNegliOcchiSottotitolo => t('5 min al giorno', '5 min a day', '5 min par jour');
  String get soleNegliOcchiDescrizione => t(
        'Ancora il tuo orologio circadiano. All\'aperto, senza occhiali da sole, entro 30 minuti dal risveglio.',
        'Anchors your circadian clock. Outdoors, without sunglasses, within 30 minutes of waking.',
        'Ancre votre horloge circadienne. À l\'extérieur, sans lunettes de soleil, dans les 30 minutes suivant le réveil.',
      );
  String get soleNegliOcchiFonte =>
      t('Fonte: vedi "Luce solare negli occhi" nel Ritual.', 'Source: see "Sunlight in your eyes" in the Ritual.', 'Source : voir « Soleil dans les yeux » dans le Rituel.');
  String get mouthTapingTitolo => t('Inizio mouth taping', 'Starting mouth taping', 'Début du mouth taping');
  String get mouthTapingSottotitolo => t('2 settimane', '2 weeks', '2 semaines');
  String get mouthTapingDescrizione => t(
        'Comincia con respirazione nasale di giorno. Poi brevi sessioni serali. Poi notti intere.',
        'Start with nasal breathing during the day. Then short evening sessions. Then full nights.',
        'Commencez par la respiration nasale en journée. Puis de courtes séances le soir. Puis des nuits entières.',
      );
  String get finaleFreddoTitolo => t('Finale freddo — 14 giorni', 'Cold finish — 14 days', 'Finition froide — 14 jours');
  String get finaleFreddoSottotitolo => t('30 sec / doccia', '30 sec / shower', '30 sec / douche');
  String get finaleFreddoDescrizione => t(
        'Termina ogni doccia con acqua fredda. Osserva come cambiano umore ed energia dal 7° giorno.',
        'End every shower with cold water. Notice how mood and energy change from day 7.',
        'Terminez chaque douche par de l\'eau froide. Observez l\'évolution de l\'humeur et de l\'énergie dès le 7e jour.',
      );
  String get finaleFreddoFonte =>
      t('Fonte: vedi "Doccia fredda" nelle Pratiche.', 'Source: see "Cold shower" in Practices.', 'Source : voir « Douche froide » dans Pratiques.');
  String get protocolliStagionali => t('PROTOCOLLI STAGIONALI', 'SEASONAL PROTOCOLS', 'PROTOCOLES SAISONNIERS');
  String get detoxPrimaveraTitolo => t('Detox di primavera', 'Spring detox', 'Détox de printemps');
  String get detoxPrimaveraDescrizione => t(
        'Verdure amare, lavoro linfatico, serate più leggere.',
        'Bitter greens, lymphatic work, lighter evenings.',
        'Légumes amers, travail lymphatique, soirées plus légères.',
      );
  String get idratazioneEstivaTitolo => t('Idratazione estiva', 'Summer hydration', 'Hydratation estivale');
  String get idratazioneEstivaDescrizione => t(
        'Sale marino al mattino, elettroliti, risciacqui freddi.',
        'Sea salt in the morning, electrolytes, cold rinses.',
        'Sel marin le matin, électrolytes, rinçages froids.',
      );
  String get immunitaAutunnoTitolo => t('Immunità d\'autunno', 'Autumn immunity', 'Immunité automnale');
  String get immunitaAutunnoDescrizione => t(
        'Rotazione di funghi, controllo vitamina D, calore.',
        'Mushroom rotation, vitamin D check, warmth.',
        'Rotation de champignons, contrôle de la vitamine D, chaleur.',
      );
  String get caloreInvernoTitolo => t('Calore d\'inverno', 'Winter warmth', 'Chaleur hivernale');
  String get caloreInvernoDescrizione => t(
        'Golden milk, stack sauna, finestre di sonno più lunghe.',
        'Golden milk, sauna stack, longer sleep windows.',
        'Golden milk, séances de sauna, fenêtres de sommeil plus longues.',
      );
  String get etaBiologicaPhenoAge => t('ETÀ BIOLOGICA (PHENOAGE)', 'BIOLOGICAL AGE (PHENOAGE)', 'ÂGE BIOLOGIQUE (PHENOAGE)');
  String etaStimataAnni(String estimated, String chronological) => t(
        '$estimated anni stimati (età anagrafica $chronological) — informazione, non una diagnosi.',
        '$estimated years estimated (chronological age $chronological) — information, not a diagnosis.',
        '$estimated ans estimés (âge chronologique $chronological) — information, pas un diagnostic.',
      );
  String get stimaNonCalcolabile => t('Stima non calcolabile.', 'Estimate not calculable.', 'Estimation non calculable.');
  String biomarcatoriUsati(String list) =>
      t('Biomarcatori usati: $list.', 'Biomarkers used: $list.', 'Biomarqueurs utilisés : $list.');
  String mancanti(String list) => t('Mancanti: $list.', 'Missing: $list.', 'Manquants : $list.');
  String fonteConData(String source, String date) =>
      t('Fonte: $source ($date).', 'Source: $source ($date).', 'Source : $source ($date).');
  String fonteSenzaData(String source) => t('Fonte: $source.', 'Source: $source.', 'Source : $source.');

  // Skincare photo picker
  String get fotocamera => t('Fotocamera', 'Camera', 'Appareil photo');
  String get libreriaFoto => t('Libreria foto', 'Photo library', 'Photothèque');
}
