//
//  NotificationSettingModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "NotificationSettingModel.h"
#import "NotificationSettingXMLParser.h"

@implementation NotificationSettingModel

// Override Tone setter to also store Tone Title (user friendly tone)
- (void)setTone:(NSString *)newTone
{
	_Tone = newTone;
	_ToneTitle = [[[newTone stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "] capitalizedString];
}

// Override ToneTitle setter to also store Tone (filename)
- (void)setToneTitle:(NSString *)newToneTitle
{
	_Tone = [self getToneFromToneTitle:newToneTitle];
	_ToneTitle = newToneTitle;
}

// Public helper method to convert Tone Title to Tone filename
- (NSString *)getToneFromToneTitle:(NSString *)toneTitle
{
	return [NSString stringWithFormat:@"%@.caf", [[toneTitle stringByReplacingOccurrencesOfString:@" " withString:@"_"] lowercaseString]];
}

- (NotificationSettingModel *)getNotificationSettingsByName:(NSString *)name
{
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSString *notificationKey = [NSString stringWithFormat:@"%@Settings", name];
	NotificationSettingModel *settings;
	
	// Load Notification Settings from device
	if([preferences objectForKey:notificationKey] != nil)
	{
		// In MyTeleMed versions 3.0 - 3.2, the Notification Settings were archived using a different class. Use this class as a substitute when unarchiving the object
		[NSKeyedUnarchiver setClass:self.class forClassName:@"NotificationSettingsModel"];
		
		// Unarchive the Notification Settings
		settings = (NotificationSettingModel *)[NSKeyedUnarchiver unarchiveObjectWithData:[preferences objectForKey:notificationKey]];
	}
	
	// If Notification Settings for type not found on device, check server for previously saved Notification Settings
	if(settings == nil || settings.Tone == nil)
	{
		// Check server for previously saved Notification Settings
		[self getServerNotificationSettingsByName:name];
		
		// Return default settings
		NSArray *tones = [[NSArray alloc] initWithObjects:NOTIFICATION_TONES_IOS7, nil];
		NSArray *intervals = [[NSArray alloc] initWithObjects:NOTIFICATION_INTERVALS, nil];
		
		settings = [[NotificationSettingModel alloc] init];
		
		[settings setEnabled:YES];
		[settings setIsReminderOn:YES];
		
		// Tones should always exist
		if([tones count] > 8)
		{
			[settings setToneTitle:[tones objectAtIndex:8]]; // iOS7 Defaults to Note tone
		}
		
		// Intervals should always exist
		if([intervals count] > 0)
		{
			[settings setInterval:[NSNumber numberWithInt:(int)[[intervals objectAtIndex:0] integerValue]]];
		}
	}
	
	return settings;
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
		
		// Parse the XML file
		if([xmlParser parse])
		{
			NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
			
			// Set isReminderOn
			[self setIsReminderOn:([self.Interval integerValue] > 0)];
			
			// Prevent Interval of 0 on device (Interval of 0 is used by server to denote that reminders are off. Interval can be null however for Comment type)
			if(self.Interval != nil && [self.Interval integerValue] == 0)
			{
				// Default Interval to 1
				self.Interval = [NSNumber numberWithInt:1];
			}
			
			// If the tone received from server is Default, change it to the iOS default: "Note"
			if([self.Tone isEqualToString:@"Default"])
			{
				NSArray *tones = [[NSArray alloc] initWithObjects:NOTIFICATION_TONES_IOS7, nil];
				
				// Tones should always exist
				if([tones count] > 8)
				{
					[self setTone:[tones objectAtIndex:8]]; // iOS7 Defaults to Note tone
				}
				
				// Save new default to server
				[self saveNotificationSettingsByName:name settings:self];
			}
			
			// Save Notification Settings for type to device
			[preferences setObject:[NSKeyedArchiver archivedDataWithRootObject:self] forKey:notificationKey];
			[preferences synchronize];
			
			if([self.delegate respondsToSelector:@selector(updateNotificationSettings:forName:)])
			{
				[self.delegate updateNotificationSettings:self forName:name];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Error parsing Notification Settings.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(updateNotificationSettingsError:)])
			{
				[self.delegate updateNotificationSettingsError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"NotificationSettingModel Error: %@", error);
		
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Notification Settings."];
		
		if([self.delegate respondsToSelector:@selector(updateNotificationSettingsError:)])
		{
			[self.delegate updateNotificationSettingsError:error];
		}
	}];
}

- (void)saveNotificationSettingsByName:(NSString *)name settings:(NotificationSettingModel *)settings
{
	[self showActivityIndicator:@"Saving..."];
	
	// Create Interval value (Comment setting does not include Interval)
	NSString *interval = ([name isEqualToString:@"comment"] ? @"<Interval i:nil=\"true\" />" : [NSString stringWithFormat:@"<Interval>%@</Interval>", (settings.isReminderOn ? settings.Interval : @"0")]);
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<NotificationSetting xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/MyTmd.Models\">"
			"<Enabled>%@</Enabled>"
			"%@"
			"<Name>%@</Name>"
			"<Tone>%@</Tone>"
		"</NotificationSetting>",
		(settings.Enabled ? @"true" : @"false"), interval, [([name isEqualToString:@"priority"] ? @"prio" : name) uppercaseString], settings.Tone];
	
	NSLog(@"XML Body: %@", xmlBody);
		
	[self.operationManager POST:@"NotificationSettings" parameters:nil constructingBodyWithXML:xmlBody success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		NSString *notificationKey = [NSString stringWithFormat:@"%@Settings", name];
		
		// Successful Post returns a 204 code with no response
		if(operation.response.statusCode == 204)
		{
			NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
			
			// Save Notification Settings for type to device
			[preferences setObject:[NSKeyedArchiver archivedDataWithRootObject:settings] forKey:notificationKey];
			[preferences synchronize];
			
			NSLog(@"Saved %@ Tone: %@", [name capitalizedString], settings.Tone);
			
			if([self.delegate respondsToSelector:@selector(saveNotificationSettingsSuccess)])
			{
				[self.delegate saveNotificationSettingsSuccess];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"There was a problem saving your Notification Settings.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(saveNotificationSettingsError:)])
			{
				[self.delegate saveNotificationSettingsError:error];
			}
		}
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"NotificationSettingModel Error: %@", error);
		
		// Close Activity Indicator
		[self hideActivityIndicator];
		
		// IMPORTANT: revisit this when TeleMed fixes the error response to parse that response for error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem saving your Notification Settings."];
		
		if([self.delegate respondsToSelector:@selector(saveNotificationSettingsError:)])
		{
			[self.delegate saveNotificationSettingsError:error];
		}
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
	if((self = [super init]))
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
