<#
Azure AD join detection for Tanium sensors.
Returns "True" for pure Azure AD joined, "False" for hybrid/domain/none

Measure-Command { .\get-AADJoined.ps1 } averages about ~800 milliseconds.
#>

# Check for CPU architecture and re-encode the script on 64-bit systems
if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {

   $x64PS = Join-Path $PSHome.ToLower().Replace("syswow64", "sysnative").Replace("system32", "sysnative") Powershell.exe

   $cmd = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($myinvocation.MyCommand.Definition))

   $Out = & "$x64PS" -NonInteractive -NoProfile -ExecutionPolicy Bypass -EncodedCommand $cmd

   $Out

   exit $LASTEXITCODE

}

# Compile regex patterns once for performance
$AzureAdRegex = [regex]::new("AzureAdJoined\s+:\s+YES", [System.Text.RegularExpressions.RegexOptions]::Compiled)
$DomainRegex = [regex]::new("DomainJoined\s+:\s+YES", [System.Text.RegularExpressions.RegexOptions]::Compiled)

try {
    $output = & "$env:SystemRoot\System32\dsregcmd.exe" /status 2>$null
    if ($LASTEXITCODE -ne 0) { throw "dsregcmd failed" }
    
    $outputString = $output -join "`n"
    $azureAdJoined = $AzureAdRegex.IsMatch($outputString)
    
    if (-not $azureAdJoined) {
        "False"
        return
    }
    
    $domainJoined = $DomainRegex.IsMatch($outputString)
    if ($domainJoined) { "False" } else { "True" }

} catch {
    "ERROR: $($_.Exception.Message)"
    exit 1
}