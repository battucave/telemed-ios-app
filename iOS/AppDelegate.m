//
//  AppDelegate.m
//  TeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "AppDelegate.h"
#import "ELCUIApplication.h"
#import "ErrorAlertController.h"
#import "SWRevealViewController.h"
#import "TeleMedHTTPRequestOperationManager.h"
#import "ProfileProtocol.h"
#import "AuthenticationModel.h"
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#ifdef MYTELEMED
	#import "MyProfileModel.h"
	#import "MyStatusModel.h"
	#import "RegisteredDeviceModel.h"
#endif

#ifdef MEDTOMED
	#import "AccountModel.h"
	#import "UserProfileModel.h"
#endif

@interface AppDelegate()

@property (nonatomic) CTCallCenter *callCenter;

@end

@implementation AppDelegate


#pragma mark - App Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// Setup app Timeout feature
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidTimeout:) name:kApplicationDidTimeoutNotification object:nil];
	
	// Setup screenshot notification feature
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidTakeScreenshot:) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
	
	// Add Reachability observer to defer web services until Reachability has been determined
	__unused TeleMedHTTPRequestOperationManager *operationManager = [TeleMedHTTPRequestOperationManager sharedInstance];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishInitialization:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
	
	// Initialize CDMAVoiceData settings
	[settings setBool:NO forKey:@"CDMAVoiceDataHidden"];
	
	#if !TARGET_IPHONE_SIMULATOR && !defined(DEBUG)
		// Initialize Carrier
		CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
		CTCarrier *carrier = [networkInfo subscriberCellularProvider];
	
		// AT&T and T-Mobile are guaranteed to support Voice and Data simultaneously, so turn off CDMAVoiceData message by default for them
		if ([carrier.carrierName isEqualToString:@"AT&T"] || [carrier.carrierName hasPrefix:@"T-M"])
		{
			[settings setBool:YES forKey:@"CDMAVoiceDataDisabled"];
		}
	#endif
	
	[settings synchronize];
	
	// Initialize Call Center
	self.callCenter = [[CTCallCenter alloc] init];
	
	[self.callCenter setCallEventHandler:^(CTCall *call)
	{
		if ([[call callState] isEqual:CTCallStateDisconnected])
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
	
	// MyTeleMed - Push Notification Registration
	#ifdef MYTELEMED
		if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
		{
			// iOS 8+ Push Notifications
			[application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
			[application registerForRemoteNotifications];
		}
	
	// MedToMed - Prevent swipe message from ever appearing
	#elif defined MEDTOMED
		[settings setBool:YES forKey:@"swipeMessageDisabled"];
		[settings synchronize];
	#endif
	
	return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	
	// Add view over app to obsure screenshot
	[self toggleScreenshotView:NO];
	
	// Save current time app was closed (used for showing CDMA screen)
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	[settings setObject:[NSDate date] forKey:@"dateApplicationDidEnterBackground"];
	[settings synchronize];
	
	// MyTeleMed - Update app's badge count with number of unread messages
	#ifdef MYTELEMED
		MyStatusModel *myStatusModel = [MyStatusModel sharedInstance];
	
		// Set Badge Number for App Icon. These values are updated every time user resumes app and opens SideNavigation. Idea is that if user is actively using app, then they will use SideNavigation which will update the unread message count. If they just briefly open the app to check messages, then the app resume will update the unread message count.
		[application setApplicationIconBadgeNumber:[myStatusModel.UnreadMessageCount integerValue]];
	#endif
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
	
	if (fabs([[NSDate date] timeIntervalSinceDate:(NSDate *)[settings objectForKey:@"dateApplicationDidEnterBackground"]]) > 900)
	{
		[settings setBool:NO forKey:@"CDMAVoiceDataHidden"];
		[settings synchronize];
	}
	
	// MyTeleMed - Verify Account is still valid
	#ifdef MYTELEMED
		MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
	
		[myProfileModel getWithCallback:^(BOOL success, id <ProfileProtocol> profile, NSError *error)
		{
			if (success)
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
				if (error.code != NSURLErrorNotConnectedToInternet && error.code != NSURLErrorTimedOut)
				{
					AuthenticationModel *authenticationModel = [AuthenticationModel sharedInstance];
					
					[authenticationModel doLogout];
				}
			}
		}];
	#endif
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

- (void)dealloc
{
	// Remove all observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Custom Methods

- (void)applicationDidTimeout:(NSNotification *)notification
{
	AuthenticationModel *authenticationModel = [AuthenticationModel sharedInstance];
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	BOOL timeoutEnabled = [settings boolForKey:@"enableTimeout"];
	
	// Only log user out if timeout is enabled and user is not currently on phone call
	if (timeoutEnabled && ! [self isCallConnected])
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
	
	// Remove Reachability observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingReachabilityDidChangeNotification object:nil];
	
	// Load Timeout Preference
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	BOOL timeoutEnabled = [settings boolForKey:@"enableTimeout"];
	
	if ( ! timeoutEnabled)
	{
		// If Enable Timeout string is NULL, then it has never been set. Set it to True
		if ([settings objectForKey:@"enableTimeout"] == nil)
		{
			[settings setBool:YES forKey:@"enableTimeout"];
			[settings synchronize];
		}
	}
	
	NSLog(@"Timeout Enabled: %@", (timeoutEnabled ? @"YES" : @"NO"));
	
	// If user has timeout disabled and a RefreshToken already exists, attempt to bypass Login screen
	if ( ! timeoutEnabled && authenticationModel.RefreshToken != nil)
	{
		#ifdef MYTELEMED
			id <ProfileProtocol> profile = [MyProfileModel sharedInstance];
		
		#elif defined MEDTOMED
			id <ProfileProtocol> profile = [UserProfileModel sharedInstance];
		
		#else
			NSLog(@"Error - Target is neither MyTeleMed nor MedToMed");
		
			[self showLoginSSOScreen];
		
			return;
		#endif

		// Verify Account is Valid
		[profile getWithCallback:^(BOOL success, id <ProfileProtocol> profile, NSError *error)
		{
			if (success)
			{
				// Update Timeout Period to the value sent from server
				[(ELCUIApplication *)[UIApplication sharedApplication] setTimeoutPeriodMins:[profile.TimeoutPeriodMins intValue]];
				
				// MyTeleMed - Validate device registration with server
				#ifdef MYTELEMED
					[self validateRegistration:profile];
				
				// MedToMed - Validate at least one account is authorized
				#elif defined MEDTOMED
					[self validateMedToMedAuthorization:profile];
				#endif
				
				// Don't need an else condition here because logic already handles it before calling profile's getWithCallback method
			}
			// Account is no longer valid so go to Login screen
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

- (BOOL)isCallConnected
{
	for(CTCall *call in self.callCenter.currentCalls)
	{
		if (call.callState == CTCallStateConnected)
		{
			return YES;
		}
	}
	
	return NO;
}

- (void)showLoginSSOScreen
{
	UIStoryboard *loginSSOStoryboard;
	UIStoryboard *currentStoryboard = self.window.rootViewController.storyboard;
	NSString *currentStoryboardName = [currentStoryboard valueForKey:@"name"];
	
	NSLog(@"Current Storyboard: %@", currentStoryboardName);
	
	// Already on LoginSSO storyboard
	if ([currentStoryboardName isEqualToString:@"LoginSSO"])
	{
		loginSSOStoryboard = currentStoryboard;
	}
	// Go to LoginSSO storyboard
	else
	{
		loginSSOStoryboard = [UIStoryboard storyboardWithName:@"LoginSSO" bundle:nil];
	}
	
	UIViewController *loginSSOViewController = [loginSSOStoryboard instantiateViewControllerWithIdentifier:@"LoginSSOViewController"];
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:loginSSOViewController];
	
	[self.window setRootViewController:navigationController];
	[self.window makeKeyAndVisible];
}

- (void)toggleScreenshotView:(BOOL)shouldHide
{
	UIView *screenshotView = [self.window viewWithTag:8353633];
	
	// Remove view over app that was used to obsure screenshot
	if (shouldHide)
	{
		if (screenshotView != nil)
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
		if (screenshotView == nil)
		{
			UIView *screenshotView = [[[NSBundle mainBundle] loadNibNamed:@"Launch Screen" owner:self options:nil] objectAtIndex:0];
			UIScreen *screen = [UIScreen mainScreen];
			
			[screenshotView setContentMode:UIViewContentModeScaleAspectFill];
			[screenshotView setFrame:CGRectMake(0.0f, 0.0f, screen.bounds.size.width, screen.bounds.size.height)];
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


#pragma mark - MyTeleMed

#ifdef MYTELEMED
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
	NSLog(@"My Device Token: %@", deviceToken);
	
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
		if (error != nil && error.code != NSURLErrorNotConnectedToInternet && error.code != NSURLErrorTimedOut)
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
	// See project's ReadMe.md for instructions on how to test push notifications using APN Tester Free.
	
	// Sample Notifications that can be used with APN Tester Free (these are real notifications that come from TeleMed)
	/* Message Push Notification
	{
		"NotificationType":"Message",
		"aps":
		{
			"alert":"3 new messages.",
			"badge":3,
			"sound":"note.caf"
		}
	}*/

	/* Message Comment Push Notification
	{
		"DeliveryID":5133538688695397,
		"NotificationType":"Comment",
		"aps":
		{
			"alert":"Dr. Matt Rogers added a comment to a message.",
			"sound":"circles.caf"
		}
	}*/

    /* Sent Message Comment Push Notification
    {
    	"DeliveryID":"",
    	"MessageID":5646855541685471,
    	"NotificationType":"Comment",
    	"aps":
    	{
    		"alert":"Dr. Matt Rogers added a comment to a message.",
    		"sound":"circles.caf"
		}
	}*/


	/* Chat Push Notification
	{
		"ChatMsgID":5594182060867965,
		"NotificationType":"Chat",
		"aps":
		{
			"alert":"Matt Rogers:What's happening?",
			"sound":"nuclear.caf"
		}
	}*/
	
	/*/ TESTING ONLY (push notifications can generally only be tested in Ad Hoc mode where nothing can be logged, so show result in an alert instead)
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Push Notification Received" message:[NSString stringWithFormat:@"%@", userInfo] preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
	
	[alertController addAction:actionOK];
	
	// PreferredAction only supported in 9.0+
	if ([alertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[alertController setPreferredAction:actionOK];
	}
	
	// Show Alert
	[self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
	
	// END TESTING ONLY */
	
	// Handle Push Notification when App is Active.
	if ([application applicationState] == UIApplicationStateActive)
	{
		// Push notification to any observers within the app (CoreViewController, CoreTableViewController, MessageDetailViewController, and MessagesTableViewController)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationDidReceiveRemoteNotification" object:userInfo];
	}
}

/*
 * Show main screen: MessagesViewController
 */
- (void)showMainScreen
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
	SWRevealViewController *initialViewController = [mainStoryboard instantiateInitialViewController];
	
	[self.window setRootViewController:initialViewController];
	[self.window makeKeyAndVisible];
}

- (void)validateRegistration:(id <ProfileProtocol>)profile
{
	RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];

	NSLog(@"User ID: %@", profile.ID);
	NSLog(@"Preferred Account ID: %@", profile.MyPreferredAccount.ID);
	NSLog(@"Device ID: %@", registeredDeviceModel.ID);
	NSLog(@"Phone Number: %@", registeredDeviceModel.PhoneNumber);
	
	// Check if device is already registered with TeleMed service
	if (registeredDeviceModel.PhoneNumber.length > 0 && ! [registeredDeviceModel.PhoneNumber isEqualToString:@"000-000-0000"])
	{
		// Phone Number is already registered with Web Service, so we just need to update Device Token (Device Token can change randomly so this keeps it up to date)
		[registeredDeviceModel setShouldRegister:YES];
		
		[registeredDeviceModel registerDeviceWithCallback:^(BOOL success, NSError *registeredDeviceError)
		{
			// If there is an error other than the device offline error, show the error. Show the error even if success returned true so that TeleMed can track issue down
			if (registeredDeviceError && registeredDeviceError.code != NSURLErrorNotConnectedToInternet && registeredDeviceError.code != NSURLErrorTimedOut)
			{
				ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
				
				[errorAlertController show:registeredDeviceError];
			}
			
			// Go to main screen regardless of whether there was an error (no need to force re-login here because Account is valid, there was just an error updating device for push notifications)
			[self showMainScreen];
		}];
	}
	// Account is Valid, but Phone Number is not yet registered with TeleMed, so go directly to Phone Number screen
	else
	{
		NSLog(@"Phone Number Invalid");
		
		// If using Simulator, skip Phone Number step because it is always invalid
		// #ifdef DEBUG
		#if TARGET_IPHONE_SIMULATOR
			NSLog(@"Skip Phone Number step when on Simulator or Debugging");
		
			[self showMainScreen];
		
		#else
			// Force user to re-login to eliminate issue of user trying to login as another user and getting permanently stuck on phone number screen (even after re-install of app)
			[self showLoginSSOScreen];
		#endif
	}
}
#endif


#pragma mark - MedToMed

#ifdef MEDTOMED


/*
 * Show main screen: MessageNewTableViewController or MessageNewUnauthorizedTableViewController
 */
- (void)showMainScreen
{
	id <ProfileProtocol> profile = [UserProfileModel sharedInstance];
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MedToMed" bundle:nil];
	SWRevealViewController *initialViewController = [mainStoryboard instantiateInitialViewController];
	UINavigationController *navigationController;
	
	// If user has at least one authorized account, then show message new screen
	if (profile.IsAuthorized)
	{
		navigationController = [mainStoryboard instantiateViewControllerWithIdentifier:@"MessageNewNavigationController"];
	}
	// Else show message new unauthorized screen
	else
	{
		navigationController = [mainStoryboard instantiateViewControllerWithIdentifier:@"MessageNewUnauthorizedNavigationController"];
	}
	
	[initialViewController setFrontViewController:navigationController];
	
	[self.window setRootViewController:initialViewController];
	[self.window makeKeyAndVisible];
}

- (void)validateMedToMedAuthorization:(id <ProfileProtocol>)profile
{
	// Fetch Accounts and check the authorization status for each
	AccountModel *accountModel = [[AccountModel alloc] init];
	
	[accountModel getAccountsWithCallback:^(BOOL success, NSMutableArray *accounts, NSError *error)
	{
		if (success)
		{
			// Verify that user is authorized for at least one account
			for (AccountModel *account in accounts)
			{
				if ([account isAuthorized])
				{
					[profile setIsAuthorized:YES];
				}
				
				NSLog(@"Account Name: %@; Status: %@", account.Name, account.MyAuthorizationStatus);
			}
			
			// Go to Main Storyboard
			[self showMainScreen];
		}
		else
		{
			ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
			
			[errorAlertController show:error];
		}
	}];
}
#endif

@end
