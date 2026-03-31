# ============================================================
# extract-codebase.ps1
#
# PURPOSE: Recursively crawl the Development Projects folder,
# filter for source code, and bundle it into a single Digest
# file for AI RAG ingestion.
# ============================================================

$SourceDir = "d:\Development Projects"
$OutputDir = "d:\Development Projects"
$OutputFile = "$OutputDir\codebase-digest.md"

# Extensions to include
$IncludeExtensions = @(".py", ".js", ".ts", ".yaml", ".yml", ".md", ".go", ".sql", ".sh", ".ps1", ".bat", ".html", ".css")

# Directories/Files to ignore
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
    "bavsworldai",      # IMPORTANT: Exclude self to prevent infinite recursion
    "codebase-digest.md"
)

Write-Host "--- Starting Codebase Extraction ---"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"--- Codebase Digest: $Timestamp ---`n" | Out-File -FilePath $OutputFile -Encoding utf8

$Files = Get-ChildItem -Path $SourceDir -Recurse -File | Where-Object {
    $filePath = $_.FullName
    $ext = $_.Extension.ToLower()
    
    $shouldInclude = $IncludeExtensions -contains $ext
    
    foreach ($pattern in $ExcludePatterns) {
        if ($filePath -like "*\$pattern\*") {
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
    "````$ExtName" | Out-File -FilePath $OutputFile -Append -Encoding utf8
    Get-Content $File.FullName | Out-File -FilePath $OutputFile -Append -Encoding utf8
    "````" | Out-File -FilePath $OutputFile -Append -Encoding utf8
}

Write-Host "--- Extraction Complete: $OutputFile ---"
