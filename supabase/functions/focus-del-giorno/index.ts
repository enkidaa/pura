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
- Se ti viene indicata la fase del ciclo mestruale, puoi usarla per contestualizzare energia/consigli
  (es. più riposo in fase mestruale, più energia in fase follicolare/ovulazione) ma solo se pertinente
  — non è un dato medico su cui basare diagnosi.
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
        .select("narrative_summary, approach, sex")
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
        .select("wake_time")
        .eq("user_id", user.id)
        .order("sleep_date", { ascending: false })
        .limit(7),
      supabase
        .from("supplement_intake_logs")
        .select("taken_on, user_supplements(name, category)")
        .eq("user_id", user.id)
        .gte("taken_on", sevenDaysAgo),
    ]);

  const stepCounts = new Map<string, number>();
  for (const row of completions ?? []) {
    stepCounts.set(row.step_id, (stepCounts.get(row.step_id) ?? 0) + 1);
  }

  const digestLines = [
    `Routine mattutina (ultimi 7 giorni, su 7 possibili):`,
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

  if (profile?.narrative_summary) {
    digestLines.push(``, `Note aggiuntive sull'utente: ${profile.narrative_summary}`);
  }

  const digest = digestLines.join("\n");

  const parts: Record<string, unknown>[] = [{ text: `${SYSTEM_PROMPT}\n\n${digest}` }];

  if (latestDocument) {
    const { data: fileBlob, error: downloadError } = await supabase.storage
      .from("user-documents")
      .download(latestDocument.storage_path);

    if (!downloadError && fileBlob && fileBlob.size <= MAX_DOCUMENT_BYTES) {
      const bytes = new Uint8Array(await fileBlob.arrayBuffer());
      parts.push({
        inline_data: { mime_type: latestDocument.mime_type, data: toBase64(bytes) },
      });
    }
  }

  const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
  if (!geminiApiKey) {
    return jsonResponse({ error: "GEMINI_API_KEY not configured" }, 500);
  }

  const startTime = Date.now();

  const geminiResponse = await fetch(
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
  );

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

  // Pipeline totals — the generation call plus the independent safety
  // classifier call, not just the first. A per-request cost/latency figure
  // that silently excludes the second LLM call understates the real cost.
  await logLlmCall(supabase, {
    userId: user.id,
    latencyMs: latencyMs + safetyResult.classifierLatencyMs,
    tokenInput: tokenInput != null || safetyResult.classifierTokenInput != null
      ? (tokenInput ?? 0) + (safetyResult.classifierTokenInput ?? 0)
      : null,
    tokenOutput: tokenOutput != null || safetyResult.classifierTokenOutput != null
      ? (tokenOutput ?? 0) + (safetyResult.classifierTokenOutput ?? 0)
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

  return jsonResponse({ suggestion: safetyResult.suggestion });
});
