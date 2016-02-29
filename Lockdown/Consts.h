//
//  Consts.h
//  Lockdown
//
//  Created by Patrick Wardle on 2/14/16 and is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
//

#ifndef Consts_h
#define Consts_h

//path to bash
#define BASH @"/bin/bash"

//osx lockdown binary
#define BINARY_FILE @"osxlockdown"

//(yaml) commands
#define COMMANDS_FILE @"commands.yaml"

//warning view
#define VIEW_WARNING 0x0

//commands view
#define VIEW_COMMANDS 0x01

//execute view
#define VIEW_EXECUTE 0x02

//enabled column
#define COLUMN_ENABLED 0x0

//command column
#define COLUMN_COMMAND 0x1

//audit mode
#define MODE_AUDIT 101

//fix mode
#define MODE_FIX 102

//error msg
#define KEY_ERROR_MSG @"errorMsg"

//sub msg
#define KEY_ERROR_SUB_MSG @"errorSubMsg"

//error URL
#define KEY_ERROR_URL @"errorURL"

//flag for error popup
#define KEY_ERROR_SHOULD_EXIT @"shouldExit"

//general error URL
#define FATAL_ERROR_URL @"https://objective-see.com/errors.html"

//product url
#define PRODUCT_URL @"https://objective-see.com/products/lockdown.html"

#endif /* Consts_h */
