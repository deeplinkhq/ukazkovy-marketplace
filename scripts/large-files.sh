#!/usr/bin/env bash
# Kontrola velkých souborů (AGENTS.md, Velké soubory do gitu nepatří): neprojde soubor nad 5 MB
# ani soubor zakázaného typu (video, audio, archiv, zdrojový soubor grafiky, obraz disku),
# pokud pro něj repo nemá výjimku v .gitattributes (atribut large-file-ok).
#   scripts/large-files.sh --staged       soubory připravené ke commitu (git hook .githooks/pre-commit)
#   scripts/large-files.sh --tree [rev]    všechny soubory ve stromu commitu, výchozí HEAD
#   scripts/large-files.sh <od> <do>       soubory, které přidaly commity od <od> do <do>
set -euo pipefail
# Cesty z gitu jsou od kořene repa, git check-attr je bere od aktuální složky.
cd "$(git rev-parse --show-toplevel)"

# Jediný řádek, který se liší mezi repy: složka repa na Disku Google v DEEPLINK_SHOW/assets/.
DRIVE_FOLDER=ukazkovy-marketplace
LIMIT_MB=5
LIMIT=$((LIMIT_MB * 1024 * 1024))
FORBIDDEN='\.(mp4|m4v|mov|webm|avi|mkv|mp3|wav|m4a|aac|flac|ogg|aup3|zip|tar|gz|tgz|xz|7z|rar|bundle|psd|ai|sketch|dmg|iso)$'

# Vypíše „<velikost v bajtech> <cesta>“ pro každý soubor ke kontrole.
list_staged() {
  git diff --cached --diff-filter=ACMR --no-renames --raw --no-abbrev -z |
    while IFS= read -r -d '' meta && IFS= read -r -d '' path; do
      read -r _ mode _ sha _ <<<"$meta"
      [[ $mode == 160000 ]] || printf '%s %s\n' "$sha" "$path" # 160000 je submodul, ne soubor
    done |
    git cat-file --batch-check='%(objectsize) %(rest)'
}
list_tree() {
  git ls-tree -r -l -z "${1:-HEAD}" | tr '\0' '\n' | awk -F '\t' '{split($1, a, " "); if (a[2] == "blob") print a[4], $2}'
}
list_range() {
  git rev-list --objects "$2" --not "$1" |
    git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' |
    awk '$1 == "blob" && $3 != "" {sub(/^blob /, ""); print}'
}

case "${1:-}" in
  --staged) files=$(list_staged) ;;
  --tree) files=$(list_tree "${2:-HEAD}") ;;
  -h | --help | "")
    sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    [[ $# -eq 2 ]] || { echo "Použití: $0 --staged | --tree [rev] | <od> <do>" >&2; exit 2; }
    files=$(list_range "$1" "$2")
    ;;
esac

found=$(printf '%s\n' "$files" | sort -u | awk -v limit="$LIMIT" -v mb="$LIMIT_MB" -v forbidden="$FORBIDDEN" '
  NF < 2 { next }
  {
    size = $1; path = $0; sub(/^[0-9]+ /, "", path)
    if (size > limit) printf "%s\t%.1f MB, limit je %d MB\n", path, size / 1048576, mb
    if (tolower(path) ~ forbidden) printf "%s\ttenhle typ souboru do gitu nepatří\n", path
  }')

# Výjimka je atribut large-file-ok v .gitattributes. Před commitem platí jen výjimka připravená
# ke commitu (--cached), aby šla do repa spolu se souborem.
cached=""
[[ "${1:-}" == --staged ]] && cached=--cached
problems=""
while IFS=$'\t' read -r path reason; do
  [[ -n "$path" ]] || continue
  [[ $(git check-attr $cached large-file-ok -- "$path") == *": set" ]] && continue
  problems+="  $path: $reason"$'\n'
done <<<"$found"

if [[ -n "$problems" ]]; then
  echo "Velké soubory do gitu nepatří (AGENTS.md):" >&2
  printf '%s' "$problems" >&2
  cat >&2 <<EOF
Je to upozornění, poraď si podle AGENTS.md. Podklady (fotky, videa, šablony, exporty) dej
na Google Drive do DEEPLINK_SHOW/assets/$DRIVE_FOLDER/<cesta v repu> a do repa jen odkaz.
Když soubor do gitu opravdu patří (data, která repo vydává nebo čte aplikace či build), navrhni
člověku výjimku a řekni proč. Až ji potvrdí, přidej do .gitattributes řádek
„<cesta nebo vzor> large-file-ok“ s komentářem proč, commitni ho spolu se souborem
a výjimku zmiň v popisu commitu.
Commit, který soubor přidal, oprav dřív, než ho pushneš: z historie na GitHubu ho dostane
jen přepsání historie s force push.
EOF
  exit 1
fi
