//
//  MyProfileModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MyProfileModel.h"
#import "TeleMedApplication.h"
#import "ProfileProtocol.h"
#import "AccountModel.h"
#import "RegisteredDeviceModel.h"
#import "MyProfileXMLParser.h"

@interface MyProfileModel()

@property (nonatomic) AccountModel *oldMyPreferredAccount;

// @property (nonatomic) BOOL hasChangedPassword; // TESTING ONLY
@property (nonatomic) BOOL IsAuthenticated; // Not passed from web service

@end

@implementation MyProfileModel

@synthesize TimeoutPeriodMins = _TimeoutPeriodMins;

+ (id <ProfileProtocol>)sharedInstance
{
	static dispatch_once_t token;
	static id <ProfileProtocol> sharedMyProfileInstance = nil;
	
	dispatch_once(&token, ^
	{
		sharedMyProfileInstance = [[self alloc] init];
	});
	
	return sharedMyProfileInstance;
}

// Override MyPreferredAccount setter to also store existing my preferred account
- (void)setMyPreferredAccount:(AccountModel *)account
{
	if (_MyPreferredAccount != account)
	{
		// Store reference to previous value to be restored (only used by PreferredAccountModel in case of error saving MyPreferredAccount to server)
		if (_MyPreferredAccount != nil)
		{
			_oldMyPreferredAccount = _MyPreferredAccount;
		}
		
		_MyPreferredAccount = account;
	}
}

// Override TimeoutPeriodMins getter
- (NSNumber *)TimeoutPeriodMins
{
	// If app timeout period is not already set, then check user preferences
	if (! _TimeoutPeriodMins)
	{
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		
		_TimeoutPeriodMins = [settings valueForKey:USER_TIMEOUT_PERIOD_MINUTES];
	}
	
	return _TimeoutPeriodMins ?: [NSNumber numberWithInteger:DEFAULT_TIMEOUT_PERIOD];
}

// Override TimeoutPeriodMins setter to update application's timeout period and store value in user preferences
- (void)setTimeoutPeriodMins:(NSNumber *)TimeoutPeriodMins
{
	if (_TimeoutPeriodMins != TimeoutPeriodMins)
	{
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		
		[settings setValue:TimeoutPeriodMins forKey:USER_TIMEOUT_PERIOD_MINUTES];
		[settings synchronize];
		
		_TimeoutPeriodMins = TimeoutPeriodMins;
	}
	
	[(TeleMedApplication *)[UIApplication sharedApplication] setTimeoutPeriodMins:[TimeoutPeriodMins integerValue]];
}

- (void)doLogout
{
	[self setIsAuthenticated:NO];
}

- (void)getWithCallback:(void (^)(BOOL success, id <ProfileProtocol> profile, NSError *error))callback
{
	[self.operationManager GET:@"MyProfile" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		MyProfileXMLParser *parser = [[MyProfileXMLParser alloc] init];
		
		[parser setMyProfile:self];
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			// Update the isAuthenticated flag
			[self setIsAuthenticated:YES];
			
			// Search user's registered devices to determine whether any match the current device. If so, update the current device with the new phone number
			[self setCurrentDevice];
			
			/*/ TESTING ONLY (used to show the change password screen after "cold" start)
			#if DEBUG
				if (! self.hasChangedPassword)
				{
					[self setPasswordChangeRequired:YES];
					[self setHasChangedPassword:YES];
				}
			#endif
			// END TESTING ONLY */
			
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
		NSLog(@"MyProfileModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving your Profile." andTitle:@"Profile Error"];
		
		callback(NO, nil, error);
	}];
}

- (BOOL)isAuthenticated {
	return _IsAuthenticated;
}

- (BOOL)isAuthorized {
	return _IsAuthorized;
}

// Restore MyPreferredAccount to previous value (only used by PreferredAccountModel in case of error saving my preferred account to server)
- (void)restoreMyPreferredAccount
{
	if (_oldMyPreferredAccount != nil)
	{
		_MyPreferredAccount = _oldMyPreferredAccount;
	}
}

- (void)setCurrentDevice
{
	#if DEBUG
		NSLog(@"Skip Set Current Device step when on Simulator or Debugging");
		
		return;
	#endif
	
	if ([self.MyRegisteredDevices count] == 0)
	{
		return;
	}
	
	RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
	
	// Search user's registered devices for the current device
	for (RegisteredDeviceModel *registeredDevice in self.MyRegisteredDevices)
	{
		// If found, set the current device's phone number
		if ([registeredDevice.ID caseInsensitiveCompare:registeredDeviceModel.ID] == NSOrderedSame)
		{
			[registeredDeviceModel setCurrentDevice:registeredDevice];
			
			NSLog(@"Current Device already Registered with ID: %@ and Phone Number: %@", registeredDeviceModel.ID, registeredDeviceModel.PhoneNumber);
		}
	}
}

@end
