//
//  UserProfileModel.m
//  Med2Med
//
//  Created by Shane Goodwin on 11/21/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "TeleMedApplication.h"
#import "UserProfileModel.h"
#import "ProfileProtocol.h"
#import "UserProfileXMLParser.h"

@implementation UserProfileModel

+ (id <ProfileProtocol>)sharedInstance
{
	static dispatch_once_t token;
	static id <ProfileProtocol> sharedUserProfileInstance = nil;
	
	dispatch_once(&token, ^
	{
		sharedUserProfileInstance = [[self alloc] init];
	});
	
	return sharedUserProfileInstance;
}

// Override PhoneNumber getter
- (NSString *)PhoneNumber
{
	// If phone number is not already set, check user preferences
	if (! _PhoneNumber)
	{
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		_PhoneNumber = [settings valueForKey:@"UserProfilePhoneNumber"];
	}
	
	return _PhoneNumber ?: @"";
}

// Override TimeoutPeriodMins setter to also update application's timeout period
- (void)setTimeoutPeriodMins:(NSNumber *)TimeoutPeriodMins
{
	if (_TimeoutPeriodMins != TimeoutPeriodMins)
	{
		_TimeoutPeriodMins = TimeoutPeriodMins;
	}
	
	[(TeleMedApplication *)[UIApplication sharedApplication] setTimeoutPeriodMins:[TimeoutPeriodMins intValue]];
}

- (void)getWithCallback:(void (^)(BOOL success, id <ProfileProtocol> profile, NSError *error))callback
{
	[self.operationManager GET:@"UserProfile" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		UserProfileXMLParser *parser = [[UserProfileXMLParser alloc] init];
		
		[parser setUserProfile:self];
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			// Update authenticated flag
			[self setIsAuthenticated:YES];
			
			callback(YES, (id <ProfileProtocol>)self, nil);
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Profile Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving your Profile.", NSLocalizedDescriptionKey, nil]];
			
			callback(NO, nil, error);
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"UserProfileModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving your Profile." andTitle:@"Profile Error"];
		
		callback(NO, nil, error);
	}];
}

@end
