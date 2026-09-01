// Edge Function: genera-allenamento
//
// Riceve i parametri raccolti dal form "Genera con AI" e li inoltra a
// Gemini, tenendo la API key lato server (mai esposta al client Flutter).
// Se in futuro si cambia provider AI, si riscrive solo questo file: il
// contratto verso l'app (corpo della richiesta e { testo } in risposta)
// resta invariato.

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-3.6-flash";

interface ParametriGenerazione {
  gruppo?: string;
  livello?: string;
  volumeMetri?: number;
  focus?: string;
  regimiAmmessi?: string[];
  vincoli?: string | null;
}

// Il browser (Flutter Web) chiama questa funzione da un'origine diversa
// (localhost in sviluppo, il dominio dell'app in produzione): senza questi
// header ogni richiesta viene bloccata dal CORS prima ancora di arrivare
// qui, con un errore di rete generico lato client ("Failed to fetch").
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

function costruisciPrompt(p: ParametriGenerazione): string {
  const regimi = Array.isArray(p.regimiAmmessi) ? p.regimiAmmessi.join(", ") : "";
  return [
    "Sei un allenatore di nuoto esperto. Genera una scheda di allenamento " +
      "per la seguente sessione.",
    `Gruppo: ${p.gruppo ?? ""}`,
    `Livello: ${p.livello ?? ""}`,
    `Volume totale: ${p.volumeMetri ?? ""} metri`,
    `Focus: ${p.focus ?? ""}`,
    `Regimi di allenamento ammessi: ${regimi}`,
    p.vincoli ? `Vincoli: ${p.vincoli}` : "",
    "Descrivi la scheda divisa in riscaldamento, parte principale e " +
      "defaticamento, con ripetute, distanze, stile ed esecuzione per ogni " +
      "serie.",
  ]
    .filter((riga) => riga.length > 0)
    .join("\n");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Metodo non supportato" }, 405);
  }

  if (!GEMINI_API_KEY) {
    return jsonResponse(
      { error: "GEMINI_API_KEY non configurata sul server" },
      500,
    );
  }

  let parametri: ParametriGenerazione;
  try {
    parametri = await req.json();
  } catch {
    return jsonResponse({ error: "Corpo della richiesta non valido" }, 400);
  }

  const prompt = costruisciPrompt(parametri);

  let rispostaGemini: Response;
  try {
    rispostaGemini = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
        }),
      },
    );
  } catch (errore) {
    return jsonResponse(
      { error: `Impossibile contattare il provider AI: ${errore}` },
      502,
    );
  }

  if (!rispostaGemini.ok) {
    const dettaglio = await rispostaGemini.text();
    return jsonResponse(
      { error: `Errore dal provider AI (${rispostaGemini.status}): ${dettaglio}` },
      502,
    );
  }

  const dati = await rispostaGemini.json();
  const testo = dati?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

  return jsonResponse({ testo });
});
