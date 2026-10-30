# Rejoins files that were split into *.part-aa, *.part-ab, ... (GitHub 100 MB file limit).
Get-ChildItem -Path $PSScriptRoot -Recurse -File -Filter '*.part-aa' | ForEach-Object {
    $target = $_.FullName.Substring(0, $_.FullName.Length - '.part-aa'.Length)
    if (Test-Path -LiteralPath $target) { return }
    $parts = Get-ChildItem -Path $_.DirectoryName -File |
        Where-Object { $_.Name -like ((Split-Path $target -Leaf) + '.part-*') } |
        Sort-Object Name
    Write-Host "joining $target ($($parts.Count) parts)"
    $out = [IO.File]::Create($target)
    try {
        foreach ($p in $parts) {
            $in = [IO.File]::OpenRead($p.FullName)
            try { $in.CopyTo($out) } finally { $in.Close() }
        }
    } finally { $out.Close() }
}
