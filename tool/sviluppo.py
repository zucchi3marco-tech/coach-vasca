"""Anteprima di sviluppo su http://localhost:8802 con riavvio automatico.

Avvia `flutter run -d web-server` (debug: segnala in console i testi e
i riquadri che sbordano) e, ogni volta che un file in lib/ o .env cambia,
gli manda "r" (hot reload): la pagina si aggiorna restando sulla stessa schermata.
"""

import os
import subprocess
import sys
import threading
import time

RADICE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FLUTTER = r"C:\Users\emanu\flutter\bin\flutter.bat"


def impronta():
    totale = 0.0
    for cartella, _, file in os.walk(os.path.join(RADICE, "lib")):
        for nome in file:
            if nome.endswith(".dart"):
                totale += os.path.getmtime(os.path.join(cartella, nome))
    env = os.path.join(RADICE, ".env")
    if os.path.exists(env):
        totale += os.path.getmtime(env)
    return totale


def main():
    processo = subprocess.Popen(
        [FLUTTER, "run", "-d", "web-server", "--web-hostname", "localhost",
         "--web-port", "8802", "--no-pub"],
        cwd=RADICE,
        stdin=subprocess.PIPE,
        stdout=sys.stdout,
        stderr=sys.stderr,
        text=True,
    )

    def osserva():
        ultima = impronta()
        while processo.poll() is None:
            time.sleep(1)
            attuale = impronta()
            if attuale != ultima:
                ultima = attuale
                time.sleep(0.5)
                print("[sviluppo] modifica rilevata: hot reload", flush=True)
                processo.stdin.write("r")
                processo.stdin.flush()

    threading.Thread(target=osserva, daemon=True).start()
    sys.exit(processo.wait())


if __name__ == "__main__":
    main()

