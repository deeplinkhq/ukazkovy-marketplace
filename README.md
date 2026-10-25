# Ukázkový marketplace sdílených skillů

Tohle repo je marketplace se skilly, které fungují ve všech projektech, v Claude i v ChatGPT (Codex). Projektové skilly sem nepatří, ty žijí přímo ve složce projektu.

## Jak je to celé poskládané

```
Firemní Google Drive                    Osobní Google Drive
AI/firma/                               AI/osobni/
├── AGENTS.md          instrukce pro Claude i ChatGPT
├── .agents/skills/    skilly jen pro tento projekt
├── .claude/skills/<nazev>  jednotlivé odkazy na .agents/skills/<nazev> (neupravovat)
├── .claude/settings.json   napojení na tento marketplace (Claude)
└── .codex/config.toml      napojení na tento marketplace (ChatGPT/Codex)

Tento počítač + GitHub
~/AI/ukazkovy-marketplace/  tohle repo = sdílené skilly
├── .agents/plugins/obornik-ukazka/skills/<nazev>/SKILL.md  zdroj
└── plugins/obornik-ukazka/skills/<nazev>/SKILL.md          generovaný payload
```

Pravidlo: **každý skill žije přesně na jednom místě.** Buď ve složce projektu (`.agents/skills`), nebo tady. Nikde jinde, ani v nastavení účtu Claude nebo ChatGPT.

## Kde co funguje

| | Claude Code | Cowork | ChatGPT (Codex, Work) |
|---|---|---|---|
| Instrukce (`AGENTS.md`) | ano | ano | ano |
| Skilly projektu (`.agents/skills`) | ano | ne | ano |
| Sdílené skilly (tento marketplace) | ano | ano | ano |

V ChatGPT Work je potřeba složku otevřít jako lokální projekt. Cowork skilly projektu ze složky nenačítá, proto se s nimi pracuje v Claude Code, v Codexu nebo v ChatGPT Work.

## Co je v pluginu `obornik-ukazka`

| Skill | K čemu |
|---|---|
| `novy-skill` | Vytvoří nebo upraví skill a uloží ho na správné místo |
| `publikuj-skilly` | Nahraje změny sdílených skillů na GitHub |
| `kontrola-skillu` | Ukáže, odkud se který skill bere, a najde duplicity |
| `letenka-do-kalendare` | Přepíše letenku nebo jízdenku do kalendáře |

Volání: v Claude `/obornik-ukazka:nazev`, v ChatGPT/Codexu `$obornik-ukazka:nazev`. Oba nástroje skill spustí i samy, když požadavek odpovídá popisu.

## Běžné situace

- **Chci nový skill**: napiš „ulož to jako skill". AI ho uloží buď jen do projektu (`.agents/skills`), nebo sem mezi sdílené a rovnou publikuje. Když z povahy skillu není jasné, kam patří, zeptá se a doporučí.
- **Upravil jsem sdílený skill ručně**: napiš „publikuj skilly". Bez toho se změna do ostatních nástrojů a zařízení nedostane.
- **Chci převzít skill z druhého projektu**: „podívej se na skill X v projektu Osobní a udělej podle něj verzi pro firmu". Vznikne samostatná kopie, projekty zůstanou nezávislé.
- **Nevím, odkud se skill bere, nebo ho vidím dvakrát**: napiš „zkontroluj skilly".

## Pravidla, která hlídají, aby to fungovalo

- Ve složkách projektů nesmí být soubor `CLAUDE.md`, jinak Claude přestane číst `AGENTS.md`.
- Tohle repo nepatří na Google Drive (Git a Drive se nesnesou), leží jen na počítači a na GitHubu.
- Nové zařízení: nainstalovat `gh`, přihlásit se (`gh auth login`, pak `gh auth setup-git`) a projekty otevřít v Claude i Codexu jako důvěryhodné.

## Úpravy zdrojů a sestavení

Zdroj sdíleného pluginu je `.agents/plugins/obornik-ukazka/`. Po úpravě spusť `python3 .agents/scripts/build-plugins.py`; kontrola beze změn je `python3 .agents/scripts/build-plugins.py --check`. Adresář `plugins/` obsahuje kompletní fyzický payload pro instalaci, nepřepisuj ho ručně. Manifest `.claude-plugin/marketplace.json` zůstává nativním vstupem marketplace. Instrukce pro úpravy repa jsou v `AGENTS.md`.
