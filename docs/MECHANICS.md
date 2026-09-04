# Mechanics Reference — Auditor Bias & District Threat

## Auditor Bias

Auditors do not fight. They **remove authorship options** by locking anchors.

### When they act
After enough SNAPs (threshold from Kernel + district threat), if not yet active, the next SNAP frame may include `AUD_LOCK`.

| Kernel | Base SNAP threshold |
|--------|---------------------|
| Final Commit | 1 |
| Force Revert | 2 |
| Keep Drafting | 3 |

If district **threat ≥ 0.85**, threshold drops by 1 (min 1).

### How they choose the lock (bias score)
For each candidate node (not already locked, not start 0 or exit 3):

```
score = degree * 2
      + 3 if node appears in recent SNAP path
      + 1.5 * threat if Layer 0 (Necropolis)
      + 0.5 if Layer 1
      + degree again if Final Commit
      * 0.75 if Keep Drafting
```

Highest score wins. Effect: hubs on your recent route get shut down; ink-layer hubs hurt more in high-threat districts.

### Player skill
Stay unreadable: change routes, use alternate mid-nodes, switch Kernel to delay pressure.

---

## District Threat

Threat ∈ [0,1] is a **design scalar** per district (from art boards). It feeds:

| System | Effect |
|--------|--------|
| UI | Threat % on room label |
| Bleed | Baseline / post-SCAN intensity scales with threat |
| Auditor | Earlier threshold at high threat; Layer-0 lock weight × threat |
| Tone | Sable lines and node naming |

### District table

| District | Threat | Pressure fantasy |
|----------|--------|------------------|
| Compiler Heights | 0.90 | Corporate immune system |
| Static Market | 0.68 | Betrayal / social risk |
| Ghost Rail | 0.50 | Motion, unstable routes |
| Rollback District | 0.70 | Time loop / pattern cages |
| Dead Repository | 0.82 | Wardens restore your work |
| The Sink | 0.95 | Collapse; minimal safety |

Threat is **not** a hidden RPG stat. It is readable pressure on the same graph rules.
