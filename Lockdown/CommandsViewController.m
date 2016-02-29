//
//  TestsViewController.m
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

#import "Consts.h"
#import "AppDelegate.h"
#import "CommandsViewController.h"


@implementation CommandsViewController

@synthesize fixButton;
@synthesize tableView;
@synthesize auditButton;

//table delegate
// ->return number of commands
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    //rows (command count)
    return ((AppDelegate*)[[NSApplication sharedApplication] delegate]).commands.count;
}

//table delegate method
// ->return cell for row
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    //command
    NSMutableDictionary* command = nil;
    
    //column index
    NSUInteger index = 0;

    //table cell
    NSTableCellView *result = nil;
    
    //check box
    NSButton* checkBox = nil;
    
    //get existing cell
    result = [self.tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    //grab index
    index = [[self.tableView tableColumns] indexOfObject:tableColumn];
    
    //get command for row
    command = ((AppDelegate*)[[NSApplication sharedApplication] delegate]).commands[row];
    
    //handle column specific logic
    switch(index)
    {
        //logic for 'enabled' column
        case COLUMN_ENABLED:
            
            //grab checkbox
            checkBox = (NSButton*)[result viewWithTag:1001];
            
            //for enabled commands
            // ->enable checkbox
            if(YES == [command[@"enabled"] isEqualToString:@"true"])
            {
                //enable
                checkBox.state = NSOnState;
            }
            //for disabled commands
            // ->disable checkbox
            else
            {
                //disable
                checkBox.state = NSOffState;
            }
            
            break;
           
        //logic for 'command' column
        case COLUMN_COMMAND:
            
            //set string to title of command
            result.textField.stringValue = command[@"title"];
            
            break;
            
        default:
            
            break;
    }
    
    return result;
}

//automatically invoked when user checks/unchecks checkbox in row
// ->enable/disable command state, plus handle some other button logic
-(IBAction)toggleTest:(id)sender
{
    //row
    NSInteger row = 0;
    
    //commands
    NSMutableArray* commands = nil;
    
    //get row
    row = [self.tableView rowForView:sender];
    
    //grab commands
    commands = ((AppDelegate*)[[NSApplication sharedApplication] delegate]).commands;
    
    //sanity check
    if( (-1 == row) ||
        (row >= commands.count) )
    {
        //bail
        goto bail;
    }
    
    //toggle command state
    // ->YAML wants 'true' or 'false' though...
    commands[row][@"enabled"] = (NSOnState == ((NSButton*)(sender)).state) ? @"true" : @"false";
    
    //buttons may have been disabled via a full toggle off
    // ->so just always re-enable (ok if they already are)
    if(NSOnState == ((NSButton*)(sender)).state)
    {
        //enable 'audit' button
        self.auditButton.enabled = YES;
        
        //enable 'fix' button
        self.fixButton.enabled = YES;
    }
    //if this is the last test disabled
    // ->disable buttons
    else
    {
        //check all
        for(NSMutableDictionary* command in commands)
        {
            //when at least one other is enabled
            // ->no need to do anything
            if(YES == [command[@"enabled"] isEqualToString:@"true"])
            {
                //bail
                goto bail;
            }
        }
        
        //all are disabled!
        // ->so disable buttons as well...
        
        //disable 'audit' button
        self.auditButton.enabled = NO;
        
        //disable 'fix' button
        self.fixButton.enabled = NO;
    }

//bail
bail:
    
    return;
}

//automatically invoked when user clicks 'Toggle All'
// ->toggle all commands 'on' or 'off' and enable/disable other buttons
-(IBAction)toggle:(id)sender
{
    //iterate over all commands
    // ->update enabled state
    for(NSMutableDictionary* command in ((AppDelegate*)[[NSApplication sharedApplication] delegate]).commands)
    {
        //toggle command state
        // ->YAML wants 'true' or 'false' though...
        command[@"enabled"] = (NSOnState == ((NSButton*)(sender)).state) ? @"true" : @"false";
    }

    //reload table
    [self.tableView reloadData];
    
    //when toggle is off
    // ->disable buttons
    if(NSOffState == ((NSButton*)(sender)).state)
    {
        //disable 'audit' button
        self.auditButton.enabled = NO;
        
        //disable 'fix' button
        self.fixButton.enabled = NO;
    }
    //otherwise enable
    // ->doesn't matter if they are already enabled
    else
    {
        //enable 'audit' button
        self.auditButton.enabled = YES;
        
        //enable 'fix' button
        self.fixButton.enabled = YES;
    }
    
    return;
}

//automatically invoked when either 'audit' or 'fix' buttons are clicked
// ->save commands (as some may be changed state), save mode, then load next view and execute commands
-(IBAction)executeCommands:(id)sender
{
    //alert
    NSAlert *alert = nil;
    
    //save all commands
    [((AppDelegate*)[[NSApplication sharedApplication] delegate]) saveCommands];
    
    //set mode
    ((AppDelegate*)[[NSApplication sharedApplication] delegate]).mode = ((NSButton*)sender).tag;
    
    //warn if updating all software (in fix mode)
    // ->this may not be what the user really wants to do, and might take awhile!
    if(MODE_FIX == ((NSButton*)sender).tag)
    {
        //find & check if 'update' software command is enabled
        if(YES == [[((AppDelegate*)[[NSApplication sharedApplication] delegate]).commands firstObject][@"enabled"] isEqualToString:@"true"])
        {
            //init alert
            alert = [[NSAlert alloc] init];
            
            //set button
            [alert addButtonWithTitle:@"ok"];
            
            //set button
            [alert addButtonWithTitle:@"cancel"];
            
            //set main text
            [alert setMessageText:@"Continuing will update all OS X software!"];
            
            //set detailed test
            [alert setInformativeText:@"\"Verify all application software is current\" is selected\r\n...this will run Apple's updater and may take awhile"];
            
            //set style to warning
            [alert setAlertStyle:NSWarningAlertStyle];
            
            //remove 'focus' ring
            // ->done via unsetting first responder
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^(void)
            {
                //unset first responder
                [[alert window] makeFirstResponder:nil];
            });
            
            //show alert/warning
            if(NSAlertFirstButtonReturn == [alert runModal])
            {
                //load view
                [((AppDelegate*)[[NSApplication sharedApplication] delegate]) changeViewController:VIEW_EXECUTE];
            }
        
            //bail
            goto bail;
            
        }//update software warning
        
    }//fix mode
    
    //load 'execute' view
    [((AppDelegate*)[[NSApplication sharedApplication] delegate]) changeViewController:VIEW_EXECUTE];
    
//bail
bail:
    
    return;
}

@end
