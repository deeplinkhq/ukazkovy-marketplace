---
name: publikuj-skilly
description: Nahraje změny sdílených skillů na GitHub, aby se propsaly do Claude i ChatGPT/Codexu na všech zařízeních. Použij, když uživatel řekne "publikuj skilly", "nahraj skilly na GitHub", nebo hned po vytvoření či úpravě sdíleného skillu.
---

# Publikování sdílených skillů

Sdílené skilly se berou z GitHubu. Dokud se změna nenahraje, Claude ani ChatGPT ji nevidí.

## Postup

1. Najdi cestu k repu marketplace v `AGENTS.md` aktuálního projektu (sekce Skilly). Když tam není, zeptej se uživatele.
2. Spusť skript `scripts/publikuj.sh` ze složky tohoto skillu. Jako první argument dej cestu k repu, jako druhý krátký český popis změny:

   ```bash
   bash "<složka tohoto skillu>/scripts/publikuj.sh" "<cesta k repu>" "Přidán skill tydenni-report"
   ```

   Skript stáhne případné změny z GitHubu, sestaví fyzický payload ze zdroje `.agents/plugins/`, zvýší verzi pluginů, ve kterých se něco změnilo, ověří marketplace, udělá commit a nahraje ho na GitHub.
3. Když skript skončí chybou, přečti hlášku a vysvětli ji uživateli lidsky. Nic nepřepisuj silou (žádné `--force`).

## Po publikování řekni uživateli

- **Claude**: změna se stáhne sama při dalším spuštění. Hned ji dostane příkazem `/plugin marketplace update <název marketplace>` a pak `/reload-plugins`.
- **ChatGPT/Codex**: změna se stáhne při dalším spuštění Codexu.
- Na ostatních zařízeních se změna projeví stejně, stačí mít nainstalovaný stejný marketplace.
