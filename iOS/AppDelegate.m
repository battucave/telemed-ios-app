//
//  AppDelegate.m
//  TeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <CallKit/CallKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <sys/utsname.h>
#import <UserNotifications/UserNotifications.h>

#import "AppDelegate.h"
#import "TeleMedApplication.h"
#import "ErrorAlertController.h"
#import "SWRevealViewController.h"
#import "ProfileProtocol.h"
#import "AuthenticationModel.h"
#import "SSOProviderModel.h"
#import "TeleMedHTTPRequestOperationManager.h"

#if MYTELEMED
	#import "ChatMessageDetailViewController.h"
	#import "MessageDetailViewController.h"
	#import "MyProfileModel.h"
	#import "MyStatusModel.h"
    #import "NotificationSettingModel.h"
	#import "RegisteredDeviceModel.h"
#endif

#if MED2MED
	#import "AccountModel.h"
	#import "UserProfileModel.h"
#endif

@interface AppDelegate()

@property (nonatomic) CXCallObserver *callObserver;

#if MYTELEMED
	@property (nonatomic) dispatch_block_t teleMedCallTimeoutBlock;
#endif

@end

@implementation AppDelegate


#pragma mark - App Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // iOS 13+ - Restore navigation bar's bottom border
	if (@available(iOS 13.0, *))
	{
		UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];

		[appearance configureWithOpaqueBackground];

		[UINavigationBar.appearance setScrollEdgeAppearance:appearance];
		[UINavigationBar.appearance setStandardAppearance:appearance];
	}
	
	// Initialize call observer
	self.callObserver = [CXCallObserver new];
	
	[self.callObserver setDelegate:self queue:dispatch_get_main_queue()];
	
	// Setup app timeout feature
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidTimeout:) name:NOTIFICATION_APPLICATION_DID_TIMEOUT object:nil];
	
	// Setup screenshot notification feature
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(userDidTakeScreenshot:) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
	
	// Add reachability observer to defer web services until reachability has been determined
	__unused TeleMedHTTPRequestOperationManager *operationManager = TeleMedHTTPRequestOperationManager.sharedInstance;
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didFinishLaunching:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
	
	NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
	
	// Med2Med - Prevent swipe message from ever appearing
	#if MED2MED
		[settings setBool:YES forKey:SWIPE_MESSAGE_DISABLED];
	
	// DEBUG Only - reset swipe message on app launch
	#elif defined DEBUG
		[settings setBool:NO forKey:SWIPE_MESSAGE_DISABLED];
	#endif
	
	// Initialize cdma voice data settings
	[settings setBool:NO forKey:CDMA_VOICE_DATA_HIDDEN];
	
	if ([settings objectForKey:SHOW_SPRINT_VOICE_DATA_WARNING] == nil || [settings objectForKey:SHOW_VERIZON_VOICE_DATA_WARNING] == nil)
	{
		[settings setBool:NO forKey:SHOW_SPRINT_VOICE_DATA_WARNING];
		[settings setBool:NO forKey:SHOW_VERIZON_VOICE_DATA_WARNING];
		
		#if !TARGET_IPHONE_SIMULATOR && !defined(DEBUG)
			// Initialize carrier
			CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
			CTCarrier *carrier = [networkInfo subscriberCellularProvider];
		
			// Initialize lists of mobile network codes for CDMA carriers (from https://en.wikipedia.org/wiki/Mobile_country_code#United_States_of_America_-_US)
			NSArray *sprintMobileNetworkCodes = @[@"053", @"054", @"120", @"190", @"240", @"250", @"260", @"490", @"530", @"830", @"870", @"880", @"940"];
			NSArray *verizonMobileNetworkCodes = @[@"004", @"005", @"006", @"010", @"012", @"013", @"110", @"270", @"271", @"272", @"273", @"274", @"275", @"276", @"277", @"278", @"279", @"280", @"281", @"282", @"283", @"284", @"285", @"286", @"287", @"288", @"289", @"350", @"390", @"480", @"481", @"482", @"483", @"484", @"485", @"486", @"487", @"488", @"489", @"590", @"770", @"820", @"890", @"910"];
		
			// If mobile network code is available and user had not previously disabled the old CDMA warning
			if (carrier.mobileNetworkCode && [settings boolForKey:CDMA_VOICE_DATA_DISABLED] != YES)
			{
				// Enable voice data warning for Sprint users
				if ([sprintMobileNetworkCodes containsObject:carrier.mobileNetworkCode])
				{
					[settings setBool:YES forKey:SHOW_SPRINT_VOICE_DATA_WARNING];
				}
				// Enable voice data warning for Verizon users on devices that don't support VoLTE
				else if ([verizonMobileNetworkCodes containsObject:carrier.mobileNetworkCode])
				{
					// Get device model
					struct utsname systemInfo;
					
					uname(&systemInfo);
					
					NSString *deviceModelName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
					deviceModelName = [[deviceModelName componentsSeparatedByString:@","] objectAtIndex:0];
					
					if (deviceModelName.length >= 6)
					{
						NSString *deviceType = [deviceModelName substringToIndex:6];
						NSInteger deviceNumber = [[deviceModelName substringFromIndex:6] integerValue];
						
						// Enable voice data warning if device is an iPhone and the model is less than 7 (iPhone 6 and iPhone 6+ are model 7)
						if ([deviceType isEqualToString:@"iPhone"] && (int)deviceNumber < 7)
						{
							[settings setBool:YES forKey:SHOW_VERIZON_VOICE_DATA_WARNING];
						}
					}
				}
			}
		
			// Remove old CDMA warning setting
			[settings removeObjectForKey:CDMA_VOICE_DATA_DISABLED];
		#endif
	}
	
	[settings synchronize];
	
	#if defined(MYTELEMED) && ! TARGET_IPHONE_SIMULATOR
		// Register device for push notifications (this does not authorize push notifications however - that is done in PhoneNumberViewController)
		// NOTE: Device registration in debug mode is not working in iOS 13 when built with XCode 11.2.1 GM, but does still work in ad hoc and production apps.
		#if defined DEBUG
			NSLog(@"Skip device registration when on Debug");

		#else
			[[UIApplication sharedApplication] registerForRemoteNotifications];
		#endif
	
		// Handle push notification data
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
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	
	// Add view over app to obsure screenshot
	[self toggleScreenshotView:NO];
	
	// Save current time app was closed (used for showing cdma screen)
	NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
	
	[settings setObject:[NSDate date] forKey:DATE_APPLICATION_DID_ENTER_BACKGROUND];
	[settings synchronize];
	
	// MyTeleMed - Update app's badge count with number of unread messages
	#if MYTELEMED
		MyStatusModel *myStatusModel = MyStatusModel.sharedInstance;
	
		// Set badge number for app icon. These values are updated every time user resumes app and opens side navigation. Idea is that if user is actively using app, then they will use side navigation which will update the unread message count. If they just briefly open the app to check messages, then the app resume will update the unread message count
		[application setApplicationIconBadgeNumber:myStatusModel.UnreadMessageCount.integerValue];
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
	
	id <ProfileProtocol> profile;
	
	#if MYTELEMED
		profile = MyProfileModel.sharedInstance;

	#elif defined MED2MED
		profile = UserProfileModel.sharedInstance;

	#else
		NSLog(@"Error - Target is neither MyTeleMed nor Med2Med");
	#endif
	
	// Remove view over app that was used to obsure screenshot (calling it here speeds up dismissal of screenshot when returning from background)
	[self toggleScreenshotView:YES];
	
	// Re-authenticate user
	if (profile && [profile isAuthenticated])
	{
		// If application has timed out while it was in the background, then log the user out (unless the user was on a phone call)
		if ([self didApplicationTimeoutWhileInactive])
		{
			[self applicationDidTimeout:nil];
		}
		// Application has not timed out so verify that account is still valid
		else
		{
			[profile getWithCallback:^(BOOL success, id <ProfileProtocol> profile, NSError *error)
			{
				if (success)
				{
					// MyTeleMed - Update MyStatusModel with updated number of unread messages
					#if MYTELEMED
						MyStatusModel *myStatusModel = MyStatusModel.sharedInstance;
					
						[myStatusModel getWithCallback:^(BOOL success, MyStatusModel *profile, NSError *error)
						{
							// No callback needed - values are stored in shared instance automatically
						}];
					#endif
				}
				// If error is not because device is offline, then account is not valid so go to login screen
				else if (error.code != NSURLErrorNotConnectedToInternet && error.code != NSURLErrorTimedOut)
				{
					NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
					
					// Notify user that their account was invalid
					[settings setValue:@"There was a problem validating your account. Please login again." forKey:REASON_APPLICATION_DID_LOGOUT];
					[settings synchronize];
					
					// Go to login screen
					[self goToLoginScreen];
				}
			}];
		}
	}
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface
	
	// Remove view over app that was used to obsure screenshot (calling it here is required when user double clicks home button and then clicks the already active TeleMed app - applicationWillEnterForeground is not called in this case)
	[self toggleScreenshotView:YES];
	
	// Dismiss error alert if showing
	ErrorAlertController *errorAlertController = ErrorAlertController.sharedInstance;
	
	[errorAlertController dismiss];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate.
	// See also applicationDidEnterBackground:
}

- (void)callObserver:(CXCallObserver *)callObserver callChanged:(CXCall *)call
{
	if (call != nil)
	{
		// Ceck whether call has disconnected
		if (call.hasEnded == YES)
		{
			NSLog(@"CXCallState: Disconnected");
			
			// Dismiss error alert if showing (after phone call has ended, user should not see data connection unavailable error)
			ErrorAlertController *errorAlertController = ErrorAlertController.sharedInstance;
			
			[errorAlertController dismiss];
			
			// Post a notification to any listeners (ChatMessageDetailViewController and MessageDetailViewController)
			[NSNotificationCenter.defaultCenter postNotificationName:NOTIFICATION_APPLICATION_DID_DISCONNECT_CALL object:nil];
			
			// Reset idle timer
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[(TeleMedApplication *)[UIApplication sharedApplication] resetIdleTimer];
			});
		}
		// Check whether call has connected (user answered the call)
		else if (call.hasConnected == YES)
		{
			NSLog(@"CXCallState: Connected");
			
			// Post a notification to any listeners (PhoneCallViewController)
			[NSNotificationCenter.defaultCenter postNotificationName:NOTIFICATION_APPLICATION_DID_CONNECT_CALL object:nil];
			
			// MyTeleMed - Stop observing for TeleMed to return phone call
			#if MYTELEMED
				[self stopTeleMedCallObserver];
			#endif
		}
	}
}

- (void)dealloc
{
	// Remove all observers
	[NSNotificationCenter.defaultCenter removeObserver:self];
}


#pragma mark - Custom Methods

- (void)applicationDidTimeout:(NSNotification *)notification
{
	NSLog(@"Application timed out");
	
	UIStoryboard *currentStoryboard = self.window.rootViewController.storyboard;
	NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
	BOOL timeoutDisabled = [settings boolForKey:DISABLE_TIMEOUT];
	
	// Only log user out if timeout is enabled, user is not currently on a phone call, and user is not currently on the login screen
	if (! timeoutDisabled && ! [self isCallConnected] && ! [[currentStoryboard valueForKey:@"name"] isEqualToString:@"LoginSSO"])
	{
		// Notify user that their session timed out
		[settings setValue:@"Your session has timed out for security. Please login again." forKey:REASON_APPLICATION_DID_LOGOUT];
		[settings synchronize];
		
		// Delay logout to ensure application is fully loaded
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
		{
			// Go to login screen
			[self goToLoginScreen];
		});
	}
}

// Notify user if a new version of the app is available in the app store
- (void)checkAppStoreVersion
{
	NSLog(@"Future Phase: Check app store version");
	
	/* TEMPORARILY COMMENTED OUT
	 * Need to decide if there should be a remote server integration so that version checks can be disabled or prioritized (change showAlertAfterCurrentVersionHasBeenReleasedForDays to 1)
	
	Harpy *harpy = Harpy.sharedInstance;
	
	[harpy setPresentingViewController:self.window.rootViewController];
	
	// Only perform check after 10 days have elapsed to allow for 7 day phased release + padding for potential pauses in the release
	[harpy setShowAlertAfterCurrentVersionHasBeenReleasedForDays:10];
	
	// DEBUG Only - check version on every app launch
	#if DEBUG
		// [harpy testSetCurrentInstalledVersion:@"4.04"];
		[harpy setDebugEnabled:YES];
		[harpy checkVersion];
	
	// Perform check only once per day
	#else
		[harpy checkVersionDaily];
	#endif
	*/
}

/**
 * Determine whether application timed out while it was in the background
 */
- (BOOL)didApplicationTimeoutWhileInactive
{
	NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
	
	// If user has timeout disabled, then the application should not time out
	if ([settings boolForKey:DISABLE_TIMEOUT])
	{
		return false;
	}
	
	// Get user timeout period from user prefences
	NSNumber *userTimeoutPeriodMinutes = [settings valueForKey:USER_TIMEOUT_PERIOD_MINUTES];
	
	// Get number of seconds list application last resigned active
	NSDate *dateApplicationResignedActive = (NSDate *)[settings objectForKey:DATE_APPLICATION_DID_ENTER_BACKGROUND];
	NSTimeInterval timeIntervalSinceApplicationResignedActive = [[NSDate date] timeIntervalSinceDate:dateApplicationResignedActive];
	
	NSLog(@"User Timeout Period: %@ minutes", userTimeoutPeriodMinutes);
	NSLog(@"Application Last Active: %f minutes ago", timeIntervalSinceApplicationResignedActive / 60);
	
	// Determine whether application has timed out since it last resigned active
	return (timeIntervalSinceApplicationResignedActive / 60 > userTimeoutPeriodMinutes.integerValue);
}

- (void)didFinishLaunching:(NSNotification *)notification
{
	// Remove reachability observer
	[NSNotificationCenter.defaultCenter removeObserver:self name:AFNetworkingReachabilityDidChangeNotification object:nil];
	
	AuthenticationModel *authenticationModel = AuthenticationModel.sharedInstance;
	NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
	
	// TEMPORARY (Version 4.08) - Timeout logic was changed to use disableTimeout so that it doesn't have to be initialized - This logic can be removed in a future update (only after Med2Med has received the update)
	if ([settings objectForKey:@"enableTimeout"])
	{
		[settings setBool:! [settings boolForKey:@"enableTimeout"] forKey:DISABLE_TIMEOUT];
		[settings removeObjectForKey:@"enableTimeout"];
		[settings synchronize];
	}
	
	// Get timeout disabled preference from user prefences
	BOOL timeoutDisabled = [settings boolForKey:DISABLE_TIMEOUT];
	
	NSLog(@"Is Timeout Disabled: %@", (timeoutDisabled ? @"YES" : @"NO"));
	
	// Note: App always requires login when launching from cold start (matches behavior of financial apps)
	
	// If user has timeout disabled and a refresh token already exists, then attempt to bypass the login screen
	if (timeoutDisabled && authenticationModel.RefreshToken != nil)
	{
		id <ProfileProtocol> profile;
		
		#if MYTELEMED
			profile = MyProfileModel.sharedInstance;
		
		#elif defined MED2MED
			profile = UserProfileModel.sharedInstance;
		
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
					#if MYTELEMED
						[self validateMyTeleMedRegistration:profile];
					
					// Med2Med - Validate that at least one account is authorized
					#elif defined MED2MED
						[self validateMed2MedAuthorization:profile];
					#endif
					
					// Else condition will never be reached since it would have been handled while defining profile
				}
				// Account is no longer valid so go to login screen
				else
				{
					[self goToNextScreen];
				}
			}];
			
			return;
		}
	}
	
	// Go to login screen by default
	[self goToNextScreen];
}

/**
 * Get the LoginSSOStoryboard
 */
- (UIStoryboard *)getLoginSSOStoryboard
{
	UIStoryboard *loginSSOStoryboard = self.window.rootViewController.storyboard;
	
	// Initialize new instance of LoginSSOStoryboard if needed
	if (! [[loginSSOStoryboard valueForKey:@"name"] isEqualToString:@"LoginSSO"])
	{
		loginSSOStoryboard = [UIStoryboard storyboardWithName:@"LoginSSO" bundle:nil];
	}
	
	return loginSSOStoryboard;
}

/**
 * Go to EmailAddressViewController
 */
- (void)goToEmailAddressScreen
{
	[self goToViewControllerWithIdentifier:@"EmailAddress"];
}

/**
 * Go to LoginSSOViewController
 */
- (void)goToLoginScreen
{
	AuthenticationModel *authenticationModel = AuthenticationModel.sharedInstance;
	UIStoryboard *loginSSOStoryboard = [self getLoginSSOStoryboard];

	// Clear stored authentication data
	[authenticationModel doLogout];
	
	// Set LoginSSONavigationController as the root view controller
	UINavigationController *loginSSONavigationController = [loginSSOStoryboard instantiateViewControllerWithIdentifier:@"LoginSSONavigationController"];
	
	self.window.rootViewController = loginSSONavigationController;
	[self.window makeKeyAndVisible];
	
	// Check whether a new version of the app is available in the app store
	[self checkAppStoreVersion];
}

/**
 * Go to PasswordViewController
 */
- (void)goToPasswordChangeScreen
{
	[self goToViewControllerWithIdentifier:@"Password"];
}

/**
 * Go to a screen in the LoginSSOStoryboard using identifier
 */
- (void)goToViewControllerWithIdentifier:(NSString *)identifier
{
	if ([identifier isEqualToString:@"LoginSSO"])
	{
		NSLog(@"WARNING: Use goToLoginScreen: directly for navigating to the LoginSSO screen.");
		
		[self goToLoginScreen];
		
		return;
	}
	
	UIStoryboard *loginSSOStoryboard = [self getLoginSSOStoryboard];
	
	// If root view controller is a navigation controller, then push screen onto the existing navigation stack
	if (self.window.rootViewController.class == UINavigationController.class)
	{
		UINavigationController *navigationController = (UINavigationController *) self.window.rootViewController;
		UIViewController *viewController = [loginSSOStoryboard instantiateViewControllerWithIdentifier:[NSString stringWithFormat:@"%@ViewController", identifier]];
	
		[navigationController pushViewController:viewController animated:YES];
	}
	// Set screen's navigation controller as the root view controller
	else
	{
		UINavigationController *navigationController = [loginSSOStoryboard instantiateViewControllerWithIdentifier:[NSString stringWithFormat:@"%@NavigationController", identifier]];
		
		self.window.rootViewController = navigationController;
		[self.window makeKeyAndVisible];
	}
}

/**
 * Determine if a phone call is actively connected
 */
- (BOOL)isCallConnected
{
	for (CXCall *call in self.callObserver.calls)
	{
		if (! call.hasEnded)
		{
			return YES;
		}
	}
	
	return NO;
}

/**
 * Obscure screen to prevent user from taking a screenshot of the app
 */
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
				screenshotView.alpha = 0.0;
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
			UIView *screenshotView = [[[NSBundle mainBundle] loadNibNamed:@"LaunchScreen" owner:self options:nil] objectAtIndex:0];
			UIScreen *screen = UIScreen.mainScreen;
			
			screenshotView.contentMode = UIViewContentModeScaleAspectFill;
			screenshotView.frame = CGRectMake(0.0f, 0.0f, screen.bounds.size.width, screen.bounds.size.height);
			screenshotView.tag = 8353633;
			
			[self.window addSubview:screenshotView];
			[self.window bringSubviewToFront:screenshotView];
		}
	}
}

/**
 * TODO: Notify TeleMed that user has taken a screenshot of the app
 */
- (void)userDidTakeScreenshot:(NSNotification *)notification
{
	NSLog(@"Screenshot Taken");
}


#pragma mark - MyTeleMed

#if MYTELEMED
- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	NSLog(@"Failed to get token, error: %@", error);
	
	// Post notification to any observers within the app (MessagesViewController and SettingsTableViewController)
	[NSNotificationCenter.defaultCenter postNotificationName:NOTIFICATION_APPLICATION_DID_FAIL_TO_REGISTER_FOR_REMOTE_NOTIFICATIONS object:self userInfo:@{
		@"errorMessage": error.localizedDescription
	}];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)notification fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler
{
	// IMPORTANT: TeleMed's test and production servers both send push notifications through apple's production server. Only apps signed with ad hoc or distribution provisioning profiles can receive these notifications - not debug
	// See project's ReadMe.md for instructions on how to test push notifications using apn tester free
	
	// Sample notifications that can be used with apn tester free (these are real notifications that come from TeleMed)
	/* Message push notification
	{
		"DeliveryID":6099510726108687,
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
		"DeliveryID":6099510726108458,
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

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	NSLog(@"Remote Notifications Device Token: %@", deviceToken);

    // Get device token as a string (NOTE: Do not use device token's description as it has changed in iOS 13)
    const char *data = deviceToken.bytes;
    NSMutableString *tokenString = [NSMutableString string];

    for (NSUInteger i = 0; i < deviceToken.length; i++)
    {
        [tokenString appendFormat:@"%02.2hhX", data[i]];
    }

    NSLog(@"Remote Notifications Device Token String: %@", tokenString);
	
	// Set device token
	RegisteredDeviceModel *registeredDeviceModel = RegisteredDeviceModel.sharedInstance;
	
	registeredDeviceModel.Token = [tokenString copy];
	
	// Run update device token web service. This will only fire if either MyProfileModel's getWithCallback: has already completed or phone number has been entered/confirmed (this method can sometimes be delayed, so fire it here too)
	[registeredDeviceModel registerDeviceWithCallback:^(BOOL success, NSError *error)
	{
		// Post notifications to any observers within the app (MessagesViewController and SettingsTableViewController)
		if (success)
		{
			[NSNotificationCenter.defaultCenter postNotificationName:NOTIFICATION_APPLICATION_DID_REGISTER_FOR_REMOTE_NOTIFICATIONS object:self userInfo:@{
				@"deviceToken": [tokenString copy]
			}];
		}
		else
		{
			[NSNotificationCenter.defaultCenter postNotificationName:NOTIFICATION_APPLICATION_DID_FAIL_TO_REGISTER_FOR_REMOTE_NOTIFICATIONS object:self userInfo:@{
				@"errorMessage": error.localizedDescription
			}];
		}
	}];
}

/**
 * Get the current root view controller
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
 * Go to MessagesViewController
 */
- (void)goToMainScreen
{
    // Initialize notification settings
    NotificationSettingModel *notificationSettingModel = [[NotificationSettingModel alloc] init];
    
    [notificationSettingModel initialize];
    
	// Set MessagesNavigationController as the root view controller
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
	SWRevealViewController *initialViewController = [mainStoryboard instantiateInitialViewController];
	
	self.window.rootViewController = initialViewController;
	[self.window makeKeyAndVisible];
	
	// If app should navigate to remote notification screen after login or app launch
	if (self.goToRemoteNotificationScreen)
	{
		UINavigationController *navigationController = [self getCurrentNavigationController];
		
		// To avoid crashes, first confirm that navigation controller actually exists (it should ALWAYS exist here)
		if (navigationController)
		{
			// Push relevant view controller onto the existing navigation stack
			dispatch_async(dispatch_get_main_queue(), ^
			{
				self.goToRemoteNotificationScreen(navigationController);
				
				self.goToRemoteNotificationScreen = nil;
			});
		}
	}
	
	// Check whether a new version of the app is available in the app store
	// [self checkAppStoreVersion];
}

/**
 * Go to the next screen in the login process
 */
- (void)goToNextScreen
{
	UIStoryboard *currentStoryboard = self.window.rootViewController.storyboard;
	id <ProfileProtocol> profile = MyProfileModel.sharedInstance;
	RegisteredDeviceModel *registeredDeviceModel = RegisteredDeviceModel.sharedInstance;
	
	/*/ 8/09/2019 - SSO email collection has been postponed to a future release
	SSOProviderModel *ssoProviderModel = [[SSOProviderModel alloc] init];
	
	// If user has not previously provided an email address, then go to email address screen
	if (! ssoProviderModel.EmailAddress)
	{
		[self goToEmailAddressScreen];
	}
	else */
	
	// If user requires authentication, then go to login screen
	if (! [profile isAuthenticated])
	{
		[self goToLoginScreen];
	}
	// If user is already on main storyboard, then skip additional checks
	else if ([[currentStoryboard valueForKey:@"name"] isEqualToString:@"Main"])
	{
		[self goToMainScreen];
	}
	// If device has not previously registered with TeleMed, then go to phone number screen
	else if (! [registeredDeviceModel isRegistered] && ! [registeredDeviceModel hasSkippedRegistration])
	{
		[self goToPhoneNumberScreen];
	}
	// If TeleMed requires a password change for the user, then go to password change screen
	else if (profile.PasswordChangeRequired)
	{
		[self goToPasswordChangeScreen];
	}
	// User has completed login process so go to main screen
	else
	{
		[self goToMainScreen];
	}
}

/**
 * Go to PhonenumberViewController
 */
- (void)goToPhoneNumberScreen
{
	[self goToViewControllerWithIdentifier:@"PhoneNumber"];
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
		
		// Prevent additional alerts from appearing as they will replace this one
		return;
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
				
				chatMessageDetailViewController.isNewChat = NO;
				chatMessageDetailViewController.conversationID = notificationID;
				
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
					messageDetailViewController.messageID = notificationID;
				}
				// Comment and message notifications contain DeliveryID
				else
				{
					messageDetailViewController.messageDeliveryID = notificationID;
				}
				
				[navigationController pushViewController:messageDetailViewController animated:YES];
			};
		}
	}
	
	// Notification received while app is active
	if (applicationState == UIApplicationStateActive)
	{
		// Post notification to any observers within the app (CoreViewController and CoreTableViewController) regardless of whether user is logged in
		[NSNotificationCenter.defaultCenter postNotificationName:NOTIFICATION_APPLICATION_DID_RECEIVE_REMOTE_NOTIFICATION object:notificationData userInfo:(goToRemoteNotificationScreen != nil ? @{
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
				// Push relevant view controller onto the existing navigation stack
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

/**
 * Parse and clean up push notification data from didReceiveRemoteNotification: or didFinishLaunchingWithOptions:
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

/**
 * Start observing for TeleMed to return phone call (from CallModel)
 */
- (void)startTeleMedCallObserver:(dispatch_block_t)teleMedCallTimeoutBlock timeoutPeriod:(int)timeoutPeriod
{
	// Cancel any previous listener to prevent duplicate error messages
	[self stopTeleMedCallObserver];
	
	self.teleMedCallTimeoutBlock = teleMedCallTimeoutBlock;
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeoutPeriod * NSEC_PER_SEC)), dispatch_get_main_queue(), self.teleMedCallTimeoutBlock);
}

/**
 * Stop observing for TeleMed to return phone call (from CallModel)
 */
- (void)stopTeleMedCallObserver
{
	if (self.teleMedCallTimeoutBlock != nil)
	{
		dispatch_block_cancel(self.teleMedCallTimeoutBlock);
		
		// Reset timeout block
		self.teleMedCallTimeoutBlock = nil;
	}
}

/**
 * Re-register user's device with TeleMed if needed
 */
- (void)validateMyTeleMedRegistration:(id <ProfileProtocol>)profile
{
	RegisteredDeviceModel *registeredDeviceModel = RegisteredDeviceModel.sharedInstance;

	NSLog(@"User ID: %@", profile.ID);
	NSLog(@"Preferred Account ID: %@", profile.MyPreferredAccount.ID);
	NSLog(@"Device ID: %@", registeredDeviceModel.ID);
	NSLog(@"Phone Number: %@", registeredDeviceModel.PhoneNumber);
	NSLog(@"Is Registered: %@", [registeredDeviceModel isRegistered] ? @"Yes" : @"No");
	
	// If this device was previously registered with TeleMed, then we should update the device token in case it changed
	if ([registeredDeviceModel isRegistered])
	{
		[registeredDeviceModel registerDeviceWithCallback:^(BOOL success, NSError *registeredDeviceError)
		{
			// If there is an error other than the device offline error, show the error. Show the error even if success returned true so that TeleMed can track issue down
			if (registeredDeviceError && registeredDeviceError.code != NSURLErrorNotConnectedToInternet && registeredDeviceError.code != NSURLErrorTimedOut)
			{
				ErrorAlertController *errorAlertController = ErrorAlertController.sharedInstance;
				
				[errorAlertController show:registeredDeviceError];
			}
			
			// Go to the next screen in the login process
			[self goToNextScreen];
		}];
	}
	// Account is valid, but phone number is not yet registered with TeleMed so go directly to PhoneNumberViewController (handled by goToNextScreen:)
	else
	{
		// Go to the next screen in the login process
		[self goToNextScreen];
	}
}
#endif


#pragma mark - Med2Med

#if MED2MED

/**
 * Go to MessageNewTableViewController or MessageNewUnauthorizedTableViewController depending on authorization status
 */
- (void)goToMainScreen
{
	id <ProfileProtocol> profile = UserProfileModel.sharedInstance;
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Med2Med" bundle:nil];
	SWRevealViewController *initialViewController = [mainStoryboard instantiateInitialViewController];
	UINavigationController *navigationController;
	
	// If user has at least one authorized account, then show MessageNewViewController
	if ([profile isAuthorized])
	{
		navigationController = [mainStoryboard instantiateViewControllerWithIdentifier:@"MessageNewNavigationController"];
	}
	// Else show MessageNewUnauthorizedTableViewController
	else
	{
		navigationController = [mainStoryboard instantiateViewControllerWithIdentifier:@"MessageNewUnauthorizedNavigationController"];
	}
	
	initialViewController.frontViewController = navigationController;
	
	self.window.rootViewController = initialViewController;
	[self.window makeKeyAndVisible];
	
	// Check whether a new version of the app is available in the app store
	// [self checkAppStoreVersion];
}

/**
 * Go to the next screen in the login process
 */
- (void)goToNextScreen
{
	id <ProfileProtocol> profile = UserProfileModel.sharedInstance;
	
	/*/ 8/09/2019 - SSO email collection has been postponed to a future release
	SSOProviderModel *ssoProviderModel = [[SSOProviderModel alloc] init];
	
	// If user has not previously provided an email address, then go to email address screen
	if (! ssoProviderModel.EmailAddress)
	{
		[self goToEmailAddressScreen];
	}
	else */
	
	// If user requires authentication, then go to login screen
	if (! [profile isAuthenticated])
	{
		[self goToLoginScreen];
	}
	/*/ Future Phase: If TeleMed requires a password change for the user, then go to password change screen
	else if (profile.PasswordChangeRequired)
	{
		[self goToPasswordChangeScreen];
	} */
	// User has completed login process so go to main screen
	else
	{
		[self goToMainScreen];
	}
	
	// TODO: Future Phase: PasswordChangeRequired not yet implemented in UserProfileModel
	NSLog(@"Future Phase: Check if password change is required");
}

/**
 * Determine the user's authorization status
 */
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
					profile.IsAuthorized = YES;
				}
				
				NSLog(@"Account Name: %@; Status: %@", account.Name, account.MyAuthorizationStatus);
			}
		}
		else
		{
			ErrorAlertController *errorAlertController = ErrorAlertController.sharedInstance;
			
			[errorAlertController show:error];
		}
		
		// Go to the next screen in the login process
		[self goToNextScreen];
	}];
}
#endif

@end
