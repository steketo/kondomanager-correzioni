#!/bin/sh
# sorgente_pubblico.sh | Toto — nel sorgente di KondoManager porta il collegamento al sorgente (pagine di accesso,
# intestazioni, piè di pagina, installatore) dal deposito a monte a quello che pubblica le correzioni, perché chi usa il
# programma corretto ne trovi il sorgente (AGPL-3.0, sezione 13).
# Uso: sh sorgente_pubblico.sh <cartella> <indirizzo>: sostituisce https://github.com/vince844/kondomanager-free con
# <indirizzo> in ogni file sotto <cartella>/resources/ che lo porta.
# Uscite: 0 sostituito; 1 nessun file lo porta (a monte il collegamento è cambiato: si rilegge il sorgente); 2 uso
# (cartella senza resources/, indirizzo vuoto o con «|», «&», «\» o spazi, che sed leggerebbe come comandi).
set -eu
VECCHIO="https://github.com/vince844/kondomanager-free"
uso() { echo "uso: sorgente_pubblico.sh <cartella> <indirizzo>" >&2; exit 2; }
[ $# -eq 2 ] && [ -d "$1/resources" ] && [ -n "$2" ] || uso
case "$2" in *'|'* | *'&'* | *'\'* | *[[:space:]]*) uso ;; esac
grep -rqF "$VECCHIO" "$1/resources" || { echo "ERROR: nessun file di $1/resources porta $VECCHIO: a monte il collegamento è cambiato" >&2; exit 1; }
# find esce con l'uscita di sed: una sostituzione fallita non passa inosservata
find "$1/resources" -type f -exec grep -qF "$VECCHIO" {} \; -exec sed -i "s|$VECCHIO|$2|g" {} + ||
  { echo "ERROR: sostituzione non riuscita in $1/resources" >&2; exit 1; }
