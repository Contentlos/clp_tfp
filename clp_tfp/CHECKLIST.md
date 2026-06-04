# clp_tfp — Überprüfung (Fragen)

Jede Frage mit **Ja / Nein / Semi** beantworten. Bei Nein/Semi kurz dazuschreiben, was passiert. Nummern (z. B. `4.1`) zum Referenzieren.

## 0 · Setup / Start
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 0.1 | Stimmt die server.cfg-Reihenfolge (esx → esx_status → esx_basicneeds → ox_lib → ox_inventory → ox_target → clp_tfp)? |  |
| 0.2 | Starten `restart ox_inventory` + `restart clp_tfp` ohne rote Konsolen-Fehler? |  |
| 0.3 | Bleibt der `cannot open inventory (fatal injury)`-Spam beim Join aus? |  |
| 0.4 | Bleibt der `GetEntityModel`-Crash beim Anvisieren aus? |  |

## 1 · Spawn & Onboarding
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 1.1 | Spawnt man verstreut an einem Strand (nicht im Wasser/Void)? |  |
| 1.2 | Ist das Starter-Kit im Inventar (Axt, Lampe, Flasche, 2 Verband, Konserve)? |  |
| 1.3 | Erscheint der Onboarding-Dialog einmalig? |  |
| 1.4 | Zeigt `/tfphelp` die Steuerung? |  |
| 1.5 | Öffnen F5 und `/survival` das Hauptmenü? |  |

## 2 · HUD
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 2.1 | Sind alle Gauges sichtbar (Leben, Blut, Hunger, Durst, Ausdauer, Wärme)? |  |
| 2.2 | Reagieren die Ringe korrekt (niedrig = rot + Puls)? |  |
| 2.3 | Erscheinen die Badges mit Krankheits**name**, Blutung, Bein-/Armbruch, Nässe? |  |
| 2.4 | Zeigt das obere Widget Wetter + Uhrzeit + °C? |  |
| 2.5 | Pulsiert bei sehr niedriger HP der rote Rand (Herzschlag)? |  |
| 2.6 | Erscheint beim Tod das Vollbild-Overlay (GESTORBEN/VERWUNDET)? |  |
| 2.7 | Bleibt das HUD nach Tod/Respawn sichtbar (nicht dauerhaft weg)? |  |

## 3 · Survival-Stats
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 3.1 | Sinken Hunger/Durst über Zeit? |  |
| 3.2 | Sinkt die Temperatur nachts/bei Regen/im Wasser? |  |
| 3.3 | Steigt Nässe (Schwimmen/Regen) und trocknet an Feuer/Sonne? |  |
| 3.4 | Leert Sprinten die Ausdauer (leer = kein Sprint)? |  |
| 3.5 | Wird man krank, wenn man kalt **und** nass ist? |  |
| 3.6 | Sinkt bei krank + kalt langsam die HP? |  |

## 4 · Sammeln & Werkzeug
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 4.1 | Zeigt **JEDER Baum** das ox_target „Baum fällen"? |  |
| 4.2 | Spielt das Fällen die **axe2-Emote**? |  |
| 4.3 | Kommt ohne Axt die klare Meldung „brauchst eine Axt"? |  |
| 4.4 | Ist die Steinaxt aus Stein + Pflanzenfaser craftbar? |  |
| 4.5 | Sind Stein/Büsche/Beeren/Schrott sammelbar? |  |
| 4.6 | Nutzt sich das Werkzeug ab und zerbricht irgendwann? |  |

## 5 · Items kommen an
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 5.1 | Gibt Sammeln tatsächlich Holz/Stein/Faser/Schrott? |  |
| 5.2 | Gibt die Jagd rohes Fleisch / Tierfell? |  |
| 5.3 | Gibt Loot tatsächlich Items? |  |
| 5.4 | Existiert Munition und wird sie vergeben? |  |

## 6 · Handwerk & Stationen
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 6.1 | Zeigt `/craft` (Hand) Rezepte? |  |
| 6.2 | Lässt sich ein Lagerfeuer platzieren? |  |
| 6.3 | Lässt sich die Werkbank platzieren & nutzen? |  |
| 6.4 | Schmilzt der **Schmelzofen** Schrott → Metallbarren? |  |
| 6.5 | Kann man **Leder gerben** (Fell→Leder)? |  |
| 6.6 | Wärmt **Fellkleidung** im Inventar? |  |
| 6.7 | Lernen Blueprint-Items Rezepte (🔒 ohne Plan)? |  |

## 7 · Essen / Wasser
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 7.1 | Füllt Essen/Trinken Hunger/Durst? |  |
| 7.2 | Macht rohes Fleisch/Fisch eine Vergiftungs-Chance? |  |
| 7.3 | Erhöht verdorbenes Essen die Krankheits-Chance? |  |
| 7.4 | Kann man Fleisch/Fisch am Feuer braten? |  |
| 7.5 | Funktioniert das Angeln (Angel → Fisch)? |  |
| 7.6 | Kann man Beeren essen? |  |
| 7.7 | Lässt sich die Flasche an Wasser füllen? |  |
| 7.8 | Lässt sich dreckiges Wasser abkochen → sauber? |  |
| 7.9 | Gibt dreckiges Wasser eine Cholera-Chance? |  |

## 8 · Medizin
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 8.1 | Lösen Treffer Blutung aus (Blut-Gauge & Max-HP sinken)? |  |
| 8.2 | Senkt der Verband (F9) die Blutung teilweise? |  |
| 8.3 | Stoppt das **Nähset** die Blutung komplett + heilt? |  |
| 8.4 | Füllt der **Blutbeutel** das Blut auf? |  |
| 8.5 | Dämpfen **Schmerzmittel** FX/Humpeln? |  |
| 8.6 | Verhindert/heilt **Desinfektion** die Wundinfektion? |  |
| 8.7 | Heilen Antibiotika/Medkit die passende Krankheit? |  |
| 8.8 | Unterscheiden sich Bein-/Armbruch und heilt die Schiene (F10)? |  |
| 8.9 | Zeigt eine Krankheit Symptome + Name im HUD? |  |

## 9 · Jagd & Tiere
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 9.1 | Ist die Ausschlacht-Animation realistisch (Knien)? |  |
| 9.2 | Gibt Ausschlachten Fleisch/Fell (NPC = Loot)? |  |
| 9.3 | Spawnen Ambient-Wildtiere (außer Safezone)? |  |

## 10 · Gegner / Predators
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 10.1 | Greift der **Hai** beim Schwimmen an? |  |
| 10.2 | Sind **Berglöwen** wirklich weg? |  |
| 10.3 | Spawnen nachts Kannibalen und jagen? |  |
| 10.4 | Sind Kartell-NPCs in den Lagern? |  |

## 11 · Safezone
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 11.1 | Ist man in der Zone unverwundbar? |  |
| 11.2 | Bleiben Gegner-Spawns in der Zone aus? |  |
| 11.3 | Verschwinden Verfolger, die reinlaufen? |  |
| 11.4 | Sind in der Zone die eigenen Waffen deaktiviert? |  |
| 11.5 | Gibt es Radius-Blip + Betreten/Verlassen-Hinweis? |  |

## 12 · Loot & Welt-Events
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 12.1 | Ist Müll durchsuchbar und gibt Items? |  |
| 12.2 | Sind Container/Munition/Militär durchsuchbar? |  |
| 12.3 | Sind Fahrzeuge durchsuchbar? |  |
| 12.4 | Kommt der Airdrop (Blip + Kiste)? |  |
| 12.5 | Kommt das Wrack-Event? |  |
| 12.6 | Sind die Tauch-Spots unter Wasser durchsuchbar? |  |

## 13 · Bauen, Tiers & Raid
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 13.1 | Öffnet & platziert das Bau-Menü (Vorschau, drehen)? |  |
| 13.2 | Lassen sich modulare bzzz_blocks bauen (snap)? |  |
| 13.3 | Überleben Bauten den Server-Neustart? |  |
| 13.4 | Funktioniert Verstärken Holz→Stein→Metall? |  |
| 13.5 | Lässt sich raiden (zerstören bei 0 HP + Rauch)? |  |
| 13.6 | Bleibt Raid in der Safezone gesperrt? |  |
| 13.7 | Funktioniert das Codeschloss an Türen? |  |
| 13.8 | Ist die Lager-Kiste ein Stash (Owner/Stamm)? |  |
| 13.9 | Verlängert Kern-Upkeep den Schutz? |  |
| 13.10 | Lässt sich Bett/Schlafsack als Respawn setzen? |  |
| 13.11 | Schädigt die Stachelfalle Feinde/Spieler? |  |

## 14 · Stamm / Coop
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 14.1 | Kann man einen Stamm gründen? |  |
| 14.2 | Funktioniert Einladen → Annehmen? |  |
| 14.3 | Funktioniert Befördern/Herabstufen/Kicken? |  |
| 14.4 | Öffnet sich die gemeinsame Truhe für Mitglieder? |  |
| 14.5 | Sieht man Stamm-Mitglieder als Karten-Blips? |  |

## 15 · Wetter / Zeit / Blips
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 15.1 | Läuft das eigene Wettersystem? |  |
| 15.2 | Beeinflusst Tag/Nacht die Temperatur? |  |
| 15.3 | Sind Safezone/Schlafplatz/Event-Blips auf der Karte? |  |

## 16 · Radiation & Flucht
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 16.1 | Sinkt auf dem Festland ohne hazmat_suit die HP? |  |
| 16.2 | Schützt `hazmat_suit` im Inventar? |  |
| 16.3 | Warnt der `geiger_counter` in Zonennähe? |  |
| 16.4 | Sind hazmat/geiger als Loot findbar? |  |
| 16.5 | Funktioniert Flucht-Schritt 1 (Funkturm)? |  |
| 16.6 | Funktioniert Schritt 2 (Treibstoff) und ist Treibstoff findbar? |  |
| 16.7 | Funktioniert Schritt 3 (Boot)? |  |
| 16.8 | Funktioniert Schritt 4 (Strandwache → ablegen → Festland)? |  |
| 16.9 | Handelt der Schwarzmarkt-Händler (Barter)? |  |
| 16.10 | Ist das Landebahn-Depot bewacht + Top-Loot? |  |

## 17 · Tod / Downed
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 17.1 | Geht man bei tödlichem Schaden in **Downed** (Ragdoll, Countdown)? |  |
| 17.2 | Kann ein Mitspieler mit Erste-Hilfe-Set wiederbeleben? |  |
| 17.3 | Beendet [X] (aufgeben) ins endgültige Sterben? |  |
| 17.4 | Fällt das Inventar als lootbarer Beutel? |  |
| 17.5 | Respawnt man am Schlafsack (sonst Strand)? |  |
| 17.6 | Bleibt die Todesschleife aus (Reset bei Respawn/Revive)? |  |

## 18 · Radio / Fahrzeuge / Companion
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 18.1 | Kann man per Funkgerät einen Kanal wählen? |  |
| 18.2 | Spawnt der Boots-Bausatz ein Boot am Wasser? |  |
| 18.3 | Ruft die Hundepfeife einen Begleithund? |  |

## 19 · Admin (`/tfpadmin`)
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 19.1 | Öffnet sich das Panel (als Admin/ACE)? |  |
| 19.2 | Funktioniert Wipe (Map/Blueprints/Voll)? |  |
| 19.3 | Lässt sich Airdrop / Wrack-Event auslösen? |  |
| 19.4 | Funktionieren Heilen/Survival/Verletzungen/Godmode? |  |
| 19.5 | Funktionieren Item geben/Fahrzeug/Teleport? |  |
| 19.6 | Funktioniert der Punkt-Editor (alle Punkte inkl. Wrack/Tauch/Escape 1–4)? |  |
| 19.7 | Kopiert `/tfppos` einen vec3? |  |

## 20 · Persistenz (über Neustart)
| # | Frage | Ja / Nein / Semi |
|---|---|---|
| 20.1 | Bleibt der Spieler-Fortschritt erhalten (Spawn, Flucht-Schritt)? |  |
| 20.2 | Bleiben Bauten + Stationen erhalten? |  |
| 20.3 | Bleiben gelernte Blueprints erhalten? |  |
| 20.4 | Bleiben Stamm + Mitglieder + Stash-Inhalt erhalten? |  |
| 20.5 | Bleiben Bau-HP/Tier erhalten? |  |
