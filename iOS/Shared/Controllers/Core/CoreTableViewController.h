//
//  CoreTableViewController.h
//  TeleMed
//
//  Created by Shane Goodwin on 5/9/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CoreTableViewController : UITableViewController

#if MYTELEMED
- (void)authorizeForRemoteNotifications;
- (void)authorizeForRemoteNotifications:(NSString *)authorizationMessage;
- (void)handleRemoteNotification:(NSMutableDictionary *)notificationInfo ofType:(NSString *)notificationType withViewAction:(UIAlertAction *)viewAction;
- (void)registerForRemoteNotifications;
#endif

@end
