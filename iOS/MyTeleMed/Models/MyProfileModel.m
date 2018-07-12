//
//  MyProfileModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "TeleMedApplication.h"
#import "MyProfileModel.h"
#import "ProfileProtocol.h"
#import "AccountModel.h"
#import "RegisteredDeviceModel.h"
#import "MyProfileXMLParser.h"

@interface MyProfileModel()

@property (nonatomic) AccountModel *oldMyPreferredAccount;

// @property (nonatomic) BOOL hasChangedPassword; // TESTING ONLY

@end

@implementation MyProfileModel

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
	[self.operationManager GET:@"MyProfile" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		MyProfileXMLParser *parser = [[MyProfileXMLParser alloc] init];
		
		[parser setMyProfile:self];
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			// Search user's registered devices to determine whether any match the current device. If so, update the current device with the new phone number
			[self setCurrentDevice];
			
			/*/ TESTING ONLY (used to show the change password screen after "cold" start)
			#ifdef DEBUG
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

// Restore MyPreferredAccount to previous value (only used by preferred account model in case of error saving my preferred account to server)
- (void)restoreMyPreferredAccount
{
	if (_oldMyPreferredAccount != nil)
	{
		_MyPreferredAccount = _oldMyPreferredAccount;
	}
}

- (void)setCurrentDevice
{
	if ([self.MyRegisteredDevices count] == 0)
	{
		return;
	}
	
	RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
	
	// Search user's registered devices for the current device
	for(RegisteredDeviceModel *registeredDevice in self.MyRegisteredDevices)
	{
		// If found, set the current device's phone number
		if ([registeredDevice.ID caseInsensitiveCompare:registeredDeviceModel.ID] == NSOrderedSame)
		{
			[registeredDeviceModel setHasRegistered:YES];
			[registeredDeviceModel setPhoneNumber:registeredDevice.PhoneNumber];
			
			NSLog(@"Current Device already Registered with ID: %@ and Phone Number: %@", registeredDeviceModel.ID, registeredDeviceModel.PhoneNumber);
		}
	}
}

@end
