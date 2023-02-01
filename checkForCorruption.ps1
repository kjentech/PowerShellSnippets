# Checks if there are more than 4 consecutive 0x00 bytes in the file
# if there's such in text files, they're likely corrupted

$path = ""

Get-ChildItem -Path $path -Recurse -File -Include "*md" | ForEach-Object {
    $content = Get-Content $_.FullName -AsByteStream
    $nullByteCount = 0
    for ($i = 0; $i -lt $content.Length; $i++) {
        if ($content[$i] -eq 0x00) {
            $nullByteCount++
            if ($nullByteCount -gt 4) {
                Write-Output "$($_.FullName) contains more than 4 consecutive null bytes."
                break
            }
        } else {
            $nullByteCount = 0
        }
    }
}
