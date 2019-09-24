//
//  RegisteredDeviceModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "RegisteredDeviceModel.h"

@interface RegisteredDeviceModel()

@property (nonatomic) BOOL hasRegistered; // Whether app has registered during current session (re-registers every launch)
@property (nonatomic) BOOL hasSkippedRegistration;
@property (nonatomic) BOOL isRegistered; // Whether device is registered with TeleMed

@end

@implementation RegisteredDeviceModel

@synthesize ID = _ID;
@synthesize AppVersionInfo = _AppVersionInfo;

static RegisteredDeviceModel *sharedRegisteredDeviceInstance = nil;

+ (instancetype)sharedInstance
{
	static dispatch_once_t token;
	
	dispatch_once(&token, ^
	{
		sharedRegisteredDeviceInstance = [[self alloc] init];
		
		// If using Simulator, then skip phone number step because it is always invalid
		// #ifdef DEBUG
		#if TARGET_IPHONE_SIMULATOR
			NSLog(@"Skip Phone Number step when on Simulator or Debugging");
		
			[sharedRegisteredDeviceInstance setIsRegistered:YES];
		#endif
	});
	
	return sharedRegisteredDeviceInstance;
}

// Override ID getter
- (NSString *)ID
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// If ID is not already set, check user preferences
	if (! _ID)
	{
		_ID = [settings valueForKey:UDDI_DEVICE];
	}
	
	// ID not already stored so generate it
	if (! _ID)
	{
		// Generate device id
		CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
		
		if (theUUID)
		{
			_ID = (__bridge NSString *)(CFUUIDCreateString(kCFAllocatorDefault, theUUID));
			
			CFRelease(theUUID);
		}
		
		// Store device id in user preferences
		[settings setValue:_ID forKey:UDDI_DEVICE];
		[settings synchronize];
	}
	
	return _ID;
}

// Override AppVersionInfo getter
- (NSString *)AppVersionInfo
{
	// If app version info is not already set, check bundle version
	if (! _AppVersionInfo)
	{
		_AppVersionInfo = [NSString stringWithFormat:@"Version: %@; Build: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey]];
	}
	
	return _AppVersionInfo;
}

// Set public hasSkippedRegistration setter
- (BOOL)hasSkippedRegistration
{
	return _hasSkippedRegistration;
}

// Set public isRegistered setter
- (BOOL)isRegistered
{
	return _isRegistered;
}

- (void)registerDeviceWithCallback:(void(^)(BOOL success, NSError *error))callback
{
	// Device simulator has no phone number and no device token. Continuing will cause web service error
	// #ifdef DEBUG
	#if TARGET_IPHONE_SIMULATOR
		NSLog(@"Skip Register Device Token step when on Simulator or Debugging");
	
		// Disable future registration until next login
		[self setHasRegistered:YES];
		[self setIsRegistered:YES];
	
		callback(YES, nil);
	
		return;
	#endif
	
	// If user has already registered during the current session, then don't register again
	if (self.hasRegistered)
	{
		callback(YES, nil);
		
		return;
	}
	// Ensure that the phone number is set. This usually only applies when called from AppDelegate's didRegisterForRemoteNotificationsWithDeviceToken:
	else if (! self.PhoneNumber)
	{
		NSLog(@"Phone number not set.");
		
		callback(YES, nil);
		
		return;
	}
	// Ensure that the token is set. Sometimes the login process completes before the token has been set. For this reason, there is always a second call to this method from AppDelegate's didRegisterForRemoteNotificationsWithDeviceToken:
	else if (! self.Token)
	{
		NSLog(@"IMPORTANT: Device does not have a token so it is not being registered with TeleMed. If this persists, make sure that an explicit provisioning profile is being used for MyTeleMed and that its certificate has Push Notifications enabled.");
		
		[self setHasSkippedRegistration:YES];
		
		callback(YES, nil);
		
		return;
	}
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<RegisteredDevice xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/" XMLNS @".Models\">"
			"<AppVersionInfo>%@</AppVersionInfo>"
			"<ID>%@</ID>"
			"<PhoneNumber>%@</PhoneNumber>"
			"<PlatformID>iOS</PlatformID>"
			"<Token>%@</Token>"
		"</RegisteredDevice>",
		
		self.AppVersionInfo,
		self.ID,
		self.PhoneNumber,
		self.Token
	];
	
	NSLog(@"XML Body: %@", xmlBody);
		
	[self.operationManager POST:@"RegisteredDevices" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Successful post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			// Disable future registration until next login
			[self setIsRegistered:YES];
			[self setHasRegistered:YES];
			
			callback(YES, nil);
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Device Registration Error", NSLocalizedFailureReasonErrorKey, @"There was a problem registering your Device.", NSLocalizedDescriptionKey, nil]];
			
			callback(NO, error);
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"RegisteredDeviceModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem registering your Device." andTitle:@"Device Registration Error"];
		
		callback(NO, error);
	}];
}

- (void)setCurrentDevice:(RegisteredDeviceModel *)registeredDevice
{
	if (! registeredDevice)
	{
		return;
	}
	
	// Set current device phone number (ID, AppVersionInfo, and Platform ID are generated locally on the device; Token should only be set by Apple's notifications service)
	[self setPhoneNumber:registeredDevice.PhoneNumber];
	
	// Device is registered
	[self setIsRegistered:YES];
}

@end
