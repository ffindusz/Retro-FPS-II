# Opt-in Meshy authoring only; never used by the Godot runtime.
# PowerShell port of tools/meshy_generate.py for machines without Python.
# Submit each paid stage once, checkpoint its ID, and resume existing tasks rather
# than silently regenerating. Credentials and signed download URLs are never saved or printed.
param(
    [Parameter(Mandatory=$true)][ValidateSet('preview', 'refine', 'balance')][string]$Stage,
    [string]$Plan = '',
    [string]$Output = '',
    [string]$Only = '',
    [switch]$Submit
)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$api = 'https://api.meshy.ai'
$terminal = @('SUCCEEDED', 'FAILED', 'CANCELED')

class SafeError : System.Exception { SafeError([string]$m) : base($m) {} }

function Read-MeshyKey {
    $key = "$env:MESHY_API_KEY".Trim()
    if (-not $key) {
        $envFile = Join-Path $project '.env'
        if (-not (Test-Path -LiteralPath $envFile)) { throw [SafeError]::new('No MESHY_API_KEY environment variable or readable .env.') }
        $found = [regex]::Matches((Get-Content -LiteralPath $envFile -Raw), '(?m)^\s*(?:export\s+)?MESHY_API_KEY\s*=\s*(.*?)\s*$')
        if ($found.Count) {
            $key = $found[$found.Count - 1].Groups[1].Value.Trim()
            if ($key.Length -ge 2 -and $key[0] -eq $key[-1] -and "`"'".Contains($key[0])) { $key = $key.Substring(1, $key.Length - 2) }
            else { $key = ($key -split '\s+#', 2)[0].Trim() }
        }
    }
    if (-not $key -or $key -in @('your_actual_key', 'your_key')) { throw [SafeError]::new('MESHY_API_KEY is missing or a placeholder.') }
    return $key
}

function Invoke-Meshy([string]$Key, [string]$Path, $Body = $null) {
    if (-not ($Path.StartsWith('/openapi/v1/balance') -or $Path.StartsWith('/openapi/v2/text-to-3d'))) { throw [SafeError]::new('Unapproved API route.') }
    $headers = @{ Authorization = "Bearer $Key" }
    $verb = if ($null -eq $Body) { 'GET' } else { 'POST' }
    try {
        if ($null -eq $Body) { return Invoke-RestMethod -Uri ($api + $Path) -Headers $headers -MaximumRedirection 0 -TimeoutSec 30 }
        return Invoke-RestMethod -Uri ($api + $Path) -Method Post -Headers $headers -ContentType 'application/json' -Body ($Body | ConvertTo-Json -Depth 6) -MaximumRedirection 0 -TimeoutSec 60
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code) { throw [SafeError]::new("Meshy HTTP $code for $verb $Path.") }
        throw [SafeError]::new("Meshy $verb did not complete; credential-bearing error details suppressed.")
    }
}

function Save-Record([string]$Path, $Record) {
    New-Item -ItemType Directory -Force -Path (Split-Path $Path -Parent) | Out-Null
    $temporary = "$Path.tmp"
    ($Record | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath $temporary -Encoding utf8
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Save-Download([string]$Url, [string]$Destination, [bool]$Glb) {
    $uri = [Uri]$Url
    if ($uri.Scheme -ne 'https' -or -not $uri.Host.EndsWith('.meshy.ai') -or $uri.UserInfo) { throw [SafeError]::new('Download host is not an approved HTTPS Meshy asset host.') }
    $temporary = "$Destination.tmp"
    try {
        # Deliberately no Authorization header on asset downloads.
        Invoke-WebRequest -Uri $Url -OutFile $temporary -MaximumRedirection 0 -TimeoutSec 120 | Out-Null
    } catch { throw [SafeError]::new('Asset download failed; signed URL and error details suppressed.') }
    $bytes = (Get-Item -LiteralPath $temporary).Length
    if ($bytes -gt 300MB) { Remove-Item -LiteralPath $temporary; throw [SafeError]::new('Download exceeds the 300 MiB safety limit.') }
    if ($Glb) {
        $stream = [System.IO.File]::OpenRead($temporary); $magic = New-Object byte[] 4; [void]$stream.Read($magic, 0, 4); $stream.Close()
        if ([System.Text.Encoding]::ASCII.GetString($magic) -ne 'glTF') { throw [SafeError]::new('Downloaded model is not a GLB.') }
    }
    Move-Item -LiteralPath $temporary -Destination $Destination -Force
    return [ordered]@{ file = (Split-Path $Destination -Leaf); bytes = $bytes; sha256 = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash.ToLower() }
}

function Get-Property($Object, [string]$Name) { if ($Object -and $Object.PSObject.Properties[$Name]) { return $Object.$Name } return $null }

try {
    if (-not $Plan) { $Plan = Join-Path $project 'docs/meshy-models.json' }
    if (-not $Output) { $Output = Join-Path $env:LOCALAPPDATA 'Temp/opencode/cinderkeep-meshy' }
    $key = Read-MeshyKey
    $balance = (Invoke-Meshy $key '/openapi/v1/balance').balance
    Write-Host "Available Meshy credits: $balance"
    if ($Stage -eq 'balance') { exit 0 }

    $planData = Get-Content -LiteralPath $Plan -Raw | ConvertFrom-Json
    $assets = @($planData.assets | Where-Object { -not $Only -or $_.id -eq $Only })
    if ($Only -and -not $assets) { throw [SafeError]::new('-Only does not name an asset in the plan.') }
    if ($planData.PSObject.Properties['authorized_ceiling_credits']) {
        $full = $planData.assets.Count * ($planData.estimated_preview_credits + $planData.estimated_refine_credits)
        if ($full -gt $planData.authorized_ceiling_credits) { throw [SafeError]::new('Plan estimate exceeds its authorized credit ceiling.') }
    }
    foreach ($asset in $assets) {
        foreach ($field in 'prompt', 'texture_prompt') { if ($asset.$field.Length -gt 800) { throw [SafeError]::new("$($asset.id) $field exceeds Meshy's 800-character limit.") } }
    }
    $ceiling = $assets.Count * $planData."estimated_$($Stage)_credits"
    if ($Submit -and $balance -lt $ceiling) { throw [SafeError]::new('Balance is below the estimated stage cost.') }
    Write-Host "Stage $Stage; at most $($assets.Count) assets; estimated new-stage ceiling $ceiling credits."

    # Submit (or resume) every asset first, then wait on all of them.
    $jobs = @()
    foreach ($asset in $assets) {
        $dir = Join-Path $Output $asset.id
        $recordPath = Join-Path $dir 'record.json'
        if (Test-Path -LiteralPath $recordPath) { $record = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json -AsHashtable }
        else {
            $record = [ordered]@{
                asset = $asset; model = $planData.model; model_type = $planData.model_type
                requested_at_utc = (Get-Date).ToUniversalTime().ToString('o')
                rights_status = 'unresolved: confirm account plan and applicable Meshy terms before distribution'
                source_inputs = 'Original text prompts only; no uploaded reference assets or personal data.'
            }
        }
        $job = $record[$Stage]
        if (-not $job) { $job = [ordered]@{} }
        if (-not $job['id']) {
            if ($job['submission'] -in @('SUBMITTING', 'UNKNOWN')) { throw [SafeError]::new("$($asset.id) ${Stage}: prior POST outcome unknown. Reconcile in Meshy before any retry.") }
            if (-not $Submit) { throw [SafeError]::new("$($asset.id) ${Stage}: not submitted; -Submit is required for paid requests.") }
            if ($Stage -eq 'preview') {
                $body = [ordered]@{ mode = 'preview'; prompt = $asset.prompt; ai_model = $planData.model; model_type = $planData.model_type; topology = 'triangle'; target_polycount = $asset.target_polycount; target_formats = @('glb') }
            } else {
                $preview = $record['preview']
                if (-not $preview -or $preview['status'] -ne 'SUCCEEDED') { throw [SafeError]::new("$($asset.id): successful preview required before refining.") }
                $body = [ordered]@{ mode = 'refine'; preview_task_id = $preview['id']; enable_pbr = $true; texture_resolution = '2k'; texture_prompt = $asset.texture_prompt; target_formats = @('glb') }
            }
            $job = [ordered]@{ submission = 'SUBMITTING'; request = $body }
            $record[$Stage] = $job
            Save-Record $recordPath $record
            try {
                $result = Invoke-Meshy $key '/openapi/v2/text-to-3d' $body
                $job['id'] = $result.result
                $job['submission'] = 'CONFIRMED'
            } catch { $job['submission'] = 'UNKNOWN'; Save-Record $recordPath $record; throw }
            Save-Record $recordPath $record
            Write-Host "$($asset.id): $Stage submitted ($($job['id']))"
        }
        $jobs += [pscustomobject]@{ asset = $asset; dir = $dir; recordPath = $recordPath; record = $record; job = $job; last = ''; done = $false; task = $null }
    }

    while ($jobs | Where-Object { -not $_.done }) {
        foreach ($entry in $jobs | Where-Object { -not $_.done }) {
            # Read failures never trigger a replacement paid job.
            $task = Invoke-Meshy $key ('/openapi/v2/text-to-3d/' + $entry.job['id'])
            foreach ($name in 'status', 'progress', 'created_at', 'started_at', 'finished_at', 'consumed_credits') {
                $value = Get-Property $task $name
                if ($null -ne $value) { $entry.job[$name] = $value }
            }
            Save-Record $entry.recordPath $entry.record
            $state = "$($task.status) $($task.progress)%"
            if ($state -ne $entry.last) { Write-Host "$($entry.asset.id): $Stage $state"; $entry.last = $state }
            if ($task.status -in $terminal) { $entry.done = $true; $entry.task = $task }
        }
        if ($jobs | Where-Object { -not $_.done }) { Start-Sleep -Seconds 5 }
    }

    $failed = @()
    foreach ($entry in $jobs) {
        if ($entry.task.status -ne 'SUCCEEDED') { $failed += "$($entry.asset.id) $Stage ended $($entry.task.status)"; continue }
        $expected = $planData."estimated_$($Stage)_credits"
        $credits = Get-Property $entry.task 'consumed_credits'
        if ($credits -and $credits -gt $expected) { $failed += "$($entry.asset.id) ${Stage}: reported credits exceeded estimate"; continue }
        # Persist exports immediately: Meshy API output has limited retention.
        $model = Join-Path $entry.dir ($(if ($Stage -eq 'preview') { 'preview.glb' } else { 'model.glb' }))
        if (-not (Test-Path -LiteralPath $model)) { $entry.job['model_download'] = Save-Download $entry.task.model_urls.glb $model $true }
        $thumb = Join-Path $entry.dir ($(if ($Stage -eq 'preview') { 'preview.png' } else { 'textured.png' }))
        $thumbUrl = Get-Property $entry.task 'thumbnail_url'
        if ($thumbUrl -and -not (Test-Path -LiteralPath $thumb)) { $entry.job['thumbnail_download'] = Save-Download $thumbUrl $thumb $false }
        Save-Record $entry.recordPath $entry.record
        Write-Host "$($entry.asset.id): $Stage downloaded to $($entry.dir)"
    }
    if ($failed) { throw [SafeError]::new(($failed -join '; ') + '; no automatic paid retry.') }
    Write-Host "Stage complete. Available Meshy credits: $((Invoke-Meshy $key '/openapi/v1/balance').balance)"
    exit 0
} catch [SafeError] {
    Write-Host "STOP: $($_.Exception.Message)"
    exit 1
} catch {
    Write-Host 'STOP: unexpected error; details suppressed to protect credentials. Check saved task records before retrying.'
    exit 1
}
