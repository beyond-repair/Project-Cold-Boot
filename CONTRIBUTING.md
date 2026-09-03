# Contributing to Project Cold Boot

This is currently a solo-dev project under active architecture lock. The highest-value contributions at this stage are:

1. Feedback on the vertical slice specification
2. Determinism / performance testing once the slice exists
3. Documentation clarity improvements

## Engineering Constitution

Any code contribution must satisfy:

- Emit MutationRecords only
- Never mutate ActiveGraph directly
- Remain replay deterministic
- Stay within GPR frame budget
- Degrade gracefully under pressure
- Serialize deterministically
- Pass the replay harness
- Preserve DCB as sole state mutation authority

See `docs/DLRSE.md` and `docs/BIBLE.md`.

## Scope Discipline

Do not expand foundational systems until the vertical slice is validated. Experience drives systems.
