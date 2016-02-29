//
//  WarningViewController.m
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

#import "Consts.h"
#import "AppDelegate.h"
#import "WarningViewController.h"


@implementation WarningViewController

@synthesize continueButton;

//view loaded
// ->enable 'continue' button after a bit
-(void)viewDidLoad
{
    //super
    [super viewDidLoad];
}

//automatically invoked
// ->button handler for 'continue' button
-(IBAction)buttonHandler:(id)sender
{
    //change to commands view
    [((AppDelegate*)[[NSApplication sharedApplication] delegate]) changeViewController:VIEW_COMMANDS];
    
    return;
}

@end
