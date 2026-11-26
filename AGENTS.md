# ukazkovy-marketplace

Začni v `README.md`. Zdroj pluginu `obornik-ukazka` je `.agents/plugins/obornik-ukazka/`. Adresář `plugins/obornik-ukazka/` je generovaný instalační payload s fyzickými soubory, nikoli místo pro ruční úpravy. Zachovej nativní manifesty `.claude-plugin/` a význam oprávnění pluginu.

## Úpravy a kontroly

- Pravidla repa patří do `AGENTS.md`, projektové skills do `.agents/skills/` a jednotlivé relativní symlinky do `.claude/skills/`. `CLAUDE.md` nevytvářej. Distribuované pluginové skills zůstávají ve svém pluginovém scope, nezrcadli je navíc jako projektové.
- Po změně zdroje spusť `python3 .agents/scripts/build-plugins.py`. Kontrola beze změn: `python3 .agents/scripts/build-plugins.py --check`. Publikování je samostatná operace; samotný build nic neinstaluje ani neposílá na síť.
- Ověř manifest přes `claude plugin validate plugins/obornik-ukazka` (u marketplace také kořen repa). Kontrola balíčku neprokazuje funkčnost workflow proti službám.
- Verze je v `.agents/plugins/obornik-ukazka/.claude-plugin/plugin.json`. Měň zdroj, potom přegeneruj výstupy. Tajemství a lokální oprávnění nikdy neverzuj.

## Velké soubory do gitu nepatří

Pravidlo pro všechna repa Deeplink HQ, celý popis je ve wiki: https://github.com/deeplinkhq/wiki/blob/main/large-files.md

- **Soubor nad 5 MB necommituj.** Bez ohledu na velikost do gitu nepatří ani video, audio, archivy, zdrojové soubory grafiky a obrazy disků (seznam typů je v `scripts/large-files.sh`). Velké soubory a podklady patří na Disk Google do `DEEPLINK_SHOW/assets/ukazkovy-marketplace/`, do repa dej jen odkaz.
- **Hlídá to git hook** `.githooks/pre-commit`. Zapíná ho Claude Code i Codex sám na začátku session (`.claude/settings.json`, `.codex/hooks.json`, Codex ho nechá jednou potvrdit v `/hooks`), bez nich jednou na klon `git config core.hooksPath .githooks`. Hook neobcházej (`--no-verify`).
- **Výjimka** je řádek `<cesta nebo vzor> large-file-ok` v `.gitattributes`. Přidej ji jen se souhlasem člověka a commitni ji spolu se souborem.
