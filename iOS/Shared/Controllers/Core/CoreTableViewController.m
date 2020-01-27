//
//  CoreTableViewController.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/9/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <AudioToolbox/AudioServices.h>
#import <UserNotifications/UserNotifications.h>

#import "CoreTableViewController.h"
#import "CDMAVoiceDataViewController.h"

#ifdef MYTELEMED
	#import "AppDelegate.h"
	#import "ChatMessageDetailViewController.h"
	#import "ErrorAlertController.h"
	#import "MessageDetailViewController.h"
	#import "NotificationSettingModel.h"
	#import "RegisteredDeviceModel.h"
#endif

@interface CoreTableViewController ()

@property (weak, nonatomic) IBOutlet UIView *viewMessageCalloutIOS10; // Remove when iOS 10 support is dropped

@property (nonatomic) NSString *remoteNotificationAuthorizationMessage;
@property (nonatomic) BOOL shouldAuthorizeRemoteNotifications;
@property (nonatomic) SystemSoundID systemSoundID;

@end

@implementation CoreTableViewController

// NOTE: All functionality in this file is duplicated in CoreViewController.m

- (void)viewWillAppear:(BOOL)animated
{
	[self showCDMAVoiceDataViewController];
	
	[super viewWillAppear:animated];
	
	// Add application did become active notification observer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	
	#ifdef MYTELEMED
		// Add application did receive remote notification observer
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveRemoteNotification:) name:NOTIFICATION_APPLICATION_DID_RECEIVE_REMOTE_NOTIFICATION object:nil];
	
		// Additional observers are added in registerForRemoteNotifications:
	#endif
	
	// iOS 11+ - When iOS 10 support is dropped, update storyboard to set this color directly (instead of custom color) and remove this logic
	if (@available(iOS 11.0, *))
	{
		[self.viewMessageCalloutIOS10 setBackgroundColor:[UIColor colorNamed:@"messageCalloutBackgroundColor"]];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove notification observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
	
	#ifdef MYTELEMED
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_APPLICATION_DID_RECEIVE_REMOTE_NOTIFICATION object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_APPLICATION_DID_REGISTER_FOR_REMOTE_NOTIFICATIONS object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_APPLICATION_DID_FAIL_TO_REGISTER_FOR_REMOTE_NOTIFICATIONS object:nil];
	#endif
}

- (void)showCDMAVoiceDataViewController
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// Show CDMAVoiceDataViewController after LoginSSO storyboard process has resolved if it hasn't already been shown or disabled
	if (! [[self.storyboard valueForKey:@"name"] isEqualToString:@"LoginSSO"] && ! [settings boolForKey:CDMA_VOICE_DATA_HIDDEN] && ([settings boolForKey:SHOW_SPRINT_VOICE_DATA_WARNING] || [settings boolForKey:SHOW_VERIZON_VOICE_DATA_WARNING]))
	{
		CDMAVoiceDataViewController *cdmaVoiceDataViewController = [[CDMAVoiceDataViewController alloc] initWithNibName:@"CDMAVoiceData" bundle:nil];
		
		[self presentViewController:cdmaVoiceDataViewController animated:NO completion:nil];
	}
}

- (void)viewDidBecomeActive:(NSNotification *)notification
{
	[self showCDMAVoiceDataViewController];
	
	#ifdef MYTELEMED
		// Update remote notifications enabled status in case user just came back from authorizing them in Settings app
		RegisteredDeviceModel *registeredDevice = [RegisteredDeviceModel sharedInstance];
	
		if ([registeredDevice isRegistered])
		{
			UNUserNotificationCenter *userNotificationCenter = [UNUserNotificationCenter currentNotificationCenter];

			[userNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings)
			{
				dispatch_async(dispatch_get_main_queue(), ^
				{
					[self didChangeRemoteNotificationAuthorization:settings.authorizationStatus == UNAuthorizationStatusAuthorized];
				});
			}];
		}
	#endif
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
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_APPLICATION_DID_RECEIVE_REMOTE_NOTIFICATION object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_APPLICATION_DID_REGISTER_FOR_REMOTE_NOTIFICATIONS object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_APPLICATION_DID_FAIL_TO_REGISTER_FOR_REMOTE_NOTIFICATIONS object:nil];
	#endif
}


#pragma mark - MyTeleMed

#ifdef MYTELEMED
- (void)authorizeForRemoteNotifications
{
	[self authorizeForRemoteNotifications:nil];
}

// Register and authorize for remote notifications
- (void)authorizeForRemoteNotifications:(NSString *)authorizationMessage
{
	// Set authorization message
	if (authorizationMessage != nil)
	{
		[self setRemoteNotificationAuthorizationMessage:authorizationMessage];
	}
	// Set default authorization message
	else if (self.remoteNotificationAuthorizationMessage == nil)
	{
		[self setRemoteNotificationAuthorizationMessage:@"Your device is not registered for notifications. To enable them:"];
	}
	
	RegisteredDeviceModel *registeredDevice = [RegisteredDeviceModel sharedInstance];
	
	// If device is already registered with TeleMed, then prompt user to authorize remote notifications
	if ([registeredDevice isRegistered])
	{
		[self showNotificationAuthorization];
	}
	// If device is not registered with TeleMed, then prompt user to register for remote notifications
	else
	{
		// After device is registered, also prompt user to authorize remote notifications
		[self setShouldAuthorizeRemoteNotifications:YES];
		
		[self registerForRemoteNotifications];
	}
}

- (void)didChangeRemoteNotificationAuthorization:(BOOL)isEnabled
{
	NSLog(@"Remote notification authorization did change to %@. Override didChangeRemoteNotificationAuthorization: in the view controller to provide custom functionality.", (isEnabled ? @"enabled" : @"disabled"));
}

- (void)didFailToRegisterForRemoteNotifications:(NSNotification *)notification
{
	NSLog(@"Did Fail To Register for Remote Notifications Extras: %@", notification.userInfo);
	
	NSString *errorMessage = @"There was a problem registering your device. Please ensure that the phone number already exists in your account.";
	
	if ([notification.userInfo objectForKey:@"error"])
	{
		NSError *originalError = ((NSError *)[notification.userInfo objectForKey:@"error"]);
		
		errorMessage = [originalError.localizedDescription stringByAppendingString:@" Please ensure that the phone number already exists in your account."];
	}
	
	NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Device Registration Error", NSLocalizedFailureReasonErrorKey, errorMessage, NSLocalizedDescriptionKey, nil]];
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		// Dismiss activity indicator with callback
		[self dismissViewControllerAnimated:NO completion:^
		{
			// Update remote notification authorization status
			[self didChangeRemoteNotificationAuthorization:NO];
			
			ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
			
			[errorAlertController show:error withRetryCallback:^
			{
				// Re-prompt user to enable remote notifications
				[self showNotificationRegistration];
			}];
		}];
	});
}

- (void)didReceiveRemoteNotification:(NSNotification *)notification
{
	NSLog(@"CoreTableViewController Remote Notification Data: %@", notification.object);
	NSLog(@"CoreTableViewController Remote Notification Extras: %@", notification.userInfo);
	
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
				// User was not logged in so assign the block to a property for AppDelegate's goToNextScreen: to handle
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

- (void)didRegisterForRemoteNotifications:(NSNotification *)notification
{
	NSLog(@"Did Register for Remote Notifications Extras: %@", notification.userInfo);
	
	UNUserNotificationCenter *userNotificationCenter = [UNUserNotificationCenter currentNotificationCenter];
	
	[userNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			// Dismiss activity indicator with callback
			[self dismissViewControllerAnimated:NO completion:^
			{
				// Update remote notification authorization status
				[self didChangeRemoteNotificationAuthorization:settings.authorizationStatus == UNAuthorizationStatusAuthorized];
				
				// If authorizing remote notifications and user has not yet authorized, then prompt user to authorize them
				if (self.shouldAuthorizeRemoteNotifications)
				{
					if (settings.authorizationStatus != UNAuthorizationStatusAuthorized)
					{
						[self showNotificationAuthorization];
					}
					
					// Reset the shouldAuthorizeRemoteNotifications flag
					[self setShouldAuthorizeRemoteNotifications:NO];
				}
			}];
		});
	}];
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
	
	// Set preferred action
	[alertController setPreferredAction:(viewAction ?: closeAction)];
	
	// Show Alert
	[self presentViewController:alertController animated:YES completion:nil];
}

// Register for remote notifications (don't authorize)
- (void)registerForRemoteNotifications
{
	// Remove any existing remote notification registration observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_APPLICATION_DID_REGISTER_FOR_REMOTE_NOTIFICATIONS object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_APPLICATION_DID_FAIL_TO_REGISTER_FOR_REMOTE_NOTIFICATIONS object:nil];

	// Add remote notification registration observers to detect if user has registered for remote notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRegisterForRemoteNotifications:) name:NOTIFICATION_APPLICATION_DID_REGISTER_FOR_REMOTE_NOTIFICATIONS object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailToRegisterForRemoteNotifications:) name:NOTIFICATION_APPLICATION_DID_FAIL_TO_REGISTER_FOR_REMOTE_NOTIFICATIONS object:nil];

	[self showNotificationRegistration];
}

- (void)showNotificationAuthorization
{
	UIAlertController *allowNotificationsAlertController = [UIAlertController alertControllerWithTitle:@"Enable Notifications" message:[NSString stringWithFormat:@"%@\n\n1) Press the Settings button below\n2) Tap Notifications\n3) Turn on 'Allow Notifications'", self.remoteNotificationAuthorizationMessage] preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
	{
		// Update remote notification authorization status
		[self didChangeRemoteNotificationAuthorization:NO];
	}];
	UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		// Simulator cannot enable notifications so emulate successful authorization
		#if TARGET_IPHONE_SIMULATOR
  			[self didChangeRemoteNotificationAuthorization:YES];

  		// Open settings app for user to enable notifications
  		#else
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        #endif
		
		// Note: The next step will be callback to viewDidBecomeActive: when user returns from the Settings app
	}];

	[allowNotificationsAlertController addAction:settingsAction];
	[allowNotificationsAlertController addAction:cancelAction];

	// PreferredAction only supported in 9.0+
	if ([allowNotificationsAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[allowNotificationsAlertController setPreferredAction:settingsAction];
	}

	// Show alert
	[self presentViewController:allowNotificationsAlertController animated:YES completion:nil];
}

- (void)showNotificationRegistration
{
	RegisteredDeviceModel *registeredDevice = [RegisteredDeviceModel sharedInstance];
	UIAlertController *registerDeviceAlertController = [UIAlertController alertControllerWithTitle:@"Register Device" message:@"Please enter the phone number you would like to use for notifications on this device. Your TeleMed profile will be updated." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
	{
		// Update remote notification authorization status
		[self didChangeRemoteNotificationAuthorization:NO];
	}];
	UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		NSString *phoneNumber = [[registerDeviceAlertController textFields][0] text];
		
		// Validate phone number
		if (phoneNumber.length < 9 || phoneNumber.length > 18 || [phoneNumber isEqualToString:@"0000000000"] || [phoneNumber isEqualToString:@"000-000-0000"])
		{
			UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:@"" message:@"Please enter a valid Phone Number." preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
			{
				// Re-show phone number dialog
				[self showNotificationRegistration];
			}];
		
			[errorAlertController addAction:okAction];
		
			// Set preferred action
			[errorAlertController setPreferredAction:okAction];
		
			// Show alert
			[self presentViewController:errorAlertController animated:YES completion:nil];
		}
		// Register device for remote notifications
		else
		{
			[registeredDevice setPhoneNumber:phoneNumber];
			
			// Show activity indicator
			[registeredDevice showActivityIndicator:@"Registering..."];
			
			// (Re-)Register device for push notifications
			[[UIApplication sharedApplication] registerForRemoteNotifications];
			
			// Note: The next step will be callbacks to either didRegisterForRemoteNotifications: or didFailToRegisterForRemoteNotifications:
		}
	}];

	[registerDeviceAlertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
		[textField setTextContentType:UITextContentTypeTelephoneNumber];
		[textField setKeyboardType:UIKeyboardTypePhonePad];
		[textField setPlaceholder:@"Phone Number"];
		[textField setText:registeredDevice.PhoneNumber];
	}];
	[registerDeviceAlertController addAction:continueAction];
	[registerDeviceAlertController addAction:cancelAction];

	// PreferredAction only supported in 9.0+
	if ([registerDeviceAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		// [registerDeviceAlertController setPreferredAction:continueAction];
	}

	// Show alert
	[self presentViewController:registerDeviceAlertController animated:YES completion:nil];
}
#endif

@end
