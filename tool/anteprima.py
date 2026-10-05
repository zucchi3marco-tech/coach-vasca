"""Serve build/web su http://localhost:8801 senza cache del browser.

Con il server standard di Python il browser riusava il vecchio
main.dart.js anche dopo una nuova compilazione: qui ogni risposta dice
di non tenere copie, cosi' una ricarica mostra sempre l'ultima build.
"""

import functools
import http.server
import os

RADICE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CARTELLA = os.path.join(RADICE, "build", "web")


class Gestore(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".js": "text/javascript",
        ".mjs": "text/javascript",
    }

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        # Isolamento cross-origin: abilita SharedArrayBuffer, cosi' il
        # database locale (drift) usa la memoria veloce del browser (OPFS)
        # invece di IndexedDB, dove ogni schermata impiegava ~20 secondi.
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "credentialless")
        super().end_headers()


if __name__ == "__main__":
    server = http.server.ThreadingHTTPServer(
        ("127.0.0.1", 8801), functools.partial(Gestore, directory=CARTELLA)
    )
    print("Anteprima su http://localhost:8801", flush=True)
    server.serve_forever()
