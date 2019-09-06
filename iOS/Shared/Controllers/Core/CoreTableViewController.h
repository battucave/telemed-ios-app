//
//  CoreTableViewController.h
//  TeleMed
//
//  Created by Shane Goodwin on 5/9/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CoreTableViewController : UITableViewController

#ifdef MYTELEMED
- (void)enableNotifications;
- (void)enableNotifications:(NSString *)authorizationMessage;
- (void)handleRemoteNotification:(NSMutableDictionary *)notificationInfo ofType:(NSString *)notificationType withViewAction:(UIAlertAction *)viewAction;
- (void)showNotificationAuthorization;
- (void)showNotificationRegistration;
#endif

@end
