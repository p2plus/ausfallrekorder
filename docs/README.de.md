# Ausfallrekorder

[English](../README.md) · Deutsch · [简体中文](README.zh-Hans.md)

Ein kleines Werkzeug, das zwei Dinge gut macht: **Verbindung messen** und
**einen verständlichen Bericht liefern**.

<img src="../Resources/AppIcon.png" width="96" alt="App-Icon">

## Mac

Die App sitzt in der Statusleiste. Ein Klick auf die Messlinie öffnet die kompakte
Ansicht. **Messung starten**, später **Exportieren**. **Beenden** stoppt die Messung,
speichert sie und schließt die App. Das Zuklappen des Menüs beendet die Messung nicht.

macOS 14 oder neuer. Fertige App unter [Releases](https://github.com/p2plus/ausfallrekorder/releases).
Die App ist lokal signiert, noch nicht von Apple notarisiert.

Aus dem Quellcode bauen (Swift 6+):

```sh
sh scripts/build-macos.sh
open dist/Ausfallrekorder.app
```

## Linux

Das Terminalprogramm verwendet denselben Kern und dieselben Messdateien.
Auf Ubuntu 24.04 ARM64 und x86_64 (GitHub CI) geprüft.

```sh
sudo apt install iproute2 iputils-ping libc-bin libcurl4t64 libstdc++6
./ausfallrekorder-cli record --language de --label WLAN --output wlan.afr
```

Strg+C speichert die Messung und erstellt den HTML-Bericht. Standard: acht Stunden,
alle 15 Sekunden. Kein dauerhaft laufender Dienst, keine Root-Rechte für die Messung.

```sh
./ausfallrekorder-cli report wlan.afr --language de --output bericht.html
./ausfallrekorder-cli compare wlan.afr lan.afr --language de --output vergleich.html
```

## Bewusst klein

Drei einzelne Pings, eine DNS-Abfrage und eine HTTPS-HEAD-Anfrage je Messrunde.
Keine Geschwindigkeitstests, keine Seiteninhalte, keine überlappenden Prüfungen.
Die App verhindert keinen Standby. Messdaten werden fortlaufend lokal gespeichert.

Export: ein offline lesbarer HTML-Bericht oder die ursprüngliche `.afr`-Messdatei.
Englisch, Deutsch und vereinfachtes Chinesisch werden unterstützt. Auf dem Mac
entscheidet die bevorzugte Systemsprache, im Terminal die Option `--language`.

## Ehrliche Grenzen

Zwischen Prüfungen können kurze Ausfälle unbemerkt bleiben. Standby gilt als
unbeobachtete Zeit. Ein Ping-Fehler beweist keine Störung beim Anbieter. DNS kann
aus dem Systemcache beantwortet werden. Für Vergleiche müssen Geräteuhren stimmen.

Die Tests kontaktieren Cloudflare, Google und example.com; diese sehen die üblichen
Verbindungsdaten. Messdateien bleiben lokal. Berichte enthalten Gerätename,
Zeitpunkte, Netzwerkinterface und Routeradresse. Vor dem Teilen prüfen.

[Messwerte und Tests](verification.md) · [Vollständige technische Anleitung](../README.md)
