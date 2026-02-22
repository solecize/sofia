#!/usr/bin/env python3
import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple

try:
    import tomllib  # Python 3.11+
except Exception as e:
    print("Python 3.11+ required (tomllib missing)", file=sys.stderr)
    raise

ROOT = Path(__file__).resolve().parent.parent
LIBRARY_DIR = ROOT / "library"
DOCS_DIR = ROOT / "documentation"
CONFIG_DIR = ROOT / "config"
SESSIONS_DIR = ROOT / "sessions"
WORKSPACES_DIR = CONFIG_DIR / "workspaces"

PROMPT_FENCE_RE = re.compile(r"^```(\w+)?\s*$")


@dataclass
class SwitchDef:
    switch: str
    help: str
    tool: str
    path: Path
    prompt: str
    includes: List[str] = field(default_factory=list)
    aliases: List[str] = field(default_factory=list)
    exclusive_group: Optional[str] = None
    is_default_variant: bool = False
    id: Optional[str] = None
    tags: List[str] = field(default_factory=list)


@dataclass
class VarsNS:
    namespace: str
    values: Dict[str, str]


@dataclass
class Templates:
    summary_template: Dict[str, str] = field(default_factory=dict)
    verbose_template: Dict[str, str] = field(default_factory=dict)
    defaults: Dict[str, str] = field(default_factory=dict)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def parse_front_matter(md: str) -> Tuple[Dict, str]:
    lines = md.splitlines()
    # find the first +++ delimiter anywhere (allows headings/comments before front matter)
    start: Optional[int] = None
    for idx, ln in enumerate(lines):
        if ln.strip() == "+++":
            start = idx
            break
    if start is None:
        return {}, md
    # collect TOML until next +++
    toml_lines: List[str] = []
    i = start + 1
    while i < len(lines) and lines[i].strip() != "+++":
        toml_lines.append(lines[i])
        i += 1
    if i >= len(lines):
        # no closing +++; treat as no front matter
        return {}, md
    body = "\n".join(lines[i + 1 :])
    fm = tomllib.loads("\n".join(toml_lines)) if toml_lines else {}
    return fm, body


def extract_fenced_blocks(body: str) -> Dict[str, List[str]]:
    blocks: Dict[str, List[str]] = {}
    lines = body.splitlines()
    i = 0
    while i < len(lines):
        m = PROMPT_FENCE_RE.match(lines[i])
        if m:
            lang = (m.group(1) or "").strip()
            i += 1
            buf: List[str] = []
            while i < len(lines) and not PROMPT_FENCE_RE.match(lines[i]):
                buf.append(lines[i])
                i += 1
            blocks.setdefault(lang, []).append("\n".join(buf).rstrip("\n"))
        i += 1
    return blocks


def load_library() -> Tuple[Dict[str, SwitchDef], Dict[str, str], Dict[str, List[str]], Dict[str, VarsNS], Templates]:
    switches: Dict[str, SwitchDef] = {}
    alias_to_canonical: Dict[str, str] = {}
    group_variants: Dict[str, List[str]] = {}
    vars_by_ns: Dict[str, VarsNS] = {}
    templates = Templates()

    for path in LIBRARY_DIR.rglob("*.md"):
        md = read_text(path)
        fm, body = parse_front_matter(md)
        t = fm.get("type")
        if t == "switch":
            switch = fm.get("switch")
            if not switch:
                continue
            help_text = fm.get("help", "")
            tool = fm.get("tool", "")
            includes = list(fm.get("includes", []))
            aliases = list(fm.get("aliases", []))
            exclusive_group = fm.get("exclusive_group")
            is_default_variant = bool(fm.get("default", False))
            tags = list(fm.get("tags", []))
            blocks = extract_fenced_blocks(body)
            prompt_blocks = blocks.get("prompt", [])
            prompt_text = "\n\n".join(prompt_blocks).strip()
            sdef = SwitchDef(
                switch=switch,
                help=help_text,
                tool=tool,
                path=path,
                prompt=prompt_text,
                includes=includes,
                aliases=aliases,
                exclusive_group=exclusive_group,
                is_default_variant=is_default_variant,
                id=fm.get("id"),
                tags=tags,
            )
            switches[switch] = sdef
            # alias mapping
            alias_to_canonical[switch] = switch
            for a in aliases:
                alias_to_canonical[a] = switch
            # group variants
            if exclusive_group:
                group_variants.setdefault(exclusive_group, []).append(switch)
        elif t == "vars":
            ns = fm.get("namespace")
            blocks = extract_fenced_blocks(body)
            toml_blocks = blocks.get("toml", [])
            merged: Dict[str, str] = {}
            for tb in toml_blocks:
                data = tomllib.loads(tb)
                for k, v in data.items():
                    merged[str(k)] = v if not isinstance(v, (dict, list)) else json.dumps(v)
            if ns:
                vars_by_ns[ns] = VarsNS(namespace=ns, values=merged)
        elif t == "templates":
            blocks = extract_fenced_blocks(body)
            toml_blocks = blocks.get("toml", [])
            for tb in toml_blocks:
                data = tomllib.loads(tb)
                templates.summary_template.update(data.get("summary_template", {}))
                templates.verbose_template.update(data.get("verbose_template", {}))
                templates.defaults.update(data.get("defaults", {}))
        else:
            # non-switch files ignored here
            pass
    return switches, alias_to_canonical, group_variants, vars_by_ns, templates


def load_defaults() -> Dict[str, Dict[str, str]]:
    dpath = CONFIG_DIR / "defaults.md"
    out: Dict[str, Dict[str, str]] = {"groups": {}, "tools": {}}
    if not dpath.exists():
        return out
    md = read_text(dpath)
    # extract first toml fenced block
    blocks = extract_fenced_blocks(md)
    toml_blocks = blocks.get("toml", [])
    if not toml_blocks:
        return out
    data = tomllib.loads(toml_blocks[0])
    # normalize groups defaults
    groups = data.get("groups", {})
    for gname, gcfg in groups.items():
        if isinstance(gcfg, dict) and "default" in gcfg:
            out.setdefault("groups", {})[gname] = {"default": gcfg["default"]}
    # per-tool (optional)
    tools = data.get("tools", {})
    for tname, tcfg in tools.items():
        gdefs = tcfg.get("groups", {})
        if gdefs:
            out.setdefault("tools", {})[tname] = {"groups": {}}
            for gname, gcfg in gdefs.items():
                if isinstance(gcfg, dict) and "default" in gcfg:
                    out["tools"][tname]["groups"][gname] = {"default": gcfg["default"]}
    return out


def load_workspace(name: Optional[str]) -> Tuple[Dict[str, Dict[str, str]], Dict[str, str], Optional[Path]]:
    """
    Load a workspace profile. Returns (workspace_defaults, workspace_vars_flat, path)
    - workspace_defaults matches the structure of load_defaults() for groups and tools
    - workspace_vars_flat is a flat dict like {"report.dir": "..."}
    """
    if not name:
        return {"groups": {}, "tools": {}}, {}, None
    wpath = WORKSPACES_DIR / f"{name}.md"
    if not wpath.exists():
        return {"groups": {}, "tools": {}}, {}, None
    md = read_text(wpath)
    blocks = extract_fenced_blocks(md)
    toml_blocks = blocks.get("toml", [])
    merged: Dict = {}
    for tb in toml_blocks:
        data = tomllib.loads(tb)
        # shallow merge
        for k, v in data.items():
            if isinstance(v, dict) and isinstance(merged.get(k), dict):
                merged[k].update(v)
            else:
                merged[k] = v

    # normalize defaults-like structure
    ws_defaults: Dict[str, Dict[str, str]] = {"groups": {}, "tools": {}}
    groups = merged.get("groups", {})
    # support both {group={default="-x"}} and {group="-x"}
    for gname, gcfg in groups.items():
        if isinstance(gcfg, dict) and "default" in gcfg:
            ws_defaults["groups"][gname] = {"default": gcfg["default"]}
        elif isinstance(gcfg, str):
            ws_defaults["groups"][gname] = {"default": gcfg}

    tools = merged.get("tools", {})
    for tname, tcfg in tools.items():
        gdefs = tcfg.get("groups", {}) if isinstance(tcfg, dict) else {}
        if gdefs:
            ws_defaults.setdefault("tools", {})[tname] = {"groups": {}}
            for gname, gcfg in gdefs.items():
                if isinstance(gcfg, dict) and "default" in gcfg:
                    ws_defaults["tools"][tname]["groups"][gname] = {"default": gcfg["default"]}
                elif isinstance(gcfg, str):
                    ws_defaults["tools"][tname]["groups"][gname] = {"default": gcfg}

    # vars overrides: [vars.<ns>]
    vars_flat: Dict[str, str] = {}
    vroot = merged.get("vars", {})
    if isinstance(vroot, dict):
        for ns, table in vroot.items():
            if isinstance(table, dict):
                for k, v in table.items():
                    vars_flat[f"{ns}.{k}"] = str(v)

    return ws_defaults, vars_flat, wpath

def substitute_vars(text: str, vars_flat: Dict[str, str]) -> str:
    def repl(m: re.Match) -> str:
        key = m.group(1)
        return str(vars_flat.get(key, m.group(0)))

    return re.sub(r"\{([\w\.\-]+)\}", repl, text)


def resolve_switches(
    requested: List[str],
    switches: Dict[str, SwitchDef],
    alias_map: Dict[str, str],
    group_variants: Dict[str, List[str]],
    defaults: Dict[str, Dict[str, str]],
    tool_name: str,
    workspace: Optional[Dict[str, Dict[str, str]]] = None,
) -> Tuple[List[str], List[str], Dict[str, Dict[str, str]], List[str]]:
    warnings: List[str] = []

    # normalize aliases
    cli_switches: List[str] = []
    for s in requested:
        can = alias_map.get(s)
        if not can:
            warnings.append(f"Unknown switch: {s}")
            continue
        cli_switches.append(can)

    # expand includes in order; track includes separately
    resolved: List[str] = []
    included: List[str] = []

    def dfs(s: str):
        if s in resolved:
            return
        sdef = switches.get(s)
        if not sdef:
            warnings.append(f"Missing switch definition: {s}")
            return
        for inc in sdef.includes:
            dfs(inc)
            if inc not in included and inc not in cli_switches:
                included.append(inc)
        resolved.append(s)

    for s in cli_switches:
        dfs(s)

    # exclusive groups selection
    selected_groups: Dict[str, Dict[str, str]] = {}

    # gather candidates by group present in registry
    by_group: Dict[str, List[str]] = {g: [] for g in group_variants.keys()}

    # CLI wins per group
    for gname, variants in group_variants.items():
        chosen_cli: Optional[str] = None
        for s in cli_switches:
            if s in variants:
                chosen_cli = s
        if chosen_cli:
            selected_groups[gname] = {"chosen": chosen_cli, "source": "cli"}
            continue
        # else check includes
        chosen_inc: Optional[str] = None
        for s in resolved:
            if s in variants and s not in cli_switches:
                chosen_inc = s
                break
        if chosen_inc:
            selected_groups[gname] = {"chosen": chosen_inc, "source": "tool"}
            continue
        # else workspace defaults (tool-specific then global)
        if workspace:
            d_ws = (
                workspace.get("tools", {})
                .get(tool_name, {})
                .get("groups", {})
                .get(gname, {})
                .get("default")
            ) or workspace.get("groups", {}).get(gname, {}).get("default")
            if d_ws:
                selected_groups[gname] = {"chosen": d_ws, "source": "workspace"}
                continue
        # else global defaults (tool-specific then global)
        d = (
            defaults.get("tools", {})
            .get(tool_name, {})
            .get("groups", {})
            .get(gname, {})
            .get("default")
        ) or defaults.get("groups", {}).get(gname, {}).get("default")
        if d:
            selected_groups[gname] = {"chosen": d, "source": "defaults"}
            continue
        # else registry default flag
        def_variant = next(
            (sw for sw in variants if switches.get(sw, SwitchDef("", "", "", Path(), "")).is_default_variant),
            None,
        )
        if def_variant:
            selected_groups[gname] = {"chosen": def_variant, "source": "group"}

    # ensure chosen variants are in resolved
    for gname, meta in selected_groups.items():
        ch = meta["chosen"]
        if ch not in resolved:
            resolved.append(ch)

    # drop other variants for a chosen group
    for gname, variants in group_variants.items():
        if gname not in selected_groups:
            continue
        chosen = selected_groups[gname]["chosen"]
        to_remove = [v for v in variants if v != chosen and v in resolved]
        for v in to_remove:
            resolved.remove(v)
            warnings.append(f"Removed conflicting variant {v} in group {gname} (kept {chosen})")

    return resolved, included, selected_groups, warnings


def flatten_vars(vars_by_ns: Dict[str, VarsNS]) -> Dict[str, str]:
    flat: Dict[str, str] = {}
    for ns, v in vars_by_ns.items():
        for k, val in v.values.items():
            flat[f"{ns}.{k}"] = str(val)
    return flat


def notator_list():
    switches, alias_map, group_variants, vars_by_ns, _ = load_library()
    # filter by tool = notator or shared
    items = [s for s in switches.values() if s.tool in ("notator", "shared")]
    items.sort(key=lambda x: x.switch)
    for s in items:
        print(f"{s.switch}\t{s.help}\t{Path(s.path).relative_to(ROOT)}")


def notator_run(cli_switches: List[str], dry_run: bool, workspace_name: Optional[str] = None):
    switches, alias_map, group_variants, vars_by_ns, templates = load_library()
    defaults = load_defaults()
    ws_defaults, ws_vars_flat, ws_path = load_workspace(workspace_name)

    resolved, included, selected_groups, warnings = resolve_switches(
        cli_switches, switches, alias_map, group_variants, defaults, tool_name="notator", workspace=ws_defaults
    )

    # compute variables
    vars_flat = flatten_vars(vars_by_ns)
    # apply workspace var overrides
    for k, v in ws_vars_flat.items():
        vars_flat[k] = v

    # figure report kind from selected group
    report_meta = None
    if "report-detail" in selected_groups:
        chosen = selected_groups["report-detail"]["chosen"]
        kind = "brief" if "brief" in chosen else ("verbose" if "verbose" in chosen else "unknown")
        r_dir = vars_flat.get("report.dir", "reports")
        r_brief = vars_flat.get("report.brief_filename", "brief.md")
        r_full = vars_flat.get("report.verbose_filename", "full.md")
        intended = f"{r_dir}/" + (r_brief if kind == "brief" else r_full)
        report_meta = {"kind": kind, "intendedPath": intended}

    # git policy
    git_policy = {
        "policy": "auto" if selected_groups.get("commit-policy", {}).get("chosen") == "-git" else "none",
        "source": selected_groups.get("commit-policy", {}).get("source", "defaults"),
    }

    # compose prompts (substitute variables)
    composed_prompts: List[str] = []
    for s in resolved:
        sdef = switches.get(s)
        if not sdef:
            continue
        if not sdef.prompt:
            continue
        composed_prompts.append(substitute_vars(sdef.prompt, vars_flat))

    # source files mapping
    source_files = {s: str(Path(switches[s].path).relative_to(ROOT)) for s in resolved if s in switches}

    # ui text
    ui = "Organize notes: " + ", ".join(resolved)

    data = {
        "tool": "notator",
        "requestedSwitches": cli_switches,
        "includedSwitches": included,
        "resolvedSwitches": resolved,
        "variables": vars_flat,
        "composedPrompts": composed_prompts,
        "sourceFiles": source_files,
        "selectedGroups": selected_groups,
        "events": [],
        "report": report_meta,
        "git": git_policy,
        "warnings": warnings,
    }

    if workspace_name and ws_path:
        data["workspace"] = {
            "name": workspace_name,
            "path": str(ws_path.relative_to(ROOT)),
            "source": "cli",
        }

    echo = {
        "ui": ui,
        "ask": {"confirm": {"default": True, "options": ["continue", "revise", "cancel"]}},
        "data": data,
        "next": {"cmd": "notator.run", "args": {"apply": False}},
    }

    # print echo JSON
    print(json.dumps(echo, indent=2))

    # write session manifest
    ts = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%SZ")
    sess_dir = SESSIONS_DIR / ts
    sess_dir.mkdir(parents=True, exist_ok=True)
    (sess_dir / "manifest.json").write_text(json.dumps(echo, indent=2), encoding="utf-8")


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(prog="sofia", description="Sofia CLI (MVP)")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_list = sub.add_parser("notator-list", help="List Notator switches")

    p_run = sub.add_parser("notator-run", help="Run Notator with switches")
    p_run.add_argument("switches", nargs="*", help="Switches like -process -preview -report-verbose")
    p_run.add_argument("--apply", action="store_true", help="No-op in MVP (prompt-only)")
    p_run.add_argument("--workspace", help="Select a workspace profile from config/workspaces", default=None)

    # Parse known args so dash-prefixed switches (e.g., -process) are captured in unknowns
    args, unknown = parser.parse_known_args(argv)

    if args.cmd == "notator-list":
        notator_list()
        return 0
    elif args.cmd == "notator-run":
        # Combine positional switches and any unknown tokens (e.g., -process)
        switches = list(getattr(args, "switches", [])) + list(unknown)
        notator_run(switches, dry_run=not args.apply, workspace_name=args.workspace)
        return 0
    else:
        parser.print_help()
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
