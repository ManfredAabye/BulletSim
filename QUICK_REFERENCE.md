# Quick Reference: Patches für Produktionsumgebung

## Status Summary

⚠️ **WICHTIG: Geschwindige Übersicht für Deployment**

| Patch | Category | Status | Action | Priority |
| --- | --- | --- | --- | --- |
| **Transform Update Sleep** | CRITICAL | ✅ Vorhanden | Verify | 🔴 HIGH |
| **Joint Force Constraints** | OPTIONAL | ❌ Fehlt | Optional | 🟡 MEDIUM |
| **SIMD Shuffle (2.86)** | FIXED | ✅ In 3.27 | Keine | ✅ N/A |
| **glibc memcpy Wrapping** | PLATFORM | ✅ Implementiert | Verify | 🟡 MEDIUM |

## ⚡ KURZ-ANLEITUNG: Was muss ich tun?

### **Schritt 1: Überprüfe ob Transform-Patch vorhanden ist** (1 Min)

```bash
cat 0001-Call-setWorldTransform-when-object-is-going-inactive.patch
# Sollte ca. 20 Zeilen sein mit "setWorldTransform"
```

✅ **Hab ich bereits - Weiter zu Schritt 2**

### **Schritt 2: Überprüfe ob Patch im Build angewendet wird** (2 Min)

**Windows:**

```batch
02buildBulletCMake.bat
# In der Ausgabe sollten diese Zeilen sichtbar sein:
# "Applying patches to Bullet source"
# "patching file src/BulletDynamics/Dynamics/btDiscreteDynamicsWorld.cpp"
```

**Linux/macOS:**

```bash
./l02buildBulletCMake.sh
# In der Ausgabe sollte stehen:
# "✓ Transform patch applied successfully"
```

### **Schritt 3: Verifiziere dass Patch im Binary vorhanden ist** (3 Min)

```bash
# Nach Build:
strings lib/libBulletDynamics.a | grep -i "setWorldTransform"
# Sollte Treffer haben
```

### **Schritt 4: Teste in Nicht-Produktionsumgebung** (Tage)

```txt
1. Kleine Test-Region mit 10 Objekten
   ✓ Objekte positionieren und ins Sleep gehen lassen
   ✓ Andere Clients sollten gleiche Positionen sehen
   
2. Mittlere Region mit 50+ Objekten
   ✓ 30 Min laufen lassen
   ✓ Memory sollte stabil sein
   
3. Avatar Physics Test
   ✓ 5 Avatare in Region
   ✓ Jumping/Flying sollte synchronisiert sein
```

## 🔴 FEHLER-CHECKLISTE

### ❌ "Physik-Objekte verschwinden/freezen"

→ **Problem:** Transform-Patch nicht angewendet  
→ **Lösung:** Siehe Schritt 2-3 oben, Build neu

### ❌ "Avatar-Positionen unterscheiden sich zwischen Clients"

→ **Problem:** Motion State Callbacks nicht aktiv  
→ **Lösung:** Transform-Patch nicht angewendet

### ❌ "Fahrzeuge sind instabil/springen"

→ **Problem:** Joint Force Patch fehlt (optional)  
→ **Lösung:** Optional - siehe PATCHES_ANALYSIS.md Patch #2

### ❌ "Linux: libBulletSim.so lädt nicht"

→ **Problem:** glibc-Mismatch  
→ **Lösung:** Überprüfe memcpy-Wrapping in l03buildBulletSim.sh

### ❌ "Windows: Physics unterscheidet sich bei jedem Start"

→ **Problem:** `/fp:fast` Compiler-Flag verwendet  
→ **Lösung:** Überprüfe 02buildBulletCMake.bat - sollte `/fp:precise` sein

---

## 📋 CHECKLISTE FÜR PRODUCTION DEPLOYMENT

### Pre-Deploy (einmalig)

- [ ] Transform-Patch `0001-Call-setWorldTransform...` existiert
- [ ] Patch wird in `l02buildBulletCMake.sh` / `02buildBulletCMake.bat` angewendet
- [ ] Build erfolgreich, keine Fehler
- [ ] `libBulletSim-3.27-*.so/dll` wurde erstellt
- [ ] Patch-Effekt verifiziert mittels `strings lib/libBulletDynamics.a`

### Pre-Live (vor Aktivierung)

- [ ] Test-Region: 10 statische + 5 dynamische Objekte → Objects gehen in Sleep → Positionen aktualisiert ✓
- [ ] Test-Region: 5 Avatare → Positions-Sync zwischen Clients korrekt ✓  
- [ ] Monitor 30 Min: Speicher stabil, keine Crashes ✓
- [ ] Optional: Fahrzeug-Test wenn Fahrzeuge verwendet werden ✓

### Notfall-Rollback

```bash
# Falls Probleme in Live-Umgebung:
# 1. Deaktiviere Physics (OpenSimulator.ini):
#    DefaultPhysicsEngine = Default
# 2. Restart Regions
# 3. Build alte Version oder repariere Patch
```

## 📊 EXPECTED RESULTS

### Mit Patch ✅

```txt
- Avatar steht auf Objekt
- Avatar wird idle (steht still)
- Andere Clients sehen Avatar auf _gleicher Position_
- Objekt bleibt sichtbar
```

### Ohne Patch ❌

```txt
- Avatar steht auf Objekt
- Avatar wird idle
- Andere Clients sehen Avatar an anderer Position
- Objekt kann "versetzen" oder verschwinden
```

---

## 🚀 PRODUCTION DEPLOYMENT CHECKLISTE

### Schritt 1: SETUP (einmalig - ✅ Bereits getan)

```txt
✅ Repository geklont
✅ Patches vorhanden (0001-Call-setWorldTransform...)
✅ Build-Skripte angepasst
✅ BUILD.md und README.md aktualisiert
```

### Schritt 2: VERIFY (vor Production)

```txt
☐ Build durchgeführt: ./01.../02.../03... durchlaufen
☐ No-Error-Build verifiziert
☐ Patch-Anwendung in Build-Log überprüft
☐ libBulletSim Binary existiert
☐ strings-Check durchgeführt
```

### Schritt 3: TEST (vor Live)

```txt
☐ Sandbox-Region erstellt
☐ Test-Szenarien (s.o.) durchgeführt  
☐ 30-Min Stability Test abgeschlossen
☐ Memory-Monitoring OK
```

### Schritt 4: DEPLOY (Production)

```txt
☐ Live-Region konfiguriert
☐ Regionen-Snapshot gemacht (Backup)
☐ Physics aktiviert
☐ Test mit Users (auch Multi-Client-Test)
☐ Monitor 24h für Issues
```

### Schritt 5: MONITOR (laufend)

```txt
☐ Tägliche Logs auf Fehler überprüfen
☐ Weekly Performance-Report
☐ Quarterly Stability Review
```

---

## 💬 SUPPORT-KONTAKT INFORMATIONEN

Falls Probleme auftreten:

1. **Überprüfe PATCHES_ANALYSIS.md** für detaillierte Erklärungen
2. **Überprüfe PATCH_APPLICATION_GUIDE.md** für Anwend-Details  
3. **Überprüfe BUILD.md** für Build-Troubleshooting
4. **Überprüfe Logs:**
   - Windows: `logs/buildBulletCMake.log`
   - Linux: `logs/buildBulletCMake.log`
   - OpenSim: `log/` Verzeichnis

---

## QUICK LINKS

- **Detaillierte Patch-Analyse:** [PATCHES_ANALYSIS.md](PATCHES_ANALYSIS.md)
- **Patch-Anwend-Anleitung:** [PATCH_APPLICATION_GUIDE.md](PATCH_APPLICATION_GUIDE.md)
- **Build-Dokumentation:** [BUILD.md](BUILD.md)
- **Repository Überblick:** [README.md](README.md)

---

**Version:** 1.0  
**Datum:** 2026-03-24  
**Status:** ✅ PRODUCTION-READY
