//
//  AppDelegate.m
//  TeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <UserNotifications/UserNotifications.h>

#import "AppDelegate.h"
#import "TeleMedApplication.h"
#import "ErrorAlertController.h"
#import "SWRevealViewController.h"
#import "ProfileProtocol.h"
#import "AuthenticationModel.h"
#import "Harpy.h"
#import "TeleMedHTTPRequestOperationManager.h"

#ifdef MYTELEMED
	#import "ChatMessageDetailViewController.h"
	#import "MessageDetailViewController.h"
	#import "MyProfileModel.h"
	#import "MyStatusModel.h"
	#import "RegisteredDeviceModel.h"
#endif

#ifdef MED2MED
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
	
	// Setup app timeout feature
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidTimeout:) name:kApplicationDidTimeoutNotification object:nil];
	
	// Setup screenshot notification feature
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidTakeScreenshot:) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
	
	// Add reachability observer to defer web services until reachability has been determined
	__unused TeleMedHTTPRequestOperationManager *operationManager = [TeleMedHTTPRequestOperationManager sharedInstance];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishLaunching:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
	
	// Med2Med - Prevent swipe message from ever appearing
	#ifdef MED2MED
		[settings setBool:YES forKey:@"swipeMessageDisabled"];
	
	// DEBUG Only - reset swipe message on app launch
	#elif defined DEBUG
		[settings setBool:NO forKey:@"swipeMessageDisabled"];
	#endif
	
	// Initialize cdma voice data settings
	[settings setBool:NO forKey:@"CDMAVoiceDataHidden"];
	
	if ([settings objectForKey:@"showSprintVoiceDataWarning"] == nil || [settings objectForKey:@"showVerizonVoiceDataWarning"] == nil)
	{
		[settings setBool:NO forKey:@"showSprintVoiceDataWarning"];
		[settings setBool:NO forKey:@"showVerizonVoiceDataWarning"];
		
		#if !TARGET_IPHONE_SIMULATOR && !defined(DEBUG)
			// Initialize carrier
			CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
			CTCarrier *carrier = [networkInfo subscriberCellularProvider];
		
			// Initialize lists of mobile network codes for CDMA carriers (from https://en.wikipedia.org/wiki/Mobile_country_code#United_States_of_America_-_US)
			NSArray *sprintMobileNetworkCodes = @[@"053", @"054", @"120", @"190", @"240", @"250", @"260", @"490", @"530", @"830", @"870", @"880", @"940"];
			NSArray *verizonMobileNetworkCodes = @[@"004", @"005", @"006", @"010", @"012", @"013", @"110", @"270", @"271", @"272", @"273", @"274", @"275", @"276", @"277", @"278", @"279", @"280", @"281", @"282", @"283", @"284", @"285", @"286", @"287", @"288", @"289", @"350", @"390", @"480", @"481", @"482", @"483", @"484", @"485", @"486", @"487", @"488", @"489", @"590", @"770", @"820", @"890", @"910"];
		
			// If mobile network code is available and user had not previously disabled the old CDMA warning
			if (carrier.mobileNetworkCode && [settings boolForKey:@"CDMAVoiceDataDisabled"] != YES)
			{
				// Enable voice data warning for Sprint
				if ([sprintMobileNetworkCodes containsObject:carrier.mobileNetworkCode])
				{
					[settings setBool:YES forKey:@"showSprintVoiceDataWarning"];
				}
				// Enable voice data warning for Verizon
				else if ([verizonMobileNetworkCodes containsObject:carrier.mobileNetworkCode])
				{
					[settings setBool:YES forKey:@"showVerizonVoiceDataWarning"];
				}
			}
		
			// Remove old CDMA warning setting
			[settings removeObjectForKey:@"CDMAVoiceDataDisabled"];
		#endif
	}
	
	[settings synchronize];
	
	// Initialize call center
	self.callCenter = [[CTCallCenter alloc] init];
	
	[self.callCenter setCallEventHandler:^(CTCall *call)
	{
		if ([[call callState] isEqual:CTCallStateDisconnected])
		{
			NSLog(@"Call disconnected");
			
			// Dismiss error alert if showing (after phone call has ended, user should not see data connection unavailable error)
			ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
			
			[errorAlertController dismiss];
			
			// Post a notification to any listeners (ChatMessageDetailViewController and MessageDetailViewController)
			[[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationDidDisconnectCall" object:nil];
			
			// Reset idle timer
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[(TeleMedApplication *)[UIApplication sharedApplication] resetIdleTimer];
			});
		}
	}];
	
	// MyTeleMed - push notification registration
	#ifdef MYTELEMED
		// Register for push notification in iOS 10+
		if ([NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10}])
		{
			UNUserNotificationCenter *userNotificationCenter = [UNUserNotificationCenter currentNotificationCenter];
			
			[userNotificationCenter setDelegate:self];
			[userNotificationCenter requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionCarPlay) completionHandler:^(BOOL granted, NSError * _Nullable error)
			{
				if (granted)
				{
					dispatch_async(dispatch_get_main_queue(), ^
					{
						[application registerForRemoteNotifications];
					});
				}
			}];
		}
		// Register for push notifications in iOS < 10
		else
		{
			[application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
			
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[application registerForRemoteNotifications];
			});
		}
	
		NSDictionary *remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
	
		if (remoteNotification)
		{
			[self handleRemoteNotification:remoteNotification applicationState:application.applicationState];
		}
	#endif
	
	return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state
	
	// Add view over app to obsure screenshot
	[self toggleScreenshotView:NO];
	
	// Save current time app was closed (used for showing cdma screen)
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	[settings setObject:[NSDate date] forKey:@"dateApplicationDidEnterBackground"];
	[settings synchronize];
	
	// MyTeleMed - Update app's badge count with number of unread messages
	#ifdef MYTELEMED
		MyStatusModel *myStatusModel = [MyStatusModel sharedInstance];
	
		// Set badge number for app icon. These values are updated every time user resumes app and opens side navigation. Idea is that if user is actively using app, then they will use side navigation which will update the unread message count. If they just briefly open the app to check messages, then the app resume will update the unread message count
		[application setApplicationIconBadgeNumber:[myStatusModel.UnreadMessageCount integerValue]];
	#endif
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background
	
	// Remove view over app that was used to obsure screenshot (calling it here speeds up dismissal of screenshot when returning from background)
	[self toggleScreenshotView:YES];
	
	// If more than 15 minutes have passed since app was closed, then reset cdma voice data hidden value
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	if (fabs([[NSDate date] timeIntervalSinceDate:(NSDate *)[settings objectForKey:@"dateApplicationDidEnterBackground"]]) > 1)
	{
		[settings setBool:NO forKey:@"CDMAVoiceDataHidden"];
		[settings synchronize];
	}
	
	// MyTeleMed - Verify account is still valid
	#ifdef MYTELEMED
		MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
	
		[myProfileModel getWithCallback:^(BOOL success, id <ProfileProtocol> profile, NSError *error)
		{
			if (success)
			{
				MyStatusModel *myStatusModel = [MyStatusModel sharedInstance];
				
				// Update MyStatusModel with updated number of unread messages
				[myStatusModel getWithCallback:^(BOOL success, MyStatusModel *profile, NSError *error)
				{
					// No callback needed - values stored in shared instance automatically
				}];
			}
			else
			{
				NSLog(@"Error %ld: %@", (long)error.code, error.localizedDescription);
				
				// If error is not because device is offline, then account not valid so go to login screen
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
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface
	
	// Remove view over app that was used to obsure screenshot (calling it here is required when user double clicks home button and then clicks the already active TeleMed app - applicationWillEnterForeground is not called in this case)
	[self toggleScreenshotView:YES];
	
	// Dismiss error alert if showing
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController dismiss];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:
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
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
		{
			[authenticationModel doLogout];
		});
	}
}

// Notify user if a new version of the app is available in the app store
- (void)checkAppStoreVersion
{
	NSLog(@"Future Phase: Check app store version");
	
	/* TEMPORARILY COMMENTED OUT
	 * Need to decide if there should be a remote server integration so that version checks can be disabled or prioritized (change showAlertAfterCurrentVersionHasBeenReleasedForDays to 1)
	
	Harpy *harpy = [Harpy sharedInstance];
	
	[harpy setPresentingViewController:self.window.rootViewController];
	
	// Only perform check after 10 days have elapsed to allow for 7 day phased release + padding for potential pauses in the release
	[harpy setShowAlertAfterCurrentVersionHasBeenReleasedForDays:10];
	
	// DEBUG Only - check version on every app launch
	#ifdef DEBUG
		// [harpy testSetCurrentInstalledVersion:@"4.04"];
		[harpy setDebugEnabled:YES];
		[harpy checkVersion];
	
	// Perform check only once per day
	#else
		[harpy checkVersionDaily];
	#endif
	*/
}

- (void)didFinishLaunching:(NSNotification *)notification
{
	AuthenticationModel *authenticationModel = [AuthenticationModel sharedInstance];
	
	// Remove reachability observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingReachabilityDidChangeNotification object:nil];
	
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	// If session timeout preference has never been set, then default it to true
	if (! [settings objectForKey:@"enableTimeout"])
	{
		[settings setBool:YES forKey:@"enableTimeout"];
		[settings synchronize];
	}
	
	BOOL timeoutEnabled = [settings boolForKey:@"enableTimeout"];
	
	NSLog(@"Timeout Enabled: %@", (timeoutEnabled ? @"YES" : @"NO"));
	
	// If user has timeout disabled and a refresh token already exists, attempt to bypass login screen
	if (! timeoutEnabled && authenticationModel.RefreshToken != nil)
	{
		id <ProfileProtocol> profile;
		
		#ifdef MYTELEMED
			profile = [MyProfileModel sharedInstance];
		
		#elif defined MED2MED
			profile = [UserProfileModel sharedInstance];
		
		#else
			NSLog(@"Error - Target is neither MyTeleMed nor Med2Med");
		#endif

		// Verify account is valid
		if (profile)
		{
			[profile getWithCallback:^(BOOL success, id <ProfileProtocol> profile, NSError *error)
			{
				if (success)
				{
					// MyTeleMed - Validate device registration with server
					#ifdef MYTELEMED
						[self validateMyTeleMedRegistration:profile];
					
					// Med2Med - Validate at least one account is authorized
					#elif defined MED2MED
						[self validateMed2MedAuthorization:profile];
					#endif
					
					// Else condition will never be reached since it would have been handled while defining profile
				}
				// Account is no longer valid so go to login screen
				else
				{
					[self showLoginScreen];
				}
			}];
			
			return;
		}
	}
	
	// Go to login screen by default
	[self showLoginScreen];
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

- (void)showLoginScreen
{
	UIStoryboard *loginSSOStoryboard = self.window.rootViewController.storyboard;
	NSString *currentStoryboardName = [loginSSOStoryboard valueForKey:@"name"];
	
	NSLog(@"Current Storyboard: %@", currentStoryboardName);
	
	// Initialize login sso storyboard
	if (! [currentStoryboardName isEqualToString:@"LoginSSO"])
	{
		loginSSOStoryboard = [UIStoryboard storyboardWithName:@"LoginSSO" bundle:nil];
	}
	
	UINavigationController *loginSSONavigationController = [loginSSOStoryboard instantiateViewControllerWithIdentifier:@"LoginSSONavigationController"];
	
	[self.window setRootViewController:loginSSONavigationController];
	[self.window makeKeyAndVisible];
	
	// Check whether a new version of the app is available in the app store
	[self checkAppStoreVersion];
}

- (void)showPasswordScreen
{
	UIStoryboard *loginSSOStoryboard = self.window.rootViewController.storyboard;
	NSString *currentStoryboardName = [loginSSOStoryboard valueForKey:@"name"];
	
	NSLog(@"Current Storyboard: %@", currentStoryboardName);
	
	// Initialize login sso storyboard
	if (! [currentStoryboardName isEqualToString:@"LoginSSO"])
	{
		loginSSOStoryboard = [UIStoryboard storyboardWithName:@"LoginSSO" bundle:nil];
	}
		
	// If root view controller is a navigation controller
	if (self.window.rootViewController.class == UINavigationController.class)
	{
		UINavigationController *navigationController = (UINavigationController *) self.window.rootViewController;
		UITableViewController *passwordViewController = [loginSSOStoryboard instantiateViewControllerWithIdentifier:@"PasswordViewController"];
	
		[navigationController pushViewController:passwordViewController animated:YES];
	}
	else
	{
		UINavigationController *passwordNavigationController = [loginSSOStoryboard instantiateViewControllerWithIdentifier:@"PasswordNavigationController"];
		
		[self.window setRootViewController:passwordNavigationController];
		[self.window makeKeyAndVisible];
	}
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
		// Only show screenshot view if it is not already visible
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
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	NSLog(@"My Device Token: %@", deviceToken);
	
	// Convert the token to a hex string and make sure it's all caps
	NSMutableString *tokenString = [NSMutableString stringWithString:[[deviceToken description] uppercaseString]];
	[tokenString replaceOccurrencesOfString:@"<" withString:@"" options:0 range:NSMakeRange(0, tokenString.length)];
	[tokenString replaceOccurrencesOfString:@">" withString:@"" options:0 range:NSMakeRange(0, tokenString.length)];
	[tokenString replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, tokenString.length)];
	
	// Set device token
	RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
	
	[registeredDeviceModel setToken:tokenString];
	
	// Run update device token web service. This will only fire if either MyProfileModel's getWithCallback: has already completed or phone number has been entered/confirmed (this method can sometimes be delayed, so fire it here too)
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

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	NSLog(@"Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	//NSLog(@"Local Notification received: %@", notification.userInfo);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)notification fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler
{
	// IMPORTANT: TeleMed's test and production servers both send push notifications through apple's production server. Only apps signed with ad hoc or distribution provisioning profiles can receive these notifications - not debug
	// See project's ReadMe.md for instructions on how to test push notifications using apn tester free
	
	// Sample notifications that can be used with apn tester free (these are real notifications that come from TeleMed)
	/* Message push notification
	{
		"DeliveryID":5133538688695397, // This property has been requested, but not yet implemented
		"NotificationType":"Message",
		"aps":
		{
			"alert":"3 new messages.",
			"badge":3,
			"sound":"note.caf"
		}
	}*/

	/* Message comment push notification
	{
		"DeliveryID":5133538688695397,
		"MessageID":"",
		"NotificationType":"Comment",
		"aps":
		{
			"alert":"Dr. Matt Rogers added a comment to a message.",
			"sound":"circles.caf"
		}
	}*/

    /* Sent message comment push notification
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


	/* Chat push notification
	{
		"ChatMsgID":5594182060867965,
		"NotificationType":"Chat",
		"aps":
		{
			"alert":"Matt Rogers:What's happening?",
			"sound":"nuclear.caf"
		}
	}*/
	
	// Handle remote notification. This method is only called if the app is in foreground or in background when notification is received; it is never called when app is inactive. However, the application state is erroneously set as UIApplicationStateInactive when app was in background so manually set it to UIApplicationStateBackground
	[self handleRemoteNotification:notification applicationState:(application.applicationState == UIApplicationStateActive ? UIApplicationStateActive : UIApplicationStateBackground)];
	
	completionHandler(UIBackgroundFetchResultNoData);
}

/*
 * Get current root view controller
 */
- (UINavigationController *)getCurrentNavigationController
{
	id navigationController = self.window.rootViewController;

	if ([navigationController isKindOfClass:SWRevealViewController.class])
	{
		navigationController = ((SWRevealViewController *)navigationController).frontViewController;
	}
	
	if ([navigationController isKindOfClass:UINavigationController.class])
	{
		return (UINavigationController *)navigationController;
	}
	
	return nil;
}

/**
 * Handle remote notification
 */
- (void)handleRemoteNotification:(NSDictionary *)notification applicationState:(UIApplicationState)applicationState
{
	NSLog(@"%@ Push Notification: %@", (applicationState == UIApplicationStateActive ? @"Foreground" : (applicationState == UIApplicationStateBackground ? @"Background" : @"Inactive")), notification);
	
	/*/ TESTING ONLY (push notifications can generally only be tested in ad hoc mode where nothing can be logged, so show result in an alert instead)
	#if !defined RELEASE
		dispatch_async(dispatch_get_main_queue(), ^
		{
			NSString *applicationStateString = (applicationState == UIApplicationStateActive ? @"Foreground" : (applicationState == UIApplicationStateBackground ? @"Background" : @"Inactive"));
			UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ Push Notification", applicationStateString] message:[NSString stringWithFormat:@"%@", notification] preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
	 
			[alertController addAction:okAction];
	 
			// Show alert
			[self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
		});
	#endif
	// END TESTING ONLY */
	
	// Initialize a block used for navigating to a remote notification's corresponding screen
	void (^goToRemoteNotificationScreen)(UINavigationController *navigationController);
	
	// Parse the remote notification data
	NSDictionary *notificationData = [self parseRemoteNotification:notification];
	NSNumber *notificationID = [notificationData objectForKey:@"notificationID"];
	NSString *notificationType = [notificationData objectForKey:@"notificationType"];
	
	// Only handle the notification if it contains a message
	if (! [notificationData objectForKey:@"message"])
	{
		return;
	}
	
	// If notification data is for a specific chat/comment/message, then create a block for navigating to it's corresponding screen
	if (notificationID)
	{
		// Received chat notification
		if ([notificationType isEqualToString:@"Chat"])
		{
			goToRemoteNotificationScreen = ^(UINavigationController *navigationController)
			{
				ChatMessageDetailViewController *chatMessageDetailViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatMessageDetailViewController"];
				
				[chatMessageDetailViewController setIsNewChat:NO];
				[chatMessageDetailViewController setConversationID:notificationID];
				
				[navigationController pushViewController:chatMessageDetailViewController animated:YES];
			};
		}
		// Received comment or message notification
		else if ([notificationType isEqualToString:@"Comment"] || [notificationType isEqualToString:@"Message"] || [notificationType isEqualToString:@"SentComment"])
		{
			goToRemoteNotificationScreen = ^(UINavigationController *navigationController)
			{
				MessageDetailViewController *messageDetailViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MessageDetailViewController"];
				
				// Comment notifications on sent messages only contain MessageID
				if ([notificationType isEqualToString:@"SentComment"])
				{
					[messageDetailViewController setMessageID:notificationID];
				}
				// Comment and message notifications contain DeliveryID
				else
				{
					[messageDetailViewController setMessageDeliveryID:notificationID];
				}
				
				[navigationController pushViewController:messageDetailViewController animated:YES];
			};
		}
	}
	
	// Notification received while app is active
	if (applicationState == UIApplicationStateActive)
	{
		// Post notification to any observers within the app (CoreViewController and CoreTableViewController) regardless of whether user is logged in
		[[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationDidReceiveRemoteNotification" object:notificationData userInfo:(goToRemoteNotificationScreen != nil ? @{
			@"goToRemoteNotificationScreen": [goToRemoteNotificationScreen copy]
		} : NULL)];
	}
	// Notification received while app was in the background or inactive and there is a remote notification screen to navigate to
	else if (goToRemoteNotificationScreen)
	{
		// User has completed the login process
		if ([[self.window.rootViewController.storyboard valueForKey:@"name"] isEqualToString:@"Main"])
		{
			UINavigationController *navigationController = [self getCurrentNavigationController];
			
			// To avoid crashes, first confirm that navigation controller actually exists (it should ALWAYS exist here)
			if (navigationController)
			{
				// Push relevant view controller onto existing navigation stack
				dispatch_async(dispatch_get_main_queue(), ^
				{
					goToRemoteNotificationScreen(navigationController);
				});
			}
		}
		// User was not logged in or the app was inactive so assign the block to a property for goToNextScreen: to handle
		else
		{
			[self setGoToRemoteNotificationScreen:goToRemoteNotificationScreen];
		}
	}
}

/*
 * Parse and clean up push notification data from didReceiveRemoteNotification or didFinishLaunchingWithOptions methods
 */
- (NSDictionary *)parseRemoteNotification:(NSDictionary *)notification
{
	NSDictionary *aps = [notification objectForKey:@"aps"];
	id alert = [aps objectForKey:@"alert"];
	NSString *message;
	id notificationID;
	NSString *notificationType = [notification objectForKey:@"NotificationType"] ?: @"Message";
	
	// Determine whether notification's alert was sent as an object or a string
	if ([alert isKindOfClass:NSString.class])
	{
		message = alert;
	}
	else if ([alert isKindOfClass:NSDictionary.class])
	{
		message = [alert objectForKey:@"body"];
	}
	
	// Only parse the notification if it contains a message
	if (! message)
	{
		return @{};
	}
	
	// Extract chat message id from chat notification
	if ([notification objectForKey:@"ChatMsgID"])
	{
		notificationID = [notification objectForKey:@"ChatMsgID"];
		notificationType = @"Chat"; // Ensure that notification type is set properly
	}
	// Extract delivery id from comment or message notification (ensure that delivery id actually has a value because sent comment notification also contains a delivery id, but with no value)
	else if ([notification objectForKey:@"DeliveryID"] && [[notification objectForKey:@"DeliveryID"] respondsToSelector:@selector(integerValue)] && [[notification objectForKey:@"DeliveryID"] integerValue] > 0)
	{
		notificationID = [notification objectForKey:@"DeliveryID"];
		notificationType = ([notificationType isEqualToString:@"Comment"] ? @"Comment" : @"Message"); // Ensure that notification type is set properly
	}
	// Extract message id from sent comment notification
	else if ([notification objectForKey:@"MessageID"])
	{
		notificationID = [notification objectForKey:@"MessageID"];
		notificationType = @"SentComment"; // Change notification type from Comment to SentComment to simplify further handling of the remote notification
	}
	
	NSLog(@"Notification Type: %@", notificationType);
	NSLog(@"Notification ID: %@", notificationID);
	NSLog(@"Message: %@", message);
	
	NSMutableDictionary *notificationData = [@{
		// @"notification"		: notification, // If specific properties need to handled by specific view controllers, then pass the entire notification and do that parsing in the specific view controller
		@"notificationType"	: notificationType,
		@"message"			: message
	} mutableCopy];
	
	// Add notification id to notification data if it is a valid number
	if ([notificationID isKindOfClass:NSNumber.class] && [notificationID integerValue] > 1)
	{
		[notificationData setObject:(NSNumber *)notificationID forKey:@"notificationID"];
	}
	// Add notification id to notification data if it is a valid numeric string
	else if ([notificationID isKindOfClass:NSString.class] && [notificationID integerValue] > 1)
	{
		NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
		
		[notificationData setObject:[numberFormatter numberFromString:(NSString *)notificationID] forKey:@"notificationID"];
	}
	
	// Add tone to notification data
	if ([aps objectForKey:@"sound"])
	{
		[notificationData setObject:[aps objectForKey:@"sound"] forKey:@"tone"];
	}
	
	return [notificationData copy];
}

/*
 * Show main screen: ChangePasswordViewController, PhoneNumberViewController, or MessagesViewController
 */
- (void)showMainScreen
{
	// Show MessagesViewController
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
	SWRevealViewController *initialViewController = [mainStoryboard instantiateInitialViewController];
	
	[self.window setRootViewController:initialViewController];
	[self.window makeKeyAndVisible];
	
	// If app should navigate to remote notification screen after login or app launch
	if (self.goToRemoteNotificationScreen)
	{
		UINavigationController *navigationController = [self getCurrentNavigationController];
		
		// To avoid crashes, first confirm that navigation controller actually exists (it should ALWAYS exist here)
		if (navigationController)
		{
			// Push relevant view controller onto existing navigation stack
			dispatch_async(dispatch_get_main_queue(), ^
			{
				self.goToRemoteNotificationScreen(navigationController);
				
				[self setGoToRemoteNotificationScreen:nil];
			});
		}
	}
	
	// Check whether a new version of the app is available in the app store
	// [self checkAppStoreVersion];
}

/*
 * Start application - launch user interface
 */
- (void)goToNextScreen
{
	UIStoryboard *currentStoryboard = self.window.rootViewController.storyboard;
	NSString *currentStoryboardName = [currentStoryboard valueForKey:@"name"];
	id <ProfileProtocol> profile = [MyProfileModel sharedInstance];
	
	// If user requires authentication, then show login screen
	if (! profile.IsAuthenticated)
	{
		[self showLoginScreen];
		
		return;
	}
	// If user is currently on login sso storyboard, then perform additional checks before sending user to main storyboard
	else if ([currentStoryboardName isEqualToString:@"LoginSSO"])
	{
		RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];
		
		// If device has not previously registered with TeleMed web service, then show PhoneNumberViewController
		if (! registeredDeviceModel.hasRegistered)
		{
			// If using Simulator, skip phone number step because it is always invalid
			// #ifdef DEBUG
			#if TARGET_IPHONE_SIMULATOR
				NSLog(@"Skip Phone Number step when on Simulator or Debugging");
			
			#else
				// If root view controller is a navigation controller
				if (self.window.rootViewController.class == UINavigationController.class)
				{
					UINavigationController *navigationController = (UINavigationController *) self.window.rootViewController;
					UIViewController *phoneNumberViewController = [currentStoryboard instantiateViewControllerWithIdentifier:@"PhoneNumberViewController"];
				
					[navigationController pushViewController:phoneNumberViewController animated:YES];
				}
				else
				{
					UINavigationController *phoneNumberNavigationController = [currentStoryboard instantiateViewControllerWithIdentifier:@"PhoneNumberNavigationController"];
					
					[self.window setRootViewController:phoneNumberNavigationController];
					[self.window makeKeyAndVisible];
				}
			
				return;
			#endif
		}
		
		// If TeleMed requires a password change for the user, then show PasswordChangeViewController
		if (profile.PasswordChangeRequired)
		{
			[self showPasswordScreen];
			
			return;
		}
	}
	
	[self showMainScreen];
}

- (void)validateMyTeleMedRegistration:(id <ProfileProtocol>)profile
{
	RegisteredDeviceModel *registeredDeviceModel = [RegisteredDeviceModel sharedInstance];

	NSLog(@"User ID: %@", profile.ID);
	NSLog(@"Preferred Account ID: %@", profile.MyPreferredAccount.ID);
	NSLog(@"Device ID: %@", registeredDeviceModel.ID);
	NSLog(@"Phone Number: %@", registeredDeviceModel.PhoneNumber);
	
	// If this device was previously registered with TeleMed, then we should update the device token in case it changed
	if (registeredDeviceModel.hasRegistered)
	{
		[registeredDeviceModel setShouldRegister:YES];
		
		[registeredDeviceModel registerDeviceWithCallback:^(BOOL success, NSError *registeredDeviceError)
		{
			// If there is an error other than the device offline error, show the error. Show the error even if success returned true so that TeleMed can track issue down
			if (registeredDeviceError && registeredDeviceError.code != NSURLErrorNotConnectedToInternet && registeredDeviceError.code != NSURLErrorTimedOut)
			{
				ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
				
				[errorAlertController show:registeredDeviceError];
			}
			
			// If the request was not successful, direct the user to re-enter their phone number again (handled by goToNextScreen:)
			if (! success)
			{
				[registeredDeviceModel setHasRegistered:NO];
			}
			
			// Go to the next screen in the login process
			[self goToNextScreen];
		}];
	}
	// Account is valid, but phone number is not yet registered with TeleMed so go directly to PhoneNumberViewController (handled by goToNextScreen:)
	else
	{
		// Go the next screen in the login process
		[self goToNextScreen];
	}
}
#endif


#pragma mark - Med2Med

#ifdef MED2MED

/*
 * Show main screen: MessageNewTableViewController or MessageNewUnauthorizedTableViewController
 */
- (void)showMainScreen
{
	id <ProfileProtocol> profile = [UserProfileModel sharedInstance];
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Med2Med" bundle:nil];
	SWRevealViewController *initialViewController = [mainStoryboard instantiateInitialViewController];
	UINavigationController *navigationController;
	
	// If user has at least one authorized account, then show MessageNewViewController
	if (profile.IsAuthorized)
	{
		navigationController = [mainStoryboard instantiateViewControllerWithIdentifier:@"MessageNewNavigationController"];
	}
	// Else show MessageNewUnauthorizedTableViewController
	else
	{
		navigationController = [mainStoryboard instantiateViewControllerWithIdentifier:@"MessageNewUnauthorizedNavigationController"];
	}
	
	[initialViewController setFrontViewController:navigationController];
	
	[self.window setRootViewController:initialViewController];
	[self.window makeKeyAndVisible];
	
	// Check whether a new version of the app is available in the app store
	// [self checkAppStoreVersion];
}

/*
 * Start application - launch user interface
 */
- (void)goToNextScreen
{
	id <ProfileProtocol> profile = [UserProfileModel sharedInstance];
	
	// TODO: Future Phase: PasswordChangeRequired not yet implemented in UserProfileModel
	NSLog(@"Future Phase: Check if password change is required");
	
	// If user requires authentication, then show login screen
	if (! profile.IsAuthenticated)
	{
		[self showLoginScreen];
	}
	/*/ Future Phase: If TeleMed requires a password change for the user, then show PasswordChangeViewController
	else if (profile.PasswordChangeRequired)
	{
		[self showPasswordScreen];
	} */
	else
	{
		[self showMainScreen];
	}
}

- (void)validateMed2MedAuthorization:(id <ProfileProtocol>)profile
{
	// Fetch accounts and check the authorization status for each
	AccountModel *accountModel = [[AccountModel alloc] init];
	
	[accountModel getAccountsWithCallback:^(BOOL success, NSArray *accounts, NSError *error)
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
		}
		else
		{
			ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
			
			[errorAlertController show:error];
		}
		
		// Go to the next screen in the login process
		[self goToNextScreen];
	}];
}
#endif

@end
