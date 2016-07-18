//
//  MyProfileModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MyProfileModel.h"
#import "AccountModel.h"
#import "RegisteredDeviceModel.h"
#import "MyProfileXMLParser.h"

@implementation MyProfileModel

static MyProfileModel *sharedMyProfileInstance = nil;

+ (MyProfileModel *)sharedInstance
{
	static dispatch_once_t token;
	
	dispatch_once(&token, ^
	{
		sharedMyProfileInstance = [[super alloc] init];
	});
	
	return sharedMyProfileInstance;
}

- (void)getWithCallback:(void (^)(BOOL success, MyProfileModel *profile, NSError *error))callback
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
			
			callback(YES, self, nil);
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Error parsing My Profile.", NSLocalizedDescriptionKey, nil]];
			
			callback(NO, nil, error);
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MyProfileModel Error: %@", error);
		
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving your Account."];
		
		callback(NO, nil, error);
	}];
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