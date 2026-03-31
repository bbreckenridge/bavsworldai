# ============================================================
# update-models.ps1
#
# PURPOSE: Automatically pull the latest versions of core models
# for the BavsworldAI / Private Gemini stack.
# ============================================================

$Models = @(
    "llama3.3:latest",
    "qwen2.5-vl:latest",
    "nemotron-mini:4b",
    "nomic-embed-text:latest"
)

# Stable Diffusion XL Models (Direct Download)
$SDModels = @{
    "Juggernaut-XL-v9.safetensors" = "https://huggingface.co/RunDiffusion/Juggernaut-XL-v9/resolve/main/Juggernaut-XL_v9_RunDiffusionPhoto_v2.safetensors"
    "stable-diffusion-xl-lightning-4step.safetensors" = "https://huggingface.co/ByteDance/SDXL-Lightning/resolve/main/sdxl_lightning_4step_vclone.safetensors"
}
$SDModelPath = "D:\AI_Data\stable-diffusion\models\Stable-diffusion"
$SVDModelPath = "D:\AI_Data\stable-diffusion\models\svd"

# Stable Video Diffusion Models
$SVDModels = @{
    "svd_xt_1-1.safetensors" = "https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt-1-1/resolve/main/svd_xt_1_1.safetensors"
}

$LogFile = "d:\Development Projects\bavsworldai\scripts\update-log.txt"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# --- Ensure Directories Exist ---
if (!(Test-Path $SDModelPath)) { New-Item -ItemType Directory -Path $SDModelPath -Force | Out-Null }
if (!(Test-Path $SVDModelPath)) { New-Item -ItemType Directory -Path $SVDModelPath -Force | Out-Null }

"--- Starting Update: $Timestamp ---" | Out-File -FilePath $LogFile -Append

foreach ($Model in $Models) {
    Write-Host "Updating $Model..."
    $Result = ollama pull $Model 2>&1
    "$Timestamp - Updated $Model" | Out-File -FilePath $LogFile -Append
    $Result | Out-File -FilePath $LogFile -Append
}

# --- Update SD Models ---
foreach ($FileName in $SDModels.Keys) {
    if (!(Test-Path "$SDModelPath\$FileName")) {
        Write-Host "Downloading SD Model: $FileName..."
        curl.exe -L $SDModels[$FileName] -o "$SDModelPath\$FileName"
        "$Timestamp - Downloaded SD Model: $FileName" | Out-File -FilePath $LogFile -Append
    }
}

# --- Update SVD Models ---
foreach ($FileName in $SVDModels.Keys) {
    if (!(Test-Path "$SVDModelPath\$FileName")) {
        Write-Host "Downloading SVD Model: $FileName..."
        curl.exe -L $SVDModels[$FileName] -o "$SVDModelPath\$FileName"
        "$Timestamp - Downloaded SVD Model: $FileName" | Out-File -FilePath $LogFile -Append
    }
}

"--- Update Complete ---" | Out-File -FilePath $LogFile -Append
