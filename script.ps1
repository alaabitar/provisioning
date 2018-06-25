Write-Output "started"

$saveDir = "D:\blog\provisioning\powershell"
$siteTitle ="";

$siteURL = "URL_OF_YOUR_SITE_SOURCE"
$destination = "URL_OF_YOUR_SITE_TARGET"

function ProcessFolder($folderUrl, $destinationFolder) {
	Write-Output "Folder URL " $folderUrl  " destinationFolder " $destinationFolder
    $folder = Get-PnPFolder -RelativeUrl $folderUrl
    $tempfiles = Get-PnPProperty -ClientObject $folder -Property Files
   
    if (!(Test-Path -path $destinationfolder )) {
        $dest = New-Item $destinationfolder -type directory 
    }

    $total = $folder.Files.Count
    For ($i = 0; $i -lt $total; $i++) {
        $file = $folder.Files[$i]
        
        Get-PnPFile -ServerRelativeUrl $file.ServerRelativeUrl -Path $destinationfolder -FileName $file.Name -AsFile -Force	

		Add-PnPFileToProvisioningTemplate -Path ($saveDir + "Template.xml") -Source ($destinationfolder + "\" + $file.Name) -Folder $folderUrl -FileLevel Published
		
    }
	
}

function ProcessSubFolders($folders, $currentPath) {
    foreach ($folder in $folders) {
        $tempurls = Get-PnPProperty -ClientObject $folder -Property ServerRelativeUrl    
        #Avoid Forms folders
        if ($folder.Name -ne "Forms") {
            $targetFolder = $currentPath +"\"+ $folder.Name;
            ProcessFolder $folder.ServerRelativeUrl.Substring($web.ServerRelativeUrl.Length) $targetFolder 
            $tempfolders = Get-PnPProperty -ClientObject $folder -Property Folders
            ProcessSubFolders $tempfolders $targetFolder
        }
    }
}


Write-Output "source: $siteURL"
Write-Output "destination: $destination"
Write-Output "Connecting to: $siteURL"

Connect-PnPOnline -Url $siteURL 
Write-Output "Connected!"

$web = Get-PnPWeb

$siteTitle = $web.Title

$saveDir = $saveDir + "\" + $siteTitle + "\"


Get-PnPProvisioningTemplate -Out $($saveDir + $pageTemplate) -Force -PersistBrandingFiles -PersistPublishingFiles -IncludeNativePublishingFiles -Handlers Navigation, Lists,PageContents, Pages, Files


$docLibs = Get-PNPList | Where-Object{$_.BaseTemplate -eq 101}

Write-Output "getting doc list"

foreach( $doc in $docLibs ){

    if( $doc.Title -ne "Site Assets"){
        #Download root files
        ProcessFolder $doc.Title ($saveDir + $doc.Title)

        #Download files in folders
        $tempfolders = Get-PnPProperty -ClientObject $doc.RootFolder -Property Folders
        ProcessSubFolders $tempfolders $($saveDir + $doc.Title) + "\"
    }
}

Apply-PnPProvisioningTemplate -path ($saveDir + "Template.xml") -Handlers Navigation, Lists, Pages, Files -ClearNavigation

Write-Output "done"