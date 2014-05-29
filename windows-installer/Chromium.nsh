!macro __ChromiumUpdate
    
    ${GetCLIParameterValue} "/build=" "auto"
    pop $R0
    
    StrCmp $R0 "auto" CheckChromiumVersions 0
    StrCpy $ChromiumVersion $R0
    
    CheckChromiumVersions:
    
    StrCmp $ChromiumVersion "" SkipChromiumUpdate
    StrCmp $CurrentChromiumVersion "" BeginChromiumUpdate
    StrCmp $ChromiumVersion $CurrentChromiumVersion 0 BeginChromiumUpdate

    ${DetailPrint} "The installed Chromium version is still up-to-date."
    ${DetailPrint} "Chromium update was skipped."
    Goto SkipChromiumUpdate
    
    ;-------------------
        
    BeginChromiumUpdate:
     
    ${DetailPrint} "Downloading Chromium build $ChromiumVersion, please wait..."
    
    StrCmp $Hidden "0" ShowProgress
    
    ${Download} "silent" "Chromium build $ChromiumVersion" "$ChromiumURL" "$PLUGINSDIR\${ChromiumZIP}" "true"
    
    Pop $R0
    StrCmp $R0 "OK" ExtractFiles
    ${DetailPrint} "Unable to download Chromium at this time, will retry later."
    StrCpy $Errors "$Errors$\n$\tCHROMIUM Update Error: Unable to download Chromium at this time, will retry later."
    Goto SkipChromiumUpdate
    
    ShowProgress:
    
    ${Download} "banner" "Chromium build $ChromiumVersion" "$ChromiumURL" "$PLUGINSDIR\${ChromiumZIP}" "true"
    
    Pop $R0
    StrCmp $R0 "OK" ExtractFiles
    StrCmp $R0 "Cancelled" CancelledDownload
    
    MessageBox MB_RETRYCANCEL|MB_ICONSTOP|MB_TOPMOST "Download failed: $R0$\nPlease check your internet connection and try again!" IDRETRY ShowProgress
    StrCpy $Errors "$Errors$\n$\tCHROMIUM Update Error: $R0 Please check your internet connection and try again!"
    ${MyAbort} "Installation has failed."
  
    CancelledDownload:
    MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST "Download was aborted by user!"
    StrCpy $Errors "$Errors$\n$\tCHROMIUM Update Error: Download was aborted by user!"
    ${MyAbort} "Installation was aborted by user."
    
    ExtractFiles:
    
    ${DetailPrint} "Extracting files, please wait..."

    CreateDirectory "$PLUGINSDIR\cache"
    
    !insertmacro ZIPDLL_EXTRACT "$PLUGINSDIR\${ChromiumZIP}" "$PLUGINSDIR\cache" "<ALL>"
    Pop $0
    
    StrCmp $0 "success" SuccessfullyExtracted 0
    ${DetailPrint} "An error has occured while extracting the files ($0)"
    StrCpy $Errors "$Errors$\n$\tCHROMIUM Update Error: An error has occured while extracting the files ($0)"
    RMDir /r "$PLUGINSDIR\cache" 
    
    StrCmp $Hidden "1" UpdateFailed
    
    MessageBox MB_RETRYCANCEL|MB_ICONSTOP|MB_TOPMOST "Extraction failed: $0$\nPlease check your user permissions and try again." IDRETRY ExtractFiles
    StrCpy $Errors "$Errors\n$\tExtraction failed: $0$\nPlease check your user permissions and try again."
    StrCpy $Errors "$Errors$\n$\tCHROMIUM Update Error: $0$\nPlease check your user permissions and try again."
    ${MyAbort} "Installation has failed."
  
    SuccessfullyExtracted:
    Delete "$PLUGINSDIR\${ChromiumZIP}"
    
    ;-------------------

    IfFileExists "$PLUGINSDIR\cache\chrome-win32\chrome.exe" 0 MissingFile
    IfFileExists "$PLUGINSDIR\cache\chrome-win32\chrome.dll" 0 MissingFile
    Goto AllFilesThere
  
    MissingFile:
    ${DetailPrint} "Error: At least one required file is missing in the update!"
    StrCpy $Errors "$Errors$\n$\tCHROMIUM Update Error: At least one required file is missing in the update!"
    RMDir /r "$PLUGINSDIR\cache"
    
    StrCmp $Hidden "1" UpdateFailed
    
    ${MyAbort} "Installation has failed."
  
    AllFilesThere:
    
    StrCpy $UpgradeNeeded "yes"
    
    ;StrCpy $ChromiumVersion $Revision
    
    SkipChromiumUpdate:
    
!macroend

!macro __ChromiumInstall
    
    StrCmp $ChromiumVersion "" SkipChromiumInstall
    StrCmp $ChromiumVersion $CurrentChromiumVersion SkipChromiumInstall

    ${DetailPrint} "Installing Chromium, please wait..."
    
    ;RetryFileCopy:
    ClearErrors
    RMDir /r "$INSTDIR\data"
    IfErrors 0 CleanSuccessful
    ${DetailPrint} "Failed to delete the previous state from the install folder!" 
    
    CleanSuccessful:
    CreateDirectory "$INSTDIR\data"
    CreateDirectory "$INSTDIR\chromium"
    CopyFiles /SILENT "$PLUGINSDIR\cache\chrome-win32\*.*" "$INSTDIR\chromium"
    IfErrors 0 ChromeCopySuccessful
    ${DetailPrint} "Failed to copy Chromium files to the install folder!" 
    RMDir /r "$PLUGINSDIR\cache"
        
    StrCmp $Hidden "1" SkipChromiumInstall   
        
    ${MyAbort} "Installation has failed."
    
    ChromeCopySuccessful:
    
    RMDir /r "$PLUGINSDIR\cache"
  
    ;-------------------

    ${DetailPrint} "Saving Chromium version information, please wait..."

    ClearErrors
    FileOpen $0 "$INSTDIR\chromium.ver" w
    IfErrors SkipWriteVersion
    FileWrite $0 $ChromiumVersion
    FileClose $0
    
    SkipWriteVersion:
    
    ${DetailPrint} "Chromium installed successfully."
    
    SkipChromiumInstall:

!macroend

!define ChromiumUpdate "!insertmacro __ChromiumUpdate"
!define ChromiumInstall "!insertmacro __ChromiumInstall"