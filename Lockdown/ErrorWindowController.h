//
//  ErrorWindowController.h
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

#import <Cocoa/Cocoa.h>

@interface ErrorWindowController : NSWindowController <NSWindowDelegate>
{
    
}

/* PROPERTIES */

//main msg in window
@property (weak) IBOutlet NSTextField *errMsg;

//sub msg in window
@property (weak) IBOutlet NSTextField *errSubMsg;

//info/help/fix button
@property (weak) IBOutlet NSButton *infoButton;

//close button
@property (weak) IBOutlet NSButton *closeButton;

//(optional) url for 'Info' button
@property(nonatomic, retain)NSURL* errorURL;

//flag indicating close button should exit app
@property BOOL shouldExit;

/* METHODS */

//configure the object/window
-(void)configure:(NSDictionary*)errorInfo;

//display (show) window
-(void)display;

@end
