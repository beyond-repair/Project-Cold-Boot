"""Host-side structural checks for Project-Cold-Boot.

These tests do not execute Godot and do not validate gameplay, DLRSE, or
commercial readiness. They lock the Claim-0 surface that smoke_test.gd
already names, so CI can fail closed without a display server.
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_PATHS = (
    "README.md",
    "GOVERNANCE.md",
    "tools/smoke_test.sh",
    "godot/project.godot",
    "godot/tools/smoke_test.gd",
    "godot/scripts/systems/GameState.gd",
    "godot/scripts/main_menu/MainMenu.gd",
    "godot/scripts/vertical_slice/VerticalSlice.gd",
    "godot/scenes/main_menu/MainMenu.tscn",
    "godot/scenes/vertical_slice/VerticalSlice.tscn",
    "godot/shaders/domain_warp_compositor.gdshader",
    "godot/shaders/domain_warp_noise.gdshader",
)

REQUIRED_FUNCS = (
    "reset_demo",
    "begin_frame",
    "log_mutation",
    "commit_frame",
    "_has_path",
    "get_district_name",
    "set_kernel",
    "get_kernel_name",
    "go_to_room",
    "is_rollback_district",
)


class StructureTests(unittest.TestCase):
    def test_required_paths_exist(self) -> None:
        missing = [p for p in REQUIRED_PATHS if not (ROOT / p).is_file()]
        self.assertEqual(missing, [])

    def test_autoload_and_main_scene(self) -> None:
        project = (ROOT / "godot/project.godot").read_text(encoding="utf-8")
        self.assertIn('run/main_scene="res://scenes/main_menu/MainMenu.tscn"', project)
        self.assertIn('GameState="*res://scripts/systems/GameState.gd"', project)
        self.assertIn('"4.2"', project)

    def test_gamestate_surface_named_by_smoke(self) -> None:
        text = (ROOT / "godot/scripts/systems/GameState.gd").read_text(encoding="utf-8")
        for name in REQUIRED_FUNCS:
            self.assertRegex(text, rf"(?m)^func {re.escape(name)}\b", msg=name)

    def test_smoke_script_names_same_loop(self) -> None:
        smoke = (ROOT / "godot/tools/smoke_test.gd").read_text(encoding="utf-8")
        for token in ("reset_demo", "SCAN", "SNAP", "SUNDER", "MainMenu.tscn", "VerticalSlice.tscn"):
            self.assertIn(token, smoke)
        shell = (ROOT / "tools/smoke_test.sh").read_text(encoding="utf-8")
        self.assertIn("smoke_test.gd", shell)
        self.assertIn("set -euo pipefail", shell)

    def test_claim_cap_present_and_commercial_claim_absent(self) -> None:
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        gov = (ROOT / "GOVERNANCE.md").read_text(encoding="utf-8")
        self.assertIn("Claim-0", readme)
        self.assertIn("Not** a commercial Steam game", readme)
        self.assertIn("Claim level:** **0", gov)
        self.assertIn("RESEARCH", gov)
        self.assertIn("Not** a commercial 1.0 / Steam-ready title", gov)
        self.assertNotIn("this repository is a shipped Steam product", readme.lower())
        self.assertNotIn("formally verified DLRSE", gov)


if __name__ == "__main__":
    unittest.main()
