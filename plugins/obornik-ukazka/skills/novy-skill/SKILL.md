---
name: novy-skill
description: Uloží nový nebo upravený skill na správné místo, buď jen pro tento projekt, nebo sdílený pro všechny projekty. Když to uživatel neřekne a z povahy skillu to není jasné, zeptá se a doporučí. Použij vždy, když uživatel řekne "ulož to jako skill", "udělej z toho skill", "nový skill", "uprav skill", "ať je to ve všech projektech" nebo chce převzít skill z jiného projektu.
---

# Uložení skillu

Uživateli stačí říct „ulož to jako skill". Kam skill patří, určíš podle postupu níže. Každý skill žije přesně na jednom místě.

## 1. Rozhodni, jestli je projektový, nebo sdílený

Postupuj v tomto pořadí:

1. **Řekl to uživatel?** („jen pro tento projekt", „pro všechny projekty", „sdílený") Udělej to a neptej se.
2. **Je skill zjevně svázaný s tímto projektem?** Zadání výslovně zmiňuje jeho firmu, klienty, lidi, složky, šablony nebo podklady. Pak ho ulož jako projektový bez ptaní a na konci jednou větou řekni proč. Samotné to, že právě pracuješ ve složce projektu, nestačí: faktury, e-maily nebo schůzky má uživatel i v jiných projektech.
3. **Ve všech ostatních případech se zeptej** jednou krátkou otázkou, ve které rovnou doporučíš a v pár slovech zdůvodníš. Dokud uživatel neodpoví, nic neukládej. Například:
   - „Tohle je obecná pomůcka, doporučuju ji mít jako sdílenou pro všechny projekty. Nebo ji chceš jen tady?"
   - „Doporučuju ho nechat jen tady, protože se v jiném projektu nejspíš bude dělat jinak. Nebo ho chceš ve všech projektech?"

**Sdílený skill nikdy neukládej bez výslovného souhlasu uživatele.** Publikuje se na GitHub a objeví se ve všech projektech.

Podle čeho doporučit:

| Spíš projektový | Spíš sdílený |
|---|---|
| pracuje s podklady, složkami nebo šablonami tohoto projektu | nepotřebuje nic z konkrétního projektu |
| týká se konkrétní firmy, klientů, lidí, jejich tónu nebo formátu | osobní pomůcka, která má všude fungovat stejně (letenka do kalendáře, vizitka do kontaktů, přepis, shrnutí) |
| v jiném projektu by se to dělalo jinak | v jiném projektu by vypadal úplně stejně |

Když znaky nejsou jednoznačné, doporuč projektový. Na sdílený jde povýšit kdykoli později, kdežto rozplétat sdílený skill na výjimky podle projektů je složité.

**Kam ho uložit:**
- **Projektový:** `<kořen projektu>/.agents/skills/<nazev>/SKILL.md`
- **Sdílený:** v repu marketplace (cesta je v `AGENTS.md` projektu, sekce Skilly) do `.agents/plugins/obornik-ukazka/skills/<nazev>/SKILL.md`

Nikdy neukládej skill do `~/.claude/skills`, `~/.codex/skills`, `~/.agents/skills`, přímo do `.claude/skills` ani do nastavení účtu Claude nebo ChatGPT. V `.claude/skills/<nazev>` je jednotlivý relativní symlink na `../../.agents/skills/<nazev>`. Upravuj cíl odkazu, ne symlink.

## 2. Zkontroluj, jestli už neexistuje

Podívej se do `.agents/skills/` v projektu a do `.agents/plugins/obornik-ukazka/skills/` v repu marketplace, jestli tam už skill se stejným nebo podobným účelem není. Když ano, uprav ten existující, nevytvářej druhý.

- **Převzetí z jiného projektu:** zkopíruj skill sem a uprav ho pro tento projekt. Neodkazuj na cizí složku, projekty mají zůstat nezávislé.
- **Povýšení projektového na sdílený:** skill přesuň (ne zkopíruj) do repa marketplace, aby v projektu nezůstala druhá kopie. Když má stejný skill i jiný projekt, upozorni na to uživatele a navrhni sjednocení.

## 3. Napiš SKILL.md

- **Název složky i `name`:** malá písmena, číslice a pomlčky, bez diakritiky, nejvýš 64 znaků (např. `tydenni-report`).
- **Hlavička:** standardně `name` a `description`. Volitelná pole zachovej jen s ověřenou podporou a popisem klientských rozdílů; Claude model, oprávnění nebo izolace se do Codexu automaticky nepřenášejí.
- **`description`:** co skill dělá a kdy se má použít, včetně typických frází uživatele. Podle ní AI pozná, že má skill spustit.
- **Tělo:** postup v krocích, co je vstup, jak má vypadat výstup, případně krátký příklad. Česky, stručně, bez vaty.
- **Pomocné soubory** (šablony, skripty, ukázky) dej do stejné složky vedle `SKILL.md` a odkazuj na ně relativní cestou.

Šablona:

```markdown
---
name: nazev-skillu
description: Co skill dělá. Použij, když uživatel ...
---

# Název skillu

## Postup
1. ...

## Výstup
...
```

Po založení projektového skillu vytvoř jednotlivý symlink `.claude/skills/<nazev> -> ../../.agents/skills/<nazev>`. Nové instrukce piš jen do `AGENTS.md`, ne do `CLAUDE.md`. Sdílený plugin po úpravě přegeneruj příkazem `python3 .agents/scripts/build-plugins.py`; adresář `plugins/` je výstup pro distribuci.

## 4. Dokonči

- **Projektový skill** je k dispozici v nové konverzaci v tomto projektu.
- **Sdílený skill** rovnou publikuj skillem `publikuj-skilly`. Je to součást uložení, uživatel nemusí nic dalšího říkat. Totéž platí po úpravě sdíleného skillu.

Nakonec uživateli řekni, kam jsi skill uložil (projektový, nebo sdílený a proč) a jak ho zavolá:
- Claude: `/nazev-skillu` (sdílený `/obornik-ukazka:nazev-skillu`)
- ChatGPT/Codex: `$nazev-skillu` (sdílený `$obornik-ukazka:nazev-skillu`)

Oba nástroje skill spustí i samy, když požadavek odpovídá popisu.
