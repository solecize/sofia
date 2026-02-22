import unittest
import importlib.util
import json
import io
import tempfile
from pathlib import Path
from contextlib import redirect_stdout
from unittest.mock import patch

# Load the sofia CLI module from tooling/sofia.py
ROOT = Path(__file__).resolve().parents[1]
SOFIA_PY = ROOT / "tooling" / "sofia.py"
spec = importlib.util.spec_from_file_location("sofia", str(SOFIA_PY))
sofia = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sofia)


def _run_notator(workspace=None, switches=None):
    switches = switches or []
    with tempfile.TemporaryDirectory() as tmpdir:
        # Patch sessions dir to keep test isolated
        with patch.object(sofia, "SESSIONS_DIR", Path(tmpdir)):
            buf = io.StringIO()
            with redirect_stdout(buf):
                sofia.notator_run(switches, dry_run=True, workspace_name=workspace)
            echo = json.loads(buf.getvalue())
            # Check a manifest was written
            manifests = list(Path(tmpdir).glob("*/manifest.json"))
            return echo, manifests


class TestResolveSwitches(unittest.TestCase):
    def test_process_default_brief_and_defaults_commit(self):
        switches, alias_map, group_variants, vars_by_ns, templates = sofia.load_library()
        defaults = sofia.load_defaults()
        resolved, included, selected, warnings = sofia.resolve_switches(
            ["-process"], switches, alias_map, group_variants, defaults, tool_name="notator"
        )
        self.assertIn("-report-brief", resolved)
        self.assertEqual(selected["report-detail"]["source"], "tool")
        self.assertEqual(selected["commit-policy"]["chosen"], "-git")
        self.assertIn(selected["commit-policy"]["source"], {"defaults", "workspace", "tool", "cli"})

    def test_cli_override_verbose(self):
        switches, alias_map, group_variants, vars_by_ns, templates = sofia.load_library()
        defaults = sofia.load_defaults()
        resolved, included, selected, warnings = sofia.resolve_switches(
            ["-process", "-report-verbose"], switches, alias_map, group_variants, defaults, tool_name="notator"
        )
        self.assertIn("-report-verbose", resolved)
        self.assertEqual(selected["report-detail"]["chosen"], "-report-verbose")
        self.assertEqual(selected["report-detail"]["source"], "cli")
        # Conflicting included brief should be removed with a warning
        self.assertTrue(any("Removed conflicting variant -report-brief" in w for w in warnings))


class TestRunWithWorkspace(unittest.TestCase):
    def test_meeting_notes_workspace(self):
        echo, manifests = _run_notator(workspace="meeting-notes", switches=["-process"]) 
        data = echo["data"]
        self.assertEqual(data["selectedGroups"]["commit-policy"]["chosen"], "-no-commit")
        self.assertEqual(data["selectedGroups"]["commit-policy"]["source"], "workspace")
        self.assertEqual(data["git"]["policy"], "none")
        self.assertEqual(data["report"]["intendedPath"], "reports/meetings/brief.md")
        self.assertGreaterEqual(len(manifests), 1)

    def test_fiction_notes_workspace(self):
        echo, _ = _run_notator(workspace="fiction-notes", switches=["-process"]) 
        data = echo["data"]
        self.assertEqual(data["selectedGroups"]["commit-policy"]["chosen"], "-git")
        self.assertEqual(data["selectedGroups"]["commit-policy"]["source"], "workspace")
        # report vars override filenames and dir
        self.assertEqual(data["report"]["intendedPath"], "reports/fiction/summary.md")


if __name__ == "__main__":
    unittest.main()
