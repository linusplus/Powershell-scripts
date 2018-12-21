set-executionpolicy remotesigned -Force -Scope CurrentUser
Add-Type -AssemblyName System.Web

# Data to be modified.Please notice that script must not reside in the same directory as data
$SourcePath = "C:\yourpath"
$ftpPath = "ftp://yourftpserver/yourftpserverpath"
$username = "username"
$password = "password"

# Do not modify
Clear-Host

if ([System.IO.Directory]::Exists($SourcePath)) {
    cd $SourcePath
}
else
{
    write-output "Path does not exist"
    Exit
}
$NumberOfIterations = 0
$NumberOfUploads = 0
$open = 1

for () {
        
    # Get the target file name
    $SourceFileName =  Get-ChildItem $SourcePath\*.dat | sort LastWriteTime | select -last 1 | % { $_.Name }
	# Add its path
    $SourceFile = "$SourcePath\$SourceFileName"
    $NumberOfIterations++

    if ([System.IO.File]::Exists($SourceFile)) {
        
        while ($open)
        {
            try { [System.IO.File]::OpenWrite($SourceFile).close();$open=0 }
            catch {$open=1}
            Start-Sleep 2
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
        $NumberOfUploads++
        Clear-Host
        Write-Output "Number of iterations: $NumberOfIterations"
        write-output "Files uploaded correctly  $NumberOfUploads times. Thank you Alessio!"
        # Clean up dir
        Remove-Item *.*
    } else {
        Clear-Host
        Write-Output "Number of iterations: $NumberOfIterations"
        write-output "Files uploaded correctly $NumberOfUploads times. Thank you Alessio!"
           }
    Start-Sleep 5
}
