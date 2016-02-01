//
//  MEXLatteSharePlugin.h
//  CocoaShare
//
//  Created by Eduardo Almeida on 31/01/16.
//  Copyright (c) 2016 Eduardo Almeida (edr.io)
//

#import <Cocoa/Cocoa.h>

#import "MGMPlugInProtocol.h"

@interface MEXLatteSharePlugin : NSObject <MGMPlugInProtocol> {
    IBOutlet NSView *view;
    
    IBOutlet NSTextField *urlField;
    IBOutlet NSTextField *userField;
    IBOutlet NSTextField *passwordField;
    
    IBOutlet NSButton *loginButton;
    
    BOOL userLoggingIn;
    BOOL performingMultiUpload;
    
    NSMutableArray *currentMultiUpload;
}

@end
