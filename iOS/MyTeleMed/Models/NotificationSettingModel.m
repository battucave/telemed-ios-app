//
//  NotificationSettingModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "NotificationSettingModel.h"
#import "NotificationSettingXMLParser.h"
#import "NSString+XML.h"

@interface NotificationSettingModel ()

@property BOOL pendingComplete;

@end

@implementation NotificationSettingModel

// Override Tone setter to also store tone title (user friendly tone)
- (void)setTone:(NSString *)newTone
{
	_Tone = newTone;
	_ToneTitle = [[[newTone stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "] capitalizedString];
}

// Override ToneTitle setter to also store tone (filename)
- (void)setToneTitle:(NSString *)newToneTitle
{
	_Tone = [self getToneFromToneTitle:newToneTitle];
	_ToneTitle = newToneTitle;
}

// Public helper method to convert tone title to tone filename
- (NSString *)getToneFromToneTitle:(NSString *)toneTitle
{
	return [NSString stringWithFormat:@"%@.caf", [[toneTitle stringByReplacingOccurrencesOfString:@" " withString:@"_"] lowercaseString]];
}

- (NotificationSettingModel *)getNotificationSettingsByName:(NSString *)name
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	NSString *notificationKey = [NSString stringWithFormat:@"%@Settings", name];
	NotificationSettingModel *notificationSettings;
	
	// Load notification settings from device
	if ([settings objectForKey:notificationKey] != nil)
	{
		// In MyTeleMed versions 3.0 - 3.2, the notification settings were archived using a different class. Use this class as a substitute when unarchiving the object
		[NSKeyedUnarchiver setClass:self.class forClassName:@"NotificationSettingsModel"];
		
		// Unarchive the notification settings
		notificationSettings = (NotificationSettingModel *)[NSKeyedUnarchiver unarchiveObjectWithData:[settings objectForKey:notificationKey]];
	}
	
	// If notification settings for type not found on device, check server for previously saved notification settings
	if (notificationSettings == nil || notificationSettings.Tone == nil)
	{
		// Check server for previously saved notification settings
		[self getServerNotificationSettingsByName:name];
		
		// Return default notification settings
		NSArray *intervals = [[NSArray alloc] initWithObjects:NOTIFICATION_INTERVALS, nil];
		
		notificationSettings = [[NotificationSettingModel alloc] init];
		
		[notificationSettings setEnabled:YES];
		[notificationSettings setIsReminderOn:YES];
		
		[notificationSettings setToneTitle:@"default"]; // Default to system's alert sound (this is also returned from TeleMed server on first load)
		
		// Intervals should always exist
		if ([intervals count] > 0)
		{
			[notificationSettings setInterval:[NSNumber numberWithInt:(int)[[intervals objectAtIndex:0] integerValue]]];
		}
	}
	
	return notificationSettings;
}

// Not currently used (only here to provide a method for viewing all notification settings)
- (void)getServerNotificationSettings
{
	[self.operationManager GET:@"NotificationSettings" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSLog(@"Got notification settings - see log");
		
		// View results in debug log. Make sure AFNetworkActivityLogger is enabled in TeleMedHTTPRequestOperationManager.m
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"NotificationSettingModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the notification settings." andTitle:@"notification settings Error"];
		
		// Handle error via delegate
		if (self.delegate && [self.delegate respondsToSelector:@selector(updateNotificationSettingsError:)])
		{
			[self.delegate updateNotificationSettingsError:error];
		}
	}];
}

- (void)getServerNotificationSettingsByName:(NSString *)name
{
	NSDictionary *parameters = @{
		@"setting"	: [([name isEqualToString:@"priority"] ? @"prio" : name) uppercaseString]
	};
	
	[self.operationManager GET:@"NotificationSettings" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		NSString *notificationKey = [NSString stringWithFormat:@"%@Settings", name];
		NotificationSettingXMLParser *parser = [[NotificationSettingXMLParser alloc] init];
		
		[parser setNotificationSetting:self];
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
			
			// Set isReminderOn
			[self setIsReminderOn:([self.Interval integerValue] > 0)];
			
			// Prevent interval of 0 on device (interval of 0 is used by server to denote that reminders are off)
			if (self.Interval != nil && [self.Interval integerValue] == 0)
			{
				// Default interval to 1
				self.Interval = [NSNumber numberWithInt:1];
			}
			
			// DEPRECATED: If the tone received from server is default, change it to the iOS default: "Note"
			/* if ([self.Tone isEqualToString:@"Default"])
			{
				NSArray *tones = [[NSArray alloc] initWithObjects:NOTIFICATION_TONES_STANDARD, nil];
				
				// Tones should always exist
				if ([tones count] > 8)
				{
					[self setTone:[tones objectAtIndex:8]]; // iOS 7+ Defaults to Note tone
				}
				
				// Save new default to server
				[self saveNotificationSettingsByName:name settings:self];
			}*/
			
			// Save notification settings for type to device
			[settings setObject:[NSKeyedArchiver archivedDataWithRootObject:self] forKey:notificationKey];
			[settings synchronize];
			
			// Handle success via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(updateNotificationSettings:forName:)])
			{
				[self.delegate updateNotificationSettings:self forName:name];
			}
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"notification settings Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the notification settings.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(updateNotificationSettingsError:)])
			{
				[self.delegate updateNotificationSettingsError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"NotificationSettingModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the notification settings." andTitle:@"notification settings Error"];
		
		// Handle error via delegate
		if (self.delegate && [self.delegate respondsToSelector:@selector(updateNotificationSettingsError:)])
		{
			[self.delegate updateNotificationSettingsError:error];
		}
	}];
}

- (void)saveNotificationSettingsByName:(NSString *)name settings:(NotificationSettingModel *)notificationSettings
{
	// Show activity indicator
	[self showActivityIndicator];
	
	// Add network activity observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Create interval value (chat and comment settings do not include interval)
	NSString *interval;
	
	if ([name isEqualToString:@"chat"] || [name isEqualToString:@"comment"] || notificationSettings.Interval == nil)
	{
		interval = @"<Interval i:nil=\"true\" />";
	}
	else
	{
		interval = [NSString stringWithFormat:@"<Interval>%@</Interval>", (notificationSettings.isReminderOn ? notificationSettings.Interval : @"0")];
	}
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<NotificationSetting xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/" XMLNS @".Models\">"
			"<Enabled>%@</Enabled>"
			"%@"
			"<Name>%@</Name>"
			"<Tone>%@</Tone>"
		"</NotificationSetting>",
		(notificationSettings.Enabled ? @"true" : @"false"), interval, [([name isEqualToString:@"priority"] ? @"prio" : name) uppercaseString], [notificationSettings.Tone escapeXML]];
	
	NSLog(@"XML Body: %@", xmlBody);
		
	[self.operationManager POST:@"NotificationSettings" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Activity indicator already closed in AFNetworkingOperationDidStartNotification: callback
		
		NSString *notificationKey = [NSString stringWithFormat:@"%@Settings", name];
		
		// Successful post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
			
			// Save notification settings for type to device
			[settings setObject:[NSKeyedArchiver archivedDataWithRootObject:notificationSettings] forKey:notificationKey];
			[settings synchronize];
			
			// Priority message notification settings removed in version 3.85. If saving notification settings for normal messages, then also save them for priority messages
			if ([name isEqualToString:@"normal"])
			{
				[self saveNotificationSettingsByName:@"priority" settings:notificationSettings];
			}
			// Handle success via delegate (not currently used)
			else if (self.delegate && [self.delegate respondsToSelector:@selector(saveNotificationSettingsSuccess)])
			{
				[self.delegate saveNotificationSettingsSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"notification settings Error", NSLocalizedFailureReasonErrorKey, @"There was a problem saving your notification settings.", NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self saveNotificationSettingsByName:name settings:notificationSettings];
			}];
			
			// Handle error via delegate (temporarily handle additional logic in UIViewController+NotificationTonesFix.m)
			if (self.delegate && [self.delegate respondsToSelector:@selector(saveNotificationSettingsError:)])
			{
				[self.delegate saveNotificationSettingsError:error];
			}
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"NotificationSettingModel Error: %@", error);
		
		// Remove network activity observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem saving your notification settings." andTitle:@"notification settings Error"];
		
		// Close activity indicator with callback (in case networkRequestDidStart was not triggered)
		[self hideActivityIndicator:^
		{
			// Handle error via delegate (temporarily handle additional logic in UIViewController+NotificationTonesFix.m)
			if (self.delegate && [self.delegate respondsToSelector:@selector(saveNotificationSettingsError:)])
			{
				[self.delegate saveNotificationSettingsError:error];
			}
		
			// Show error even if user has navigated to another screen
			[self showError:error withCallback:^
			{
				// Include callback to retry the request
				[self saveNotificationSettingsByName:name settings:notificationSettings];
			}];
		}];
	}];
}

// Network request has been sent, but still awaiting response
- (void)networkRequestDidStart:(NSNotification *)notification
{
	// Remove network activity observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
	
	// Close activity indicator with callback
	[self hideActivityIndicator:^
	{
		// Notify delegate that notification settings has been sent to server
		if (! self.pendingComplete && self.delegate && [self.delegate respondsToSelector:@selector(saveNotificationSettingsPending)])
		{
			[self.delegate saveNotificationSettingsPending];
		}
		
		// Ensure that pending callback doesn't fire again after possible error
		self.pendingComplete = YES;
	}];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	// Encode properties, other class variables, etc
	[encoder encodeBool:self.Enabled forKey:@"Enabled"];
	[encoder encodeBool:self.isReminderOn  forKey:@"isReminderOn"];
	[encoder encodeObject:self.Tone forKey:@"Tone"];
	[encoder encodeObject:self.Interval forKey:@"Interval"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super init]))
	{
		// Decode properties, other class vars
		self.Enabled = [decoder decodeBoolForKey:@"Enabled"];
		self.isReminderOn = [decoder decodeBoolForKey:@"isReminderOn"];
		self.Tone = [decoder decodeObjectForKey:@"Tone"];
		self.Interval = [decoder decodeObjectForKey:@"Interval"];

	}
	
	return self;
}

@end
