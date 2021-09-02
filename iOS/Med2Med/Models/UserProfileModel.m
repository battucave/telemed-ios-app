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

@interface UserProfileModel()

@property (nonatomic) BOOL IsAuthenticated; // Not passed from web service

@end

@implementation UserProfileModel

@synthesize TimeoutPeriodMins = _TimeoutPeriodMins;

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
		NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
		_PhoneNumber = [settings valueForKey:USER_PROFILE_PHONE_NUMBER];
	}
	
	return _PhoneNumber ?: @"";
}

// Override TimeoutPeriodMins getter
- (NSNumber *)TimeoutPeriodMins
{
	// If app timeout period is not already set, then check user preferences
	if (! _TimeoutPeriodMins)
	{
		NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
		
		_TimeoutPeriodMins = [settings valueForKey:USER_TIMEOUT_PERIOD_MINUTES];
	}
	
	return _TimeoutPeriodMins ?: [NSNumber numberWithInteger:DEFAULT_TIMEOUT_PERIOD];
}

// Override TimeoutPeriodMins setter to update application's timeout period and store value in user preferences
- (void)setTimeoutPeriodMins:(NSNumber *)TimeoutPeriodMins
{
	if (_TimeoutPeriodMins != TimeoutPeriodMins)
	{
		NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
		
		[settings setValue:TimeoutPeriodMins forKey:USER_TIMEOUT_PERIOD_MINUTES];
		[settings synchronize];
		
		_TimeoutPeriodMins = TimeoutPeriodMins;
	}
	
	[(TeleMedApplication *)[UIApplication sharedApplication] setTimeoutPeriodMins:TimeoutPeriodMins.integerValue];
}

- (void)doLogout
{
	[self setIsAuthenticated:NO];
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
			// Update the isAuthenticated flag
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

- (BOOL)isAuthenticated
{
	return _IsAuthenticated;
}

- (BOOL)isAuthorized
{
	return _IsAuthorized;
}

@end
