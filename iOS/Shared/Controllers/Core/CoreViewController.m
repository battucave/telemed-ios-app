//
//  CoreViewController.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/9/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <AudioToolbox/AudioServices.h>

#import "CoreViewController.h"
#import "CDMAVoiceDataViewController.h"

#ifdef MYTELEMED
	#import "AppDelegate.h"
	#import "ChatMessageDetailViewController.h"
	#import "MessageDetailViewController.h"
	#import "NotificationSettingModel.h"
#endif

@interface CoreViewController ()

@property (nonatomic) SystemSoundID systemSoundID;

@end

@implementation CoreViewController

// NOTE: All functionality in this file is duplicated in CoreTableViewController.m

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
	
	// Show CDMAVoiceDataViewController after LoginSSO storyboard process has resolved if it hasn't already been shown or disabled
	if (! [[self.storyboard valueForKey:@"name"] isEqualToString:@"LoginSSO"] && ! [settings boolForKey:@"CDMAVoiceDataHidden"] && ([settings boolForKey:@"showSprintVoiceDataWarning"] || [settings boolForKey:@"showVerizonVoiceDataWarning"]))
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
	NSLog(@"CoreViewController Remote Notification Data: %@", notification.object);
	NSLog(@"CoreViewController Remote Notification Extras: %@", notification.userInfo);
	
	UIAlertAction *viewAction;
	NSString *tone = [notification.object objectForKey:@"tone"];
	
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
			
			// Stop notification sound automatically after a short time in case action view erroneously doesn't show up
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
			{
				AudioServicesDisposeSystemSoundID(self.systemSoundID);
			});
		}
	}
	
	// If there is a remote notification screen to navigate to, then create an extra alert action for navigating to the remote notification screen
	if (notification.userInfo && [notification.userInfo objectForKey:@"goToRemoteNotificationScreen"])
	{
		void (^goToRemoteNotificationScreen)(UINavigationController *navigationController) = [notification.userInfo objectForKey:@"goToRemoteNotificationScreen"];
		
		if (goToRemoteNotificationScreen != nil)
		{
			viewAction = [UIAlertAction actionWithTitle:@"View" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
			{
				// Stop notification sound
				AudioServicesDisposeSystemSoundID(self.systemSoundID);
				
				// User has completed the login process
				if ([[self.storyboard valueForKey:@"name"] isEqualToString:@"Main"])
				{
					dispatch_async(dispatch_get_main_queue(), ^{
						goToRemoteNotificationScreen(self.navigationController);
					});
				}
				// User was not logged in so assign the block to a property for the showMainScreen method to handle
				else
				{
					[(AppDelegate *)[[UIApplication sharedApplication] delegate] setGoToRemoteNotificationScreen:goToRemoteNotificationScreen];
				}
			}];
		}
	}
	
	// Execute the handleRemoteNotification method on the current view controller. Some view controllers override the method below to execute additional logic if the notification specifically pertains to it (ChatMessageDetailViewController, MessageDetailViewController)
	[self handleRemoteNotification:((NSDictionary *)notification.object).mutableCopy ofType:[notification.object objectForKey:@"notificationType"] withViewAction:viewAction];
}

- (void)handleRemoteNotification:(NSMutableDictionary *)notificationInfo ofType:(NSString *)notificationType withViewAction:(UIAlertAction *)viewAction
{
	NSString *message = [notificationInfo objectForKey:@"message"];
	
	// Present user with the message from notification
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"MyTeleMed" message:message preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		// Stop notification sound
		AudioServicesDisposeSystemSoundID(self.systemSoundID);
	}];
	
	[alertController addAction:closeAction];
	
	if (viewAction != nil)
	{
		[alertController addAction:viewAction];
	}
	
	// PreferredAction only supported in 9.0+
	if ([alertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[alertController setPreferredAction:(viewAction ?: closeAction)];
	}
	
	// Show Alert
	[self presentViewController:alertController animated:YES completion:nil];
}
#endif

@end
