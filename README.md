# Correzioni di KondoManager

Correzioni al sorgente di [KondoManager](https://github.com/vince844/kondomanager-free) e file per ricostruire le
immagini del programma che le porta. Versione a monte: v1.11.0, commit `4d825d2d0b34b62e8f7c8691dd39eab2e3197edb`.
Licenza: AGPL-3.0-or-later, come il programma (file `LICENSE`). Il deposito non contiene dati di persone né di studi.

## Che cosa c'è

| file | contenuto |
|---|---|
| `correzioni/*.patch` | una correzione per file, in formato `git diff`, con in testa il motivo; si applicano in ordine di nome |
| `versione.lock`, `composer.lock` | versione e commit a monte, e le librerie PHP alle versioni con cui si ricostruisce |
| `Dockerfile`, `.dockerignore`, `php.ini`, `supervisord.conf` | la costruzione delle due immagini (`app` e `web`) |
| `applica_correzioni.sh` | applica le patch di una cartella a un sorgente; si ferma se una non si applica o è già a monte |
| `sorgente_pubblico.sh` | porta il collegamento al sorgente delle pagine del programma a questo deposito |

La configurazione di nginx (`nginx.conf`) non è pubblicata: chi ricostruisce l'immagine `web` la scrive da sé, e il
`Dockerfile` la copia da `nginx.conf` nella cartella di costruzione.

## Ricostruire

1. Portare il sorgente a monte al commit di `versione.lock` in `sorgente/`:
   `git clone https://github.com/vince844/kondomanager-free sorgente && git -C sorgente checkout 4d825d2d0b34b62e8f7c8691dd39eab2e3197edb`
2. Scrivere `nginx.conf` accanto al `Dockerfile`.
3. Costruire le immagini, passando l'elenco delle patch che il `Dockerfile` applica:

       CORREZIONI="$(sh applica_correzioni.sh --elenco correzioni)"
       docker build --build-arg KONDO_COMMIT=4d825d2d0b34b62e8f7c8691dd39eab2e3197edb --build-arg "KONDO_CORREZIONI=$CORREZIONI" --target app -t kondo:app .
       docker build --build-arg KONDO_COMMIT=4d825d2d0b34b62e8f7c8691dd39eab2e3197edb --build-arg "KONDO_CORREZIONI=$CORREZIONI" --target web -t kondo:web .

Le patch si applicano nello stadio `fonte` del `Dockerfile`, non in `sorgente/`. Una patch che non si applica ferma la
costruzione con `ERROR: <patch> non si applica`; una già presente a monte con `ERROR: <patch> è già a monte`.
