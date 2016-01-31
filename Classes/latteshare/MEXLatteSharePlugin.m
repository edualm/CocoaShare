//
//  MEXLatteSharePlugin.m
//  CocoaShare
//
//  Created by Eduardo Almeida on 31/01/16.
//
//

#import "MEXLatteSharePlugin.h"

#import <MGMUsers/MGMUsers.h>

#import "MGMController.h"
#import "MGMAddons.h"

NSString * const MGMCopyright = @"Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/";

NSString * const MEXLatteURL = @"MEXLatteURL";
NSString * const MEXLatteUser = @"MEXLatteUser";
NSString * const MEXLatteKey = @"MEXLatteKey";

NSString * const MGMHTTPPostMethod = @"POST";
NSString * const MGMHTTPURLForm = @"application/x-www-form-urlencoded";
NSString * const MGMHTTPContentType = @"content-type";

NSString * const MEXJSONKeyKey = @"key";
NSString * const MEXJSONSuccessKey = @"success";
NSString * const MEXJSONErrorKey = @"error";

const BOOL MGMHTTPResponseInvisible = YES;

@implementation MEXLatteSharePlugin

- (void)dealloc {
    [self releaseView];
    [super dealloc];
}

- (BOOL)isAccountPlugIn {
    return YES;
}
- (NSString *)plugInName {
    return @"latteshare";
}
- (NSView *)plugInView {
    if (view == nil) {
        if (![NSBundle loadNibNamed:@"latteAccountPane" owner:self]) {
            NSLog(@"Unable to load latteshare Account Pane");
        } else {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *url = [defaults objectForKey:MEXLatteURL];
            
            if (url != nil)
                [urlField setStringValue:url];
            
            NSString *user = [defaults objectForKey:MEXLatteUser];
            
            if (user != nil)
                [userField setStringValue:user];
        }
    }
    
    return view;
}

- (void)releaseView {
    [view release];
    
    view = nil;
    urlField = nil;
    userField = nil;
    passwordField = nil;
    loginButton = nil;
}

- (void)setCurrentPlugIn:(BOOL)isCurrent {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (isCurrent) {
        if ([defaults objectForKey:MEXLatteURL] != nil) {
            userLoggingIn = YES;
            
            MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[defaults objectForKey:MEXLatteURL]]] delegate:self];
            
            [handler setFailWithError:@selector(check:didFailWithError:)];
            [handler setFinish:@selector(checkDidFinish:)];
            [handler setInvisible:MGMHTTPResponseInvisible];
            
            [[[MGMController sharedController] connectionManager] addHandler:handler];
        }
    } else {
        [[[MGMController sharedController] connectionManager] cancelAll];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [defaults removeObjectForKey:MEXLatteURL];
        [defaults removeObjectForKey:MEXLatteUser];
    }
}

- (void)login {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[defaults objectForKey:MEXLatteURL]]];
    
    [request setHTTPMethod:MGMHTTPPostMethod];
    [request setValue:MGMHTTPURLForm forHTTPHeaderField:MGMHTTPContentType];
    [request setHTTPBody:[[NSString stringWithFormat:@"username=%@&password=%@", [[defaults objectForKey:MEXLatteUser] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[[MGMController sharedController] password] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    
    MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:request delegate:self];
    
    [handler setFailWithError:@selector(check:didFailWithError:)];
    [handler setFinish:@selector(checkDidFinish:)];
    [handler setInvisible:MGMHTTPResponseInvisible];
    
    [[[MGMController sharedController] connectionManager] addHandler:handler];
}

- (void)check:(MGMURLBasicHandler *)theHandler didFailWithError:(NSError *)theError {
    NSLog(@"HTTP Error: %@", theError);
    
    NSAlert *alert = [[NSAlert new] autorelease];
    [alert setMessageText:[@"Account Error" localizedFor:self]];
    [alert setInformativeText:[theError localizedDescription]];
    [alert runModal];
    
    [self unlockLogin];
}

- (void)checkDidFinish:(MGMURLBasicHandler *)theHandler {
    NSDictionary *response = [[theHandler string] parseJSON];
    
    NSLog(@"%@", response);
    
    if (response != nil) {
        if ([[response objectForKey:MEXJSONSuccessKey] boolValue]) {
            if ([response objectForKey:MEXJSONKeyKey] && !userLoggingIn) {
                NSAlert *alert = [[NSAlert new] autorelease];
                
                [alert setMessageText:[@"Login Successful" localizedFor:self]];
                [alert setInformativeText:[@"You have successfully logged into your account." localizedFor:self]];
                [alert runModal];
                
                [self unlockLogin];
            } else if (![[response objectForKey:MEXJSONKeyKey] boolValue]) {
                NSLog(@"HTTP Error: Unknown response from server.");
            }
        } else {
            if (![[response objectForKey:MEXJSONSuccessKey] boolValue]) {
                NSAlert *alert = [[NSAlert new] autorelease];
                
                [alert setMessageText:[@"Account Error" localizedFor:self]];
                [alert setInformativeText:@"The inserted details are wrong."];
                [alert runModal];
                
                [self unlockLogin];
            } else {
                NSLog(@"HTTP: Logged in.");
            }
        }
    } else {
        NSAlert *alert = [[NSAlert new] autorelease];
        
        [alert setMessageText:[@"Account Error" localizedFor:self]];
        [alert setInformativeText:[NSString stringWithFormat:[@"The URL %@ may not be a latteshare server." localizedFor:self], [[NSUserDefaults standardUserDefaults] objectForKey:MEXLatteURL]]];
        [alert runModal];
        
        [self unlockLogin];
    }
}

- (void)lockLogin {
    [urlField setEnabled:NO];
    [userField setEnabled:NO];
    [passwordField setEnabled:NO];
    [loginButton setEnabled:NO];
    [loginButton setTitle:[@"Logging In" localizedFor:self]];
}

- (void)unlockLogin {
    [urlField setEnabled:YES];
    [userField setEnabled:YES];
    [passwordField setEnabled:YES];
    [loginButton setEnabled:YES];
    [loginButton setTitle:[@"Login" localizedFor:self]];
}

- (IBAction)login:(id)sender {
    userLoggingIn = NO;
    
    if ([[urlField stringValue] isEqual:@""]) {
        NSAlert *alert = [[NSAlert new] autorelease];
        
        [alert setMessageText:[@"URL Required" localizedFor:self]];
        [alert setInformativeText:[@"Please enter the URL for the latteshare server." localizedFor:self]];
        [alert runModal];
    } else {
        [[MGMController sharedController] setPassword:[passwordField stringValue]];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [defaults setObject:[urlField stringValue] forKey:MEXLatteURL];
        [defaults setObject:[userField stringValue] forKey:MEXLatteUser];
        
        [self lockLogin];
        [self login];
    }
}

- (void)sendFileAtPath:(NSString *)thePath withName:(NSString *)theName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:MEXLatteURL] == nil || [[defaults objectForKey:MEXLatteURL] isEqual:@""]) {
        NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:5 userInfo:[NSDictionary dictionaryWithObject:[@"Account is not logged in." localizedFor:self] forKey:NSLocalizedDescriptionKey]];
        
        [[MGMController sharedController] upload:thePath receivedError:error];
        
        return;
    }
    
    srandomdev();
    
    NSString *boundary = [NSString stringWithFormat:@"----Boundary+%d", (int) random() % 100000];
    
    NSURL *uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [[NSUserDefaults standardUserDefaults] objectForKey:MEXLatteURL], @"/api/upload"]];
    
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:uploadURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:120.0];
    
    [postRequest setHTTPMethod:MGMHTTPPostMethod];
    [postRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary, nil] forHTTPHeaderField:@"Content-Type"];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    [data setObject:@"file" forKey:@"upload"];
    [data setObject:[NSDictionary dictionaryWithObjectsAndKeys:thePath, MGMMPFPath, theName, MGMMPFName, nil] forKey:@"file"];
    
    [postRequest setHTTPBody:[data buildMultiPartBodyWithBoundary:boundary]];
    
    MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:postRequest delegate:self];
    
    [handler setFailWithError:@selector(upload:didFailWithError:)];
    [handler setFinish:@selector(uploadDidFinish:)];
    [handler setInvisible:MGMHTTPResponseInvisible];
    [handler setObject:thePath];
    
    [[[MGMController sharedController] connectionManager] addHandler:handler];
}

- (void)upload:(MGMURLBasicHandler *)theHandler didFailWithError:(NSError *)theError {
    [[MGMController sharedController] upload:[theHandler object] receivedError:theError];
}

- (void)uploadDidFinish:(MGMURLBasicHandler *)theHandler {
    NSDictionary *response = [[theHandler string] parseJSON];
    
    if (response != nil) {
        if ([[response objectForKey:MEXJSONSuccessKey] boolValue]) {
            [[MGMController sharedController] uploadFinished:[theHandler object] url:[NSURL URLWithString:[response objectForKey:MEXLatteURL]]];
        } else {
            NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:1 userInfo:[NSDictionary dictionaryWithObject:[response objectForKey:MEXJSONErrorKey] forKey:NSLocalizedDescriptionKey]];
            
            [[MGMController sharedController] upload:[theHandler object] receivedError:error];
        }
    } else {
        NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier] code:1 userInfo:[NSDictionary dictionaryWithObject:[@"Invalid response." localizedFor:self] forKey:NSLocalizedDescriptionKey]];
        
        [[MGMController sharedController] upload:[theHandler object] receivedError:error];
    }
}

@end
