#!/usr/bin/env bash
# Kontrola AI složky a skillů: instrukce, odkaz .claude/skills, napojení na marketplace, původ skillů a duplicity.
# Použití: kontrola.sh [kořen-projektu]
set -u

if ! PROJEKT="$(cd "${1:-$PWD}" 2>/dev/null && pwd -P)"; then
  echo "CHYBA: složka ${1:-} neexistuje."
  exit 1
fi
HOME_REAL="$(cd "$HOME" && pwd -P)"
TAB="$(printf '\t')"
POZOR=0
ok()    { printf '  OK     %s\n' "$1"; }
pozor() { printf '  POZOR  %s\n' "$1"; POZOR=$((POZOR + 1)); }
realna() { (cd "$1" 2>/dev/null && pwd -P); }

echo "Projekt: $PROJEKT"

echo
echo "1) Instrukce"
if [ -f "$PROJEKT/AGENTS.md" ]; then
  VELIKOST="$(wc -c < "$PROJEKT/AGENTS.md" | tr -d ' ')"
  if [ "$VELIKOST" -gt 32768 ]; then
    pozor "AGENTS.md má $VELIKOST B, ChatGPT/Codex z něj načte jen prvních 32 KiB"
  else
    ok "AGENTS.md ($VELIKOST B)"
  fi
else
  pozor "chybí AGENTS.md"
fi
D="$PROJEKT"
BLOKUJE=0
while :; do
  for F in CLAUDE.md CLAUDE.local.md .claude/CLAUDE.md; do
    # Globální ~/.claude/CLAUDE.md čtení AGENTS.md neblokuje.
    [ "$D" = "$HOME_REAL" ] && [ "$F" = ".claude/CLAUDE.md" ] && continue
    if [ -e "$D/$F" ]; then
      pozor "$D/$F: kvůli němu Claude nečte AGENTS.md (obsah přesuň do AGENTS.md a soubor smaž)"
      BLOKUJE=1
    fi
  done
  [ "$D" = "/" ] && break
  D="$(dirname "$D")"
done
[ "$BLOKUJE" -eq 0 ] && ok "ve složce ani nad ní není CLAUDE.md, Claude čte AGENTS.md"

echo
echo "2) Projektové skilly"
ODKAZ="$PROJEKT/.claude/skills"
if [ -d "$ODKAZ" ]; then
  for S in "$PROJEKT/.agents/skills"/*/; do
    [ -f "$S/SKILL.md" ] || continue
    JMENO="$(basename "$S")"
    if [ -L "$ODKAZ/$JMENO" ] && [ "$(readlink "$ODKAZ/$JMENO")" = "../../.agents/skills/$JMENO" ] && [ "$(realna "$ODKAZ/$JMENO")" = "$(realna "$S")" ]; then
      ok "$JMENO: Claude odkazuje na zdroj v .agents/skills"
    else
      pozor "$JMENO: chybí relativní symlink .claude/skills/$JMENO na ../../.agents/skills/$JMENO"
    fi
  done
  for S in "$ODKAZ"/*/; do
    [ -f "$S/SKILL.md" ] || continue
    JMENO="$(basename "$S")"
    [ "$(realna "$S")" = "$(realna "$PROJEKT/.agents/skills/$JMENO")" ] || pozor "$JMENO: samostatná kopie v .claude/skills"
  done
else
  [ ! -d "$PROJEKT/.agents/skills" ] || pozor "chybí .claude/skills s jednotlivými symlinky"
fi

echo
echo "3) Napojení na sdílené skilly"
NASTAVENI="$PROJEKT/.claude/settings.json"
if [ -f "$NASTAVENI" ] && grep -q '"extraKnownMarketplaces"' "$NASTAVENI"; then
  ok "Claude: $(sed -nE 's/.*"([^"]+@[^"]+)"[[:space:]]*:[[:space:]]*true.*/\1/p' "$NASTAVENI" | tr '\n' ' ')"
else
  pozor "Claude: .claude/settings.json nemá marketplace, sdílené skilly v Claude nebudou"
fi
KONFIG="$PROJEKT/.codex/config.toml"
if [ -f "$KONFIG" ] && grep -q '^\[marketplaces\.' "$KONFIG"; then
  ok "ChatGPT/Codex: $(sed -nE 's/^\[plugins\."([^"]+)"\].*/\1/p' "$KONFIG" | tr '\n' ' ')"
else
  pozor "ChatGPT/Codex: .codex/config.toml nemá marketplace, sdílené skilly v Codexu nebudou"
fi

# Soupis skillů: zdroj, jméno pro volání, holé jméno, identita (skutečná cesta, u pluginů plugin:jméno).
SEZNAM="$(mktemp)"
trap 'rm -f "$SEZNAM"' EXIT
pridej() {
  local ZDROJ="$1" SLOZKA="$2" PREFIX="${3:-}" S JMENO ID
  [ -d "$SLOZKA" ] || return 0
  for S in "$SLOZKA"/*/; do
    [ -f "$S/SKILL.md" ] || continue
    JMENO="$(basename "$S")"
    if [ "$ZDROJ" = "projekt-jen-claude" ] && [ "$(realna "$S")" = "$(realna "$PROJEKT/.agents/skills/$JMENO")" ]; then continue; fi
    if [ -n "$PREFIX" ]; then ID="plugin:$PREFIX$JMENO"; else ID="$(realna "$S")"; fi
    printf '%s\t%s\t%s\t%s\n' "$ZDROJ" "$PREFIX$JMENO" "$JMENO" "$ID" >> "$SEZNAM"
  done
}
pridej_pluginy() {
  local ZDROJ="$1" CACHE="$2" P VERZE
  [ -d "$CACHE" ] || return 0
  for P in "$CACHE"/*/*/; do
    [ -d "$P" ] || continue
    VERZE="$(ls -1dt "$P"*/ 2>/dev/null | head -1)"
    [ -n "$VERZE" ] && pridej "$ZDROJ" "${VERZE}skills" "$(basename "$P"):"
  done
}
pridej projekt "$PROJEKT/.agents/skills"
[ -L "$ODKAZ" ] || pridej projekt-jen-claude "$ODKAZ"
pridej_pluginy plugin-claude "$HOME/.claude/plugins/cache"
pridej_pluginy plugin-codex "$HOME/.codex/plugins/cache"
pridej claude-uzivatel "$HOME/.claude/skills"
pridej codex-uzivatel "$HOME/.codex/skills"
pridej spolecne-uzivatel "$HOME/.agents/skills"

echo
echo "4) Odkud se berou skilly"
for Z in projekt projekt-jen-claude plugin-claude plugin-codex claude-uzivatel codex-uzivatel spolecne-uzivatel; do
  N="$(awk -F"$TAB" -v z="$Z" '$1 == z' "$SEZNAM" | wc -l | tr -d ' ')"
  [ "$N" -eq 0 ] && continue
  case "$Z" in
    plugin-*) OBSAH="$(awk -F"$TAB" -v z="$Z" '$1 == z { split($2, a, ":"); n[a[1]]++ } END { for (k in n) printf "%s (%d) ", k, n[k] }' "$SEZNAM")" ;;
    *)        OBSAH="$(awk -F"$TAB" -v z="$Z" '$1 == z { print $2 }' "$SEZNAM" | sort -u | tr '\n' ' ')" ;;
  esac
  printf '  %-18s %3s  %s\n' "$Z" "$N" "$OBSAH"
done
for Z in claude-uzivatel codex-uzivatel spolecne-uzivatel projekt-jen-claude; do
  if awk -F"$TAB" -v z="$Z" '$1 == z { f = 1 } END { exit !f }' "$SEZNAM"; then
    pozor "skilly ve zdroji $Z sem nepatří: přesuň je do projektu (.agents/skills) nebo do sdíleného pluginu"
  fi
done

echo
echo "5) Duplicity (stejný název na víc místech)"
DUPLICITY="$(awk -F"$TAB" '!videno[$4]++' "$SEZNAM" \
  | awk -F"$TAB" '{ n[$3]++; kde[$3] = kde[$3] " " $1 "(" $2 ")" } END { for (k in n) if (n[k] > 1) print k ":" kde[k] }' | sort)"
if [ -z "$DUPLICITY" ]; then
  ok "žádný skill není na víc místech"
else
  printf '%s\n' "$DUPLICITY" | sed 's/^/  POZOR  /'
  POZOR=$((POZOR + $(printf '%s\n' "$DUPLICITY" | grep -c .)))
fi

echo
echo "Skilly nahrané přímo v účtu (claude.ai: Nastavení > Skills, ChatGPT: Skills) na disku nejsou, zkontroluj je ručně."
echo
if [ "$POZOR" -eq 0 ]; then
  echo "Výsledek: vše v pořádku."
else
  echo "Výsledek: $POZOR věcí k řešení."
fi
