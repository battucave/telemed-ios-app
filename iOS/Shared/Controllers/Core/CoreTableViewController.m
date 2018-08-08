//
//  CoreTableViewController.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/9/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <AudioToolbox/AudioServices.h>

#import "CoreTableViewController.h"
#import "CDMAVoiceDataViewController.h"

#ifdef MYTELEMED
	#import "NotificationSettingModel.h"
#endif

@interface CoreTableViewController ()

@property (nonatomic) SystemSoundID systemSoundID;

@end

@implementation CoreTableViewController

// NOTE: All functionality in this file is duplicated in CoreViewController.m

- (void)viewWillAppear:(BOOL)animated
{
	[self showCDMAVoiceDataViewController:nil];
	
	[super viewWillAppear:animated];
	
	// Add application did become active notification observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showCDMAVoiceDataViewController:) name:UIApplicationDidBecomeActiveNotification object:nil];
	
	// MyTeleMed - Add application did receive remote notification observer
	#ifdef MYTELEMED
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveRemoteNotification:) name:@"UIApplicationDidReceiveRemoteNotification" object:nil];
	#endif
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove notification observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
	
	#ifdef MYTELEMED
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationDidReceiveRemoteNotification" object:nil];
	#endif
}

- (void)showCDMAVoiceDataViewController:(NSNotification *)notification
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// Show CDMA Voice Data after LoginSSO storyboard process has resolved if it hasn't already been disabled or hidden
	if (! [[self.storyboard valueForKey:@"name"] isEqualToString:@"LoginSSO"] && ! [settings boolForKey:@"CDMAVoiceDataDisabled"] && ! [settings boolForKey:@"CDMAVoiceDataHidden"])
	{
		CDMAVoiceDataViewController *cdmaVoiceDataViewController = [[CDMAVoiceDataViewController alloc] initWithNibName:@"CDMAVoiceData" bundle:nil];
		
		[self presentViewController:cdmaVoiceDataViewController animated:NO completion:nil];
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
	// Remove notification observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
	
	#ifdef MYTELEMED
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationDidReceiveRemoteNotification" object:nil];
	#endif
}


#pragma mark - MyTeleMed

#ifdef MYTELEMED
- (void)didReceiveRemoteNotification:(NSNotification *)notification
{
	NSDictionary *notificationInfo = notification.object;
	
	NSLog(@"CoreTableViewController Remote Notification: %@", notificationInfo);
	
	if (notificationInfo)
	{
		[self handleRemoteNotificationMessage:[notificationInfo objectForKey:@"message"] ofType:[notificationInfo objectForKey:@"notificationType"] withID:[notificationInfo objectForKey:@"notificationID"] withTone:[notificationInfo objectForKey:@"tone"]];
	}
}

- (void)handleRemoteNotificationMessage:(NSString *)message ofType:(NSString *)notificationType withID:(NSNumber *)notificationID withTone:(NSString *)tone
{
	// Play notification sound
	if (tone != nil)
	{
		// If tone is "default", then use Standard's default tone (there is no way to retrieve system's default alert sound)
		if ([tone isEqualToString:@"default"])
		{
			NotificationSettingModel *notificationSettingModel = [[NotificationSettingModel alloc] init];
			NSArray *tones = [[NSArray alloc] initWithObjects:NOTIFICATION_TONES_STANDARD, nil];
			
			if ([tones count] > 8)
			{
				tone = [notificationSettingModel getToneFromToneTitle:[tones objectAtIndex:8]]; // Default to Note tone
			}
		}
		
		NSString *tonePath = [[NSBundle mainBundle] pathForResource:tone ofType:nil];
	
		if (tonePath != nil)
		{
			AudioServicesDisposeSystemSoundID(self.systemSoundID);
			
			NSURL *toneURL = [NSURL fileURLWithPath:tonePath];
			AudioServicesCreateSystemSoundID((__bridge CFURLRef)toneURL, &_systemSoundID);
			AudioServicesPlaySystemSound(self.systemSoundID);
		}
	}
	
	// Present user with the message from notification
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"MyTeleMed" message:message preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *actionClose = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		// Stop notification sound
		AudioServicesDisposeSystemSoundID(self.systemSoundID);
	}];
	
	[alertController addAction:actionClose];
	
	// PreferredAction only supported in 9.0+
	if ([alertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[alertController setPreferredAction:actionClose];
	}
	
	// Show Alert
	[self presentViewController:alertController animated:YES completion:nil];
}
#endif

@end
