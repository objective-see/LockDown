//
//  ExecuteViewController.m
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

#import <syslog.h>

#import "Consts.h"
#import "AppDelegate.h"
#import "AMR_ANSIEscapeHelper.h"
#import "ExecuteViewController.h"


@implementation ExecuteViewController

@synthesize output;
@synthesize statusMsg;
@synthesize backButton;
@synthesize closeButton;
@synthesize progressIndicator;

//view loaded
// ->init UI and spawn commands
-(void)viewDidLoad
{
    //initial output msg
    NSMutableString* outputMsg = nil;
    
    //super
    [super viewDidLoad];
    
    //init status message to nada
    self.statusMsg.stringValue = @"";
    
    //disable 'back' button
    self.backButton.enabled = NO;
    
    //disable 'close' button
    self.closeButton.enabled = NO;
    
    //init output msg
    outputMsg = [NSMutableString stringWithString:@"starting 'osxlockdown' "];
    
    //append msg for 'auditing'...
    if(MODE_AUDIT == ((AppDelegate*)[[NSApplication sharedApplication] delegate]).mode)
    {
        //append
        [outputMsg appendString:@"to AUDIT security configuration settings..."];
    }
    //append msg for 'fix'
    else
    {
        //append
        [outputMsg appendString:@"to FIX security configuration settings..."];
    }

    //set initial output message
    // ->some of the commands take a while to generate output...
    [[self.output textStorage] setAttributedString: [[[AMR_ANSIEscapeHelper alloc] init] attributedStringWithANSIEscapedString:outputMsg]];
    
    //exec commands in background thread
    // ->ensures UI is still responsive, etc.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //nap to allow inital msg to show
        [NSThread sleepForTimeInterval:0.75f];
        
        //exec
        // ->'mode' variable will indicate audit or fix
        [self execCommands:((AppDelegate*)[[NSApplication sharedApplication] delegate]).mode];
        
    });
    
    return;
}

//execute commands in background
// ->dump output to text view (via main thread)
-(void)execCommands:(NSUInteger)mode
{
    //osxlockdown's binary path
    NSString* binaryPath = nil;
    
    //args
    NSMutableString* arguments = nil;
    
    //task
    NSTask *task = nil;
    
    //output pipe
    NSPipe *outPipe = nil;
    
    //read handle
    NSFileHandle* readHandle = nil;
    
    //number of enabled commands
    NSUInteger enabledCommands = 0;
    
    //partial output
    NSString* partialOutput = nil;
    
    //ansi converted string
    NSAttributedString *convertedString = nil;
    
    //cumulative output
    NSMutableAttributedString* cumulativeOutput = nil;
    
    //init cumulative output string
    cumulativeOutput = [[NSMutableAttributedString alloc] initWithString:@""];
    
    //init binary path
    binaryPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:BINARY_FILE];
    
    //change dir
    // ->otherwise osxlockdown binary will fail....
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:[binaryPath stringByDeletingLastPathComponent]];
    
    //calculate number of enabled commands
    // ->needed to accurately increment progress indicator
    for(NSMutableDictionary* command in ((AppDelegate*)[[NSApplication sharedApplication] delegate]).commands)
    {
        //for enabled commands
        // ->increment count...
        if(YES == [command[@"enabled"] isEqualToString:@"true"])
        {
            //inc
            enabledCommands++;
        }
    }
    
    //add extra for system info command(s)
    // ->date/serial #, etc...
    enabledCommands += 5;
    
    //init args
    arguments = [NSMutableString stringWithFormat:@"\"%@\" %@ \"%@\"", binaryPath, @"-commands_file", ((AppDelegate*)[[NSApplication sharedApplication] delegate]).commandsFile];
    
    //logic for 'audit' mode
    // ->just set msg, as no extra args are needed
    if(MODE_AUDIT == mode)
    {
        //update status msg in main thread
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            //set
            self.statusMsg.stringValue = @"auditing...";
            
        });
    }
    
    //logic for 'fix' mode
    // ->set msg and specify '-remediate' arg
    else
    {
        //update status msg in main thread
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            //set
            self.statusMsg.stringValue = @"fixing...";

        });

        //append '-remediate' arg
        [arguments appendString:@" -remediate"];
    }
   
    //init task
    task = [NSTask new];
    
    //init output pipe
    outPipe = [NSPipe pipe];
    
    //assign pipe to std output
    [task setStandardOutput:outPipe];
    
    //assign pipe to std error too
    [task setStandardError:outPipe];

    //init read handle
    readHandle = [outPipe fileHandleForReading];
    
    //set task's path
    // ->exec via /bin/bash, so specify that
    [task setLaunchPath:BASH];
    
    //set task's args
    [task setArguments:@[@"-c", arguments]];
    
    //launch
    [task launch];
    
    //grab output
    // ->display in scrolling text view
    while(YES == [task isRunning])
    {
        //init string with avaialable data
        partialOutput = [[NSString alloc] initWithData:[readHandle availableData] encoding:NSUTF8StringEncoding];
    
        //convert to attributed string
        // ->wrap as AMR_ANSIEscapeHelper is a bit buggy (e.g. if ansi escapings aren't balanced)
        @try
        {
            //convert
            convertedString = [[[AMR_ANSIEscapeHelper alloc] init] attributedStringWithANSIEscapedString:partialOutput];
            
            //append to cumulative output
            [cumulativeOutput appendAttributedString:convertedString];
        }
        //if conversion failed
        // ->just use unconverted string...
        @catch (NSException *exception)
        {
            //append to cumulative output
            [cumulativeOutput appendAttributedString:[[NSAttributedString alloc] initWithString:partialOutput attributes:nil]];
        }
        
        //update ui on main thread
        // ->add output to text view, scroll, and update progress indicator
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            //update text view's text
            [[self.output textStorage] setAttributedString:cumulativeOutput];
            
            //scroll
            [self.output scrollRangeToVisible:NSMakeRange([[self.output string] length], 0)];

            //increment circular progress indicator
            [self.progressIndicator incrementBy:(float)100/enabledCommands];
            
        });
    }
    
    //init string with avaialable data
    partialOutput = [[NSString alloc] initWithData:[readHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    
    //convert to attributed string
    // ->wrap as AMR_ANSIEscapeHelper is a bit buggy (e.g. if ansi escapings aren't balanced)
    @try
    {
        //convert
        convertedString = [[[AMR_ANSIEscapeHelper alloc] init] attributedStringWithANSIEscapedString:partialOutput];
        
        //append to cumulative output
        [cumulativeOutput appendAttributedString:convertedString];
    }
    //if conversion failed
    // ->just use unconverted string...
    @catch (NSException *exception)
    {
        //append to cumulative output
        [cumulativeOutput appendAttributedString: [[NSAttributedString alloc] initWithString:partialOutput attributes:nil]];
    }

    //finalize UI
    // ->set status message and enable buttons
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        //update text view's text
        [[self.output textStorage] setAttributedString:cumulativeOutput];
        
        //scroll
        [self.output scrollRangeToVisible:NSMakeRange([[self.output string] length], 0)];
    
        //make sure process indicator is complete
        self.progressIndicator.doubleValue = 100;
        
        //update status msg
        self.statusMsg.stringValue = @"complete!";
        
        //enable 'back' button
        self.backButton.enabled = YES;
        
        //enable 'close' button
        self.closeButton.enabled = YES;
        
        //make 'close' button selected
        [[[NSApplication sharedApplication] keyWindow] makeFirstResponder:self.closeButton];
        
    });
    
    return;
}

//automatically invoked when user clicks 'back'
// ->return to previous ('commands') view
-(IBAction)backButtonHandler:(id)sender
{
    //change (back) to commands view
    [((AppDelegate*)[[NSApplication sharedApplication] delegate]) changeViewController:VIEW_COMMANDS];
    
    return;
}

//automatically invoked when user clicks 'close'
// ->just exit app
-(IBAction)closeButtonHandler:(id)sender
{
    //exit
    [NSApp terminate:self];
    
    return;
}

@end
