# Encoding ---> UTF8 with BOM.
Param (
    [switch]$reset
);
$country = $args[0]
$protocol = $args[1]
$id = $args[2]

$path_OpenVPN  = "$env:USERPROFILE\OpenVPN\"
$path_ovpn = "$path_OpenVPN\config\"
$files = @()
(Get-ChildItem $path_ovpn$country$id*$protocol.ovpn) | ForEach-Object {$files += $_}
$len = $files.length
Function concat_Credfilenames([Object[]] $credfilenames) {
    $out = "("
    for ($i=0; $i -lt $credfilenames.Count; $i++) {
        $out+=$credfilenames[$i]
        if ($i -ne ($credfilenames.Count-1)) {$out+="|"} else {$out+=")"}
    }
    return $out
}
Function Check_auth_user_pass([string] $s,[Object[]] $selection,[Object[]] $credfilenames){
    # $s should be "C:\Users\jen_7\OpenVPN\"
    $concated = concat_Credfilenames($credfilenames)
    $find = "(?!^auth-user-pass\s*"+$concated+"\s*$)(^auth-user-pass ?[\s\S]*$)"
    # Write-Host $find -ForegroundColor Cyan
    # Write-Host ($s+"config\"+$selection.Name) -ForegroundColor Yellow
    $lines = (Get-Content ($s+"config\"+$selection.Name)) | Select-String -CaseSensitive -Pattern $find | Select-Object -ExpandProperty Line
    if ($null -eq $lines) {
        return $false # DOES CONTAIN credentials
    } else {
        return $true # DOES NOT CONTAIN credentials
    }
}

Function isAll_auth_user_pass([Object[]] $f,[Object[]] $c) {
    $concated = concat_Credfilenames($c)
    $find = "(?!^auth-user-pass\s*"+$concated+"\s*$)(^auth-user-pass ?[\s\S]*$)"
    $f | 
    Foreach-Object {
        $lines = Get-Content $_.FullName | Select-String -CaseSensitive -Pattern $find | Select-Object -ExpandProperty Line
        if ($null -ne $lines) {
            return $true # AT LEAST 1 FILE DOES NOT CONTAIN credentials
            break
        }
    }
    return $false # ALL FILES CONTAIN credentials
}

Function update_auth_user_pass([Object[]] $f,[Object[]] $c,[string] $r) {
    $concated = concat_Credfilenames($c)
    $find = "(?!^auth-user-pass\s*"+$concated+"\s*$)(^auth-user-pass ?[\s\S]*$)"
    $f | 
    Foreach-Object {
        $lines = Get-Content $_.FullName | Select-String -CaseSensitive -Pattern $find | Select-Object -ExpandProperty Line
        if ($null -ne $lines) {
            foreach ($line in $lines){
                $content = Get-Content $_.FullName
                $content = $content | ForEach-Object {$_ -replace $line,"auth-user-pass $($r)"}
            }
            $content | Set-Content $_.FullName
        }
    }
}

if ($reset) {	
	Do{
	Write-Host "ARE YOU SURE YOU WANT TO REMOVE ALL CREDENTIALS FROM THE .ovpn FILES AND ALL CREDENTIAL FILES IN $($path_ovpn) (i.e. all files with .txt or .conf extension)? " -ForegroundColor Red
	Write-Host "ENTER YES/NO" -ForegroundColor Red	
	$sure=Read-Host}While(($sure -notin ("YES","NO"))-or($sure -eq ""))
	if ($sure -eq "YES") {
		update_auth_user_pass -f $files -c @("") -r ""
		Remove-Item -Path $path_ovpn\* -Include *.conf,*.txt
		Write-Host "Reset has been performed." -ForegroundColor Yellow
	} else {
		Write-Host "Reset aborted." -ForegroundColor Red;
		Write-Host "Press any key to exit." -ForegroundColor Yellow
		Read-Host
		exit
	}
} else {
	$credfilename = "cred.conf" # default credfilename
	$credfiles = (Get-ChildItem -Path $path_ovpn\* -Include *.conf,*.txt)
	if ($null -eq $credfiles) {
		Write-Host "Neither a .txt or .conf file was found in the path." -ForegroundColor Red
		Write-Host "A new file called " -NoNewline; Write-Host $credfilename -ForegroundColor Yellow -NoNewline; Write-Host " containing the login details will be created."
		$user_ovpn = Read-Host "Enter the username (mind empty spaces!)"
		$pass_ovpn = Read-Host "Enter the password (mind empty spaces!)"
		@("$($user_ovpn)`n","$($pass_ovpn)") | Out-File -Encoding "ascii" -NoNewLine ($path_ovpn+$credfilename)
	
		if (Test-Path -Path ($path_ovpn+$credfilename) -PathType Leaf) {
			Write-Host "$($credfilename) successfully created." -ForegroundColor Green
			update_auth_user_pass -f $files -c @($credfilename) -r $credfilename
			Write-Host "All files are updated to use $($credfilename)!" -ForegroundColor Green
		} else {
			Write-Host "Failed to create $($credfilename). Now exiting the script." -ForegroundColor Red
			exit
			# NEED TO IMPLEMENT HOW TO HANDLE THIS EXCEPTIONAL CASE.
		}
	} else {
		$n = $credfiles.Count
		$credfilenames = @($credfiles[$n-1].Name)
		
		if (isAll_auth_user_pass -f $files -c $credfilenames) {
			Write-Host "Found at least 1 file that doesn't contain credential." -ForegroundColor Red
			# IF > 0 FILES DOESN'T CONTAIN CRED, ADD CRED.
			# IF CREDFILES.COUNT > 1, ASK USER TO CHOOSE.
			update_auth_user_pass -f $files -c $credfilenames -r $credfilenames[0]
            Write-Host "All files in red are updated to use $($credfilenames[0])!" -ForegroundColor Green
		} else {
			Write-Host "All .ovpn files already contain credentials." -ForegroundColor Green
			# IMPLEMENT RESET MESSAGE
		}
	}
    if ($len -lt 1) {
    Write-Host "#####" No files found with country code $country and protocol $protocol"#####" -ForegroundColor Red
    exit
    }
    $ind = Get-Random -Minimum 0 -Maximum $len
    
    Write-Host "##### " $files[$ind].basename "is chosen. #####" -ForegroundColor Green
    Start-Sleep -Milliseconds 1000
    openvpn-gui --command disconnect_all
    Start-Sleep -Milliseconds 1000
    openvpn-gui --connect $files[$ind].name
}

