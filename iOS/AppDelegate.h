//
//  AppDelegate.h
//  TeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, UNUserNotificationCenterDelegate>

@property (nonatomic) UIWindow *window;
@property (nonatomic) UIStoryboard *storyboard;

#ifdef MYTELEMED
	@property (nonatomic) void (^goToRemoteNotificationScreen)(UINavigationController *navigationController); // Used by AppDelegate, CoreViewController, and CoreTableViewController
#endif

- (void)showMainScreen;

@end
