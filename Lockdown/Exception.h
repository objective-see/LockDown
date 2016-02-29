//
//  Exception.h
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

@import Foundation;

#import <syslog.h>
#import <signal.h>

/* FUNCTIONS */

//install exception/signal handlers
void installExceptionHandlers();

//exception handler for Obj-C exceptions
void exceptionHandler(NSException *exception);

//signal handler for *nix style exceptions
void signalHandler(int signal, siginfo_t *info, void *context);




