//
//  NSApplicationKeyEvents.m
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

#import "NSApplicationKeyEvents.h"

@implementation NSApplicationKeyEvents

//to enable select/copy etc even though app doesn't have an 'Edit' menu
// details: http://stackoverflow.com/questions/970707/cocoa-keyboard-shortcuts-in-dialog-without-an-edit-menu
-(void)sendEvent:(NSEvent *)event
{
    //keydown logic
    // ->cmd+c, cmd+v, cmd+a
    if( ([event type] == NSKeyDown) &&
        (([event modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) )
    {
        //cmd+a
        if ([[event charactersIgnoringModifiers] isEqualToString:@"a"])
        {
            if ([self sendAction:@selector(selectAll:) to:nil from:self])
                return;
        }
        
        //cmd+c
        else if ([[event charactersIgnoringModifiers] isEqualToString:@"c"])
        {
            if ([self sendAction:@selector(copy:) to:nil from:self])
                return;
        }
    }
    
    //super
    [super sendEvent:event];
    
    return;
}

@end
