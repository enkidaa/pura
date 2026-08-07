// Edge Function: builds a compact digest of the user's recent data and asks
// Gemini Flash for a personalized "focus del giorno" suggestion. The Gemini
// API key lives only here (Supabase secret), never in the Flutter app.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GEMINI_MODEL = "gemini-flash-latest";

const SYSTEM_PROMPT = `Sei l'assistente di Pura, un'app di benessere personale.
Ricevi un riassunto compatto delle abitudini recenti dell'utente (routine mattutina,
diversità vegetale settimanale). Il tuo compito: scrivere UN SOLO consiglio breve
("focus del giorno"), concreto e motivante, in italiano, basato sui dati forniti.
Non inventare dati che non ti sono stati dati. Massimo 3 frasi. Nessun elenco puntato.`;

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    .toISOString()
    .slice(0, 10);

  const [{ data: completions }, { data: plants }, { data: profile }] = await Promise.all([
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
      .select("narrative_summary")
      .eq("user_id", user.id)
      .maybeSingle(),
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

  if (profile?.narrative_summary) {
    digestLines.push(``, `Note aggiuntive sull'utente: ${profile.narrative_summary}`);
  }

  const digest = digestLines.join("\n");

  const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
  if (!geminiApiKey) {
    return new Response(JSON.stringify({ error: "GEMINI_API_KEY not configured" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const geminiResponse = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${geminiApiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: `${SYSTEM_PROMPT}\n\n${digest}` }] }],
      }),
    },
  );

  if (!geminiResponse.ok) {
    const errorText = await geminiResponse.text();
    return new Response(JSON.stringify({ error: `Gemini error: ${errorText}` }), {
      status: 502,
      headers: { "Content-Type": "application/json" },
    });
  }

  const geminiData = await geminiResponse.json();
  const suggestion = geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

  return new Response(JSON.stringify({ suggestion }), {
    headers: { "Content-Type": "application/json" },
  });
});
