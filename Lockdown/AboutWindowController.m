//
//  AboutWindowController.m
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

#import "Consts.h"
#import "AppDelegate.h"

#import "AboutWindowController.h"


@implementation AboutWindowController

@synthesize versionLabel;

//automatically called when nib is loaded
// ->center window
-(void)awakeFromNib
{
    //center
    [self.window center];
}

//automatically invoked when window is loaded
// ->set to white
-(void)windowDidLoad
{
    //super
    [super windowDidLoad];
    
    //make white
    [self.window setBackgroundColor: NSColor.whiteColor];
    
    //set version sting
    [self.versionLabel setStringValue:[NSString stringWithFormat:@"version: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];

    return;
}

//automatically invoked when user clicks 'more info'
// ->load lockdown's html page in the user's default browser
-(IBAction)moreInfo:(id)sender
{
    //open URL
    // ->invokes user's default browser
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:PRODUCT_URL]];
        
    return;
}
@end
