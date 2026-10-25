---
name: letenka-do-kalendare
description: Přepíše letenku, jízdenku nebo potvrzení rezervace (PDF, e-mail, screenshot, text) do kalendáře jako událost se všemi detaily. Použij, když uživatel pošle letenku nebo jízdenku a chce ji dát do kalendáře.
---

# Letenka nebo jízdenka do kalendáře

## 1. Vytáhni údaje

Z podkladu zjisti pro každý úsek cesty (tam i zpět jsou samostatné události):

- typ (let, vlak, autobus), dopravce a číslo spoje
- odkud a kam (město, letiště nebo stanice, terminál nebo nástupiště, když je uvedené)
- datum a čas odjezdu a příjezdu, každý v místním čase daného místa
- rezervační kód, sedadlo, třída, zavazadla

Když něco chybí nebo je nejasné (hlavně časová zóna nebo datum příjezdu po půlnoci), zeptej se. Nic si nedomýšlej.

Když přijde víc letenek nebo jízdenek najednou, zpracuj všechny a ukaž jeden společný návrh seřazený podle času.

## 2. Ukaž návrh a počkej na potvrzení

Vypiš návrh událostí v tomto tvaru a zeptej se, jestli je založit:

- **Název**: `Let OK 123 Praha (PRG) → Londýn (LHR)`, u vlaku `Vlak RJ 1041 Praha → Vídeň`
- **Začátek a konec**: odjezd a příjezd, každý ve správné časové zóně
- **Místo**: letiště nebo stanice odjezdu, s terminálem nebo nástupištěm
- **Popis**: rezervační kód, sedadlo, třída, zavazadla, dopravce

## 3. Založ události

Po potvrzení založ události přes kalendářový konektor (Google Calendar), který je připojený v účtu. Když konektor k dispozici není, vytvoř soubor `.ics` se stejnými údaji a řekni uživateli, kde leží a jak ho otevřít.

Nakonec shrň, co bylo založeno, a upozorni na věci, na které je dobré myslet (online check-in, přesun na letiště).
