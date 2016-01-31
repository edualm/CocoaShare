//
//  MEXLatteSharePlugin.h
//  CocoaShare
//
//  Created by Eduardo Almeida on 31/01/16.
//  Copyright (c) 2016 Eduardo Almeida (edr.io)
//

#import <Cocoa/Cocoa.h>

@interface MEXLatteSharePlugin : NSObject {
    IBOutlet NSView *view;
    
    IBOutlet NSTextField *urlField;
    IBOutlet NSTextField *userField;
    IBOutlet NSTextField *passwordField;
    
    IBOutlet NSButton *loginButton;
    
    BOOL userLoggingIn;
}

- (void)releaseView;

- (void)lockLogin;
- (void)unlockLogin;

- (IBAction)login:(id)sender;

@end
