//
//  ViewController.m
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

#import "AppDelegate.h"
#import "ViewController.h"

@implementation ViewController

//initial view loaded
// ->make front, and load 'warning' view
-(void)viewDidLoad
{
    //super
    [super viewDidLoad];
    
    //make front
    [NSApp activateIgnoringOtherApps:YES];
    
    //save view
    ((AppDelegate*)[[NSApplication sharedApplication] delegate]).mainView = self.view;
    
    //load intial view
    // ->warns user of 'risks'
    [((AppDelegate*)[[NSApplication sharedApplication] delegate]) changeViewController:0x0];

    return;
}

@end
