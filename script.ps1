set-executionpolicy remotesigned -Force -Scope CurrentUser
Add-Type -AssemblyName System.Web

# Data to be modified.Please notice that script must not reside in the same directory as data, that is supposed to be empty or
# containing one file only.
$SourcePath = "C:\yourpath"
$ftpPath = "ftp://yourftpserver/yourpath"
$username = "username"
$password = "password"

# Do not modify
cd $SourcePath

for () {
    # Get the target file name
    $SourceFileName = Get-ChildItem $SourcePath\*.dat -Name
    # Add its path
    $SourceFile = "$SourcePath\$SourceFileName"

    if ([System.IO.File]::Exists($SourceFile)) {
        # The target file is supposed to have an "X" in the name.To be replaced with a "#"
        Get-ChildItem $SourcePath -name | ForEach-Object {
            Move-Item $_ $_.replace("X", "`#")
        }
        # Remove.dat extension
        Get-ChildItem -File | % { Rename-Item -Path $_.PSPath -NewName $_.Name.replace(".dat",".")}

        # Get target file name again
        $SourceFileName = Get-ChildItem $SourcePath\* -Name
        # Since name contain a "#" we nee to encode it as an URL, since we 're going to upload to a ftp server
        $SourceFileNameUrl = [System.Web.HttpUtility]::UrlEncode($SourceFileName)
        $ftpName = "$ftpPath/$SourceFileNameUrl"
        $SourceFile = "$SourcePath\$SourceFileName"

        # Let 's create a dummy .flg file, we're going to upload it as well
        Copy-Item -Path $SourceFile -Destination "$SourceFile.flg"

        # Get its name
        $SourceFileNameA = Get-ChildItem $SourcePath\*.flg -Name
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
        
        # Empty file
        $ftp.ContentLength = 0
        try {
            $rs = $ftp.GetResponse()
        } catch {
            write-output "FAILED: $_"
            Exit
        }

        # get the request stream, and write the bytes into it
        $rs = $ftp.GetRequestStream()
        try {
            $rs.Write($content, 0, $content.Length)
        } catch {
            write-output "FAILED: $_"
            Exit
        }
        # be sure to clean up after ourselves
        $rs.Close()
        $rs.Dispose()
        write-output "Files uploaded correctly"
        Remove-Item $SourceFile
        Remove-Item $SourceFileA
    } else {
        write-output "File does not exist"
    }
    Start-Sleep 5
}
