//
//  AppDelegate.h
//  TeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <CallKit/CallKit.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate : UIResponder <CXCallObserverDelegate, UIApplicationDelegate, UNUserNotificationCenterDelegate>

@property (nonatomic) UIWindow *window;
@property (nonatomic) UIStoryboard *storyboard;

#if MYTELEMED
	@property (nonatomic) void (^goToRemoteNotificationScreen)(UINavigationController *navigationController); // Used by AppDelegate, CoreViewController, and CoreTableViewController
#endif

- (void)goToLoginScreen;
- (void)goToNextScreen;

#if MYTELEMED
	- (void)startTeleMedCallObserver:(dispatch_block_t)returnCallTimeout timeoutPeriod:(int)timeoutPeriod;
	- (void)stopTeleMedCallObserver;
#endif

@end
