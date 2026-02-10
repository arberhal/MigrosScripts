# Intune Win32 – Scheduled Tasks (XML) + PowerShell Scripts (User Context)

## Zweck
Dieses Intune-Win32-Paket verteilt:
- PowerShell-Skripte nach `C:\Scripts`
- Scheduled Tasks (aus XML) in den Task-Scheduler-Ordner `\IT Education Services`

Die Tasks laufen **bei Benutzeranmeldung** im **Benutzerkontext** (Interactive Token). Das ist notwendig fuer benutzerspezifische Einstellungen (z. B. Tastaturlayouts), die nicht systemweit per einmaligem SYSTEM-Skript gesetzt werden koennen.

---

## Paketstruktur

IntunePackage
│
├─ ScheduledTasks
│ └─ *.xml
│
├─ Scripts
│ └─ *.ps1
│
├─ Install.ps1
├─ Uninstall.ps1
└─ Detection.ps1

### ScheduledTasks\
Enthaelt die Scheduled-Task-Definitionen als XML.
Regel: **Taskname = XML-Dateiname (BaseName)**

Beispiel:
- `ScheduledTasks\FremdsprachenTastaturLayout.xml`
- Task wird erstellt als: `\IT Education Services\FremdsprachenTastaturLayout`

### Scripts\
Enthaelt die auszufuehrenden PowerShell-Skripte.
Alle Dateien werden nach `C:\Scripts` kopiert.

---

## Funktionsweise (High-Level)

### Installation (Install.ps1, laeuft als SYSTEM ueber Intune)
1. Erstellt `C:\Scripts` falls nicht vorhanden
2. Kopiert alle Dateien aus `Scripts\` nach `C:\Scripts`
3. Erstellt den Task-Scheduler-Ordner `\IT Education Services` falls nicht vorhanden
4. Importiert alle XML-Dateien aus `ScheduledTasks\` als Tasks in `\IT Education Services`
   - Existierende Tasks werden ueberschrieben (Update-faehig)

### Laufzeit (Scheduled Tasks, laeuft bei Logon)
- Bei jeder Benutzeranmeldung wird der jeweilige Task gestartet
- Der Task ruft ein Script aus `C:\Scripts` auf
- Das Script setzt/ergaenzt Einstellungen im Benutzerprofil (z. B. Tastaturlayouts)

### Deinstallation (Uninstall.ps1, laeuft als SYSTEM ueber Intune)
- Entfernt die Tasks basierend auf den XML-Dateien im Paket
- Entfernt die zugehoerigen Skripte basierend auf den PS1-Dateien im Paket
- Loescht `\IT Education Services` nur, wenn der Ordner danach leer ist
- Loescht `C:\Scripts` nur, wenn der Ordner danach leer ist

### Detection (Detection.ps1)
- Keine Hardcodierung einzelner Tasknamen
- Vergleicht dynamisch:
  - Alle `*.xml` im Paket => muessen als Tasks in `\IT Education Services` existieren
  - Alle `*.ps1` im Paket => muessen in `C:\Scripts` existieren
- Rueckgabe:
  - `exit 0` = installiert
  - `exit 1` = nicht installiert

Hinweis: Intune fuehrt Custom Detection Scripts i. d. R. aus einem IMECache-Ordner aus. In diesem Kontext ist die Paketstruktur (ScheduledTasks/Scripts) typischerweise verfuegbar. Falls in einer Umgebung die Paketdateien im Detection-Kontext nicht vorhanden sind, muss Detection alternativ nur ueber Task-Existenz/TaskCount erfolgen.

---

## Vorgaben fuer die XML-Tasks (Wichtig)
Damit es fuer **alle Benutzer** funktioniert, muessen die XMLs folgende Eigenschaften haben:
- Trigger: **Logon**
- **Kein** fest definierter UserId im LogonTrigger (damit "Any user")
- Aktion: `powershell.exe` mit `-File C:\Scripts\<script>.ps1`
- LogonType: **InteractiveToken**
- RunLevel: **LeastPrivilege** (keine hoechsten Privilegien)
- Optional/empfohlen: Task laeuft nur wenn User angemeldet ist (bei InteractiveToken implizit)

---

## Intune (Win32 App) – Empfohlene Einstellungen

### Install command
powershell.exe -ExecutionPolicy Bypass -File Install.ps1
### Uninstall command
powershell.exe -ExecutionPolicy Bypass -File Uninstall.ps1

### Install behavior
- **System**

### Detection rule
- **Custom detection script**: `Detection.ps1`
- Run script as 64-bit: **Yes** (empfohlen)

---

## Wartung / Updates (Langfristig wartungsfaehig)
Neue Tasks / neue Skripte hinzufuegen:
1. Neues XML nach `ScheduledTasks\` legen
2. Neues/angepasstes PS1 nach `Scripts\` legen
3. Win32-Paket neu bauen und in Intune aktualisieren

Update-Verhalten:
- `Install.ps1` ueberschreibt:
  - Skripte in `C:\Scripts` (Copy -Force)
  - Tasks via `schtasks /create /xml ... /f`

Damit ist ein Rollout von neuen/angepassten Tasks/Skripten ohne manuelle Schritte moeglich.

---

## Troubleshooting (Kurz)

### Task laeuft nur fuer Ersteller / nicht fuer andere User
- XML pruefen: LogonTrigger darf keinen festen UserId enthalten
- Principal muss InteractiveToken sein
- Trigger muss "Bei Anmeldung" sein (Any user)

### Task existiert, aber Script wird nicht ausgefuehrt
- Pfad pruefen: `C:\Scripts\<script>.ps1` vorhanden?
- Aktion pruefen: Argumente korrekt (ExecutionPolicy Bypass, -File ...)
- Event Viewer: Microsoft-Windows-TaskScheduler/Operational
- Test als User:
  - `Get-WinUserLanguageList` (oder entsprechende Script-Logik)

### Detection schlaegt fehl
- Pruefen ob alle XML/PS1 Dateien im Paket vorhanden sind (IMECache Kontext)
- Alternativ Detection auf Task-Existenz umstellen (nur TaskFolder/Tasks)

---

## Sicherheit / Prinzip
- Deployment (Install/Uninstall) = SYSTEM (Intune)
- Fachlogik (z. B. Tastaturlayouts) = User Context (Scheduled Task bei Logon)
- Keine Hardcodierung einzelner Tasknamen in Detection/Uninstall (Skalierbarkeit)
