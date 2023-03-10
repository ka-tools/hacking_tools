Write-Host ""
Write-Host "What would you like to do?"
Write-Host "A)Collect new Baseline"
Write-Host "B)Begin monitoring files with saved Baseline."
$response = Read-Host -Prompt "Please chose"
Write-Host ""

Function Calculate-File-Hash($filePath){
    $fileHash = Get-FileHash -Path $filePath -Algorithm SHA512
    return $fileHash
}

Function Erase-Baseline-If-Already-Exists(){
    $baselineExists = Test-Path -Path .\baseline.txt

    if($baselineExists){
        Remove-Item -Path .\baseline.txt
    }
}

Function If-No-Baseline(){
    $baselineExists = Test-Path -Path .\baseline.txt

    if(-not $baselineExists){
        Write-Host "There isn't baseline"
        break
    }
}

Function If-No-File(){
    $baselineExists = Test-Path -Path .\baseline.txt

    if(-not $baselineExists){
        Write-Host "Not found any file"
        break
    }
}

if ($response -eq "A".ToUpper()) {

    Erase-Baseline-If-Already-Exists
   

    $files = Get-ChildItem -Path .\

    foreach ($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        if(-not $null -eq $hash){
             "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
           }
    }

    If-No-File

     Write-Host "Calculated Hashes:baseline.txt" -ForegroundColor Cyan
}
elseif ($response -eq "B".ToUpper()) {
    If-No-Baseline
    Write-Host "Read existing baseline.txt, start monitoring files." -ForegroundColor Yellow

    $fileHashDictionary = @{}
    $filePathsAndHashes = Get-Content -Path .\baseline.txt

    foreach ($f in $filePathsAndHashes) {
        $fileHashDictionary.add($f.Split("|")[0],$f.Split("|")[1])
    }

    while($true){
        Start-Sleep -Seconds 1
        Write-Host "Checking"

        $files = Get-ChildItem -Path ./

        foreach ($f in $files) {
            $hash = Calculate-File-Hash $f.FullName

            if(-not ($null -eq $hash -or $f.Name -eq "baseline.txt") ){
                # New File Created
                if($fileHashDictionary[$hash.Path] -eq $null){
                    Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
                }
                else{
                    # Notify Changes
                    if($fileHashDictionary[$hash.Path] -eq $hash.Hash){
                            #Nothing Change
                    }
                    else{
                        Write-Host "$($hash.Path) has changed!" -ForegroundColor Red
                    }
                }

                foreach ($key in $fileHashDictionary.Keys) {
                    $baselineFileStillExists = Test-Path -Path $key
                    if(-Not $baselineFileStillExists){
                        # Notify Deleting
                        Write-Host "$($key) has been deleted!" -ForegroundColor DarkRed -BackgroundColor Gray
                    }
                
                }
              }
        }
    }

}


