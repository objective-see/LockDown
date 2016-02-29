//
//  AppDelegate.h
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

#import <Cocoa/Cocoa.h>

#import "AboutWindowController.h"
#import "ErrorWindowController.h"


@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    
}

/* PROPERTIES */

//current view controller
@property(nonatomic, retain)NSViewController* currentViewController;

//commands
@property(nonatomic, retain)NSMutableArray* commands;

//commands path
@property(nonatomic, retain)NSString* commandsFile;

//main view
@property(nonatomic, retain)NSView *mainView;

//command execution mode
// ->audit/fix
@property NSUInteger mode;

//about window controller
@property(nonatomic, retain)AboutWindowController* aboutWindowController;

//error window controller
@property(nonatomic, retain)ErrorWindowController* errorWindowController;


/* METHODS */

//change top pane
// ->switch between either flat (default) or tree-based (hierachical) view
-(void)changeViewController:(NSUInteger)viewID;

//check if app is pristine
// ->that is to say, nobody modified on-disk image/resources
OSStatus verifySelf();

//load commands
// ->read them into memory and convery into objc obj
-(BOOL)loadCommands;

//save commands
// ->write out commands to disk
-(BOOL)saveCommands;

//display error window
-(void)displayErrorWindow:(NSDictionary*)errorInfo;

@end

