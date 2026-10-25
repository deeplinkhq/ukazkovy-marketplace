#!/usr/bin/env bash
# Publikuje změny v repu marketplace: zvýší verzi změněných pluginů, ověří, commitne a pushne.
# Použití: publikuj.sh <cesta-k-repu-marketplace> ["popis změny"]
set -euo pipefail

REPO="${1:?Chybí cesta k repu marketplace}"
ZPRAVA="${2:-Aktualizace skillů}"

cd "$REPO"
if [ ! -f .claude-plugin/marketplace.json ]; then
  echo "CHYBA: $REPO není marketplace (chybí .claude-plugin/marketplace.json)."
  exit 1
fi

if ! git pull --rebase --autostash -q; then
  echo "CHYBA: nepodařilo se stáhnout změny z GitHubu. Zkontroluj připojení a přihlášení (gh auth status)."
  exit 1
fi

if [ -f .agents/scripts/build-plugins.py ]; then
  python3 .agents/scripts/build-plugins.py
fi

git add -A
ZMENY="$(git diff --cached --name-only)"
if [ -z "$ZMENY" ]; then
  echo "Žádné změny k publikování."
  exit 0
fi

# Claude pozná novou verzi pluginu jen podle změny "version", proto ji zvedáme automaticky.
PLUGINY="$(printf '%s\n' "$ZMENY" | sed -n -e 's|^plugins/\([^/]*\)/.*|\1|p' -e 's|^\.agents/plugins/\([^/]*\)/.*|\1|p' | sort -u)"
for PLUGIN in $PLUGINY; do
  MANIFEST=".agents/plugins/$PLUGIN/.claude-plugin/plugin.json"
  [ -f "$MANIFEST" ] || MANIFEST="plugins/$PLUGIN/.claude-plugin/plugin.json"
  [ -f "$MANIFEST" ] || continue
  if git diff --cached -- "$MANIFEST" | grep -q '^+.*"version"'; then
    echo "  $PLUGIN: verze je nastavená v této změně (nový nebo ručně upravený plugin), nechávám"
    continue
  fi
  STARA="$(sed -nE 's/.*"version"[[:space:]]*:[[:space:]]*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/p' "$MANIFEST" | head -1)"
  if [ -z "$STARA" ]; then
    echo "  POZOR: $MANIFEST nemá version ve tvaru X.Y.Z, přeskakuji"
    continue
  fi
  NOVA="$(printf '%s' "$STARA" | awk -F. '{printf "%d.%d.%d", $1, $2, $3 + 1}')"
  STARA="$STARA" NOVA="$NOVA" perl -pi -e 's/("version"\s*:\s*")\Q$ENV{STARA}\E"/$1$ENV{NOVA}"/' "$MANIFEST"
  echo "  $PLUGIN: $STARA -> $NOVA"
done

if [ -f .agents/scripts/build-plugins.py ]; then
  python3 .agents/scripts/build-plugins.py
fi

if command -v claude >/dev/null 2>&1; then
  if ! claude plugin validate . >/tmp/publikuj-validace.$$ 2>&1; then
    cat /tmp/publikuj-validace.$$
    rm -f /tmp/publikuj-validace.$$
    echo "CHYBA: marketplace neprošel kontrolou, nic jsem nenahrál."
    exit 1
  fi
  rm -f /tmp/publikuj-validace.$$
fi

git add -A
git commit -qm "$ZPRAVA"
git push -q
echo "Publikováno: $(git log -1 --format='%h %s')"
