//
//  SSOProviderModel.m
//  TeleMed
//
//  Created by Shane Goodwin on 6/18/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "SSOProviderModel.h"
#import "AuthenticationHTTPSessionManager.h"
#import "GenericErrorXMLParser.h"
#import "SSOProviderXMLParser.h"

@implementation SSOProviderModel

@synthesize Name = _Name;

// Override Name getter
- (NSString *)Name
{
	// If SSOProvider is not already set, check User Preferences
	if( ! _Name)
	{
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		_Name = [settings valueForKey:@"SSOProvider"];
	}
	
	return _Name ?: @"";
}

// Override Name setter to store value in User Preferences
- (void)setName:(NSString *)newName
{
	if(_Name != newName)
	{
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		
		[settings setValue:newName forKey:@"SSOProvider"];
		[settings synchronize];
		
		_Name = newName;
	}
}

- (void)validate:(NSString *)newName withCallback:(void(^)(BOOL success, NSError *error))callback
{
	// Allow user to clear out SSO Provider in order to use the default provider
	if(newName.length == 0)
	{
		return callback(YES, nil);
	}
	
	AuthenticationHTTPSessionManager *authenticationManager = [AuthenticationHTTPSessionManager sharedInstance];
	
	newName = [newName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	[authenticationManager GET:[NSString stringWithFormat:@"SsoProvider/%@", newName] parameters:nil success:^(__unused NSURLSessionDataTask *task, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		SSOProviderXMLParser *parser = [[SSOProviderXMLParser alloc] init];
		
		[parser setSsoProvider:self];
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if([xmlParser parse])
		{
			if( ! [self.Name isEqualToString:@""])
			{
				return callback(YES, nil);
			}
		}
		
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"ID Provider Error", NSLocalizedFailureReasonErrorKey, @"The ID Provider you entered is invalid. Please try again or leave blank.", NSLocalizedDescriptionKey, nil]];
		
		callback(NO, error);
	}
	failure:^(__unused NSURLSessionDataTask *task, NSError *error)
	{
		NSLog(@"SSOProviderModel Error: %@", error);
		NSLog(@"Header Fields: %@", [task.originalRequest allHTTPHeaderFields]);
		
		NSString *errorString;
		NSData *data = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseDataErrorKey];
		NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
		GenericErrorXMLParser *parser = [[GenericErrorXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file to obtain Error Message
		if([xmlParser parse] && ! [parser.error isEqualToString:@"An error has occurred."])
		{
			errorString = parser.error;
		}
		// Error parsing XML file or generic response returned
		else
		{
			errorString = @"The ID Provider entered is invalid.";
		}
		
		// Build a generic error message
		error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:error.code userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"ID Provider Error", NSLocalizedFailureReasonErrorKey, errorString, NSLocalizedDescriptionKey, nil]];
		
		callback(NO, error);
	}];
}

@end
