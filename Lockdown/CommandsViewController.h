//
//  TestsViewController.h
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

#import <Cocoa/Cocoa.h>

@interface CommandsViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
{
    
}

/* PROPERTIES */

//table view
@property(weak)IBOutlet NSTableView *tableView;

//'audit' button
@property(weak)IBOutlet NSButton *auditButton;

//'fix' button
@property(weak)IBOutlet NSButton *fixButton;

/* METHODS */

//checkbox button handler
-(IBAction)toggleTest:(id)sender;

//'audit' and 'fix' button handler
-(IBAction)executeCommands:(id)sender;

@end
