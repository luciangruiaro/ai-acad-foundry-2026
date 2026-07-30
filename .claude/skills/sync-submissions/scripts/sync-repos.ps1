<#
.SYNOPSIS
  Clone or update every submitted repository and rebuild the submissions mapping.

.DESCRIPTION
  Reads the Google Form export (columns found by header, never by position), clones new
  repositories in FULL (all branches, full history — the analysis needs authorship over
  time), fetches and fast-forwards existing ones, then rebuilds
  _submissions/submissions.md:

    - one summary row per student: branches, student commits, last activity,
      student-authored LoC, warnings
    - a detail block per student: per-branch commit counts and last student-commit
      dates, and every warning with its evidence
    - the classified failure list, with what each student must do

  Student work = every commit whose author does not match -InstructorPattern.
  Idempotent; the mapping is rebuilt from scratch on every run.

.EXAMPLE
  ./sync-repos.ps1 -Export "responses.csv"
  ./sync-repos.ps1 -Export "responses.csv" -OutDir "_submissions" -InstructorPattern "Lucian Gruia|luciancgruia"
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Export,
    [string]$OutDir = "_submissions",
    [string]$InstructorPattern = "Lucian Gruia|luciancgruia",
    [int]$LargeFileMB = 5
)

$ErrorActionPreference = "Stop"
$env:GIT_TERMINAL_PROMPT = "0"          # a private repo must FAIL, not hang
$env:GCM_INTERACTIVE     = "Never"

# In Windows PowerShell 5.1, redirecting a native command's stderr under
# $ErrorActionPreference = "Stop" turns each line into a terminating error — fatal for
# a script whose whole point is surviving failed clones. cmd.exe owns the redirection.
function Invoke-Git([string]$ArgumentLine) {
    # PowerShell hands native stdout over as an array of lines with the endings already
    # stripped. Out-String would re-join them with CRLF — and a CR glued to a parsed
    # value breaks every markdown table row it lands in and defeats every $-anchored
    # regex (a path ending in `r never matches '\.env$'). Join with LF and never look
    # at a carriage return again.
    $out = cmd /c "git $ArgumentLine 2>&1"
    return (@($out) -join "`n")
}

# Vendored / generated paths: excluded from the LoC count, flagged when tracked.
$VendoredRegex  = '(^|/)(node_modules|\.venv|venv|dist|build|__pycache__|\.idea|\.vscode)(/|$)'
$GeneratedRegex = '(package-lock\.json|uv\.lock|poetry\.lock|yarn\.lock|\.min\.(js|css)|\.map)$'

if (-not (Test-Path $Export)) { throw "Export not found: $Export" }
New-Item -ItemType Directory -Force $OutDir | Out-Null

# --- 1 · parse the export ------------------------------------------------------
$rows = Import-Csv -Path $Export
if (-not $rows) { throw "The export is empty." }
$headers = $rows[0].PSObject.Properties.Name
function Find-Column($patterns) {
    foreach ($p in $patterns) {
        $hit = $headers | Where-Object { $_ -match $p } | Select-Object -First 1
        if ($hit) { return $hit }
    }
    return $null
}
$colName   = Find-Column @('full\s*name', '^name')
$colEmail  = Find-Column @('e-?mail')
$colRepo   = Find-Column @('repo', 'git')
$colBranch = Find-Column @('submitted\s*branch')
if (-not $colRepo) { throw "No repository column found. Headers: $($headers -join ' | ')" }
Write-Host "Columns  name='$colName'  email='$colEmail'  repo='$colRepo'  branch='$colBranch'"

$submissions = [ordered]@{}
$dupePeople  = @()
foreach ($row in $rows) {
    # identity = email when present, name otherwise — PER ROW, because participants
    # added outside the form arrive without an address
    $key = if ($colEmail) { "$($row.$colEmail)".Trim().ToLower() } else { "" }
    if (-not $key) { $key = "$($row.$colName)".Trim().ToLower() }
    if (-not $key) { continue }
    if ($submissions.Contains($key)) { $dupePeople += $key }
    $submissions[$key] = $row                       # rows arrive oldest-first; last wins
}

function Get-Slug($name, $email) {
    $base = if ($name) { $name } else { ($email -split '@')[0] }
    $slug = ($base.Trim().ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
    if (-not $slug) { $slug = "unknown" }
    return $slug
}

# --- 2 · clone or update -------------------------------------------------------
$results = @()
foreach ($key in $submissions.Keys) {
    $row  = $submissions[$key]
    $name = if ($colName) { "$($row.$colName)".Trim() } else { $key }
    $url  = "$($row.$colRepo)".Trim()
    $slug = Get-Slug $name $key
    $dest = Join-Path $OutDir $slug

    $wantBranch = if ($colBranch) { "$($row.$colBranch)".Trim() } else { "" }

    $r = [ordered]@{
        Name = $name; Slug = $slug; Url = $url; Submitted = $wantBranch
        Result = ""; Class = ""; Detail = ""
        Default = ""; EvalBranch = ""; Branches = @(); StudentCommits = 0; LastStudent = ""
        StudentLoC = 0; Warnings = @(); OtherAuthors = @()
    }

    # ---- URL triage, before any network call
    if (-not $url) {
        $r.Result = "failed"; $r.Class = "no URL"; $r.Detail = "The form row has no repository URL."
        $results += [pscustomobject]$r; continue
    }
    if ($url -notmatch '^https?://' -or $url -match 'drive\.google|docs\.google|\.zip($|\?)') {
        $r.Result = "failed"; $r.Class = "not a git URL"; $r.Detail = "Submitted: $url"
        $results += [pscustomobject]$r; continue
    }
    $urlPath = ([uri]$url).AbsolutePath.Trim('/')
    if ($url -match 'github\.com|gitlab\.com' -and ($urlPath -split '/').Count -lt 2) {
        $r.Result = "failed"; $r.Class = "not a git URL"; $r.Detail = "A profile page, not a repository: $url"
        $results += [pscustomobject]$r; continue
    }

    # ---- clone new / update existing
    if (Test-Path (Join-Path $dest ".git")) {
        Write-Host "update  $slug" -ForegroundColor DarkGray
        Invoke-Git "-C `"$dest`" fetch --all --prune" | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $r.Result = "failed"; $r.Class = "network"; $r.Detail = "fetch failed — kept the previous clone"
            $results += [pscustomobject]$r; continue
        }
        # fast-forward only: this mirror never resolves anything
        $head = (Invoke-Git "-C `"$dest`" rev-parse --abbrev-ref HEAD").Trim()
        Invoke-Git "-C `"$dest`" merge --ff-only origin/$head" | Out-Null
        $r.Result = "cloned"; $r.Detail = "updated"
    } else {
        Write-Host "clone   $slug  <-  $url"
        if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
        $output = Invoke-Git "clone --quiet `"$url`" `"$dest`""
        if ($LASTEXITCODE -ne 0 -and $output -match 'unable to access|Could not resolve|timed out|early EOF|RPC failed') {
            Start-Sleep -Seconds 5
            $output = Invoke-Git "clone --quiet `"$url`" `"$dest`""
        }
        if ($LASTEXITCODE -ne 0) {
            $r.Result = "failed"
            $r.Class = switch -Regex ($output) {
                'Authentication failed|could not read (Username|Password)|Permission denied|403' { "private — access denied" }
                'not found|404'                                                                  { "not found" }
                'unable to access|Could not resolve|timed out|early EOF|RPC failed'              { "network" }
                default                                                                          { "other" }
            }
            $r.Detail = ($output.Trim() -split "`n")[-1].Trim()
            $results += [pscustomobject]$r; continue
        }
        $r.Result = "cloned"; $r.Detail = "new clone"
    }

    # ---- survey the branches BEFORE choosing which one to evaluate
    $defaultRef = (Invoke-Git "-C `"$dest`" symbolic-ref refs/remotes/origin/HEAD").Trim()
    $default = if ($defaultRef -match 'origin/(.+)$') { $Matches[1] }
               else { (Invoke-Git "-C `"$dest`" rev-parse --abbrev-ref HEAD").Trim() }
    $r.Default = $default

    # Plain `branch -r` output, because everything here transits cmd.exe — where `|`
    # in a --format string becomes a pipe and %(...) placeholders are not safe either.
    $branchNames = (Invoke-Git "-C `"$dest`" branch -r") -split "`n" |
                   ForEach-Object { $_.Trim() } |
                   Where-Object { $_ -and $_ -notmatch '->' }
    foreach ($b in $branchNames) {
        $short = $b -replace '^origin/', ''
        # %x09 is a TAB, expanded by git itself — nothing for cmd.exe to misread.
        $log = (Invoke-Git "-C `"$dest`" log `"$b`" --no-merges --format=%an%x09%ad --date=short") -split "`n" |
               Where-Object { $_ -match "`t" }
        $studentLines = @($log | Where-Object { ($_ -split "`t")[0] -notmatch $InstructorPattern })
        $lastStudent = if ($studentLines) { ($studentLines[0] -split "`t")[1] } else { "" }
        $r.Branches += [pscustomobject]@{
            Name = $short; Total = $log.Count
            Student = $studentLines.Count; LastStudent = $lastStudent
        }
    }

    # ---- choose the branch the evaluation looks at
    # Priority 1: the branch from a submitted /tree/ URL — the student told us.
    # Priority 2: the default branch, IF it holds student work.
    # Priority 3: the branch with the most recent student commit — students often work
    #   on a branch and submit the repository root URL; evaluating a default branch
    #   that contains none of their commits would score the wrong code. The switch is
    #   recorded, never silent.
    $evalBranch = $default
    if ($wantBranch) {
        Invoke-Git "-C `"$dest`" rev-parse --verify `"origin/$wantBranch`"" | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $evalBranch = $wantBranch
        } else {
            $r.Warnings += "submitted branch ``$wantBranch`` does not exist on the remote — falling back to ``$default``"
        }
    }
    if (-not $wantBranch -or $evalBranch -eq $default) {
        # Pick where the FINAL work lives, not merely where some work lives. Students
        # branch for the project and often never merge back, so a default branch that
        # still holds only assignment 1 would score the wrong repository — even though
        # it is not empty. Most recent student commit wins; ties go to the branch with
        # more student commits. When the default IS the newest, nothing changes.
        $candidates = @($r.Branches | Where-Object { $_.Student -gt 0 } |
                        Sort-Object @{E={$_.LastStudent}; D=$true}, @{E={$_.Student}; D=$true})
        if ($candidates -and $candidates[0].Name -ne $evalBranch) {
            $chosen = $candidates[0]
            $prev = $r.Branches | Where-Object Name -eq $default
            $prevDesc = if ($prev) { "$($prev.Student) student commits, last $(if ($prev.LastStudent) { $prev.LastStudent } else { 'never' })" } else { "none" }
            $evalBranch = $chosen.Name
            $r.Warnings += "auto-selected branch ``$evalBranch`` ($($chosen.Student) student commits, last $($chosen.LastStudent)) over the default ``$default`` ($prevDesc) — the newest student work is here"
        }
    }
    $r.EvalBranch = $evalBranch
    # -B: create or reset the local branch to the remote — this mirror holds no local work
    Invoke-Git "-C `"$dest`" checkout -q -B `"$evalBranch`" `"origin/$evalBranch`"" | Out-Null

    $total = (Invoke-Git "-C `"$dest`" rev-list --count HEAD").Trim()
    if (-not $total -or $total -eq "0") {
        $r.Result = "failed"; $r.Class = "empty"; $r.Detail = "Cloned, but the repository has no commits."
        $results += [pscustomobject]$r; continue
    }

    $evalInfo = $r.Branches | Where-Object Name -eq $evalBranch
    $r.StudentCommits = if ($evalInfo) { $evalInfo.Student } else { 0 }
    $r.LastStudent    = if ($evalInfo) { $evalInfo.LastStudent } else { "" }
    $evalLastStudent  = $r.LastStudent

    # unmerged work: a branch whose last student commit is newer than the evaluated one's
    foreach ($b in $r.Branches) {
        if ($b.Name -ne $evalBranch -and $b.LastStudent -and
            (-not $evalLastStudent -or $b.LastStudent -gt $evalLastStudent)) {
            $r.Warnings += "branch ``$($b.Name)`` has student work newer than ``$evalBranch`` ($($b.LastStudent)) — possibly unmerged"
        }
    }

    # authors that are neither the instructor nor obvious bots — catches students
    # committing under a different name than the form's
    $authors = (Invoke-Git "-C `"$dest`" log --all --format=%an") -split "`n" |
               ForEach-Object { $_.Trim() } | Where-Object { $_ } | Sort-Object -Unique
    $r.OtherAuthors = @($authors | Where-Object { $_ -notmatch $InstructorPattern -and $_ -notmatch '\[bot\]' })
    if ($r.OtherAuthors.Count -eq 0) {
        $r.Warnings += "no student-authored commits on any branch — the fork may be untouched"
    }

    # student LoC on the EVALUATED branch (HEAD after checkout): additions in
    # excluding vendored and generated paths. An approximation, and reported as one.
    $loc = 0
    $numstat = (Invoke-Git "-C `"$dest`" log --no-merges --numstat --format=C%x09%an") -split "`n"
    $counting = $false
    foreach ($line in $numstat) {
        if ($line -like "C`t*") {
            $counting = (($line.Substring(2)) -notmatch $InstructorPattern)
        } elseif ($counting -and $line -match '^(\d+)\s+\d+\s+(.+)$') {
            $file = $Matches[2]
            if ($file -notmatch $VendoredRegex -and $file -notmatch $GeneratedRegex) {
                $loc += [int]$Matches[1]
            }
        }
    }
    $r.StudentLoC = $loc

    # hygiene: what is tracked that should not be
    $tracked = (Invoke-Git "-C `"$dest`" ls-files") -split "`n" | Where-Object { $_ }
    foreach ($pattern in @('(^|/)\.venv/', '(^|/)venv/', '(^|/)node_modules/', '(^|/)__pycache__/', '(^|/)dist/')) {
        $hits = @($tracked | Where-Object { $_ -match $pattern })
        if ($hits) {
            $label = ($pattern -replace '[^a-z_\.]', '')
            $r.Warnings += "``$label`` is committed ($($hits.Count) files) — belongs in .gitignore"
        }
    }
    $envFiles = @($tracked | Where-Object { $_ -match '(^|/)\.env$' })
    foreach ($e in $envFiles) {
        $r.Warnings += "``$e`` is tracked — open it: if values are live this is an incident (rotate), if REDACTED it is only hygiene"
    }
    foreach ($f in $tracked) {
        # git C-quotes paths containing non-ASCII ("path with \303\251"), and square
        # brackets are wildcards to Test-Path — so strip quotes and use -LiteralPath,
        # and skip anything that still will not resolve rather than dying on it.
        $clean = $f.Trim('"')
        $full = Join-Path $dest $clean
        try {
            if ((Test-Path -LiteralPath $full) -and ((Get-Item -LiteralPath $full).Length -gt $LargeFileMB * 1MB)) {
                $mb = [math]::Round((Get-Item -LiteralPath $full).Length / 1MB, 1)
                $r.Warnings += "large file tracked: ``$clean`` ($mb MB)"
            }
        } catch { }
    }

    $results += [pscustomobject]$r
}

# --- 3 · the mapping file ------------------------------------------------------
$ok  = @($results | Where-Object Result -eq "cloned")
$bad = @($results | Where-Object Result -eq "failed")
$now = Get-Date -Format "yyyy-MM-dd HH:mm"

$md = @()
$md += "# Submissions — mapping"
$md += ""
$md += "Synced $now from ``$(Split-Path $Export -Leaf)`` · $($results.Count) submissions · **$($ok.Count) cloned**, **$($bad.Count) failed**"
$md += ""
$md += "**Reading the table:** *Commits by them* and *Lines added by them* count only commits whose author is the student (not ``$InstructorPattern``), on the evaluated branch. *Lines added* is every line their commits added — code, corpus documents, golden-set JSON, notes — with vendored and generated files excluded. A 1,500-line corpus file makes this number large and that is fine: it screens for empty and enormous, it is not a score. *Evaluated branch* is the branch from the submitted /tree/ URL when one was given, otherwise the default — unless the default holds none of their commits, in which case the branch with their most recent work is auto-selected and a warning records it."
if ($dupePeople) {
    $md += ""
    $md += "> $(@($dupePeople | Select-Object -Unique).Count) student(s) submitted more than once; the latest submission was kept."
}
$md += ""
$md += "## Overview"
$md += ""
$md += "| Student | Evaluated branch | Branches | Commits by them | Last commit | Lines added by them | Warnings |"
$md += "|---|---|---|---|---|---|---|"
foreach ($r in ($ok | Sort-Object Name)) {
    $last = if ($r.LastStudent) { $r.LastStudent } else { "—" }
    $ev = if ($r.EvalBranch -eq $r.Default) { "``$($r.EvalBranch)``" }
          elseif ($r.Submitted -eq $r.EvalBranch) { "``$($r.EvalBranch)`` (submitted)" }
          else { "``$($r.EvalBranch)`` (auto-selected)" }
    $md += "| $($r.Name) | $ev | $($r.Branches.Count) | $($r.StudentCommits) | $last | $($r.StudentLoC) | $($r.Warnings.Count) |"
}
$md += ""
$md += "## Detail"
foreach ($r in ($ok | Sort-Object Name)) {
    $md += ""
    $md += "### $($r.Name) — ``$($r.Slug)``"
    $md += ""
    $md += "$($r.Url) · $($r.Detail) · evaluated branch: ``$($r.EvalBranch)``$(if ($r.Submitted) { ' (from the submitted URL)' }) · default: ``$($r.Default)``"
    $md += ""
    $md += "| Branch | Commits | Student commits | Last student commit |"
    $md += "|---|---|---|---|"
    foreach ($b in ($r.Branches | Sort-Object { $_.Name -ne $r.EvalBranch }, Name)) {
        $last = if ($b.LastStudent) { $b.LastStudent } else { "—" }
        $md += "| ``$($b.Name)`` | $($b.Total) | $($b.Student) | $last |"
    }
    if ($r.OtherAuthors) { $md += ""; $md += "Student author identities: $(($r.OtherAuthors | ForEach-Object { '``' + $_ + '``' }) -join ', ')" }
    if ($r.Warnings) {
        $md += ""
        $md += "**Warnings:**"
        foreach ($w in $r.Warnings) { $md += "- $w" }
    }
}
$md += ""
$md += "## Failed"
$md += ""
if (-not $bad) {
    $md += "Nothing failed."
} else {
    $md += "| Student | Repository | Why | Error |"
    $md += "|---|---|---|---|"
    foreach ($r in ($bad | Sort-Object Class, Name)) { $md += "| $($r.Name) | $($r.Url) | **$($r.Class)** | $($r.Detail) |" }
    $md += ""
    $md += "### To chase — send before evaluation starts"
    $md += ""
    $md += "| Student | What they must do |"
    $md += "|---|---|"
    foreach ($r in ($bad | Sort-Object Name)) {
        $fix = switch ($r.Class) {
            "private — access denied" { "Make the repository public, or add the reviewer as a collaborator, and reply when done" }
            "not found"               { "Re-check the URL — the repository does not exist at that address" }
            "not a git URL"           { "Submit the git repository URL, not a link to a file or a profile" }
            "empty"                   { "Push the project — the repository has no commits" }
            "no URL"                  { "Submit the repository URL — the form field was empty" }
            "network"                 { "Nothing yet — likely on our side; will be retried" }
            default                   { "See the error above" }
        }
        $md += "| $($r.Name) | $fix |"
    }
}
$mapping = Join-Path $OutDir "submissions.md"
Set-Content -Path $mapping -Value ($md -join "`n") -Encoding utf8

Write-Host ""
Write-Host "cloned/updated $($ok.Count) · failed $($bad.Count)  ->  $mapping" -ForegroundColor Green
exit 0    # a failed clone is a REPORTED outcome, not a script failure
