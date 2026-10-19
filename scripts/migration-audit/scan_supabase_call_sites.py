#!/usr/bin/env python3
"""Inventory SchoolPro client/server references to Supabase and HTTP data APIs.

Run from the SchoolPro repository root:
  python scripts/migration-audit/scan_supabase_call_sites.py --root . --out-dir migration-audit-output

Conservative lexical scanner, not a semantic TypeScript/JavaScript parser.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
import re
import subprocess
from pathlib import Path

PATTERNS = [
    ("supabase.from", re.compile(r"\b(?:supabase|client|supabaseClient)\s*\.from\s*\(")),
    ("supabase.rpc", re.compile(r"\b(?:supabase|client|supabaseClient)\s*\.rpc\s*\(")),
    ("supabase.storage", re.compile(r"\b(?:supabase|client|supabaseClient)\s*\.storage\b")),
    ("supabase.auth", re.compile(r"\b(?:supabase|client|supabaseClient)\s*\.auth\b")),
    ("functions.invoke", re.compile(r"\b(?:supabase|client|supabaseClient)\s*\.functions\s*\.invoke\s*\(")),
    ("createClient", re.compile(r"\bcreateClient\s*\(")),
    ("direct-fetch", re.compile(r"\bfetch\s*\(")),
    ("axios", re.compile(r"\baxios(?:\.(?:get|post|put|patch|delete|request))?\s*\(")),
    ("XMLHttpRequest", re.compile(r"\bXMLHttpRequest\b")),
    ("supabase-url", re.compile(r"https?://[A-Za-z0-9.-]+\.supabase\.co")),
    ("rest-or-rpc-path", re.compile(r"/(?:rest/v1|auth/v1|storage/v1|functions/v1|rpc)/")),
]
SKIP_DIRS = {".git", "node_modules", "dist", "build", "coverage", ".next", ".vite"}
TEXT_SUFFIXES = {".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".html", ".json", ".yaml", ".yml", ".toml", ".sql", ".sh", ".ps1"}
MAX_FILE_BYTES = 3_000_000

def tracked_files(root: Path) -> list[Path]:
    try:
        proc = subprocess.run(["git", "-C", str(root), "ls-files", "-z"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        names = [x.decode("utf-8", "replace") for x in proc.stdout.split(b"\0") if x]
        return [root / n for n in names]
    except (FileNotFoundError, subprocess.CalledProcessError):
        return [p for p in root.rglob("*") if p.is_file() and not any(x in SKIP_DIRS for x in p.parts)]

def classify(path: str) -> str:
    p = path.lower()
    if "supabase/functions/" in p: return "edge-function-source"
    if p.startswith("server/") or "/server/" in p: return "server-source"
    if p.startswith("src/") or "/src/" in p: return "client-or-shared-source"
    if p.endswith(".sql"): return "sql-or-migration"
    return "config-or-other"

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".")
    ap.add_argument("--out-dir", default="migration-audit-output")
    args = ap.parse_args()
    root, out = Path(args.root).resolve(), Path(args.out_dir).resolve()
    if not root.is_dir(): raise SystemExit(f"Root is not a directory: {root}")
    out.mkdir(parents=True, exist_ok=True)
    findings, errors, files_seen = [], [], 0
    for path in tracked_files(root):
        if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES: continue
        if any(part in SKIP_DIRS for part in path.parts) or path.stat().st_size > MAX_FILE_BYTES: continue
        try:
            raw = path.read_bytes()
            content = raw.decode("utf-8", "replace")
        except OSError as e:
            errors.append({"path": str(path.relative_to(root)), "error": str(e)})
            continue
        files_seen += 1
        rel, sha = path.relative_to(root).as_posix(), hashlib.sha256(raw).hexdigest()
        for lineno, line in enumerate(content.splitlines(), 1):
            for kind, pattern in PATTERNS:
                for match in pattern.finditer(line):
                    findings.append({"path": rel, "line": lineno, "column": match.start()+1,
                        "pattern": kind, "match": match.group(0)[:200], "context": line.strip()[:500],
                        "file_sha256": sha, "area": classify(rel), "review_status": "unreviewed", "disposition": "review"})
    try:
        git = subprocess.run(["git", "-C", str(root), "rev-parse", "HEAD"], check=True, capture_output=True, text=True).stdout.strip()
    except Exception: git = "unknown-or-not-a-git-checkout"
    meta = {"scanner": "scan_supabase_call_sites.py", "scanner_version": "1.0.0",
        "root": str(root), "git_commit": git, "tracked_text_files_scanned": files_seen,
        "finding_count": len(findings),
        "pattern_counts": {k: sum(1 for f in findings if f["pattern"] == k) for k, _ in PATTERNS},
        "errors": errors, "limitations": [
            "Lexical scan only; does not resolve imports, aliases, wrappers, call graphs, computed names, or runtime-built URLs.",
            "Line hits are not unique database operations; a line can contain multiple hits and wrappers can duplicate downstream use.",
            "No hit does not prove absence. Review generated code, env-driven URLs, SDK wrappers, native code and deployed Edge Functions.",
            "Every finding starts unreviewed/review; raw counts are not migration approval."] }
    (out / "supabase-call-sites.json").write_text(json.dumps({"metadata": meta, "findings": findings}, indent=2)+"\n", encoding="utf-8")
    fields = ["path","line","column","pattern","match","context","file_sha256","area","review_status","disposition"]
    with (out / "supabase-call-sites.csv").open("w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=fields); writer.writeheader(); writer.writerows(findings)
    (out / "supabase-call-sites-metadata.json").write_text(json.dumps(meta, indent=2)+"\n", encoding="utf-8")
    print(json.dumps(meta, indent=2))
    print(f"Outputs: {out / 'supabase-call-sites.json'}")
    print(f"         {out / 'supabase-call-sites.csv'}")
    print(f"         {out / 'supabase-call-sites-metadata.json'}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
