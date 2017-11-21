//
//  MyProfileModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MyProfileModel.h"
#import "ProfileProtocol.h"
#import "AccountModel.h"
#import "RegisteredDeviceModel.h"
#import "MyProfileXMLParser.h"

@interface MyProfileModel()

@property (nonatomic) AccountModel *oldMyPreferredAccount;

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

// Override MyPreferredAccount setter to also store existing MyPreferredAccount
- (void)setMyPreferredAccount:(AccountModel *)account
{
	if(_MyPreferredAccount != account)
	{
		// Store reference to previous value to be restored (only used by PreferredAccountModel in case of error saving MyPreferredAccount to server)
		if(_MyPreferredAccount != nil)
		{
			_oldMyPreferredAccount = _MyPreferredAccount;
		}
		
		_MyPreferredAccount = account;
	}
}

- (void)getWithCallback:(void (^)(BOOL success, id <ProfileProtocol> profile, NSError *error))callback
{
	[self.operationManager GET:@"MyProfile" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		MyProfileXMLParser *parser = [[MyProfileXMLParser alloc] init];
		
		[parser setMyProfile:self];
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if([xmlParser parse])
		{
			// Search user's Registered Devices to determine whether any match the current device. If so, update the current device with the new Phone Number
			[self setCurrentDevice];
			
			callback(YES, (id <ProfileProtocol>)self, nil);
		}
		// Error parsing XML file
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

// Restore MyPreferredAccount to previous value (only used by PreferredAccountModel in case of error saving MyPreferredAccount to server)
- (void)restoreMyPreferredAccount
{
	if(_oldMyPreferredAccount != nil)
	{
		_MyPreferredAccount = _oldMyPreferredAccount;
	}
}

- (void)setCurrentDevice
{
	if([self.MyRegisteredDevices count] == 0)
	{
		return;
	}
	
	RegisteredDeviceModel *myRegisteredDevice = [RegisteredDeviceModel sharedInstance];
	
	// Search user's Registered Devices for the current device
	for(RegisteredDeviceModel *registeredDevice in self.MyRegisteredDevices)
	{
		// If found, set the current device's Phone Number
		if([registeredDevice.ID caseInsensitiveCompare:myRegisteredDevice.ID] == NSOrderedSame)
		{
			myRegisteredDevice.PhoneNumber = registeredDevice.PhoneNumber;
			
			NSLog(@"Current Device already Registered with ID: %@ and Phone Number: %@", myRegisteredDevice.ID, myRegisteredDevice.PhoneNumber);
		}
	}
}

@end
