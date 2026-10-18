import 'package:coach_vasca/features/calendario_telefono/domain/indirizzi_calendario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const url = 'https://abc.supabase.co';
  const codice = '0123456789abcdef0123456789abcdef0123456789abcdef';

  test('l\'indirizzo https punta alla funzione calendario con il codice', () {
    expect(
      indirizzoCalendario(url, codice),
      'https://abc.supabase.co/functions/v1/calendario?c=$codice',
    );
  });

  test('uno slash finale nell\'indirizzo del progetto si ignora', () {
    expect(
      indirizzoCalendario('$url/', codice),
      indirizzoCalendario(url, codice),
    );
  });

  test('l\'indirizzo webcal cambia solo lo schema', () {
    expect(
      indirizzoWebcal(url, codice),
      'webcal://abc.supabase.co/functions/v1/calendario?c=$codice',
    );
    expect(indirizzoWebcal('$url/', codice), indirizzoWebcal(url, codice));
  });

  test('il collegamento a Google Calendar porta il webcal codificato', () {
    final google = indirizzoGoogleCalendar(url, codice);
    expect(
      google,
      'https://calendar.google.com/calendar/r?cid='
      'webcal%3A%2F%2Fabc.supabase.co%2Ffunctions%2Fv1%2Fcalendario'
      '%3Fc%3D$codice',
    );
    // Decodificato, il parametro è l'indirizzo webcal intero.
    expect(
      Uri.parse(google).queryParameters['cid'],
      indirizzoWebcal(url, codice),
    );
  });
}
