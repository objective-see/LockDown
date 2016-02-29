//
//  Exception.m
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

#import "Consts.h"
#import "Exception.h"
#import "AppDelegate.h"

#import <syslog.h>

//global
// ->only report an fatal exception once
BOOL wasReported = NO;

//install exception/signal handlers
void installExceptionHandlers()
{
    //sigaction struct
    struct sigaction sa = {0};
    
    //init signal struct
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_SIGINFO;
    sa.sa_sigaction = signalHandler;
    
    //objective-C exception handler
    NSSetUncaughtExceptionHandler(&exceptionHandler);
    
    //install signal handlers
    sigaction(SIGILL, &sa, NULL);
    sigaction(SIGSEGV, &sa, NULL);
    sigaction(SIGBUS,  &sa, NULL);
    sigaction(SIGABRT, &sa, NULL);
    sigaction(SIGTRAP, &sa, NULL);
    sigaction(SIGFPE, &sa, NULL);
    
    return;
}

//exception handler
// will be invoked for Obj-C exceptions
void exceptionHandler(NSException *exception)
{
    //error info dictionary
    NSMutableDictionary* errorInfo = nil;

    //error msg
    NSString* errorMessage = nil;
    
    //ignore if exception was already reported
    if(YES == wasReported)
    {
        //bail
        goto bail;
    }
    
    //alloc
    errorInfo = [NSMutableDictionary dictionary];
        
    //err msg
    syslog(LOG_ERR, "OBJECTIVE-SEE LOCKDOWN ERROR: OS version: %s /App version: %s\n", [[NSProcessInfo processInfo] operatingSystemVersionString].UTF8String, [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] UTF8String]);

    //create error msg
    errorMessage = [NSString stringWithFormat:@"unhandled obj-c exception caught [name: %@ / reason: %@]", [exception name], [exception reason]];
    
	//err msg
    syslog(LOG_ERR, "OBJECTIVE-SEE LOCKDOWN ERROR: %s\n", errorMessage.UTF8String);
    
    //err msg
    syslog(LOG_ERR, "OBJECTIVE-SEE ERROR: %s\n", [[NSThread callStackSymbols] description].UTF8String);
    
    //add main error msg
    errorInfo[KEY_ERROR_MSG] = @"ERROR: unrecoverable fault";
    
    //add sub msg
    errorInfo[KEY_ERROR_SUB_MSG] = [exception name];
    
    //set error URL
    errorInfo[KEY_ERROR_URL] = FATAL_ERROR_URL;
    
    //fatal error
    // ->agent should exit
    errorInfo[KEY_ERROR_SHOULD_EXIT] = [NSNumber numberWithBool:YES];
    
    //display error msg
    [((AppDelegate*)[[NSApplication sharedApplication] delegate]) displayErrorWindow:errorInfo];
    
    //set flag
    wasReported = YES;
    
    //need to sleep, otherwise returning from this function will cause OS to kill agent
    //   instead, we want error popup to be displayed (which will exit agent when closed)
    if(YES != [NSThread isMainThread])
    {
        //nap
        while(YES)
        {
            //nap
            [NSThread sleepForTimeInterval:1.0f];
        }
    }

//bail
bail:
    
	return;
}

//handler for signals
// will be invoked for BSD/*nix signals
void signalHandler(int signal, siginfo_t *info, void *context)
{
    //error info dictionary
    NSMutableDictionary* errorInfo = nil;

    //error msg
    NSString* errorMessage = nil;
    
    //context
    ucontext_t *uContext = NULL;

    //ignore if exception was already reported
    if(YES == wasReported)
    {
        //bail
        goto bail;
    }
    
    //alloc
    errorInfo = [NSMutableDictionary dictionary];
    
    //err msg
   syslog(LOG_ERR, "OBJECTIVE-SEE LOCKDOWN ERROR: OS version: %s /App version: %s\n", [[NSProcessInfo processInfo] operatingSystemVersionString].UTF8String, [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] UTF8String]);
    
    //typecast context
	uContext = (ucontext_t *)context;

    //create error msg
    errorMessage = [NSString stringWithFormat:@"unhandled exception caught, si_signo: %d  /si_code: %s  /si_addr: %p /rip: %p",
              info->si_signo, (info->si_code == SEGV_MAPERR) ? "SEGV_MAPERR" : "SEGV_ACCERR", info->si_addr, (unsigned long*)uContext->uc_mcontext->__ss.__rip];
    
    //err msg
    syslog(LOG_ERR, "OBJECTIVE-SEE LOCKDOWN ERROR: %s\n", errorMessage.UTF8String);
    
    //err msg
    syslog(LOG_ERR, "OBJECTIVE-SEE ERROR: %s\n", [[NSThread callStackSymbols] description].UTF8String);
    
    //add main error msg
    errorInfo[KEY_ERROR_MSG] = @"ERROR: unrecoverable fault";
    
    //add sub msg
    errorInfo[KEY_ERROR_SUB_MSG] = [NSString stringWithFormat:@"si_signo: %d / rip: %p", info->si_signo, (unsigned long*)uContext->uc_mcontext->__ss.__rip];
    
    //set error URL
    errorInfo[KEY_ERROR_URL] = FATAL_ERROR_URL;
    
    //fatal error
    // ->agent should exit
    errorInfo[KEY_ERROR_SHOULD_EXIT] = [NSNumber numberWithBool:YES];
    
    //display error msg
    [((AppDelegate*)[[NSApplication sharedApplication] delegate]) displayErrorWindow:errorInfo];
    
    //set flag
    wasReported = YES;
    
//bail
bail:
    
    return;
}
