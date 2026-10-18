// Il nome dell'app che legge il calendario, da come si presenta
// (User-Agent): si mostra nella pagina "Partite nel calendario" per dire
// se il collegamento è riuscito. Solo un nome generico, mai il testo
// intero.

const APP: [RegExp, string][] = [
  [/google/i, "Google Calendar"],
  [/icsx|davx/i, "ICSx⁵ (Android)"],
  [/iphone|ipad|\bios\b|dataaccessd/i, "iPhone"],
  [/mac ?os|calendaragent|macintosh/i, "Mac"],
  [/outlook|microsoft|office/i, "Outlook"],
  [/thunderbird/i, "Thunderbird"],
  [/android/i, "Android"],
];

export function lettore(userAgent: string | null): string {
  const testo = userAgent ?? "";
  for (const [segno, nome] of APP) {
    if (segno.test(testo)) return nome;
  }
  return "un altro calendario";
}
