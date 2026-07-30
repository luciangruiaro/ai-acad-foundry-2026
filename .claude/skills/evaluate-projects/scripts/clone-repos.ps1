<#
.SYNOPSIS
  Clone every repository from the project-submission form export and write the
  clone report.

.DESCRIPTION
  Reads the Google Form CSV export, finds the name / email / repository columns by
  header (form edits reorder columns, so positions are never trusted), clones each
  repository shallow into _submissions/<slug>/, and writes
  _submissions/clone-report.md with successes, classified failures, and the list of
  students to chase.

  Private repositories fail in seconds rather than hanging: GIT_TERMINAL_PROMPT=0
  forbids credential prompts for this process only.

  Idempotent: a repository that is already cloned is fetched, not re-cloned; a slug
  whose previous attempt failed is retried.

.EXAMPLE
  ./clone-repos.ps1 -Export "responses.csv"
  ./clone-repos.ps1 -Export "responses.csv" -OutDir "_submissions"
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Export,
    [string]$OutDir = "_submissions"
)

$ErrorActionPreference = "Stop"

# --- no credential prompts: a private repo must FAIL, not hang -----------------
$env:GIT_TERMINAL_PROMPT = "0"
$env:GCM_INTERACTIVE     = "Never"

# git writes progress and errors to stderr. In Windows PowerShell 5.1, redirecting a
# native command's stderr while $ErrorActionPreference = "Stop" turns each line into a
# terminating NativeCommandError — the script dies on the first failed clone, which is
# the one case this script exists to survive. So git runs through cmd.exe, which owns
# the redirection; PowerShell sees plain text and $LASTEXITCODE.
function Invoke-Git([string]$ArgumentLine) {
    $out = cmd /c "git $ArgumentLine 2>&1"
    return ($out | Out-String)
}

if (-not (Test-Path $Export)) { throw "Export not found: $Export" }
New-Item -ItemType Directory -Force $OutDir | Out-Null

# --- read the export, find columns by header -----------------------------------
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
$colName  = Find-Column @('full\s*name', '^name')
$colEmail = Find-Column @('e-?mail')
$colRepo  = Find-Column @('repo', 'git')
$colTime  = Find-Column @('timestamp')

if (-not $colRepo) { throw "No repository column found. Headers: $($headers -join ' | ')" }
Write-Host "Columns  name='$colName'  email='$colEmail'  repo='$colRepo'  time='$colTime'"

# --- de-duplicate: same person twice -> keep the latest by timestamp ------------
$submissions = @{}
$dupePeople  = @()
foreach ($row in $rows) {
    $key = if ($colEmail) { "$($row.$colEmail)".Trim().ToLower() } else { "$($row.$colName)".Trim().ToLower() }
    if (-not $key) { continue }
    if ($submissions.ContainsKey($key)) { $dupePeople += $key }
    $submissions[$key] = $row          # rows arrive in timestamp order; last wins
}

function Get-Slug($name, $email) {
    $base = if ($name) { $name } else { ($email -split '@')[0] }
    $slug = ($base.Trim().ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
    if (-not $slug) { $slug = "unknown" }
    return $slug
}

# --- clone each ---------------------------------------------------------------
$results = @()
foreach ($key in $submissions.Keys) {
    $row   = $submissions[$key]
    $name  = if ($colName)  { "$($row.$colName)".Trim() }  else { $key }
    $url   = "$($row.$colRepo)".Trim()
    $slug  = Get-Slug $name $key
    $dest  = Join-Path $OutDir $slug

    $r = [ordered]@{ Name = $name; Slug = $slug; Url = $url; Result = ""; Class = ""; Detail = "" }

    if (-not $url) {
        $r.Result = "failed"; $r.Class = "no URL"; $r.Detail = "The form row has no repository URL."
        $results += [pscustomobject]$r; continue
    }
    if ($url -notmatch '^https?://' -or $url -match 'drive\.google|docs\.google|\.zip($|\?)') {
        $r.Result = "failed"; $r.Class = "not a git URL"; $r.Detail = "Submitted: $url"
        $results += [pscustomobject]$r; continue
    }
    # A GitHub/GitLab URL with exactly one path segment is a profile, not a repository.
    $path = ([uri]$url).AbsolutePath.Trim('/')
    if ($url -match 'github\.com|gitlab\.com' -and ($path -split '/').Count -lt 2) {
        $r.Result = "failed"; $r.Class = "not a git URL"; $r.Detail = "A profile page, not a repository: $url"
        $results += [pscustomobject]$r; continue
    }

    if (Test-Path (Join-Path $dest ".git")) {
        Write-Host "fetch   $slug" -ForegroundColor DarkGray
        Invoke-Git "-C `"$dest`" fetch --depth 50 origin" | Out-Null
        $r.Result = "cloned"; $r.Detail = "already present; fetched"
    } else {
        Write-Host "clone   $slug  <-  $url"
        if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }   # failed previous attempt
        $output = Invoke-Git "clone --depth 50 --quiet `"$url`" `"$dest`""
        if ($LASTEXITCODE -ne 0) {
            # transient network errors deserve one retry before being blamed on the student
            if ($output -match 'unable to access|Could not resolve|timed out|early EOF|RPC failed') {
                Start-Sleep -Seconds 5
                $output = Invoke-Git "clone --depth 50 --quiet `"$url`" `"$dest`""
            }
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
        $r.Result = "cloned"
    }

    # successful clone: describe it
    $branch  = (Invoke-Git "-C `"$dest`" rev-parse --abbrev-ref HEAD").Trim()
    $commits = (Invoke-Git "-C `"$dest`" rev-list --count HEAD").Trim()
    $last    = (Invoke-Git "-C `"$dest`" log -1 --format=%ad --date=short").Trim()
    if ($commits -eq "0" -or -not $commits) {
        $r.Result = "failed"; $r.Class = "empty"; $r.Detail = "Cloned, but the repository has no commits."
    } else {
        $sizeMB  = [math]::Round(((Get-ChildItem $dest -Recurse -File | Measure-Object Length -Sum).Sum / 1MB), 1)
        $r.Detail = "branch $branch · $commits commits (shallow) · last $last · ${sizeMB} MB"
    }
    $results += [pscustomobject]$r
}

# --- the report ----------------------------------------------------------------
$ok   = @($results | Where-Object Result -eq "cloned")
$bad  = @($results | Where-Object Result -eq "failed")
$now  = Get-Date -Format "yyyy-MM-dd HH:mm"

$md = @()
$md += "# Clone report — project submissions"
$md += ""
$md += "Generated $now from ``$(Split-Path $Export -Leaf)`` · $($results.Count) submissions · " +
       "**$($ok.Count) cloned**, **$($bad.Count) failed**"
if ($dupePeople) {
    $md += ""
    $md += "> $(($dupePeople | Select-Object -Unique).Count) student(s) submitted more than once; " +
           "the latest submission was kept in each case."
}
$md += ""
$md += "## Cloned"
$md += ""
$md += "| Student | Repository | Detail |"
$md += "|---|---|---|"
foreach ($r in ($ok | Sort-Object Name)) { $md += "| $($r.Name) | $($r.Url) | $($r.Detail) |" }
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
    $md += "### Failure counts"
    $md += ""
    foreach ($g in ($bad | Group-Object Class | Sort-Object Count -Descending)) { $md += "- **$($g.Name)** — $($g.Count)" }
    $md += ""
    $md += "### To chase — send this list before evaluation starts"
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
            "network"                 { "Nothing yet — this failure is likely on our side and will be retried" }
            default                   { "See the error above" }
        }
        $md += "| $($r.Name) | $fix |"
    }
}
$report = Join-Path $OutDir "clone-report.md"
Set-Content -Path $report -Value ($md -join "`n") -Encoding utf8

Write-Host ""
Write-Host "cloned $($ok.Count) / failed $($bad.Count)  ->  $report" -ForegroundColor Green
