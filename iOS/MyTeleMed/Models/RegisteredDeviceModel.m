//
//  RegisteredDeviceModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "RegisteredDeviceModel.h"

@implementation RegisteredDeviceModel

@synthesize ID = _ID;
@synthesize AppVersionInfo = _AppVersionInfo;

static RegisteredDeviceModel *sharedRegisteredDeviceInstance = nil;

+ (RegisteredDeviceModel *)sharedInstance
{
	static dispatch_once_t token;
	
	dispatch_once(&token, ^
	{
		sharedRegisteredDeviceInstance = [[super alloc] init];
	});
	
	return sharedRegisteredDeviceInstance;
}

// Override ID getter
- (NSString *)ID
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// If ID is not already set, check User Preferences
	if( ! _ID)
	{
		_ID = [settings valueForKey:@"UDDIDevice"];
	}
	
	// ID not already stored so generate it
	if( ! _ID)
	{
		// Generate Device ID
		CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
		
		if(theUUID)
		{
			_ID = (__bridge NSString *)(CFUUIDCreateString(kCFAllocatorDefault, theUUID));
			
			CFRelease(theUUID);
		}
		
		// Store Device ID in User Preferences
		[settings setValue:_ID forKey:@"UDDIDevice"];
		[settings synchronize];
	}
	
	return _ID;
}

// Override AppVersionInfo getter
- (NSString *)AppVersionInfo
{
	// If AppVersionInfo is not already set, check bundle version
	if( ! _AppVersionInfo)
	{
		_AppVersionInfo = [NSString stringWithFormat:@"Version: %@; Build: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey]];
	}
	
	return _AppVersionInfo;
}

- (void)registerDeviceWithCallback:(void(^)(BOOL success, NSError *error))callback
{
	// Device Simulator has no Phone Number and no Device Token. Continuing will cause Web Service Error
	//#if defined(DEBUG)
	#if (TARGET_IPHONE_SIMULATOR)
	NSLog(@"Skip Register Device Token step when on Simulator or Debugging");
	
	callback(YES, nil);
	
	return;
	#endif
	
	// Ensure that token is set. Sometimes the login process completes before the token has been set. For this reason, there is always a second call to this method from [AppDelegate didRegisterForRemoteNotificationsWithDeviceToken]
	// Also ensure that device actually needs to register
	if(self.Token == NULL || self.PhoneNumber == NULL || ! self.shouldRegister)
	{
		if(self.Token == NULL)
		{
			NSLog(@"IMPORTANT: Device does not have a token so it is not being registered with TeleMed. If this persists, make sure that an explicit provisioning profile is being used for MyTeleMed and that its certificate has Push Notifications enabled.");
		}
		
		callback(YES, nil);
		
		return;
	}
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<RegisteredDevice xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/MyTmd.Models\">"
			"<AppVersionInfo>%@</AppVersionInfo>"
			"<ID>%@</ID>"
			"<PhoneNumber>%@</PhoneNumber>"
			"<PlatformID>iOS</PlatformID>"
			"<Token>%@</Token>"
		"</RegisteredDevice>",
		self.AppVersionInfo, self.ID, self.PhoneNumber, self.Token];
	
	NSLog(@"XML Body: %@", xmlBody);
		
	[self.operationManager POST:@"RegisteredDevices" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Successful Post returns a 204 code with no response
		if(operation.response.statusCode == 204)
		{
			// Disable Future Registration until next login
			self.shouldRegister = NO;
			
			callback(YES, nil);
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem registering your Device.", NSLocalizedDescriptionKey, nil]];
			
			callback(NO, error);
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"RegisteredDeviceModel Error: %@", error);
		
		// IMPORTANT: revisit this when TeleMed fixes the error response to parse that response for error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem registering your Device."];
		
		callback(NO, error);
	}];
}

@end