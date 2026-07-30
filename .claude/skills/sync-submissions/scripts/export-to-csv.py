"""Normalize the Google Form XLSX export for the sync and evaluation flows.

Reads the .xlsx with the standard library only (an xlsx is a zip of XML — no
openpyxl on the machine, and no reason to need it), plus an optional
extra-participants.csv for submissions that arrived outside the form, and writes:

    _submissions/responses.csv        Timestamp, Full name, Email, Git repository URL,
                                      Submitted branch, Answers  (input to sync-repos.ps1)
    _submissions/review/answers/<slug>.md    one file per student with their project
                                      description — each evaluator receives ONLY its own
                                      student's file, which is part of the isolation story

GitHub "tree" URLs are normalized here: students paste the page they are looking
at, which is often https://github.com/u/repo/tree/<branch>. That is not a clonable
URL, and the branch is signal, not noise — it is where their work lives. The URL
is stripped to the repository root and the branch recorded in its own column.

Usage:
    python export-to-csv.py "<form export>.xlsx" [extra-participants.csv]
"""
import csv
import html
import pathlib
import re
import sys
import zipfile
from datetime import datetime, timedelta

OUT_DIR = pathlib.Path("_submissions")
NO_ANSWERS_MARKER = (
    "ANSWERS UNAVAILABLE — the participant could not submit the project description due "
    "to a technical issue with the form (office network/VPN), through no fault of their "
    "own. Score the answers-verification line 0 for now, to be re-scored on receipt. Do "
    "NOT treat the absence as evidence against any other line."
)


def read_xlsx(path):
    z = zipfile.ZipFile(path)
    shared = []
    if "xl/sharedStrings.xml" in z.namelist():
        xml = z.read("xl/sharedStrings.xml").decode("utf-8")
        shared = [html.unescape(re.sub(r"<[^>]+>", "", m))
                  for m in re.findall(r"<si>(.*?)</si>", xml, re.S)]
    sheet = z.read("xl/worksheets/sheet1.xml").decode("utf-8")
    rows = []
    for row_xml in re.findall(r"<row[^>]*>(.*?)</row>", sheet, re.S):
        cells = {}
        for m in re.finditer(r'<c r="([A-Z]+)\d+"(?:[^>]*t="(\w+)")?[^>]*>(?:<v>(.*?)</v>)?', row_xml):
            col, typ, val = m.groups()
            if val is None:
                continue
            cells[col] = shared[int(val)] if typ == "s" else val
        if cells:
            rows.append(cells)
    return rows


def excel_date(serial):
    try:
        return (datetime(1899, 12, 30) + timedelta(days=float(serial))).strftime("%Y-%m-%d %H:%M:%S")
    except (TypeError, ValueError):
        return str(serial or "")


def slug_of(name):
    s = re.sub(r"[^a-z0-9]+", "-", name.strip().lower()).strip("-")
    return s or "unknown"


def split_tree_url(url):
    """https://github.com/u/repo/tree/branch[/...] -> (clone URL, branch)."""
    url = url.strip()
    m = re.match(r"^(https?://[^/]+/[^/]+/[^/]+?)(?:\.git)?/tree/([^?#]+?)/?$", url)
    if m:
        return m.group(1), m.group(2)
    return re.sub(r"\.git$", "", url), ""


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    rows = read_xlsx(sys.argv[1])
    header, data = rows[0], rows[1:]

    def col_of(pattern):
        for col, title in header.items():
            if re.search(pattern, title, re.I):
                return col
        return None

    c_time = col_of(r"^timestamp")
    c_name = col_of(r"full\s*name")
    c_mail = col_of(r"^e-?mail")            # the form-collected address, column B
    c_repo = col_of(r"repo")
    c_desc = col_of(r"project\s*description")
    if not (c_name and c_repo):
        sys.exit(f"Could not find name/repo columns in: {dict(sorted(header.items()))}")

    answers_dir = OUT_DIR / "review" / "answers"
    answers_dir.mkdir(parents=True, exist_ok=True)

    out, seen = [], {}
    for row in data:
        name = row.get(c_name, "").strip()
        url = row.get(c_repo, "").strip()
        if not name and not url:
            continue
        clone_url, branch = split_tree_url(url) if url else ("", "")
        rec = {
            "Timestamp": excel_date(row.get(c_time)),
            "Full name": name,
            "Email": row.get(c_mail, "").strip(),
            "Git repository URL": clone_url,
            "Submitted branch": branch,
            "Answers": (row.get(c_desc, "") or "").strip(),
        }
        key = (rec["Email"] or name).lower()
        seen[key] = rec                      # rows arrive oldest-first; last wins
    out = list(seen.values())

    # participants whose submission arrived outside the form
    if len(sys.argv) > 2 and pathlib.Path(sys.argv[2]).exists():
        with open(sys.argv[2], newline="", encoding="utf-8-sig") as f:
            for row in csv.DictReader(f):
                clone_url, branch = split_tree_url(row["Git repository URL"])
                out.append({
                    "Timestamp": row.get("Timestamp", ""),
                    "Full name": row["Full name"].strip(),
                    "Email": row.get("Email", "").strip(),
                    "Git repository URL": clone_url,
                    "Submitted branch": branch or row.get("Submitted branch", ""),
                    "Answers": (row.get("Answers", "") or "").strip(),
                })

    csv_path = OUT_DIR / "responses.csv"
    with open(csv_path, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=["Timestamp", "Full name", "Email",
                                          "Git repository URL", "Submitted branch"])
        w.writeheader()
        for rec in out:
            w.writerow({k: rec[k] for k in w.fieldnames})

    for rec in out:
        slug = slug_of(rec["Full name"])
        body = rec["Answers"] if rec["Answers"] else NO_ANSWERS_MARKER
        (answers_dir / f"{slug}.md").write_text(
            f"# Project description — {rec['Full name']}\n\n{body}\n", encoding="utf-8")

    n_missing = sum(1 for r in out if not r["Answers"])
    n_branch = sum(1 for r in out if r["Submitted branch"])
    print(f"{len(out)} participants -> {csv_path}")
    print(f"{n_branch} submitted a /tree/<branch> URL (branch recorded)")
    print(f"{n_missing} without a description (marked, not penalized elsewhere)")
    print(f"answer files -> {answers_dir}/<slug>.md")


if __name__ == "__main__":
    main()
