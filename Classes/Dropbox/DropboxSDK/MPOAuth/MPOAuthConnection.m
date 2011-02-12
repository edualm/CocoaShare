//
//  MPOAuthConnection.m
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import "MPOAuthConnection.h"
#import "MPOAuthURLRequest.h"
#import "MPOAuthURLResponse.h"
#import "MPOAuthParameterFactory.h"
#import "MPOAuthCredentialConcreteStore.h"

@implementation MPOAuthConnection

+ (MPOAuthConnection *)connectionWithRequest:(MPOAuthURLRequest *)inRequest delegate:(id)inDelegate credentials:(NSObject <MPOAuthCredentialStore, MPOAuthParameterFactory> *)inCredentials {
	MPOAuthConnection *aConnection = [[MPOAuthConnection alloc] initWithRequest:inRequest delegate:inDelegate credentials:inCredentials];
	return [aConnection autorelease];
}

+ (NSData *)sendSynchronousRequest:(MPOAuthURLRequest *)inRequest usingCredentials:(NSObject <MPOAuthCredentialStore, MPOAuthParameterFactory> *)inCredentials returningResponse:(MPOAuthURLResponse **)outResponse error:(NSError **)inError {
	[inRequest addParameters:[inCredentials oauthParameters]];
	NSURLRequest *urlRequest = [inRequest urlRequestSignedWithSecret:[inCredentials signingKey] usingMethod:[inCredentials signatureMethod]];
	NSURLResponse *urlResponse = nil;
	NSData *responseData = [self sendSynchronousRequest:urlRequest returningResponse:&urlResponse error:inError];
	MPOAuthURLResponse *oauthResponse = [[[MPOAuthURLResponse alloc] init] autorelease];
	[oauthResponse setResponse:urlResponse];
	*outResponse = oauthResponse;
	
	return responseData;
}

- (id)initWithRequest:(MPOAuthURLRequest *)inRequest delegate:(id)inDelegate credentials:(NSObject <MPOAuthCredentialStore, MPOAuthParameterFactory> *)inCredentials {
	[inRequest addParameters:[inCredentials oauthParameters]];
	NSURLRequest *urlRequest = [inRequest urlRequestSignedWithSecret:[inCredentials signingKey] usingMethod:[inCredentials signatureMethod]];
	if ((self = [super initWithRequest:urlRequest delegate:inDelegate])) {
		credentials = [inCredentials retain];
	}
	return self;
}

- (oneway void)dealloc {
	[credentials release];
	[super dealloc];
}

- (id<MPOAuthCredentialStore,MPOAuthParameterFactory>)credentials {
	return credentials;
}

#pragma mark -

@end
