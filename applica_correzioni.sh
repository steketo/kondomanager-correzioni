#!/bin/sh
# applica_correzioni.sh | Toto — applica a <cartella> le patch (*.patch, formato git diff) di <correzioni>, in ordine di nome.
# Uso: sh applica_correzioni.sh <cartella> <correzioni>; sh applica_correzioni.sh --elenco <correzioni> stampa i nomi
# separati da virgola (vuoto se non ce ne sono). Non entra nelle sottocartelle di <correzioni>.
# Uscite: 0 tutte applicate (anche nessuna); 1 una patch non si applica, è già a monte o git apply ne salta un file;
# 2 uso. Si ferma alla prima che fallisce: le precedenti restano applicate.
set -eu
uso() { echo "uso: applica_correzioni.sh <cartella> <correzioni> | --elenco <correzioni>" >&2; exit 2; }
if [ "${1:-}" = --elenco ]; then
  [ $# -eq 2 ] && [ -d "$2" ] || uso
  elenco=""
  for p in "$2"/*.patch; do
    [ -f "$p" ] || continue
    elenco="${elenco:+$elenco,}$(basename "$p")"
  done
  echo "$elenco"
  exit 0
fi
[ $# -eq 2 ] && [ -d "$1" ] && [ -d "$2" ] || uso
CORREZIONI="$(cd "$2" && pwd -P)"
# dentro un deposito git, git apply salta i file e risponde 0: il tetto (assoluto, uno relativo git lo ignora) gli
# fa vedere solo la cartella
GIT_CEILING_DIRECTORIES="$(cd "$1/.." && pwd -P)"
export GIT_CEILING_DIRECTORIES
cd "$1"
for p in "$CORREZIONI"/*.patch; do
  [ -f "$p" ] || continue
  n="$(basename "$p")"
  if rov="$(git apply --reverse --check --verbose "$p" 2>&1)" && ! printf '%s\n' "$rov" | grep -q 'Skipped patch'; then
    echo "ERROR: $n è già a monte: si toglie dal kit" >&2; exit 1
  fi
  if ! out="$(git apply --verbose "$p" 2>&1)" || printf '%s\n' "$out" | grep -q 'Skipped patch'; then
    printf '%s\n' "$out" >&2
    echo "ERROR: $n non si applica" >&2; exit 1
  fi
done
