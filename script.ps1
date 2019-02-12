set-executionpolicy Unrestricted -Force -Scope CurrentUser
Add-Type -AssemblyName System.Web

# Data to be modified.Please notice that script must not reside in the same directory as data
# TODO: Handle server request failures
$SourcePath1 = "C:\yourpath"
$ftpPath1 = "ftp://yourftpserver/yourftpserverpath"
$username1 = "username"
$password1 = "password"
$SourcePath2 = "C:\yourpath"
$ftpPath2 = "ftp://yourftpserver/yourftpserverpath"
$username2 = "username"
$password2 = "password"
$SourcePath3 = "C:\yourpath"
$ftpPath3 = "ftp://yourftpserver/yourftpserverpath"
$username3 = "username"
$password3 = "password"

# Do not modify

Function UploadToFTPServer ([string]$SourcePath, [string]$ftpPath, [string]$username, [string]$password)
{
	if ([System.IO.Directory]::Exists($SourcePath)) {
		cd $SourcePath
	}
	else
	{
		write-output "Path does not exist"
		Exit
	}
	$open = 1
	# Get the target file name
	$SourceFileName =  Get-ChildItem $SourcePath\*.dat | sort LastWriteTime | select -last 1 | % { $_.Name }
	# Add its path
	$SourceFile = "$SourcePath\$SourceFileName"

	if ([System.IO.File]::Exists($SourceFile)) {
		
		while ($open)
		{
			try { [System.IO.File]::OpenWrite($SourceFile).close();$open=0 }
			catch {$open=1}
			Start-Sleep 3
		}
		
		# The target file is supposed to have an "X" in the name.To be replaced with a "#"
		Get-ChildItem $SourcePath -name | ForEach-Object {
			Move-Item $_ $_.replace("X", "`#")
		}
		
		# Get the target file name again
		$SourceFileName =  Get-ChildItem $SourcePath\*.dat | sort LastWriteTime | select -last 1 | % { $_.Name }
		$SourceFileBaseName =  Get-ChildItem $SourcePath\* | sort LastWriteTime | select -last 1 | % { $_.BaseName }
		
		# Since name contain a "#" we nee to encode it as an URL, since we 're going to upload to a ftp server
		$SourceFileNameUrl = [System.Web.HttpUtility]::UrlEncode($SourceFileName)
		$ftpName = "$ftpPath/$SourceFileNameUrl"
		$SourceFile = "$SourcePath\$SourceFileName"
		
		# Create dummy .flg filename
		$SourceFileNameA = $SourceFileBaseName + ".flg"

		# Encode it as an URL
		$SourceFileNameAUrl = [System.Web.HttpUtility]::UrlEncode($SourceFileNameA)
		$ftpNameA = "$ftpPath/$SourceFileNameAUrl"
		$SourceFileA = "$SourcePath\$SourceFileNameA"

		# Data file: create the FtpWebRequest and configure it
		$ftp = [System.Net.FtpWebRequest]::Create($ftpName)
		$ftp = [System.Net.FtpWebRequest] $ftp
		$ftp.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
		$ftp.Credentials = new-object System.Net.NetworkCredential($username, $password)
		$ftp.UseBinary = $true
		$ftp.UsePassive = $true
				 
		# Read in the file to upload as a byte array
		$content = [System.IO.File]::ReadAllBytes($SourceFile)
		$ftp.ContentLength = $content.Length
		try {
			$rs = $ftp.GetResponse()
		} catch {
			write-output "FAILED: $_"
			Exit
		}

		# Get the request stream, and write the bytes into it
		$rs = $ftp.GetRequestStream()
		try {
			$rs.Write($content, 0, $content.Length)
		} catch {
			write-output "FAILED: $_"
			Exit
		}
		# Be sure to clean up after ourselves
		$rs.Close()
		$rs.Dispose()

		# Flg file: create the FtpWebRequest and configure it
		$ftp = [System.Net.FtpWebRequest]::Create($ftpNameA)
		$ftp = [System.Net.FtpWebRequest] $ftp
		$ftp.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
		$ftp.Credentials = new-object System.Net.NetworkCredential($username, $password)
		$ftp.UseBinary = $true
		$ftp.UsePassive = $true# read in the file to upload as a byte array
		
		try {
			$rs = $ftp.GetResponse()
		} catch {
			write-output "FAILED: $_"
			Exit
		}

		# Flg file: write a single byte into it
		$rs = $ftp.GetRequestStream()
		try {
			$rs.WriteByte(0)
		} catch {
			write-output "FAILED: $_"
			Exit
		}
		# be sure to clean up after ourselves
		$rs.Close()
		$rs.Dispose()
		$Global:NumberOfUploads++
		Remove-Item *.*
	}
}

Clear-Host
$NumberOfIterations = 0
$Global:NumberOfUploads = 0
for () 
{
	$NumberOfIterations++
    
    UploadToFTPServer -SourcePath $SourcePath1 -ftpPath $ftpPath1 -username $username1 -password $password1
	sleep 1
	UploadToFTPServer -SourcePath $SourcePath2 -ftpPath $ftpPath2 -username $username2 -password $password2
	sleep 1
	UploadToFTPServer -SourcePath $SourcePath3 -ftpPath $ftpPath3 -username $username3 -password $password3
	sleep 1
	
	Clear-Host
	Write-Output "Number of iterations: $NumberOfIterations"
	Write-output "Files uploaded correctly  $NumberOfUploads times. Thank you Alessio!"
	
	sleep 10
}
