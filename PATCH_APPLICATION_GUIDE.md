# Patch Application Guide für BulletSim 3.27

**Datum:** 2026-03-24  
**Ziel:** Anleitung zur Anwendung von Patches auf Bullet 3.x Quellcode während des Builds

---

## Overview

Der Build-Prozess für BulletSim besteht aus zwei Phasen:

1. **Phase 1:** Bullet Physics Engine bauen (CMake + Compiler)
2. **Phase 2:** BulletSim C++ Glue Code bauen (MSBuild/Make)

Patches werden in **Phase 1** angewendet, bevor CMake läuft.

---

## Patch #1: Transform Update bei Sleep (KRITISCH)

### Status

- **Patch-Datei:** `0001-Call-setWorldTransform-when-object-is-going-inactive.patch`
- **Zieldatei:** `bullet3/src/BulletDynamics/Dynamics/btDiscreteDynamicsWorld.cpp`
- **Zeilen:** ~616-623
- **Status:** ✅ Manuell verifizierbar

### Anwendung

#### Option A: Automatisch via Skript (empfohlen)

**Datei:** `makeBullets.sh` (existiert bereits)

```bash
#!/usr/bin/env bash

# ...

# Apply patches to Bullet source
echo "Applying patches to Bullet 3..."
cd "$BASE/${BULLETDIR}"

# Apply setWorldTransform patch for motion state updates
patch -p1 < ../0001-Call-setWorldTransform-when-object-is-going-inactive.patch
if [ $? -ne 0 ]; then
    echo "WARNING: Patch failed. Object motion state updates may not work correctly."
    echo "See PATCHES_ANALYSIS.md for more information."
fi

# ...continue with build
```

#### Option B: Manuell via Patch-Befehl

```bash
cd bullet3/
patch -p1 < ../0001-Call-setWorldTransform-when-object-is-going-inactive.patch
```

**Erwartete Ausgabe:**

```txt
patching file src/BulletDynamics/Dynamics/btDiscreteDynamicsWorld.cpp
```

#### Option C: Manueller Edit

**Datei:** `bullet3/src/BulletDynamics/Dynamics/btDiscreteDynamicsWorld.cpp`

**Finden Sie (ca. Zeile 616):**

```cpp
void btDiscreteDynamicsWorld::updateActivationState(btScalar timeStep)
{
    // ...
    if (body->getActivationState() == ISLAND_SLEEPING)
    {
        body->setAngularVelocity(btVector3(0, 0, 0));
        body->setLinearVelocity(btVector3(0, 0, 0));
    }
}
```

**Ersetzen durch:**

```cpp
void btDiscreteDynamicsWorld::updateActivationState(btScalar timeStep)
{
    // ...
    if (body->getActivationState() == ISLAND_SLEEPING)
    {
        body->setAngularVelocity(btVector3(0, 0, 0));
        body->setLinearVelocity(btVector3(0, 0, 0));
        // when sleeping, force the motion state to be called/updated
        if (body->getMotionState())
            body->getMotionState()->setWorldTransform(body->getWorldTransform());
    }
}
```

### Verifikation

**Nach dem Build überprüfen:**

```bash
# Windows
cd BulletSim
findstr /C:"setWorldTransform(body->getWorldTransform())" build\BulletDynamics\CMakeFiles\BulletDynamics.dir\Dynamics\*.cpp

# Linux/macOS
cd BulletSim/bullet3
grep -r "setWorldTransform(body->getWorldTransform())" .. | grep -v ".patch"
```

**Erwartung:** Ungefähr 3 Treffer im Code (original + patch)

---

## Patch #2: Joint Force Constraints (OPTIONAL)

### Status2

- **Patch-Datei:** Nicht im Repository - muss erstellt werden
- **Zieldateien:**
  - `bullet3/src/BulletDynamics/ConstraintSolver/btConstraintSolver.cpp`
  - `bullet3/src/BulletDynamics/ConstraintSolver/btHingeConstraint.cpp`
- **Quelle:** Bulletphysics GitHub PR #2956, #3045

### Nur wenn erforderlich (für Fahrzeugphysik)

Wenn Sie Fahrzeuge mit Constraints haben, die instabil sind:

#### Schritt 1: Patch finden/erstellen

```bash
# Option A: Von OpenSimulator adaptieren
curl -s https://raw.githubusercontent.com/opensimulator/OpenSim-PhysicsModules/master/PhysicsMeshing/BulletSim/Patches/joint-force-fix.patch \
  > bullet3/joint-force-fix.patch

# Option B: Manuell basierend auf PR #2956
# https://github.com/bulletphysics/bullet3/pull/2956/files
```

#### Schritt 2: Anwenden

```bash
cd bullet3
patch -p1 < joint-force-fix.patch
```

#### Schritt 3: Kompilieren und testen

```bash
# Nach regulärem Build Test durchführen
# Test: Fahrzeug mit RotorTargetOmega für 5 Minuten laufen lassen
# Sollte stabil bleiben ohne Jitter
```

### Wenn nicht verfügbar: BulletSim.cpp Workaround

In `BulletSim.cpp` können Sie einen Workaround einbauen:

```cpp
// BulletSim.cpp - Forces for constrained bodies
void BulletSim::applyConstraintForces()
{
    for (auto constraint : constraints_) {
        // Force the constraint solver to re-evaluate forces
        constraint->calculateTransforms();
        constraint->buildJacobian();
        // ... apply forces manually if needed
    }
}
```

---

## Patch Application Timeline (Build-Prozess)

```txt
┌─────────────────────────────────────────┐
│  01buildBulletClear.bat/sh              │
│  - Räume auf, lösche alte Build         │
└────────────────────┬────────────────────┘
                     │
┌────────────────────▼────────────────────┐
│  02buildBulletCMake.bat/sh              │
│  Step 1: Git clone bullet3              │
│  Step 2: ▶ APPLY PATCHES HERE ◀         │
│    └─ patch -p1 < 0001-*.patch          │
│    └─ [patch #2 if needed]              │
│  Step 3: CMake configure                │
│  Step 4: CMAKE BUILD                    │
│  Step 5: Copy headers/libs              │
└────────────────────┬────────────────────┘
                     │
┌────────────────────▼────────────────────┐
│  03buildBulletSim.bat/sh                │
│  - Baue BulletSim C++ Glue Code         │
│  - Link gegen gebaute Bullet Libraries  │
└────────────────────┬────────────────────┘
                     │
                     ▼
            🎯 OUTPUT BINARY 🎯
      libBulletSim-3.27-*.so/dll
```

---

## Build-Skripte anpassen

### Windows: 02buildBulletCMake.bat

**Hinzufügen nach dem Clone (ca. Zeile 26):**

```batch
if not exist "%BULLETROOT%\" (
    echo === BULLETDIR not found. Cloning Bullet into %BULLETROOT%
    git clone --depth 1 --single-branch --branch master https://github.com/bulletphysics/bullet3.git "%BULLETROOT%"
    if errorlevel 1 exit /b 1
)

REM ▶ NEW: Apply patches
echo === Applying patches to Bullet source
cd "%BULLETROOT%"
patch -p1 < ..\0001-Call-setWorldTransform-when-object-is-going-inactive.patch
if errorlevel 1 (
    echo WARNING: Patch application failed - physics motion state updates may not work
)
cd "%BUILDROOT%"
REM ◀ END
```

### Linux/macOS: l02buildBulletCMake.sh

**Hinzufügen nach dem Clone (ca. Zeile 56):**

```bash
if [[ ! -d "$BULLETDIR" ]]; then
    echo "$ECHOLINE"
    echo "=== BULLETDIR not found. Cloning Bullet into $BULLETDIR"
    echo "$ECHOLINE"
    git clone --depth 1 --single-branch --branch master https://github.com/bulletphysics/bullet3.git "$BULLETDIR"
fi

# ▶ NEW: Apply patches
print_section "Applying BulletSim patches to Bullet source"
cd "$BULLETDIR"
if patch -p1 < ../0001-Call-setWorldTransform-when-object-is-going-inactive.patch; then
    echo "✓ Transform patch applied successfully"
else
    echo "✗ WARNING: Transform patch failed - physics motion state updates may not work correctly"
fi
cd - > /dev/null
# ◀ END
```

---

## Patch-Kompatibilität überprüfen

### Pre-Build Check

```bash
# Simuliere Patch ohne zu aplikuieren (-p1 --dry-run)
cd bullet3
patch --dry-run -p1 < ../0001-Call-setWorldTransform-when-object-is-going-inactive.patch
```

**Erwartung:**

```txt
checking file src/BulletDynamics/Dynamics/btDiscreteDynamicsWorld.cpp
```

Keine Fehler = OK zum Anwenden

### Post-Build Verification

```bash
# Überprüfe ob Patch tatsächlich im Objektcode ist
strings libBulletDynamics.a | grep -i "motion" | head -5

# Oder: Decompile um Patch zu sehen
objdump -d libBulletDynamics.a | grep -A 10 "updateActivationState"
```

---

## Troubleshooting

### Problem: "Patch already applied"

**Symptom:**

```txt
patch: **** malformed patch at line 10: Already applied in file ...
```

**Lösung:**

```bash
# Option 1:  Überprüfe ob Patch bereits vorhanden ist
grep "setWorldTransform(body->getWorldTransform())" \
  bullet3/src/BulletDynamics/Dynamics/btDiscreteDynamicsWorld.cpp

# Option 2: Patch zurückrollen und neu anwenden
patch -R -p1 < 0001-*.patch   # Reverse apply
patch -p1 < 0001-*.patch       # Re-apply

# Option 3: Build cleannen
01buildBulletClear.bat  # Windows
l01buildBulletClear.sh  # Linux/macOS
# ... dann neu bauen
```

### Problem: "Hunk FAILED"

**Symptom:**

```txt
Hunk #1 FAILED at 616.
Hunk #2 FAILED at 750.
```

**Ursache:**  

- Zeilen haben sich verschoben (andere Bullet-Version als erwartet)
- Quellcode unterscheidet sich

**Lösung:**

```bash
# Überprüfe Bullet-Version
cat bullet3/VERSION

# Überprüfe erwartete Zeilen
sed -n '614,625p' bullet3/src/BulletDynamics/Dynamics/btDiscreteDynamicsWorld.cpp

# Manuell anpassen wenn notwendig (siehe Option C oben)
```

### Problem: "No such file or directory"

**Symptom:**

```txt
patch: can't find file to patch
```

**Lösung:**

```bash
# Überprüfe aktuellen Verzeichnis
pwd  # Sollte Bullet-root sein oder parent

# Richtige Reihenfolge:
cd bullet3/
patch -p1 < ../0001-Call-setWorldTransform-when-object-is-going-inactive.patch

# ODER:
patch -p0 < 0001-Call-setWorldTransform-when-object-is-going-inactive.patch
```

---

## Patch-Verwaltung für Zukunft

### Neue Patches erstellen

```bash
# Lokal ändern:
cd bullet3/src/BulletDynamics/Dynamics/
# ... edit btDiscreteDynamicsWorld.cpp ...

# Patch generieren:
cd /d:/BulletSim
git diff bullet3/src/BulletDynamics/Dynamics/btDiscreteDynamicsWorld.cpp \
  > 0002-my-custom-fix.patch

# Überprüfe Patch:
git apply --check 0002-my-custom-fix.patch
```

### Patch-Serie verwalten

```bash
# Alle Patches auf einmal anwenden
for patch in 000*.patch; do
    echo "Applying $patch..."
    patch -p1 < "$patch" || exit 1
done
```

---

## DoD (Definition of Done) für Patches

✅ Patch wurde erfolgreich angewendet
✅ Build läuft ohne Fehler/Warnungen  
✅ BulletSim Binary wurde erstellt
✅ Patch-Effekt wurde im Binary verifiziert
✅ Dokumentation wurde aktualisiert (dieses Dokument)

---

## Weiterführende Ressourcen

- **GNU patch Manual:** <https://www.gnu.org/software/patch/manual/patch.html>
- **Bullet Physics GitHub:** <https://github.com/bulletphysics/bullet3/pulls>
- **OpenSim Physics Docs:** <http://opensimulator.org/wiki/Physics>
