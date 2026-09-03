# How to Play (Current Build — Cycle 4)

## Run

1. Godot 4.2+
2. Open `godot/` folder
3. F5

## Controls

| Input | Action |
|-------|--------|
| **E** | SCAN |
| **Left Mouse** | SNAP (select two nodes) |
| **Space** | SUNDER |
| **R** | Reset current run |
| **Esc** | Pause |
| **H** | Toggle history panel |
| **1 / 2 / 3** | Select Kernel (Final Commit / Force Revert / Keep Drafting) |
| **N** | Go to next room (after win) |

## Objective

- Room 1: Connect node 0 (Lamp) to the Gate via SNAP links, then SUNDER.
- Auditor will lock a node (timing depends on Kernel).
- After win, press **N** to enter Room 2 (different layout).
- Kernels change how early the Auditor intervenes.

## Kernels

- **1 Final Commit** — Auditor locks early (aggressive)
- **2 Force Revert** — Medium
- **3 Keep Drafting** — More tolerant (locks later)
