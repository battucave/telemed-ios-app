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

@implementation NotificationSettingModel

// Notification Options
+ (NSArray *)classicTones
{
    return @[@"Alarm", @"Anticipate", @"Bell", @"Bloom", @"Calypso", @"Chime", @"Choo Choo", @"Descent", @"Electronic", @"Fanfare", @"Glass", @"Horn", @"Ladder", @"Minuet", @"News Flash", @"Noir", @"Sherwood Forest", @"Spell", @"Suspense", @"Telegraph", @"Tiptoes", @"Tri-tone", @"Typewriters", @"Update"];
}

+ (NSString *)defaultTone
{
    return @"alert.caf";
}

+ (NSArray *)intervals
{
    return @[@"1 minute", @"5 minutes", @"10 minutes", @"15 minutes", @"20 minutes"];
}

+ (NSArray *)myTeleMedTones
{
    return @[@"Alert", @"Chirp", @"Low", @"Notice", @"Quantum", @"Sonar"];
}

+ (NSArray *)staffFavoriteTones
{
    return @[@"Ascending", @"Digital Alarm 1", @"Digital Alarm 2", @"Irritating", @"Nuclear", @"Sci-Fi", @"Sonic Reverb", @"Warning"];
}

+ (NSArray *)standardTones
{
    return @[@"Aurora", @"Bamboo", @"Chord", @"Circles", @"Complete", @"Hello", @"Input", @"Keys", @"Note", @"Popcorn", @"Pulse", @"Synth"];
}

+ (NSArray *)subCategoryTones
{
    return @[@"Staff Favorites", @"MyTeleMed", @"Standard", @"Classic"];
}

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

- (NotificationSettingModel *)getNotificationSettingsForName:(NSString *)name
{
	NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
	NSString *notificationKey = [NSString stringWithFormat:@"%@Settings", name];
	NotificationSettingModel *notificationSettings;
	
	// Load notification settings from device
	if ([settings objectForKey:notificationKey] != nil)
	{
		// Use this class for unarchiving settings saved with the old version of this class (slighly different name)
		[NSKeyedUnarchiver setClass:self.class forClassName:@"NotificationSettingsModel"];
		
		// Unarchive the notification settings
		notificationSettings = (NotificationSettingModel *)[NSKeyedUnarchiver unarchiveObjectWithData:[settings objectForKey:notificationKey]];
	}
	
	// If notification settings for type not found on device, then set default values
	// Note: Initialize method should always run on app startup, thus preventing these settings from ever being nil
	if (notificationSettings == nil || notificationSettings.Tone == nil)
	{
		notificationSettings = [[NotificationSettingModel alloc] init];

		notificationSettings.Enabled = YES;
		notificationSettings.Interval = [NSNumber numberWithInt:(int)[[NotificationSettingModel.intervals objectAtIndex:0] integerValue]];
		notificationSettings.isReminderOn = YES;
		
		// Default to system's alert sound (this is the server's initial value)
		notificationSettings.ToneTitle = @"Default"; // Setter also automatically sets Tone
	}
	
	return notificationSettings;
}

- (void)getServerNotificationSettings:(void (^)(BOOL success, NSArray *allNotificationSettings, NSError *error))callback
{
	[self.operationManager GET:@"NotificationSettings" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		NotificationSettingXMLParser *parser = [[NotificationSettingXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			NSArray *allNotificationSettings = [parser.notificationSettings copy];
			
			for (NotificationSettingModel *notificationSettings in allNotificationSettings)
			{
				// Set isReminderOn since it is not passed from web service
				notificationSettings.isReminderOn = (notificationSettings.Interval.integerValue > 0);
				
				// Prevent interval of 0 on device (interval of 0 is used by server to denote that reminders are off)
				if (notificationSettings.Interval != nil && notificationSettings.Interval.integerValue == 0)
				{
					// Default interval to 1
					notificationSettings.Interval = @1;
				}
			}
			
			// Handle success via callback
			callback(YES, allNotificationSettings, nil);
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Notification Settings Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Notification Settings.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via callback
			callback(NO, nil, error);
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"NotificationSettingModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Notification Settings." andTitle:@"Notification Settings Error"];
		
		// Handle error via callback
		callback(NO, nil, error);
	}];
}

- (void)getServerNotificationSettingsForName:(NSString *)name withCallback:(void (^)(BOOL success, NotificationSettingModel *notificationSettings, NSError *error))callback
{
	NSDictionary *parameters = @{
		@"setting"	: ([name isEqualToString:@"priority"] ? @"prio" : name).uppercaseString
	};
	
	[self.operationManager GET:@"NotificationSettings" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		NotificationSettingXMLParser *parser = [[NotificationSettingXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			NotificationSettingModel *notificationSettings = [[parser.notificationSettings copy] objectAtIndex:0];
			
			// Set isReminderOn
			notificationSettings.isReminderOn = (notificationSettings.Interval.integerValue > 0);
			
			// Prevent interval of 0 on device (interval of 0 is used by server to denote that reminders are off)
			if (notificationSettings.Interval != nil && notificationSettings.Interval.integerValue == 0)
			{
				// Default interval to 1
				notificationSettings.Interval = @1;
			}
			
			// Handle success via callback
			callback(YES, notificationSettings, nil);
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Notification Settings Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Notification Settings.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via callback
			callback(NO, nil, error);
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"NotificationSettingModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Notification Settings." andTitle:@"Notification Settings Error"];
		
		// Handle error via callback
		callback(NO, nil, error);
	}];
}

- (void)initialize
{
    NotificationSettingModel *chatMessageNotificationSettings = [self getNotificationSettingsForName:@"chat"];
	NotificationSettingModel *commentNotificationSettings = [self getNotificationSettingsForName:@"comment"];
	NotificationSettingModel *normalMessageNotificationSettings = [self getNotificationSettingsForName:@"normal"];
	NotificationSettingModel *statMessageNotificationSettings = [self getNotificationSettingsForName:@"stat"];
	
	// If any of the notification settings aren't saved on the device, then check if user has any settings saved on the server
	if ([chatMessageNotificationSettings.ToneTitle isEqualToString:@"Default"] ||
		[commentNotificationSettings.ToneTitle isEqualToString:@"Default"] ||
		[normalMessageNotificationSettings.ToneTitle isEqualToString:@"Default"] ||
		[statMessageNotificationSettings.ToneTitle isEqualToString:@"Default"])
	{
		[self getServerNotificationSettings:^(BOOL success, NSArray *allNotificationSettings, NSError *error)
		{
			if (success)
			{
				BOOL isChatIncluded = NO;
				NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
				
				void (^saveNotificationSettings)(NotificationSettingModel *notificationSettings) = ^void(NotificationSettingModel *notificationSettings)
				{
					NSString *name = notificationSettings.Name.lowercaseString;
					
					// Replace the default tone from server ("default") with a unique MyTeleMed tone
					if (notificationSettings.Tone == nil ||
						[notificationSettings.Tone isEqualToString:@""] ||
						[notificationSettings.Tone hasPrefix:@"default"])
					{
						notificationSettings.ToneTitle = [NotificationSettingModel.myTeleMedTones objectAtIndex:0]; // Setter also automatically sets Tone

						// Save new tone to server and device
						[self saveNotificationSettingsForName:name settings:notificationSettings];
					}
					// Save server settings to device
					else
					{
						NSString *notificationKey = [NSString stringWithFormat:@"%@Settings", name];

						// Set notification settings for type
						[settings setObject:[NSKeyedArchiver archivedDataWithRootObject:notificationSettings] forKey:notificationKey];
					}
				};
				
				for (NotificationSettingModel *notificationSettings in allNotificationSettings)
				{
					// TEMPORARY: Chat is not currently included when fetching all notification settings
					if ([notificationSettings.Name isEqualToString:@"CHAT"])
					{
						isChatIncluded = YES;
					}
					
					// Only verify the 4 notification types used by the app
					if ([@[@"CHAT", @"COMMENT", @"NORMAL", @"STAT"] containsObject:notificationSettings.Name])
					{
						saveNotificationSettings(notificationSettings);
					}
				}
				
				// TEMPORARY: Chat is not currently included when fetching all notification settings so fetch it separately if needed
				if (! isChatIncluded)
				{
					[self getServerNotificationSettingsForName:@"chat" withCallback:^(BOOL success, NotificationSettingModel *notificationSettings, NSError *error)
					{
						if (success)
						{
							saveNotificationSettings(notificationSettings);
						}
						// Don't alert the user of any error since this method runs without user interaction
						else
						{
							NSLog(@"Failed to initialize Chat Notification Settings");
						}
					}];
				}
				
				// Save notification settings to device
				[settings synchronize];
			}
			// Don't alert the user of any error since this method runs without user interaction
			else
			{
				NSLog(@"Failed to initialize Notification Settings");
			}
		}];
	}
}

- (void)saveNotificationSettingsForName:(NSString *)name settings:(NotificationSettingModel *)notificationSettings
{
	// Don't show activity indicator
	
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
		
		(notificationSettings.Enabled ? @"true" : @"false"),
		interval,
		([name isEqualToString:@"priority"] ? @"prio" : name).uppercaseString,
		[notificationSettings.Tone escapeXML]
	];
	
	NSLog(@"XML Body: %@", xmlBody);
		
	[self.operationManager POST:@"NotificationSettings" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Activity indicator already closed in AFNetworkingOperationDidStartNotification: callback
		
		NSString *notificationKey = [NSString stringWithFormat:@"%@Settings", name];
		
		// Successful post returns a 204 code with no response
		if (operation.response.statusCode == 204)
		{
			NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
			
			// Save notification settings for type to device
			[settings setObject:[NSKeyedArchiver archivedDataWithRootObject:notificationSettings] forKey:notificationKey];
			[settings synchronize];
			
			// Priority message notification settings removed in version 3.85. If saving notification settings for normal messages, then also save them for priority messages
			if ([name isEqualToString:@"normal"])
			{
				[self saveNotificationSettingsForName:@"priority" settings:notificationSettings];
			}
			
			// No callback or delegate method is called
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Notification Settings Error", NSLocalizedFailureReasonErrorKey, @"There was a problem saving your Notification Settings.", NSLocalizedDescriptionKey, nil]];
			
			// Show error even if user has navigated to another screen
			[self showError:error withRetryCallback:^
			{
				// Include callback to retry the request
				[self saveNotificationSettingsForName:name settings:notificationSettings];
			}];
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"NotificationSettingModel Error: %@", error);
		
		// Remove network activity observer
		[NSNotificationCenter.defaultCenter removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem saving your Notification Settings." andTitle:@"Notification Settings Error"];
	
		// Show error even if user has navigated to another screen
		[self showError:error withRetryCallback:^
		{
			// Include callback to retry the request
			[self saveNotificationSettingsForName:name settings:notificationSettings];
		}];
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
