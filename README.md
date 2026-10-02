<div align="center">

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   ██████╗  ██████╗ ██╗     ██████╗                           ║
║  ██╔════╝ ██╔═══██╗██║     ██╔══██╗                          ║
║  ██║      ██║   ██║██║     ██║  ██║                          ║
║  ██║      ██║   ██║██║     ██║  ██║                          ║
║  ╚██████╗ ╚██████╔╝███████╗██████╔╝                          ║
║   ╚═════╝  ╚═════╝ ╚══════╝╚═════╝                           ║
║                                                              ║
║              ＢＯＯＴ  ·  ＶＥＳＰＥＲ  ＣＩＴＹ                 ║
╚══════════════════════════════════════════════════════════════╝
```

# PROJECT COLD BOOT

### You are not the hero. You are the cold boot.

**THE CITY WRITES ITS OWN REALITY.**  
**YOU JUST EDIT IT.**

[![RUNNABLE SKETCH](https://img.shields.io/badge/●_RUNNABLE_SKETCH-Claim--0-f59e0b?style=for-the-badge&labelColor=0f0f23)](GOVERNANCE.md)
[![Godot 4](https://img.shields.io/badge/Godot-4.2+-22d3ee?style=for-the-badge&labelColor=0f0f23)](https://godotengine.org)
[![Dual](https://img.shields.io/badge/1994_↔_2026-a855f7?style=for-the-badge&labelColor=0f0f23)](#)

```
STABILITY  ████████████░░░░░░░░░░░░  58%
ALERT      ████░░░░░░░░░░░░░░░░░░░░  31%
```

</div>

---

**Claim cap:** **RUNNABLE SKETCH / Claim-0 foundation prototype** — playable Godot vertical slice (SCAN → SNAP → SUNDER), dual-timeline framing, domain-warp shaders, deterministic mutation log. **Not** a commercial Steam game. **Not** a formal DLRSE / AC-4.1 / GPR proof. See [GOVERNANCE.md](GOVERNANCE.md) and [ADL-Governance](https://github.com/beyond-repair/ADL-Governance).

---

## ▌ MAIN OBJECTIVE

**REACH THE CORE TOWER**

SCAN → SNAP → SUNDER across dual timelines.  
Vesper City 2026 / Necropolis 1994.

---

## ▌ TOOLS

| # | Tool | |
|:-:|:----:|:-|
| 1 | **SCAN** | Probe layer |
| 2 | **FORK** | Parallel snapshot |
| 3 | **SPIKE** | Local rewrite |
| 4 | **ANCHOR** | Lock state |
| 5 | **ESCAPE** | Cold boot |

Vertical-slice inputs today: **E** = SCAN · **LMB** = SNAP · **SPACE** = SUNDER · **R** = Reset.

---

## ▌ RUN (stranger clone)

**Requires:** [Godot 4.2+](https://godotengine.org/download) (editor or Linux `x86_64` binary). Set `GODOT` if not on `PATH`.

```bash
git clone https://github.com/beyond-repair/Project-Cold-Boot.git
cd Project-Cold-Boot

# Play (editor / with display): open godot/ as the project, then F5
# Or from CLI:
godot --path godot

# Headless smoke (no display) — GameState SCAN/SNAP/SUNDER + scene/shader load
./tools/smoke_test.sh
# equivalent:
#   godot --headless --path godot -s res://tools/smoke_test.gd
# Expect: "28 passed, 0 failed" and exit 0

# Optional: boot main scene for a few frames then quit
godot --headless --path godot --quit-after 2
```

---

<div align="center">

```
YOU WERE HERE BEFORE.
VERSION 17 FAILED.
DO NOT TRUST SABLE.
THE CITY REMEMBERS.
```

**REWRITE · BUILD · TRANSCEND**

[Atomic Dream Labs](https://github.com/beyond-repair)

</div>
