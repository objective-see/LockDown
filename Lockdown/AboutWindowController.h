//
//  AboutWindowController.h
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

#import <Cocoa/Cocoa.h>

@interface AboutWindowController : NSWindowController <NSWindowDelegate>
{
    
}

/* PROPERTIES */

//version label/string
@property(weak) IBOutlet NSTextField *versionLabel;

/* METHODS */

//invoked when user clicks 'more info' button
// ->open Lockdown's product page
- (IBAction)moreInfo:(id)sender;

@end
