//
//  ExecuteViewController.h
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

#import <Cocoa/Cocoa.h>

@interface ExecuteViewController : NSViewController

/* PROPERTIES */

//output text field
@property(unsafe_unretained)IBOutlet NSTextView *output;

//progress indicator
@property(weak)IBOutlet NSProgressIndicator *progressIndicator;

//status message
@property(weak)IBOutlet NSTextField *statusMsg;

//back button
@property(weak)IBOutlet NSButton *backButton;

//close button
@property(weak)IBOutlet NSButton *closeButton;

/* METHODS */

//execute commands
// ->dump output to text view
-(void)execCommands:(NSUInteger)mode;

//back button handler
-(IBAction)backButtonHandler:(id)sender;

//close button handler
-(IBAction)closeButtonHandler:(id)sender;

@end
