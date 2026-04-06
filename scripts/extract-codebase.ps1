# ============================================================
# extract-codebase2.ps1
#
# PURPOSE: Same as extract-codebase.ps1 but outputs to
# codebase-digest2.md (fresh regeneration).
# ============================================================

$SourceDir = "d:\Development Projects"
$OutputFile = "$SourceDir\codebase-digest2.md"

$IncludeExtensions = @(".py", ".js", ".ts", ".yaml", ".yml", ".md", ".go", ".sql", ".sh", ".ps1", ".bat", ".html", ".css")

$ExcludePatterns = @(
    "node_modules",
    ".git",
    "dist",
    "build",
    ".venv",
    "venv",
    "__pycache__",
    ".next",
    ".gemini",
    "bavsworldai",
    "codebase-digest"
)

Write-Host "--- Starting Codebase Extraction ---"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"--- Codebase Digest: $Timestamp ---`n" | Out-File -FilePath $OutputFile -Encoding utf8

$Files = Get-ChildItem -Path $SourceDir -Recurse -File | Where-Object {
    $filePath = $_.FullName
    $ext = $_.Extension.ToLower()

    $shouldInclude = $IncludeExtensions -contains $ext

    foreach ($pattern in $ExcludePatterns) {
        if ($filePath -like "*\$pattern*") {
            $shouldInclude = $false
            break
        }
    }

    $shouldInclude
}

Write-Host "Processing $($Files.Count) files..."

foreach ($File in $Files) {
    $RelativePath = $File.FullName.Replace($SourceDir, "")
    $ExtName = $File.Extension.Replace(".", "")
    "`n## FILE: $RelativePath" | Out-File -FilePath $OutputFile -Append -Encoding utf8
    "``````$ExtName" | Out-File -FilePath $OutputFile -Append -Encoding utf8
    Get-Content $File.FullName | Out-File -FilePath $OutputFile -Append -Encoding utf8
    "``````" | Out-File -FilePath $OutputFile -Append -Encoding utf8
}

Write-Host "--- Extraction Complete: $OutputFile ---"
