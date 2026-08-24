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
}
