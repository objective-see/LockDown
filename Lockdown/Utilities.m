//
//  Utilities.m
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

@import AppKit;

#import <syslog.h>

//check if app is pristine
// ->that is to say, nobody modified on-disk image/resources
OSStatus verifySelf()
{
    //status
    OSStatus status = !noErr;
    
    //sec ref (for self)
    SecCodeRef secRef = NULL;
    
    //get sec ref to self
    status = SecCodeCopySelf(kSecCSDefaultFlags, &secRef);
    
    //check
    if(noErr != status)
    {
        //bail
        goto bail;
    }
    
    //validate
    status = SecStaticCodeCheckValidityWithErrors(secRef, kSecCSDefaultFlags, NULL, NULL);
    
    //check
    if(status != noErr)
    {
        //err msg
        syslog(LOG_ERR, "OBJECTIVE-SEE LOCKDOWN ERROR: failed to validate application bundle (%d)\n", status);
        
        //bail
        goto bail;
    }
    
//bail
bail:
    
    //release sec ref
    if(NULL != secRef)
    {
        //release
        CFRelease(secRef);
    }
    
    return status;
}

//display alert about app being unverifable
void showUnverifiedAlert(OSStatus signingError)
{
    //alert box
    NSAlert* modifiedAlert = nil;
    
    //alloc/init alert
    modifiedAlert = [NSAlert alertWithMessageText:@"ERROR: application could not be verified" defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"code: %d\nplease re-download and run again!", signingError];
    
    //show it
    [modifiedAlert runModal];
    
    //make front
    [NSApp activateIgnoringOtherApps:YES];
    
    return;
}

//spawn self as root
BOOL spawnAsRoot(char* path, char** argv)
{
    //return/status var
    BOOL bRet = NO;
    
    //authorization ref
    AuthorizationRef authorizatioRef = {0};
    
    //flag indicating auth ref was created
    BOOL authRefCreated = NO;
    
    //status code
    OSStatus osStatus = -1;
    
    //create authorization ref
    // ->and check
    osStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizatioRef);
    if(errAuthorizationSuccess != osStatus)
    {
        //bail
        goto bail;
    }
    
    //set flag indicating auth ref was created
    authRefCreated = YES;
    
    //spawn self as r00t w/ install flag (will ask user for password)
    // ->and check
    osStatus = AuthorizationExecuteWithPrivileges(authorizatioRef, path, 0, argv, NULL);
    if(errAuthorizationSuccess != osStatus)
    {
        //bail
        goto bail;
    }
    
    //no errors
    bRet = YES;
    
//bail
bail:
    
    //free auth ref
    if(YES == authRefCreated)
    {
        //free
        AuthorizationFree(authorizatioRef, kAuthorizationFlagDefaults);
    }
    
    return bRet;
}

//get OS version
NSDictionary* getOSVersion()
{
    //os version info
    NSMutableDictionary* osVersionInfo = nil;
    
    //major v
    SInt32 majorVersion = 0;
    
    //minor v
    SInt32 minorVersion = 0;
    
    //alloc dictionary
    osVersionInfo = [NSMutableDictionary dictionary];
    
    //get major version
    if(0 != Gestalt(gestaltSystemVersionMajor, &majorVersion))
    {
        //reset
        osVersionInfo = nil;
        
        //bail
        goto bail;
    }
    
    //get minor version
    if(0 != Gestalt(gestaltSystemVersionMinor, &minorVersion))
    {
        //reset
        osVersionInfo = nil;
        
        //bail
        goto bail;
    }
    
    //set major version
    osVersionInfo[@"majorVersion"] = [NSNumber numberWithInteger:majorVersion];
    
    //set minor version
    osVersionInfo[@"minorVersion"] = [NSNumber numberWithInteger:minorVersion];
    
//bail
bail:
    
    return osVersionInfo;
}

//is current OS version supported?
// ->for now, just OS X 10.11.* (El Capitan)
BOOL isSupportedOS()
{
    //support flag
    BOOL isSupported = NO;
    
    //OS version info
    NSDictionary* osVersionInfo = nil;
    
    //get OS version info
    osVersionInfo = getOSVersion();
    
    //sanity check
    if(nil == osVersionInfo)
    {
        //bail
        goto bail;
    }
    
    //gotta be OS X
    if(10 != [osVersionInfo[@"majorVersion"] intValue])
    {
        //err msg
        syslog(LOG_ERR, "OBJECTIVE-SEE LOCKDOWN ERROR: OS major version %s not supported\n", [osVersionInfo[@"majorVersion"] UTF8String]);
        
        //bail
        goto bail;
    }
    
    //gotta be OS X 11
    if([osVersionInfo[@"minorVersion"] intValue] < 11)
    {
        //err msg
        syslog(LOG_DEBUG, "OS minor version %s not supported\n", [osVersionInfo[@"minor"] UTF8String]);
        
        //bail
        goto bail;
    }
    
    //OS version is supported
    isSupported = YES;
    
//bail
bail:
    
    return isSupported;
}
