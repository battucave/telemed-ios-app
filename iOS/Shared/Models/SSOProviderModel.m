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
#import "Validation.h"

@implementation SSOProviderModel

@synthesize EmailAddress = _EmailAddress;
@synthesize Name = _Name;

// Override EmailAddress getter
- (NSString *)EmailAddress
{
	// If email address is not already set, then check user preferences
	if (! _EmailAddress)
	{
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		
		_EmailAddress = [settings valueForKey:@"SSOProviderEmailAddress"];
	}
	
	return _EmailAddress ?: nil;
}

// Override EmailAddress setter to store value in user preferences
- (void)setEmailAddress:(NSString *)newEmailAddress
{
	if (_EmailAddress != newEmailAddress)
	{
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		
		[settings setValue:newEmailAddress forKey:@"SSOProviderEmailAddress"];
		[settings synchronize];
		
		_EmailAddress = newEmailAddress;
	}
}

// Override Name getter
- (NSString *)Name
{
	// If name is not already set, then check user preferences
	if (! _Name)
	{
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		
		_Name = [settings valueForKey:@"SSOProvider"];
	}
	
	return _Name ?: @"";
}

// Override Name setter to store value in user preferences
- (void)setName:(NSString *)newName
{
	if (_Name != newName)
	{
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		
		[settings setValue:newName forKey:@"SSOProvider"];
		[settings synchronize];
		
		_Name = newName;
	}
}

/**
 * Validate sso provider by email address
 */
- (void)validateEmailAddress:(NSString *)emailAddress withCallback:(void(^)(BOOL success, NSError *error))callback
{
	// Allow user to clear out sso provider in order to use the default provider
	if (emailAddress.length == 0)
	{
		// Build a generic error message
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"SSO Provider Error", NSLocalizedFailureReasonErrorKey, @"Email address field is required.", NSLocalizedDescriptionKey, nil]];
		
		callback(NO, error);
		
		return;
	}
	else if (! [Validation isEmailAddressValid:emailAddress])
	{
		// Build a generic error message
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"SSO Provider Error", NSLocalizedFailureReasonErrorKey, @"Email address field must be a valid email address.", NSLocalizedDescriptionKey, nil]];
		
		callback(NO, error);
		
		return;
	}
	
	AuthenticationHTTPSessionManager *authenticationManager = [AuthenticationHTTPSessionManager sharedInstance];
	
	emailAddress = [emailAddress stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	
	[authenticationManager GET:[NSString stringWithFormat:@"SsoProvider?em=%@", emailAddress] parameters:nil success:^(__unused NSURLSessionDataTask *task, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		SSOProviderXMLParser *parser = [[SSOProviderXMLParser alloc] init];
		
		[parser setSsoProvider:self];
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			if (! [self.Name isEqualToString:@""])
			{
				return callback(YES, nil);
			}
		}
		
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"SSO Provider Error", NSLocalizedFailureReasonErrorKey, @"Email address field must be a valid email address.", NSLocalizedDescriptionKey, nil]];
		
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
		
		// Parse the xml file to obtain error message
		if ([xmlParser parse] && ! [parser.error isEqualToString:@"An error has occurred."])
		{
			errorString = parser.error;
		}
		// Error parsing xml file or generic response returned
		else
		{
			errorString = @"The email address you entered is invalid.";
		}
		
		// Build a generic error message
		error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:error.code userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"SSO Provider Error", NSLocalizedFailureReasonErrorKey, errorString, NSLocalizedDescriptionKey, nil]];
		
		callback(NO, error);
	}];
}

/**
 * Validate sso provider by name
 *
 * Deprecated 5/16/19
 */
- (void)validateName:(NSString *)name withCallback:(void(^)(BOOL success, NSError *error))callback
{
	// Allow user to clear out sso provider in order to use the default provider
	if (name.length == 0)
	{
		return callback(YES, nil);
	}
	
	AuthenticationHTTPSessionManager *authenticationManager = [AuthenticationHTTPSessionManager sharedInstance];
	
	name = [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	
	[authenticationManager GET:[NSString stringWithFormat:@"SsoProvider/%@", name] parameters:nil success:^(__unused NSURLSessionDataTask *task, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		SSOProviderXMLParser *parser = [[SSOProviderXMLParser alloc] init];
		
		[parser setSsoProvider:self];
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			if (! [self.Name isEqualToString:@""])
			{
				return callback(YES, nil);
			}
		}
		
		NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"SSO Provider Error", NSLocalizedFailureReasonErrorKey, @"The ID Provider you entered is invalid. Please try again or leave blank.", NSLocalizedDescriptionKey, nil]];
		
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
		
		// Parse the xml file to obtain error message
		if ([xmlParser parse] && ! [parser.error isEqualToString:@"An error has occurred."])
		{
			errorString = parser.error;
		}
		// Error parsing xml file or generic response returned
		else
		{
			errorString = @"The ID Provider you entered is invalid.";
		}
		
		// Build a generic error message
		error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:error.code userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"SSO Provider Error", NSLocalizedFailureReasonErrorKey, errorString, NSLocalizedDescriptionKey, nil]];
		
		callback(NO, error);
	}];
}

@end
