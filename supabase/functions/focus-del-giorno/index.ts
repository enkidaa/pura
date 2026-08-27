// Edge Function: builds a compact digest of the user's recent data and asks
// Gemini Flash for a personalized "focus del giorno" suggestion, returned as
// validated structured output (not free text). The Gemini API key lives only
// here (Supabase secret), never in the Flutter app.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GEMINI_MODEL = "gemini-flash-latest";
const PROMPT_VERSION = "v1";

// Approximate Gemini Flash pricing (USD per 1M tokens) — verify current
// pricing at ai.google.dev/pricing before relying on this for real budgeting;
// it's an estimate for relative cost tracking, not an exact billing figure.
const GEMINI_INPUT_PRICE_PER_MILLION = 0.075;
const GEMINI_OUTPUT_PRICE_PER_MILLION = 0.30;

function estimateCostUsd(tokenInput: number, tokenOutput: number): number {
  return (
    (tokenInput / 1_000_000) * GEMINI_INPUT_PRICE_PER_MILLION +
    (tokenOutput / 1_000_000) * GEMINI_OUTPUT_PRICE_PER_MILLION
  );
}

const SYSTEM_PROMPT = `Sei l'assistente di Pura, un'app di benessere personale.
Ricevi un riassunto compatto delle abitudini recenti dell'utente (routine mattutina,
diversità vegetale settimanale) ed eventualmente un documento allegato (es. referto
nutrizionale). Il tuo compito: produrre UN SOLO consiglio ("focus del giorno") in
italiano, seguendo esattamente lo schema JSON richiesto.

Regole:
- "observation": cosa noti nei dati (1 frase, basata SOLO sui dati forniti).
- "evidence": elenco puntuale dei dati concreti usati (es. "3/7 giorni routine completata").
- "recommendation": il consiglio vero e proprio, concreto, massimo 2 frasi.
- "confidence": quanto sei sicuro che il consiglio sia utile dato il poco contesto disponibile.
- "evidence_strength": quanto sono solidi i dati a supporto (none = nessun dato reale, weak =
  pochi dati, moderate = dati normali, strong = dati abbondanti o documento allegato pertinente).
- "sources": quali fonti hai usato tra "routine_completions", "plant_diversity_logs",
  "profile_narrative", "user_document". Vuoto se non hai usato nulla di specifico.
- "safety_category": "wellness_recommendation" per consigli di abitudini generiche;
  "medical_information" se citi dati/valori da un documento medico; "diagnosis_treatment"
  se il consiglio equivarrebbe a una diagnosi o prescrizione (EVITALO, riformula come
  wellness_recommendation o medical_information); "concerning_signal" se noti qualcosa
  nei dati che meriterebbe attenzione professionale.
- Se ti viene indicata una preferenza dell'utente su rimedi naturali vs integratori mirati, tienine
  conto quando il consiglio riguarda un rimedio/integratore specifico — non forzarla se il consiglio
  del giorno non c'entra nulla con quell'ambito.
- Se ti viene indicata la fase del ciclo mestruale, trattala come contesto da considerare quando dai un
  consiglio su energia, allenamento intenso o digiuno — non come regola rigida da applicare sempre.
  Es.: un digiuno prolungato o un allenamento ad alta intensità possono essere meno indicati in fase
  luteale/mestruale che in fase follicolare/ovulatoria, e più riposo può avere senso in fase mestruale.
  Usa questi esempi solo se pertinenti al consiglio che stai per dare — non forzarli, e non è comunque
  un dato medico su cui basare diagnosi.
- Potrebbe esserti allegato un documento (es. referto). Decidi tu se è pertinente al consiglio di
  oggi: se lo è, usalo e aggiungi "user_document" a "sources"; se non c'entra nulla con il consiglio
  che stai per dare, IGNORALO — non citarlo, non forzare un collegamento, non spostare il consiglio
  verso un tema medico solo perché il documento esiste.
- Priorità: sonno > movimento > alimentazione > integratori > protocolli sperimentali/biohacking
  avanzati. Se il digest indica "Fondamenta di base fuori target" (sonno, routine di base o digiuno),
  il consiglio di oggi DEVE riguardare quella fondamenta, non un'ottimizzazione più avanzata — anche
  se ci sono integratori assunti, un documento allegato interessante, o altri dati disponibili.
  Suggerire un integratore o un protocollo sperimentale a chi dorme poco o salta la routine di base
  sarebbe come un cattivo coach che salta le basi per la parte più appariscente: non farlo. Se ci sono
  più fondamenta fuori target, scegli quella più in alto nell'ordine di priorità sopra. Se le fondamenta
  sono tutte a target (o non c'è abbastanza dato per giudicarle), sei libero di dare il consiglio più
  rilevante tra tutti i dati disponibili, incluse aree più avanzate.
- Non inventare dati che non ti sono stati dati.`;

const RESPONSE_SCHEMA = {
  type: "OBJECT",
  properties: {
    observation: { type: "STRING" },
    evidence: { type: "ARRAY", items: { type: "STRING" } },
    recommendation: { type: "STRING" },
    confidence: { type: "STRING", enum: ["low", "medium", "high"] },
    evidence_strength: { type: "STRING", enum: ["none", "weak", "moderate", "strong"] },
    sources: {
      type: "ARRAY",
      items: {
        type: "STRING",
        enum: ["routine_completions", "plant_diversity_logs", "profile_narrative", "user_document"],
      },
    },
    safety_category: {
      type: "STRING",
      enum: ["wellness_recommendation", "medical_information", "diagnosis_treatment", "concerning_signal"],
    },
  },
  required: [
    "observation",
    "evidence",
    "recommendation",
    "confidence",
    "evidence_strength",
    "sources",
    "safety_category",
  ],
};

const CONFIDENCE_VALUES = ["low", "medium", "high"];
const EVIDENCE_STRENGTH_VALUES = ["none", "weak", "moderate", "strong"];
const SOURCE_VALUES = ["routine_completions", "plant_diversity_logs", "profile_narrative", "user_document"];
const SAFETY_CATEGORY_VALUES = [
  "wellness_recommendation",
  "medical_information",
  "diagnosis_treatment",
  "concerning_signal",
];

interface FocusSuggestion {
  observation: string;
  evidence: string[];
  recommendation: string;
  confidence: string;
  evidence_strength: string;
  sources: string[];
  safety_category: string;
}

// Explicit validation — a malformed/missing field must surface as a clear
// error, never as a silently-accepted partial or wrong-shaped object.
function validateSuggestion(raw: unknown): { ok: true; value: FocusSuggestion } | { ok: false; reason: string } {
  if (typeof raw !== "object" || raw === null) {
    return { ok: false, reason: "Response is not a JSON object" };
  }
  const obj = raw as Record<string, unknown>;

  if (typeof obj.observation !== "string" || obj.observation.trim() === "") {
    return { ok: false, reason: "Missing or invalid field: observation" };
  }
  if (!Array.isArray(obj.evidence) || !obj.evidence.every((e) => typeof e === "string")) {
    return { ok: false, reason: "Missing or invalid field: evidence" };
  }
  if (typeof obj.recommendation !== "string" || obj.recommendation.trim() === "") {
    return { ok: false, reason: "Missing or invalid field: recommendation" };
  }
  if (typeof obj.confidence !== "string" || !CONFIDENCE_VALUES.includes(obj.confidence)) {
    return { ok: false, reason: "Missing or invalid field: confidence" };
  }
  if (
    typeof obj.evidence_strength !== "string" ||
    !EVIDENCE_STRENGTH_VALUES.includes(obj.evidence_strength)
  ) {
    return { ok: false, reason: "Missing or invalid field: evidence_strength" };
  }
  if (
    !Array.isArray(obj.sources) ||
    !obj.sources.every((s) => typeof s === "string" && SOURCE_VALUES.includes(s))
  ) {
    return { ok: false, reason: "Missing or invalid field: sources" };
  }
  if (
    typeof obj.safety_category !== "string" ||
    !SAFETY_CATEGORY_VALUES.includes(obj.safety_category)
  ) {
    return { ok: false, reason: "Missing or invalid field: safety_category" };
  }

  return {
    ok: true,
    value: {
      observation: obj.observation,
      evidence: obj.evidence as string[],
      recommendation: obj.recommendation,
      confidence: obj.confidence,
      evidence_strength: obj.evidence_strength,
      sources: obj.sources as string[],
      safety_category: obj.safety_category,
    },
  };
}

// --- Safety layer ---------------------------------------------------------
// Independent second pass: the model's own `safety_category` (from the same
// call that generated the suggestion) is treated as an untrusted signal, not
// a verdict. This layer re-classifies the recommendation text alone, with a
// narrower prompt and no view of the original digest/system prompt, so it
// isn't anchored by the same framing that produced the content.

const SAFETY_CLASSIFIER_PROMPT = `Sei un classificatore di sicurezza indipendente per
contenuti di wellness. Ricevi SOLO un'osservazione e una raccomandazione, senza altro
contesto. Classifica il testo in una di queste categorie, valutando esclusivamente
quello che leggi:
- "wellness_recommendation": consiglio di abitudine generica (sonno, alimentazione, movimento).
- "medical_information": cita informazioni o valori medici specifici.
- "diagnosis_treatment": equivale a una diagnosi, prescrizione, dosaggio o piano terapeutico.
- "concerning_signal": indica un problema di salute che meriterebbe attenzione professionale.
Sii conservativo: in caso di dubbio tra due categorie, scegli quella più cauta.`;

const SAFETY_CLASSIFIER_SCHEMA = {
  type: "OBJECT",
  properties: {
    category: { type: "STRING", enum: SAFETY_CATEGORY_VALUES },
  },
  required: ["category"],
};

const DIAGNOSIS_KEYWORDS = [
  "diagnosi",
  "diagnostic",
  "prescriv",
  "dosaggio di",
  "posologia",
  "hai il diabete",
  "hai una carenza di",
  "sei affetto da",
  "soffri di",
  "cura per",
  "terapia per",
  "trattamento per",
];

function ruleBasedDiagnosisFlag(text: string): boolean {
  const lower = text.toLowerCase();
  return DIAGNOSIS_KEYWORDS.some((keyword) => lower.includes(keyword));
}

interface ClassifierResult {
  category: string | null;
  failed: boolean;
  latencyMs: number;
  tokenInput: number | null;
  tokenOutput: number | null;
}

async function classifyIndependently(
  observation: string,
  recommendation: string,
  apiKey: string,
): Promise<ClassifierResult> {
  const startTime = Date.now();
  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text:
                `${SAFETY_CLASSIFIER_PROMPT}\n\nOsservazione: ${observation}\nRaccomandazione: ${recommendation}`,
            }],
          }],
          generationConfig: {
            responseMimeType: "application/json",
            responseSchema: SAFETY_CLASSIFIER_SCHEMA,
          },
        }),
      },
    );
    const latencyMs = Date.now() - startTime;

    if (!response.ok) {
      return { category: null, failed: true, latencyMs, tokenInput: null, tokenOutput: null };
    }

    const data = await response.json();
    const tokenInput = data.usageMetadata?.promptTokenCount ?? null;
    const tokenOutput = data.usageMetadata?.candidatesTokenCount ?? null;
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;

    if (typeof text !== "string") {
      return { category: null, failed: true, latencyMs, tokenInput, tokenOutput };
    }

    const parsed = JSON.parse(text);
    const category = parsed?.category;
    const valid = typeof category === "string" && SAFETY_CATEGORY_VALUES.includes(category);

    // A response that parses but doesn't contain a valid category still
    // counts as a failed classification — fail-open must be explicit and
    // logged, never silently indistinguishable from "the classifier voted
    // wellness_recommendation".
    return {
      category: valid ? category : null,
      failed: !valid,
      latencyMs,
      tokenInput,
      tokenOutput,
    };
  } catch {
    // Independent classifier failing is not silent: it just can't add a
    // vote, the rule-based flag and the model's own category still apply —
    // fail-open, tracked explicitly via `failed` rather than left implicit.
    return { category: null, failed: true, latencyMs: Date.now() - startTime, tokenInput: null, tokenOutput: null };
  }
}

const DIAGNOSIS_FALLBACK_MESSAGE =
  "Questo tipo di consiglio richiede il parere di un professionista sanitario — non posso " +
  "fornirlo come raccomandazione personale. Parlane con il tuo medico o nutrizionista.";

const UNGROUNDED_MEDICAL_FALLBACK_MESSAGE =
  "Non ho abbastanza dati concreti per darti un'indicazione medica specifica — se hai dubbi " +
  "di salute, parlane con un professionista.";

const CONCERNING_SIGNAL_SUFFIX =
  " Se questo pattern persiste, potrebbe valere la pena parlarne con un professionista.";

interface SafetyResult {
  suggestion: FocusSuggestion;
  modelCategory: string;
  finalCategory: string;
  action: "passthrough" | "modified";
  classifierFailed: boolean;
  classifierLatencyMs: number;
  classifierTokenInput: number | null;
  classifierTokenOutput: number | null;
}

async function applySafetyLayer(
  suggestion: FocusSuggestion,
  geminiApiKey: string,
): Promise<SafetyResult> {
  const modelCategory = suggestion.safety_category;
  const combinedText = `${suggestion.observation} ${suggestion.recommendation}`;

  const ruleFlag = ruleBasedDiagnosisFlag(combinedText);
  const classifierResult = await classifyIndependently(
    suggestion.observation,
    suggestion.recommendation,
    geminiApiKey,
  );
  const independentCategory = classifierResult.category;

  let finalCategory: string;
  if (ruleFlag || modelCategory === "diagnosis_treatment" || independentCategory === "diagnosis_treatment") {
    finalCategory = "diagnosis_treatment";
  } else if (modelCategory === "concerning_signal" || independentCategory === "concerning_signal") {
    finalCategory = "concerning_signal";
  } else if (modelCategory === "medical_information" || independentCategory === "medical_information") {
    finalCategory = "medical_information";
  } else {
    finalCategory = "wellness_recommendation";
  }

  let finalSuggestion = suggestion;
  let action: "passthrough" | "modified" = "passthrough";

  if (finalCategory === "diagnosis_treatment") {
    finalSuggestion = { ...suggestion, recommendation: DIAGNOSIS_FALLBACK_MESSAGE, safety_category: finalCategory };
    action = "modified";
  } else if (finalCategory === "medical_information") {
    // "Grounded" means the medical claim is actually tied to the user's
    // uploaded document — not just "the model listed some evidence".
    // Evidence citing routine/plant data isn't medical grounding.
    const grounded = suggestion.evidence.length > 0 && suggestion.sources.includes("user_document");
    if (!grounded) {
      finalSuggestion = {
        ...suggestion,
        recommendation: UNGROUNDED_MEDICAL_FALLBACK_MESSAGE,
        safety_category: finalCategory,
      };
      action = "modified";
    } else {
      finalSuggestion = { ...suggestion, safety_category: finalCategory };
    }
  } else if (finalCategory === "concerning_signal") {
    finalSuggestion = {
      ...suggestion,
      recommendation: suggestion.recommendation + CONCERNING_SIGNAL_SUFFIX,
      safety_category: finalCategory,
    };
    action = "modified";
  } else {
    finalSuggestion = { ...suggestion, safety_category: finalCategory };
  }

  return {
    suggestion: finalSuggestion,
    modelCategory,
    finalCategory,
    action,
    classifierFailed: classifierResult.failed,
    classifierLatencyMs: classifierResult.latencyMs,
    classifierTokenInput: classifierResult.tokenInput,
    classifierTokenOutput: classifierResult.tokenOutput,
  };
}

// --- Biological age (PhenoAge) ---------------------------------------------
// Levine BS, et al. "An epigenetic biomarker of aging for lifespan and
// healthspan." Aging (Albany NY). 2018;10(4):573-591. PMID 29676998.
// Formula/coefficients cross-checked against the published correction in
// Liu Z, et al. PLOS Medicine 2018 (PMID 30596641; correction notice PMCID
// PMC6388911) and an independent open-source reimplementation
// (github.com/KyteProject/phenotypic-age-calc) — both agree on every
// coefficient and on the two-step mortality-score transform below.
//
// This is the original blood-biomarker "Phenotypic Age", not the DNAm/
// epigenetic-clock variant of the same name (that one needs a methylation
// array, which we don't have).
//
// Deliberately NOT computed by the LLM: the 9 biomarker values are
// extracted from the document by Gemini (a text/vision-reading task, which
// is what it's good at), but the actual age arithmetic runs here in plain
// TypeScript. A hallucinated biomarker value or a hallucinated age would
// both be bad, but only one of those risks is worth taking — extraction
// errors are visible in `markers_used`/`markers_missing` and self-correct
// on a clearer document; a silently-wrong LLM-computed age would not be.

type BiomarkerKey =
  | "albumin"
  | "creatinine"
  | "glucose"
  | "crp"
  | "lymphocyte_percent"
  | "mcv"
  | "rdw"
  | "alkaline_phosphatase"
  | "wbc";

const BIOMARKER_KEYS: BiomarkerKey[] = [
  "albumin",
  "creatinine",
  "glucose",
  "crp",
  "lymphocyte_percent",
  "mcv",
  "rdw",
  "alkaline_phosphatase",
  "wbc",
];

const BIOMARKER_LABELS: Record<BiomarkerKey, string> = {
  albumin: "Albumina",
  creatinine: "Creatinina",
  glucose: "Glicemia",
  crp: "PCR (proteina C-reattiva)",
  lymphocyte_percent: "Linfociti (%)",
  mcv: "MCV (volume corpuscolare medio)",
  rdw: "RDW (ampiezza di distribuzione eritrocitaria)",
  alkaline_phosphatase: "Fosfatasi alcalina",
  wbc: "Globuli bianchi (WBC)",
};

// Unit strings as they realistically appear on a referto, mapped to the
// multiplier that converts the extracted value into the unit the formula
// needs. An unrecognized unit is never guessed at — that marker is treated
// as missing rather than silently mis-converted, since a wrong conversion
// here would silently produce a bogus age, which is worse than an honest
// "not enough data".
const UNIT_CONVERSIONS: Record<BiomarkerKey, Record<string, number>> = {
  albumin: { "g/dl": 10, "g/l": 1 }, // -> g/L
  creatinine: { "mg/dl": 88.401, "umol/l": 1, "µmol/l": 1 }, // -> umol/L
  glucose: { "mg/dl": 0.0555, "mmol/l": 1 }, // -> mmol/L
  crp: { "mg/l": 0.1, "mg/dl": 1 }, // -> mg/dL (formula uses ln(CRP mg/dL))
  lymphocyte_percent: { "%": 1 },
  mcv: { "fl": 1 },
  rdw: { "%": 1 },
  alkaline_phosphatase: { "u/l": 1, "iu/l": 1 },
  wbc: { "10^3/ul": 1, "10^3/µl": 1, "x10^9/l": 1, "10^9/l": 1, "k/ul": 1 },
};

function normalizeUnit(raw: string): string {
  return raw.trim().toLowerCase().replace(/\s+/g, "");
}

interface ExtractedField {
  value: number;
  unit: string;
}

interface ExtractedBiomarkers {
  is_blood_panel: boolean;
  report_date: string | null;
  [key: string]: unknown;
}

// Converts each extracted field to the formula's required unit, dropping
// (not guessing at) anything with an unrecognized unit.
function normalizeMarkers(extracted: ExtractedBiomarkers): {
  values: Partial<Record<BiomarkerKey, number>>;
  used: BiomarkerKey[];
  missing: BiomarkerKey[];
} {
  const values: Partial<Record<BiomarkerKey, number>> = {};
  const used: BiomarkerKey[] = [];
  const missing: BiomarkerKey[] = [];

  for (const key of BIOMARKER_KEYS) {
    const field = extracted[key] as ExtractedField | null | undefined;
    if (!field || typeof field.value !== "number" || typeof field.unit !== "string") {
      missing.push(key);
      continue;
    }
    const factor = UNIT_CONVERSIONS[key][normalizeUnit(field.unit)];
    if (factor === undefined) {
      missing.push(key);
      continue;
    }
    values[key] = field.value * factor;
    used.push(key);
  }

  return { values, used, missing };
}

const PHENOAGE_INTERCEPT = -19.907;
const PHENOAGE_COEFFICIENTS: Record<BiomarkerKey, number> = {
  albumin: -0.0336,
  creatinine: 0.0095,
  glucose: 0.1953,
  crp: 0.0954, // applied to ln(CRP), not CRP directly — see computePhenoAge
  lymphocyte_percent: -0.0120,
  mcv: 0.0268,
  rdw: 0.3306,
  alkaline_phosphatase: 0.00188,
  wbc: 0.0554,
};
const PHENOAGE_AGE_COEFFICIENT = 0.0804;
const PHENOAGE_GAMMA = -1.51714;
const PHENOAGE_LAMBDA = 0.0076927;
const PHENOAGE_ALPHA = 141.50225;
const PHENOAGE_BETA = -0.00553;
const PHENOAGE_FINAL_DIVISOR = 0.09165;

function computePhenoAge(values: Record<BiomarkerKey, number>, chronologicalAgeYears: number): number {
  let xb = PHENOAGE_INTERCEPT + PHENOAGE_AGE_COEFFICIENT * chronologicalAgeYears;
  for (const key of BIOMARKER_KEYS) {
    const v = values[key];
    xb += PHENOAGE_COEFFICIENTS[key] * (key === "crp" ? Math.log(v) : v);
  }

  const mortalityScore = 1 - Math.exp((PHENOAGE_GAMMA * Math.exp(xb)) / PHENOAGE_LAMBDA);
  return PHENOAGE_ALPHA + Math.log(PHENOAGE_BETA * Math.log(1 - mortalityScore)) / PHENOAGE_FINAL_DIVISOR;
}

const BIOMARKER_FIELD_SCHEMA = {
  type: "OBJECT",
  nullable: true,
  properties: {
    value: { type: "NUMBER" },
    unit: { type: "STRING" },
  },
  required: ["value", "unit"],
};

const BIOMARKER_EXTRACTION_SCHEMA = {
  type: "OBJECT",
  properties: {
    is_blood_panel: { type: "BOOLEAN" },
    report_date: { type: "STRING", nullable: true },
    albumin: BIOMARKER_FIELD_SCHEMA,
    creatinine: BIOMARKER_FIELD_SCHEMA,
    glucose: BIOMARKER_FIELD_SCHEMA,
    crp: BIOMARKER_FIELD_SCHEMA,
    lymphocyte_percent: BIOMARKER_FIELD_SCHEMA,
    mcv: BIOMARKER_FIELD_SCHEMA,
    rdw: BIOMARKER_FIELD_SCHEMA,
    alkaline_phosphatase: BIOMARKER_FIELD_SCHEMA,
    wbc: BIOMARKER_FIELD_SCHEMA,
  },
  required: ["is_blood_panel"],
};

const BIOMARKER_EXTRACTION_PROMPT = `Sei un estrattore di dati di laboratorio. Ricevi un documento.
Il tuo compito, in ordine:
1. Determina se il documento è un pannello di analisi del sangue (esami ematici/emocromo/analisi cliniche).
2. Se lo è, estrai SOLO i seguenti valori se presenti nel documento, con il valore numerico e l'unità
   di misura ESATTAMENTE come scritti nel referto (es. "g/dL", "mg/dL", "mg/L", "fL", "%", "U/L",
   "10^3/uL") — non convertire le unità, non calcolare nulla, non stimare un valore che non vedi scritto.
   Se un valore non è nel documento, ometti quel campo.
   - Albumina
   - Creatinina
   - Glicemia
   - PCR / proteina C-reattiva
   - Linfociti (%)
   - MCV (volume corpuscolare medio)
   - RDW (ampiezza di distribuzione eritrocitaria)
   - Fosfatasi alcalina
   - Globuli bianchi / leucociti (WBC)
3. Se la data del referto è scritta nel documento, riportala così com'è (report_date). Altrimenti null.
Non inventare mai un valore, un'unità o una data che non sono scritti nel documento.`;

interface BiologicalAgeResult {
  computed: boolean;
  phenotypic_age_years?: number;
  chronological_age_years?: number;
  markers_used?: string[];
  markers_missing?: string[];
  source_document?: string;
  source_date?: string;
  reason?: string;
}

interface BiomarkerExtractionOutcome {
  result: BiologicalAgeResult | null; // null: no document, or document isn't a blood panel
  latencyMs: number;
  tokenInput: number | null;
  tokenOutput: number | null;
}

async function extractBiologicalAge(
  base64Data: string,
  mimeType: string,
  documentLabel: string,
  birthDate: string | null,
  apiKey: string,
): Promise<BiomarkerExtractionOutcome> {
  const startTime = Date.now();
  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{
            parts: [
              { text: BIOMARKER_EXTRACTION_PROMPT },
              { inline_data: { mime_type: mimeType, data: base64Data } },
            ],
          }],
          generationConfig: {
            responseMimeType: "application/json",
            responseSchema: BIOMARKER_EXTRACTION_SCHEMA,
          },
        }),
      },
    );
    const latencyMs = Date.now() - startTime;

    if (!response.ok) {
      return { result: null, latencyMs, tokenInput: null, tokenOutput: null };
    }

    const data = await response.json();
    const tokenInput = data.usageMetadata?.promptTokenCount ?? null;
    const tokenOutput = data.usageMetadata?.candidatesTokenCount ?? null;
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;

    if (typeof text !== "string") {
      return { result: null, latencyMs, tokenInput, tokenOutput };
    }

    const extracted = JSON.parse(text) as ExtractedBiomarkers;
    if (!extracted.is_blood_panel) {
      return { result: null, latencyMs, tokenInput, tokenOutput };
    }

    const { values, used, missing } = normalizeMarkers(extracted);

    if (!birthDate) {
      return {
        result: {
          computed: false,
          markers_used: used.map((k) => BIOMARKER_LABELS[k]),
          markers_missing: missing.map((k) => BIOMARKER_LABELS[k]),
          reason: "Manca la data di nascita in Profilo — necessaria per calcolare l'età biologica " +
            "anche quando tutti i biomarcatori sono disponibili.",
        },
        latencyMs,
        tokenInput,
        tokenOutput,
      };
    }

    const sourceDate = extracted.report_date ?? undefined;

    if (missing.length > 0) {
      return {
        result: {
          computed: false,
          markers_used: used.map((k) => BIOMARKER_LABELS[k]),
          markers_missing: missing.map((k) => BIOMARKER_LABELS[k]),
          source_document: documentLabel,
          source_date: sourceDate,
          reason: `Servono tutti e 9 i biomarcatori per una stima PhenoAge — ne mancano ` +
            `${missing.length} dal documento più recente.`,
        },
        latencyMs,
        tokenInput,
        tokenOutput,
      };
    }

    const chronologicalAgeYears =
      (Date.now() - new Date(birthDate).getTime()) / (365.25 * 24 * 60 * 60 * 1000);
    const phenotypicAge = computePhenoAge(values as Record<BiomarkerKey, number>, chronologicalAgeYears);

    return {
      result: {
        computed: true,
        phenotypic_age_years: Math.round(phenotypicAge * 10) / 10,
        chronological_age_years: Math.round(chronologicalAgeYears * 10) / 10,
        markers_used: used.map((k) => BIOMARKER_LABELS[k]),
        source_document: documentLabel,
        source_date: sourceDate,
      },
      latencyMs,
      tokenInput,
      tokenOutput,
    };
  } catch {
    return { result: null, latencyMs: Date.now() - startTime, tokenInput: null, tokenOutput: null };
  }
}

const MAX_DOCUMENT_BYTES = 15 * 1024 * 1024;

function toBase64(bytes: Uint8Array): string {
  let binary = "";
  const chunkSize = 0x8000;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunkSize));
  }
  return btoa(binary);
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// Metadata-only telemetry — never the prompt, digest, or suggestion text.
// Latency/tokens are pipeline totals (generation call + independent safety
// classifier call), so cost tracking reflects what a request actually costs.
async function logLlmCall(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  params: {
    userId: string;
    latencyMs: number;
    tokenInput: number | null;
    tokenOutput: number | null;
    error: string | null;
    safetyCategory: string | null;
    rateLimited?: boolean;
  },
) {
  const estimatedCost =
    params.tokenInput != null && params.tokenOutput != null
      ? estimateCostUsd(params.tokenInput, params.tokenOutput)
      : null;

  const { error: logError } = await supabase.from("llm_call_logs").insert({
    user_id: params.userId,
    model: GEMINI_MODEL,
    prompt_version: PROMPT_VERSION,
    latency_ms: params.latencyMs,
    token_input: params.tokenInput,
    token_output: params.tokenOutput,
    estimated_cost_usd: estimatedCost,
    error: params.error,
    safety_category: params.safetyCategory,
    rate_limited: params.rateLimited ?? false,
  });
  if (logError) console.error("llm_call_logs insert failed:", logError.message);
}

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Missing Authorization header" }, 401);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  // --- Rate limiting -----------------------------------------------------
  // Gemini Flash's free tier caps the whole PROJECT at 20 requests/day —
  // shared across every user of the app, not per-user. Each focus-del-
  // giorno request can itself make up to 3 Gemini calls (generation +
  // independent safety classifier + biomarker extraction when a document
  // is attached), so one user hammering this endpoint (a UI bug causing a
  // retry loop, or just impatient tapping) can burn the shared daily quota
  // for everyone else in a handful of requests. 10/user/day leaves
  // headroom under the project cap even in the worst case (every request
  // has a document attached, i.e. 3 Gemini calls each) while still being
  // generous for what's meant to be a once-or-a-few-times-a-day suggestion.
  const RATE_LIMIT_PER_USER_PER_DAY = 10;
  const rateLimitWindowStart = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

  const { count: recentRequestCount, error: rateLimitCheckError } = await supabase
    .from("llm_call_logs")
    .select("*", { count: "exact", head: true })
    .eq("user_id", user.id)
    .eq("rate_limited", false) // only count actual attempted Gemini calls, not prior blocks
    .gte("created_at", rateLimitWindowStart);

  if (rateLimitCheckError) {
    // Fail-open on the check itself failing (e.g. a transient DB issue) —
    // the alternative is taking down the whole feature over an unrelated
    // outage. Failing open on the *check* is not the same risk as failing
    // open on the safety classifier: worst case here is a few extra
    // requests on a bad day, not an unvetted medical claim reaching a user.
    console.error("Rate limit check failed:", rateLimitCheckError.message);
  } else if ((recentRequestCount ?? 0) >= RATE_LIMIT_PER_USER_PER_DAY) {
    await logLlmCall(supabase, {
      userId: user.id,
      latencyMs: 0,
      tokenInput: null,
      tokenOutput: null,
      error: "rate_limited",
      safetyCategory: null,
      rateLimited: true,
    });
    return jsonResponse(
      { error: `Hai raggiunto il limite di ${RATE_LIMIT_PER_USER_PER_DAY} richieste al giorno per il Focus del giorno. Riprova domani.` },
      429,
    );
  }

  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    .toISOString()
    .slice(0, 10);

  const [
    { data: completions },
    { data: plants },
    { data: profile },
    { data: latestDocument },
    { data: cycleStarts },
    { data: recentSleep },
    { data: supplementIntake },
    { data: currentFasting },
    { data: recentFastWindows },
    { data: stepNotes },
    { data: supplementNotes },
  ] = await Promise.all([
      supabase
        .from("routine_completions")
        .select("step_id, completed_on")
        .eq("user_id", user.id)
        .gte("completed_on", sevenDaysAgo),
      supabase
        .from("plant_diversity_logs")
        .select("plant_name")
        .eq("user_id", user.id)
        .gte("logged_on", sevenDaysAgo),
      supabase
        .from("profiles")
        .select("narrative_summary, approach, sex, birth_date, fasting_enabled")
        .eq("user_id", user.id)
        .maybeSingle(),
      supabase
        .from("user_documents")
        .select("storage_path, mime_type, label")
        .eq("user_id", user.id)
        .order("uploaded_at", { ascending: false })
        .limit(1)
        .maybeSingle(),
      supabase
        .from("menstrual_cycle_logs")
        .select("period_start_date")
        .eq("user_id", user.id)
        .order("period_start_date", { ascending: false })
        .limit(6),
      supabase
        .from("sleep_logs")
        .select("bedtime, wake_time")
        .eq("user_id", user.id)
        .order("sleep_date", { ascending: false })
        .limit(7),
      supabase
        .from("supplement_intake_logs")
        .select("taken_on, user_supplements(name, category)")
        .eq("user_id", user.id)
        .gte("taken_on", sevenDaysAgo),
      supabase
        .from("fasting_logs")
        .select("first_meal_time, last_meal_time")
        .eq("user_id", user.id)
        .maybeSingle(),
      supabase
        .from("fasting_windows")
        .select("kind, started_at, ended_at")
        .eq("user_id", user.id)
        .eq("kind", "fast")
        .gte("started_at", sevenDaysAgo),
      supabase
        .from("routine_step_notes")
        .select("step_id, note")
        .eq("user_id", user.id)
        .neq("note", ""),
      supabase
        .from("supplement_notes")
        .select("supplement_id, note")
        .eq("user_id", user.id)
        .neq("note", ""),
    ]);

  const stepCounts = new Map<string, number>();
  for (const row of completions ?? []) {
    stepCounts.set(row.step_id, (stepCounts.get(row.step_id) ?? 0) + 1);
  }

  const digestLines = [
    `Routine (mattutina e serale, ultimi 7 giorni, su 7 possibili):`,
    ...[...stepCounts.entries()].map(([step, count]) => `- ${step}: ${count}/7`),
    ``,
    `Diversità vegetale: ${new Set((plants ?? []).map((p) => p.plant_name)).size} piante uniche negli ultimi 7 giorni (obiettivo 30/settimana).`,
  ];

  const APPROACH_LABELS: Record<string, string> = {
    natural: "preferisce un approccio naturale/plastic-free (es. zenzero, semi di chia, olio EVO, " +
      "frutti rossi, golden milk) rispetto a integratori mirati da laboratorio",
    scientific: "preferisce un approccio scientifico/da ricerca (es. integratori mirati come NAD+ " +
      "o urolitina) rispetto a rimedi naturali generici",
    balanced: "non ha una preferenza marcata tra rimedi naturali e integratori mirati da ricerca",
  };
  if (profile?.approach && APPROACH_LABELS[profile.approach]) {
    digestLines.push(``, `Preferenza dell'utente: ${APPROACH_LABELS[profile.approach]}.`);
  }

  if (profile?.sex === "female" && cycleStarts && cycleStarts.length > 0) {
    const starts = cycleStarts.map((row) => new Date(row.period_start_date));
    const lastStart = starts[0];
    const cycleDay = Math.floor((Date.now() - lastStart.getTime()) / (24 * 60 * 60 * 1000)) + 1;

    let avgLength = 28;
    if (starts.length >= 2) {
      const diffs: number[] = [];
      for (let i = 0; i < starts.length - 1; i++) {
        diffs.push(Math.round((starts[i].getTime() - starts[i + 1].getTime()) / (24 * 60 * 60 * 1000)));
      }
      avgLength = Math.round(diffs.reduce((a, b) => a + b, 0) / diffs.length);
    }

    const ovulationDay = avgLength - 14;
    let phase: string;
    if (cycleDay <= 5) phase = "mestruale";
    else if (cycleDay < ovulationDay - 1) phase = "follicolare";
    else if (cycleDay <= ovulationDay + 1) phase = "ovulazione";
    else phase = "luteale";

    digestLines.push(``, `Ciclo mestruale: giorno ${cycleDay}, fase stimata ${phase} (ciclo medio ${avgLength} giorni).`);
  }

  if (recentSleep && recentSleep.length >= 2) {
    // sleep_logs.wake_time is `timestamp` (no timezone) — a wall-clock value,
    // not an instant. PostgREST returns it as a zone-less string (e.g.
    // "2026-08-10T07:00:00"), which the JS Date constructor parses as local
    // time to *this* runtime. Supabase Edge Functions run in UTC, so
    // local-to-runtime = UTC and getUTCHours() recovers the original digits
    // exactly. (Same circular-arc logic as the Flutter client in
    // today_screen.dart — a plain max-min breaks near midnight.)
    const minutesOfDay = recentSleep
      .map((row) => {
        const t = new Date(row.wake_time);
        return t.getUTCHours() * 60 + t.getUTCMinutes();
      })
      .sort((a, b) => a - b);

    const dayMinutes = 24 * 60;
    let largestGap = 0;
    for (let i = 0; i < minutesOfDay.length; i++) {
      const next = i + 1 < minutesOfDay.length ? minutesOfDay[i + 1] : minutesOfDay[0] + dayMinutes;
      const gap = next - minutesOfDay[i];
      if (gap > largestGap) largestGap = gap;
    }
    const variability = dayMinutes - largestGap;
    const hours = Math.floor(variability / 60);
    const minutes = variability % 60;
    digestLines.push(
      ``,
      `Ritmo circadiano: orario di sveglia variabile di ${hours}h${minutes}m negli ultimi ${recentSleep.length} giorni tracciati.`,
    );
  }

  // --- Foundations check (Bryan Johnson's stated priority order: sleep >
  // exercise > diet > supplements > experimental) ---------------------------
  // Recommending an advanced optimization (a supplement, an experimental
  // protocol) while a basic pillar is clearly off track is the opposite of
  // what a good coach would do — it's optimizing the margins while ignoring
  // the foundation. This computes which pillars are off target from data
  // we already query, and the prompt is told to prioritize *that* over
  // anything more advanced when one is off. Deliberately not a rules
  // engine: three simple, transparent checks, not a scored/weighted model.
  const offTargetFoundations: string[] = [];

  if (recentSleep && recentSleep.length > 0) {
    const durationsHours = recentSleep
      .map((row) => {
        // Same wall-clock-as-UTC interpretation as the variability check
        // above — both columns are `timestamp` (no timezone).
        const bed = new Date(row.bedtime).getTime();
        const wake = new Date(row.wake_time).getTime();
        return (wake - bed) / (1000 * 60 * 60);
      })
      .filter((h) => h > 0 && h < 16); // discard obviously-bad rows, not guess at them
    if (durationsHours.length > 0) {
      const avgHours = durationsHours.reduce((a, b) => a + b, 0) / durationsHours.length;
      if (avgHours < 7) {
        const h = Math.floor(avgHours);
        const m = Math.round((avgHours - h) * 60);
        offTargetFoundations.push(
          `sonno sotto target (media ${h}h${m}m/notte su ${durationsHours.length} notti tracciate, obiettivo 7-9h)`,
        );
      }
    }
  }

  if (stepCounts.size === 0) {
    offTargetFoundations.push("routine mattutina/serale non tracciata negli ultimi 7 giorni");
  } else {
    const avgCompletionRate =
      [...stepCounts.values()].reduce((a, b) => a + b, 0) / (stepCounts.size * 7);
    if (avgCompletionRate < 0.5) {
      offTargetFoundations.push(
        `routine mattutina/serale completata meno della metà dei giorni (${Math.round(avgCompletionRate * 100)}%)`,
      );
    }
  }

  if (profile?.fasting_enabled) {
    // Live state first — the AI should know *right now* whether the user
    // is mid-fast or mid-eating-window, not just a 7-day average.
    const firstMeal = currentFasting?.first_meal_time ? new Date(currentFasting.first_meal_time) : null;
    const lastMeal = currentFasting?.last_meal_time ? new Date(currentFasting.last_meal_time) : null;
    const isEating = firstMeal !== null && (lastMeal === null || firstMeal > lastMeal);
    const phaseStart = isEating ? firstMeal : lastMeal;
    if (phaseStart) {
      const elapsedHours = (Date.now() - phaseStart.getTime()) / (1000 * 60 * 60);
      digestLines.push(
        ``,
        isEating
          ? `Digiuno: attualmente in finestra alimentare da ${elapsedHours.toFixed(1)}h (obiettivo finestra 8h).`
          : `Digiuno: attualmente in corso da ${elapsedHours.toFixed(1)}h (obiettivo 16h).`,
      );
    }

    // Then the trend — real completed-window durations (see migration
    // 0031), not a fragile reconstruction from day-keyed rows.
    if (recentFastWindows && recentFastWindows.length > 0) {
      const windowHours = recentFastWindows
        .map((w) => (new Date(w.ended_at).getTime() - new Date(w.started_at).getTime()) / (1000 * 60 * 60))
        .filter((hours) => hours > 0 && hours < 30); // discard bad data, don't guess at it
      if (windowHours.length > 0) {
        const avgWindow = windowHours.reduce((a, b) => a + b, 0) / windowHours.length;
        if (avgWindow < 12) {
          offTargetFoundations.push(
            `finestra di digiuno sotto l'obiettivo (media ${avgWindow.toFixed(1)}h su ${windowHours.length} finestre completate negli ultimi 7 giorni, obiettivo 16h)`,
          );
        }
      }
    }
  }

  if (offTargetFoundations.length > 0) {
    digestLines.push(
      ``,
      `Fondamenta di base fuori target: ${offTargetFoundations.join("; ")}.`,
    );
  }

  if (supplementIntake && supplementIntake.length > 0) {
    const nameCounts = new Map<string, number>();
    for (const row of supplementIntake) {
      // deno-lint-ignore no-explicit-any
      const supplement = row.user_supplements as any;
      if (!supplement) continue;
      const label = `${supplement.name} (${supplement.category === "scientific" ? "scientifico" : "naturale"})`;
      nameCounts.set(label, (nameCounts.get(label) ?? 0) + 1);
    }
    if (nameCounts.size > 0) {
      digestLines.push(
        ``,
        `Integratori assunti negli ultimi 7 giorni:`,
        ...[...nameCounts.entries()].map(([label, count]) => `- ${label}: ${count}/7`),
      );
    }
  }

  const personalNotes = [
    ...(stepNotes ?? []).map((row) => `- ${row.step_id}: ${row.note}`),
    ...(supplementNotes ?? []).map((row) => `- ${row.supplement_id}: ${row.note}`),
  ];
  if (personalNotes.length > 0) {
    digestLines.push(``, `Note personali dell'utente su pratiche/integratori specifici:`, ...personalNotes);
  }

  if (profile?.narrative_summary) {
    digestLines.push(``, `Note aggiuntive sull'utente: ${profile.narrative_summary}`);
  }

  const digest = digestLines.join("\n");

  const parts: Record<string, unknown>[] = [{ text: `${SYSTEM_PROMPT}\n\n${digest}` }];

  let documentBase64: string | null = null;

  if (latestDocument) {
    const { data: fileBlob, error: downloadError } = await supabase.storage
      .from("user-documents")
      .download(latestDocument.storage_path);

    if (!downloadError && fileBlob && fileBlob.size <= MAX_DOCUMENT_BYTES) {
      const bytes = new Uint8Array(await fileBlob.arrayBuffer());
      documentBase64 = toBase64(bytes);
      parts.push({
        inline_data: { mime_type: latestDocument.mime_type, data: documentBase64 },
      });
    }
  }

  const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
  if (!geminiApiKey) {
    return jsonResponse({ error: "GEMINI_API_KEY not configured" }, 500);
  }

  const startTime = Date.now();

  // Biomarker extraction reads the same document independently of the main
  // suggestion generation — it doesn't need the generated observation, so
  // it runs concurrently rather than after, to not add latency on top of
  // the main call.
  const biomarkerExtractionPromise = documentBase64
    ? extractBiologicalAge(
      documentBase64,
      latestDocument!.mime_type,
      latestDocument!.label,
      profile?.birth_date ?? null,
      geminiApiKey,
    )
    : Promise.resolve<BiomarkerExtractionOutcome>({
      result: null,
      latencyMs: 0,
      tokenInput: null,
      tokenOutput: null,
    });

  const [geminiResponse, biomarkerOutcome] = await Promise.all([
    fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${geminiApiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts }],
          generationConfig: {
            responseMimeType: "application/json",
            responseSchema: RESPONSE_SCHEMA,
          },
        }),
      },
    ),
    biomarkerExtractionPromise,
  ]);

  if (!geminiResponse.ok) {
    const errorText = await geminiResponse.text();
    await logLlmCall(supabase, {
      userId: user.id,
      latencyMs: Date.now() - startTime,
      tokenInput: null,
      tokenOutput: null,
      error: `Gemini HTTP ${geminiResponse.status}`,
      safetyCategory: null,
    });
    return jsonResponse({ error: `Gemini error: ${errorText}` }, 502);
  }

  const geminiData = await geminiResponse.json();
  const latencyMs = Date.now() - startTime;
  const tokenInput = geminiData.usageMetadata?.promptTokenCount ?? null;
  const tokenOutput = geminiData.usageMetadata?.candidatesTokenCount ?? null;
  const rawText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;

  if (typeof rawText !== "string") {
    await logLlmCall(supabase, {
      userId: user.id,
      latencyMs,
      tokenInput,
      tokenOutput,
      error: "Gemini returned no content",
      safetyCategory: null,
    });
    return jsonResponse({ error: "Gemini returned no content" }, 502);
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(rawText);
  } catch {
    await logLlmCall(supabase, {
      userId: user.id,
      latencyMs,
      tokenInput,
      tokenOutput,
      error: "Gemini returned invalid JSON",
      safetyCategory: null,
    });
    return jsonResponse({ error: "Gemini returned invalid JSON" }, 502);
  }

  const validation = validateSuggestion(parsed);
  if (!validation.ok) {
    // Explicit, visible failure — never silently pass through a malformed
    // suggestion to the client.
    await logLlmCall(supabase, {
      userId: user.id,
      latencyMs,
      tokenInput,
      tokenOutput,
      error: `Invalid suggestion schema: ${validation.reason}`,
      safetyCategory: null,
    });
    return jsonResponse({ error: `Invalid suggestion schema: ${validation.reason}` }, 502);
  }

  const safetyResult = await applySafetyLayer(validation.value, geminiApiKey);

  // Pipeline totals — generation + independent safety classifier + (when a
  // document was attached) biomarker extraction. A per-request cost/latency
  // figure that silently excludes any of these understates the real cost.
  await logLlmCall(supabase, {
    userId: user.id,
    latencyMs: latencyMs + safetyResult.classifierLatencyMs + biomarkerOutcome.latencyMs,
    tokenInput: tokenInput != null || safetyResult.classifierTokenInput != null || biomarkerOutcome.tokenInput != null
      ? (tokenInput ?? 0) + (safetyResult.classifierTokenInput ?? 0) + (biomarkerOutcome.tokenInput ?? 0)
      : null,
    tokenOutput: tokenOutput != null || safetyResult.classifierTokenOutput != null || biomarkerOutcome.tokenOutput != null
      ? (tokenOutput ?? 0) + (safetyResult.classifierTokenOutput ?? 0) + (biomarkerOutcome.tokenOutput ?? 0)
      : null,
    error: null,
    safetyCategory: safetyResult.finalCategory,
  });

  // Fire-and-forget-ish, but awaited so a logging failure doesn't silently
  // vanish from server logs — it just doesn't block the response either way.
  const { error: safetyLogError } = await supabase.from("safety_events").insert({
    user_id: user.id,
    model_category: safetyResult.modelCategory,
    final_category: safetyResult.finalCategory,
    action: safetyResult.action,
    classifier_failed: safetyResult.classifierFailed,
  });
  if (safetyLogError) console.error("safety_events insert failed:", safetyLogError.message);

  return jsonResponse({
    suggestion: safetyResult.suggestion,
    // A biological-age estimate is never a diagnosis and is always
    // presented as medical_information, regardless of what the day's
    // actual "focus" suggestion is about — it's deterministic, cited data,
    // not model discretion, so there's nothing here for the safety
    // classifier to mis-categorize.
    biological_age: biomarkerOutcome.result,
  });
});
