//
//  UIViewController+NotificationTonesFix.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 7/7/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import "UIViewController+NotificationTonesFix.h"
#import "NotificationSettingModel.h"

@implementation UIViewController (NotificationToneFix)

- (void)verifyNotificationTones
{
	NSLog(@"verifyNotificationTones");
	
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// If Notification Tones have already been fixed, then skip doing it again
	if ([settings boolForKey:@"notificationTonesFixed"])
	{
		return;
	}
	
	// Remove old Notification Tones user default setting
	[settings removeObjectForKey:@"notificationTonesConverted"];
	
	[self verifyNotificationToneForName:@"stat"];
	// [self verifyNotificationToneForName:@"priority"]; // Version 3.85+ saves priority settings with normal settings
	[self verifyNotificationToneForName:@"normal"];
	[self verifyNotificationToneForName:@"comment"];
	
	[settings setBool:TRUE forKey:@"notificationTonesFixed"];
	[settings synchronize];
}

- (void)verifyNotificationToneForName:(NSString *)name
{
	NSLog(@"verifyNotificationToneForName: %@", name);
	
	// Initialize NotificationSettingModel
	NotificationSettingModel *notificationSettings = [[NotificationSettingModel alloc] init];
	
	[notificationSettings setDelegate:self];
	
	// Load Notification Settings for type
	notificationSettings = [notificationSettings getNotificationSettingsByName:name];
	
	if (notificationSettings != nil && notificationSettings.Tone != nil)
	{
		NSLog(@"%@ Tone: %@", [name capitalizedString], notificationSettings.Tone);
	}
	
	// Save Notification Settings with .caf format only if Tone does not contain file extension
	if (notificationSettings != nil && notificationSettings.Tone != nil && ! [notificationSettings.Tone hasSuffix:@".caf"])
	{
		[notificationSettings setTone:[notificationSettings getToneFromToneTitle:notificationSettings.Tone]];
		
		NSLog(@"New %@ Tone: %@", [name capitalizedString], notificationSettings.Tone);
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^
		{
			[notificationSettings saveNotificationSettingsByName:name settings:notificationSettings];
		});
	}
}

// Return Server Notification Settings from NotificationSettingModel delegate
- (void)updateNotificationSettings:(NotificationSettingModel *)serverNotificationSettings forName:(NSString *)name
{
	NSLog(@"Got %@ Notification Settings", [name capitalizedString]);
	NSLog(@"%@ Tone: %@", [name capitalizedString], serverNotificationSettings.Tone);
	
	// Save server notification settings with .caf format only if old MyTeleMed Tone
	if (serverNotificationSettings != nil && serverNotificationSettings.Tone != nil && ! [serverNotificationSettings.Tone hasSuffix:@".caf"])
	{
		[serverNotificationSettings setTone:[NSString stringWithFormat:@"%@.caf", serverNotificationSettings.Tone]];
		
		NSLog(@"New %@ Tone: %@", [name capitalizedString], serverNotificationSettings.Tone);
		
		[serverNotificationSettings saveNotificationSettingsByName:name settings:serverNotificationSettings];
	}
}

// Return error from NotificationSettingModel delegate
- (void)updateNotificationSettingsError:(NSError *)error
{
	NSLog(@"Error loading notification settings");
}

/*/ Return Save success from NotificationSettingModel delegate (no longer used)
- (void)saveNotificationSettingsSuccess
{
	NSLog(@"Fixed Notification Settings saved to server successfully");
}*/

// Return Save error from NotificationSettingsModel delegate (still used)
-(void)saveNotificationSettingsError:(NSError *)error
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	[settings setBool:FALSE forKey:@"notificationTonesFixed"];
	[settings synchronize];
}

@end
