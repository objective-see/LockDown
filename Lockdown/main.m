//
//  main.m
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

#import <syslog.h>
#import <Cocoa/Cocoa.h>

#import "Utilities.h"


/*CODE */

//main
int main(int argc, char *argv[])
{
    //return var
    int retVar = -1;

    //app's (self) signing status
    OSStatus signingStatus = !noErr;
    
    //verify self
    // ->show error if app cannot be verified (will exit)
    signingStatus = verifySelf();
    if(noErr != signingStatus)
    {
        //show alert
        showUnverifiedAlert(signingStatus);
        
        //exit
        exit(0);
    }
    
    //when non-r00t instance
    // ->spawn self via auth exec
    if(0 != geteuid())
    {
        //spawn as root
        if(YES != spawnAsRoot(argv[0], argv))
        {
            //err msg
            syslog(LOG_ERR, "OBJECTIVE-SEE ERROR: failed to spawn self as r00t\n");
            
            //bail
            goto bail;
        }
        
        //happy
        retVar = 0;
    }
    
    //otherwise
    // ->just kick off app, as we're root now
    else
    {
        //app away
        retVar = NSApplicationMain(argc, (const char **)argv);
    }
    
//bail
bail:
     
    return retVar;
}



