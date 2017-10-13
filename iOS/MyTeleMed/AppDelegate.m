//
//  AppDelegate.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "AppDelegate.h"
#import "ELCUIApplication.h"
#import "ErrorAlertController.h"
#import "TeleMedHTTPRequestOperationManager.h"
#import "AuthenticationModel.h"
#import "MyProfileModel.h"
#import "MyStatusModel.h"
#import "RegisteredDeviceModel.h"
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

@interface AppDelegate()

@property (nonatomic) CTCallCenter *callCenter;

@end

@implementation AppDelegate

@synthesize window = _window;


#pragma mark - Application Delegate Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// Push Services - Let the device know we want to receive Push Notifications
	if([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
	{
		// iOS 8+ Push Notifications
		[application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
		[application registerForRemoteNotifications];
	}
	
	// Setup app Timeout feature
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidTimeout:) name:kApplicationDidTimeoutNotification object:nil];
	
	// Setup screenshot notification feature
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidTakeScreenshot:) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
	
	// Add Reachability observer to defer web services until Reachability has been determined
	__unused TeleMedHTTPRequestOperationManager *operationManager = [TeleMedHTTPRequestOperationManager sharedInstance];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishInitialization:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
	
	#if !TARGET_IPHONE_SIMULATOR && !DEBUG
		// Initialize Carrier
		CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
		CTCarrier *carrier = [networkInfo subscriberCellularProvider];
	
		// AT&T and T-Mobile are guaranteed to support Voice and Data simultaneously, so turn off CDMAVoiceData message by default for them
		if([carrier.carrierName isEqualToString:@"AT&T"] || [carrier.carrierName hasPrefix:@"T-M"])
		{
			[settings setBool:YES forKey:@"CDMAVoiceDataDisabled"];
		}
	#endif
	
	// Initialize CDMAVoiceData settings
	[settings setBool:NO forKey:@"CDMAVoiceDataHidden"];
	
	[settings synchronize];
	
	// Initialize Call Center
	self.callCenter = [[CTCallCenter alloc] init];
	
	[self.callCenter setCallEventHandler:^(CTCall *call)
	{
		if([[call callState] isEqual:CTCallStateDisconnected])
		{
			NSLog(@"Call disconnected");
			
			// Dismiss Error Alert if showing (after phone call has ended, user should not see Data Connection Unavailable error)
			ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
			
			[errorAlertController dismiss];
			
			// Post a notification to other files in the project
			[[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationDidDisconnectCall" object:nil];
			
			// Reset idle timer
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[(ELCUIApplication *)[UIApplication sharedApplication] resetIdleTimer];
			});
		}
	}];
	
	return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	
	// Add view over app to obsure screenshot
	[self toggleScreenshotView:NO];
	
	MyStatusModel *myStatusModel = [MyStatusModel sharedInstance];
	
	// Set Badge Number for App Icon. These values are updated every time user resumes app and opens SideNavigation. Idea is that if user is actively using app, then they will use SideNavigation which will update the unread message count. If they just briefly open the app to check messages, then the app resume will update the unread message count.
	[application setApplicationIconBadgeNumber:[myStatusModel.UnreadMessageCount integerValue]];
	
	// Save current time app was closed (used for showing CDMA screen)
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	[settings setObject:[NSDate date] forKey:@"dateApplicationDidEnterBackground"];
	[settings synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	
	// Remove view over app that was used to obsure screenshot (calling it here speeds up dismissal of screenshot when returning from background)
	[self toggleScreenshotView:YES];
	
	// If more than 15 minutes have passed since app was closed, then reset CDMAVoiceDataHidden value
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	if(fabs([[NSDate date] timeIntervalSinceDate:(NSDate *)[settings objectForKey:@"dateApplicationDidEnterBackground"]]) > 900)
	{
		[settings setBool:NO forKey:@"CDMAVoiceDataHidden"];
		[settings synchronize];
	}
	
	AuthenticationModel *authenticationModel = [AuthenticationModel sharedInstance];
	MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
	
	// Verify Account is  still valid
	[myProfileModel getWithCallback:^(BOOL success, MyProfileModel *profile, NSError *error)
	{
		if(success)
		{
			MyStatusModel *myStatusModel = [MyStatusModel sharedInstance];
			
			// Update My Status Model with updated number of Unread Messages
			[myStatusModel getWithCallback:^(BOOL success, MyStatusModel *profile, NSError *error)
			{
				// No callback needed - Values stored in shared instance automatically
			}];
		}
		else
		{
			NSLog(@"Error %ld: %@", (long)error.code, error.localizedDescription);
			
			// If error is not because device is offline, then Account not valid so go to Login Screen
			if(error.code != NSURLErrorNotConnectedToInternet && error.code != NSURLErrorTimedOut)
			{
				[authenticationModel doLogout];
			}
		}
	}];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	
	// Remove view over app that was used to obsure screenshot (calling it here is required when user double clicks home button and then clicks the already active TeleMed app - applicationWillEnterForeground is not called in this case)
	[self toggleScreenshotView:YES];
	
	// Dismiss Error Alert if showing
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController dismiss];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
	NSLog(@"My token is: %@", deviceToken);
    
    // Convert the token to a hex string and make sure it's all caps  
    NSMutableString *tokenString = [NSMutableString stringWithString:[[deviceToken description] uppercaseString]];  
    [tokenString replaceOccurrencesOfString:@"<" withString:@"" options:0 range:NSMakeRange(0, tokenString.length)];  
    [tokenString replaceOccurrencesOfString:@">" withString:@"" options:0 range:NSMakeRange(0, tokenString.length)];  
    [tokenString replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, tokenString.length)];
	
	// Set Device Token
	RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
	
	[registeredDeviceModel setToken:tokenString];
	
	// Run updateDeviceToken web service. This will only fire if either [MyProfileModel getWithCallback] has already completed or Phone Number has been entered/confirmed (this method can sometimes be delayed, so fire it here too).
	[registeredDeviceModel registerDeviceWithCallback:^(BOOL success, NSError *error)
	{
		// If there is an error other than the device offline error, show the error. Show the error even if success returned true so that TeleMed can track issue down
		if(error != nil && error.code != NSURLErrorNotConnectedToInternet && error.code != NSURLErrorTimedOut)
		{
			ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
			
			[errorAlertController show:error];
		}
	}];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	NSLog(@"Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	//NSLog(@"Local Notification received: %@", notification.userInfo);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	// IMPORTANT: TeleMed's test and production servers both send push notifications through Apple's production server. Only apps signed with Ad Hoc or Distribution provisioning profiles can receive these notifications - not Debug.
	// To test on debug, find/generate a Sandbox Push Notification Certificate for TeleMed (com.solutionbuilt.telemed.debug) and save its .cer file somewhere. Then use "APN Tester Free" Mac app to send push notifications to a specific device using its Device Token.
		// Sample Notifications that can be used with APNS Tester Free (these are real notifications that come from TeleMed)
		/* Message Push Notification
		{
			"aps":
			{
				"alert":"3 new messages.",
				"badge":3,
				"sound":"note.caf"
			},
			"NotificationType":"Message"
		}*/

		/* Comment Push Notification
		{
			"aps":
			{
				"alert":"Dr. Matt Rogers added a comment to a message.",
				"sound":"circles.caf"
			},
			"DeliveryID":5133538688695397,
			"NotificationType":"Comment"
		}*/
	
		/* Chat Push Notification
		{
			"aps":
			{
				"alert":"Matt Rogers:What's happening?",
				"sound":"note.caf"
			},
			"ChatMsgID":12345,
			"NotificationType":"Chat"
		}*/
	
	/*/ TESTING ONLY (push notifications can generally only be tested in Ad Hoc mode where nothing can be logged, so show result in an alert instead)
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Push Notification Received" message:[NSString stringWithFormat:@"%@", userInfo] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[alertView show];
	// END TESTING ONLY*/
	
	// Handle Push Notification when App is Active.
	if([application applicationState] == UIApplicationStateActive)
	{
		// Push notification to any observers within the app (CoreViewController, CoreTableViewController, MessageDetailViewController, and MessagesTableViewController)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationDidReceiveRemoteNotification" object:userInfo];
	}
}


#pragma mark - Public Methods

- (void)showMainScreen
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
	UIViewController *messagesViewController = [mainStoryboard instantiateInitialViewController];
	
	[self.window setRootViewController:messagesViewController];
	[self.window makeKeyAndVisible];
}


#pragma mark - Private Methods

- (void)applicationDidTimeout:(NSNotification *)notification
{
	AuthenticationModel *authenticationModel = [AuthenticationModel sharedInstance];
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	BOOL timeoutEnabled = [settings boolForKey:@"enableTimeout"];
	
	// Only log user out if timeout is enabled and user is not currently on phone call
	if(timeoutEnabled && ! [self isCallConnected])
	{
		// Delay logout to ensure application is fully loaded
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^
		{
			[authenticationModel doLogout];
		});
	}
}

- (void)didFinishInitialization:(NSNotification *)notification
{
	AuthenticationModel *authenticationModel = [AuthenticationModel sharedInstance];
	MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
	RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
	
	// Load Timeout Preference
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	BOOL timeoutEnabled = [settings boolForKey:@"enableTimeout"];
	
	if( ! timeoutEnabled)
	{
		// If Enable Timeout string is NULL, then it has never been set. Set it to True
		if([settings objectForKey:@"enableTimeout"] == nil)
		{
			[settings setBool:YES forKey:@"enableTimeout"];
			[settings synchronize];
		}
	}
	
	// Remove Reachability observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingReachabilityDidChangeNotification object:nil];
	
	NSLog(@"Timeout Enabled: %@", (timeoutEnabled ? @"YES" : @"NO"));
	NSLog(@"Device ID: %@", registeredDeviceModel.ID);
	
	// If user has timeout disabled and a RefreshToken already exists, attempt to bypass Login screen
	if( ! timeoutEnabled && authenticationModel.RefreshToken != nil)
	{
		// Verify Account is Valid
		[myProfileModel getWithCallback:^(BOOL success, MyProfileModel *profile, NSError *error)
		{
			if(success)
			{
				// Update Timeout Period to the value sent from Server
				[(ELCUIApplication *)[UIApplication sharedApplication] setTimeoutPeriodMins:[profile.TimeoutPeriodMins intValue]];
				
				NSLog(@"User ID: %@", myProfileModel.ID);
				NSLog(@"Preferred Account ID: %@", myProfileModel.MyPreferredAccount.ID);
				NSLog(@"Device ID: %@", registeredDeviceModel.ID);
				NSLog(@"Phone Number: %@", registeredDeviceModel.PhoneNumber);
				
				// Check if device is already registered with TeleMed service
				if(registeredDeviceModel.PhoneNumber.length > 0 && ! [registeredDeviceModel.PhoneNumber isEqualToString:@"000-000-0000"])
				{
					// Phone Number is already registered with Web Service, so we just need to update Device Token (Device Token can change randomly so this keeps it up to date)
					[registeredDeviceModel setShouldRegister:YES];
					
					[registeredDeviceModel registerDeviceWithCallback:^(BOOL success, NSError *registeredDeviceError)
					{
						// If there is an error other than the device offline error, show the error. Show the error even if success returned true so that TeleMed can track issue down
						if(registeredDeviceError && registeredDeviceError.code != NSURLErrorNotConnectedToInternet && registeredDeviceError.code != NSURLErrorTimedOut)
						{
							ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
							
							[errorAlertController show:error];
						}
						
						// Go to Main Storyboard regardless of whether there was an error (no need to force re-login here because Account is valid, there was just an error updating device for push notifications)
						[self showMainScreen];
					}];
				}
				// Account is Valid, but Phone Number is not yet registered with TeleMed, so go directly to Phone Number screen
				else
				{
					NSLog(@"Phone Number Invalid");
					
					// If using Simulator, skip Phone Number step because it is always invalid
					// #if DEBUG
					#if TARGET_IPHONE_SIMULATOR
						NSLog(@"Skip Phone Number step when on Simulator or Debugging");
						
						[self showMainScreen];
					
					#else
						// Phone Number invalid, so direct user to enter it
						/*UIViewController *phoneNumberViewController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"PhoneNumberViewController"];
						UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:phoneNumberViewController];
						
						[self.window setRootViewController:navigationController];*/
					
						// Force user to re-login to eliminate issue of user trying to login as another user and getting permanently stuck on phone number screen (even after re-install of app)
						[self showLoginSSOScreen];
					#endif
				}
			}
			// Account is no longer valid so go to LoginSSO screen
			else
			{
				[self showLoginSSOScreen];
			}
		}];
	}
	// Go to Login screen by default
	else
	{
		[self showLoginSSOScreen];
	}
}

- (void)showLoginSSOScreen
{
	UIStoryboard *loginSSOStoryboard;
	UIStoryboard *currentStoryboard = self.window.rootViewController.storyboard;
	NSString *currentStoryboardName = [currentStoryboard valueForKey:@"name"];
	
	NSLog(@"Current Storyboard: %@", currentStoryboardName);
	
	if([currentStoryboardName isEqualToString:@"LoginSSO"])
	{
		loginSSOStoryboard = currentStoryboard;
	}
	else
	{
		loginSSOStoryboard = [UIStoryboard storyboardWithName:@"LoginSSO" bundle:nil];
	}
	
	UIViewController *loginSSOViewController = [loginSSOStoryboard instantiateViewControllerWithIdentifier:@"LoginSSOViewController"];
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:loginSSOViewController];
	
	[self.window setRootViewController:navigationController];
	[self.window makeKeyAndVisible];
}

- (BOOL)isCallConnected
{
	for(CTCall *call in self.callCenter.currentCalls)
	{
		if(call.callState == CTCallStateConnected)
		{
			return YES;
		}
	}
	
	return NO;
}

- (void)toggleScreenshotView:(BOOL)shouldHide
{
	UIView *screenshotView = [self.window viewWithTag:8353633];
	
	// Remove view over app that was used to obsure screenshot
	if(shouldHide)
	{
		if(screenshotView != nil)
		{
			[UIView animateWithDuration:0.25f animations:^
			{
				[screenshotView setAlpha:0.0];
			}
			completion:^(BOOL finished)
			{
				[screenshotView removeFromSuperview];
			}];
		}
	}
	// Add view over app to obsure screenshot
	else
	{
		// Only show Screenshot View if it is not already visible
		if(screenshotView == nil)
		{
			UIImageView *screenshotView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LaunchImage"]];
			UIScreen *screen = [UIScreen mainScreen];
			
			// iPhone 6+
			if(screen.currentMode.size.width == 1242)
			{
				screenshotView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LaunchImage-800-Portrait-736h@3x"]];
			}
			// iPhone 6
			else if(screen.currentMode.size.width == 750)
			{
				screenshotView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LaunchImage-800-667h@2x"]];
			}
			
			[screenshotView setContentMode:UIViewContentModeScaleAspectFill];
			[screenshotView setFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
			[screenshotView setTag:8353633];
			[self.window addSubview:screenshotView];
			[self.window bringSubviewToFront:screenshotView];
		}
	}
}

- (void)userDidTakeScreenshot:(NSNotification *)notification
{
	NSLog(@"Screenshot Taken");
}

- (void)dealloc
{
	// Remove all observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
