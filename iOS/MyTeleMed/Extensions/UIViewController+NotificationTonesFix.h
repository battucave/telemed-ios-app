//
//  UIViewController+NotificationTonesFix.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 7/7/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NotificationSettingModel.h"

@interface UIViewController (NotificationTonesFix)

- (void)verifyNotificationTones;

// Delegate Methods
- (void)updateNotificationSettings:(NotificationSettingModel *)serverNotificationSettings forName:(NSString *)name;
- (void)updateNotificationSettingsError:(NSError *)error;
- (void)saveNotificationSettingsSuccess;
- (void)saveNotificationSettingsError:(NSError *)error;

@end
