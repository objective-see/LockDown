//
//  AppDelegate.m
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//
//  3rd-party components (all  MIT license'd)
//  a) osxlockdown: https://github.com/SummitRoute/osxlockdown
//  b) ANSIEscapeHelper: https://github.com/ali-rantakari/ANSIEscapeHelper
//  c) YAML -> Obj-C framework: https://github.com/mirek/YAML.framework

#import <syslog.h>
#include <sys/xattr.h>

#import "Consts.h"
#import "Exception.h"
#import "Utilities.h"
#import "AppDelegate.h"
#import "CommandsViewController.h"
#import "ExecuteViewController.h"
#import "WarningViewController.h"
#import "3rd-Party/YAML.framework/Headers/YAMLSerialization.h"


@implementation AppDelegate

@synthesize mode;
@synthesize commands;
@synthesize commandsFile;
@synthesize aboutWindowController;
@synthesize currentViewController;
@synthesize errorWindowController;


//automatically called as app's 'main' method
// ->check version, load commands, and initial UI view
-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //app's (self) signing status
    OSStatus signingStatus = !noErr;
    
    //install exception handlers
    installExceptionHandlers();
    
    //check if OS is supported
    if(YES != isSupportedOS())
    {
        //show error popup
        [self displayErrorWindow: @{KEY_ERROR_MSG:@"ERROR: unsupported OS", KEY_ERROR_SUB_MSG: [NSString stringWithFormat:@"OS X %@ is not supported", [[NSProcessInfo processInfo] operatingSystemVersionString]], KEY_ERROR_SHOULD_EXIT:@YES}];
        
        //bail
        goto bail;
    }
    
    //r00t
    // ->for realz
    if(0 != setuid(0))
    {
        //err msg
        syslog(LOG_ERR, "OBJECTIVE-SEE LOCKDOWN ERROR: setuid() failed with: %d\n", errno);
        
        //bail
        goto bail;
    }
    
    //alloc array for commands
    commands = [NSMutableArray array];
    
    //get a path for the commands file
    // ->as user might select/deselect commands
    commandsFile = [NSTemporaryDirectory() stringByAppendingPathComponent:COMMANDS_FILE];
    
    //prepare osxlockdown
    // ->set to r00t, remove q attr, etc
    [self prepOSXLockdown];
    
    //(re)verify self
    // ->show error if app cannot be verified (will exit)
    signingStatus = verifySelf();
    if(noErr != signingStatus)
    {
        //show alert
        showUnverifiedAlert(signingStatus);
        
        //exit
        exit(0);
    }

    //load yaml commands
    if(YES != [self loadCommands])
    {
        //show error popup
        [self displayErrorWindow: @{KEY_ERROR_MSG:@"ERROR: load failure", KEY_ERROR_SUB_MSG: @"failed to load lockdown commands", KEY_ERROR_SHOULD_EXIT:@YES}];
        
        //bail
        goto bail;
    }
    
    //all happy, now enable 'continue' button
    // ->need 'else' to scope for dispatch_after
    else
    {
        //wait 1 second
        // ->then enable 'continue' button & make it selected
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                
                //enable
                ((WarningViewController*)self.currentViewController).continueButton.enabled = YES;
                
                //make selected
                [[[NSApplication sharedApplication] keyWindow] makeFirstResponder:((WarningViewController*)self.currentViewController).continueButton];
        });
    }
    
//bail
bail:
    
    return;
}

//tell app to close when user clicks 'x' button
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

//delete temp copy of commands file
-(void)applicationWillTerminate:(NSNotification *)notification
{
    //delete
    [[NSFileManager defaultManager] removeItemAtPath:self.commandsFile error:NULL];
    
    return;
}

//prepare osxlockdown components
// ->make exec, set to r00t, etc...
-(void)prepOSXLockdown
{
    //path to osxlockdown binary
    NSString* osxlockdown = nil;
   
    //init path to osxlockdown binary
    osxlockdown = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:BINARY_FILE];
    
    //make sure osxlockdown binary has executable bit set
    [[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions:@0755} ofItemAtPath:osxlockdown error:NULL];
    
    //set osxlockdown binary to r00t
    [[NSFileManager defaultManager] setAttributes:@{NSFileGroupOwnerAccountID:@0, NSFileOwnerAccountID:@0} ofItemAtPath:osxlockdown error:NULL];
    
    //set osxlockdown commands to r00t
    [[NSFileManager defaultManager] setAttributes:@{NSFileGroupOwnerAccountID:@0, NSFileOwnerAccountID:@0} ofItemAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:COMMANDS_FILE] error:NULL];
    
    return;
}

//automatically invoked when user clicks 'About/Info'
// ->show about window
-(IBAction)about:(id)sender
{
    //alloc/init settings window
    if(nil == self.aboutWindowController)
    {
        //alloc/init
        aboutWindowController = [[AboutWindowController alloc] initWithWindowNibName:@"AboutWindow"];
    }
    
    //center window
    [[self.aboutWindowController window] center];
    
    //show it
    [self.aboutWindowController showWindow:self];
    
    return;
}


//change top pane
// ->switch between either flat (default) or tree-based (hierachical) view
-(void)changeViewController:(NSUInteger)viewID
{
    //key window
    NSWindow* keyWindow = nil;
    
    //grab key window
    keyWindow = [[NSApplication sharedApplication] keyWindow];
    
    //first
    // ->remove existing view
    if([self.currentViewController view] != nil)
    {
        //remove
        [[self.currentViewController view] removeFromSuperview];
        
        //'free'
        self.currentViewController = nil;
    }
    
    //display specified view
    switch(viewID)
    {
        //warning view
        case VIEW_WARNING:
        {
            //alloc/init
            currentViewController = [[WarningViewController alloc] initWithNibName:@"WarningView" bundle:nil];
            
            break;
        }
            
        //command selector view
        case VIEW_COMMANDS:
        {
            //alloc/init
            currentViewController = [[CommandsViewController alloc] initWithNibName:@"TestsView" bundle:nil];
            
            //resize window
            [keyWindow setFrame:NSMakeRect(0,0,600,533) display:YES];
            
            //set view's frame to match window's
            self.currentViewController.view.frame = [keyWindow contentRectForFrameRect:keyWindow.frame];
            
            //center window
            [[[NSApplication sharedApplication] keyWindow] center];
            
            break;
        }
            
        //execute commands view
        case VIEW_EXECUTE:
        {
            //alloc/init
            currentViewController = [[ExecuteViewController alloc] initWithNibName:@"ExecuteView" bundle:nil];
            
            //resize window
            [keyWindow setFrame:NSMakeRect(0,0,600,533) display:YES];
            
            //set view's frame to match window's
            self.currentViewController.view.frame = [keyWindow contentRectForFrameRect:keyWindow.frame];
            
            //center window
            [[[NSApplication sharedApplication] keyWindow] center];
            
            break;
        }
    }
    
    //add subview
    [self.mainView addSubview:self.currentViewController.view];
    
    return;
}

//load original commands
// ->read them into memory and convery into an objc obj
-(BOOL)loadCommands
{
    //loaded
    BOOL bLoaded = NO;
    
    //error
    NSError* error = nil;
    
    //path to commands
    NSString* commandsPath = nil;
    
    //input stream
    NSInputStream *yamlStream = nil;
    
    //init path to commands file
    commandsPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:COMMANDS_FILE];
    
    //init yaml input stream from w/ commands
    yamlStream = [[NSInputStream alloc] initWithFileAtPath:commandsPath];
    if(nil == yamlStream)
    {
        //err msg
        syslog(LOG_ERR, "OBJECTIVE-SEE LOCKDOWN ERROR: loading commands initialization failed\n");
        
        //bail
        goto bail;
    }
    
    //load commands
    self.commands = [YAMLSerialization objectsWithYAMLStream:yamlStream options:kYAMLReadOptionStringScalars error:&error];
    
    //make sure loading succeeded and data looks ok
    if( (nil != error) ||
        (YES != [self.commands isKindOfClass:[NSMutableArray class]]) ||
        (0 == self.commands.count) )
    {
        //err msg
        syslog(LOG_ERR, "OBJECTIVE-SEE LOCKDOWN ERROR: loading commands failed with: %s\n", error.description.UTF8String);
        
        //bail
        goto bail;
    }
    
    //format is an array, with a single member
    // ->and array of dictionaries (want that)
    self.commands = self.commands.firstObject;
    
    //again, make sure this data looks ok
    if( (YES != [self.commands isKindOfClass:[NSMutableArray class]]) ||
        (0 == self.commands.count) )
    {
        //err msg
        syslog(LOG_ERR, "OBJECTIVE-SEE LOCKDOWN ERROR: loading commands failed\n");
        
        //bail
        goto bail;
    }
    
    //happy
    bLoaded = YES;
    
//bail
bail:
    
    return bLoaded;
}

//save commands
// ->write commands out to disk
-(BOOL)saveCommands
{
    //loaded
    BOOL bSaved = NO;
    
    //error
    NSError* error = nil;
    
    //output stream
    NSOutputStream *yamlStream = nil;
    
    //init output stream
    yamlStream =  [NSOutputStream outputStreamToFileAtPath:self.commandsFile append:NO];
    if(nil == yamlStream)
    {
        //err msg
        syslog(LOG_ERR, "OBJECTIVE-SEE LOCKDOWN ERROR: failed to output output stream for %s\n", self.commandsFile.UTF8String);
        
        //bail
        goto bail;
    }

    //open stream
    [yamlStream open];
    
    //write commands to stream
    if(YES != [YAMLSerialization writeObject:self.commands toYAMLStream:yamlStream options:kYAMLWriteOptionSingleDocument error:&error])
    {
        //err msg
        syslog(LOG_ERR, "OBJECTIVE-SEE LOCKDOWN ERROR: writing commands to output stream failed with: %s\n", error.description.UTF8String);
        
        //bail
        goto bail;
    }
    
    //close stream
    [yamlStream close];
    
    //happy
    bSaved = YES;
    
//bail
bail:
    
    return bSaved;
}

//display error window
-(void)displayErrorWindow:(NSDictionary*)errorInfo
{
    //alloc error window
    errorWindowController = [[ErrorWindowController alloc] initWithWindowNibName:@"ErrorWindowController"];
    
    //main thread
    // ->just show UI alert, unless its fatal (then load URL)
    if(YES == [NSThread isMainThread])
    {
        //non-fatal errors
        // ->show error error popup
        if(YES != [errorInfo[KEY_ERROR_URL] isEqualToString:FATAL_ERROR_URL])
        {
            //display it
            // ->call this first to so that outlets are connected
            [self.errorWindowController display];
            
            //configure it
            [self.errorWindowController configure:errorInfo];
        }
        //fatal error
        // ->launch browser to go to fatal error page, then exit
        else
        {
            //launch browser
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:errorInfo[KEY_ERROR_URL]]];
            
            //then exit
            [NSApp terminate:self];
        }
    }
    //background thread
    // ->have to show error window on main thread
    else
    {
        //show alert
        // ->in main UI thread
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            //display it
            // ->call this first to so that outlets are connected
            [self.errorWindowController display];
            
            //configure it
            [self.errorWindowController configure:errorInfo];
            
        });
    }
    
    return;
}


@end
