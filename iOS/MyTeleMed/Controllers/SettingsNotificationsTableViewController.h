//
//  SettingsNotificationsTableViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/11/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreTableViewController.h"
#import "NotificationSettingModel.h"

@interface SettingsNotificationsTableViewController : CoreTableViewController

@property (nonatomic) NSInteger notificationSettingsType; // 1 = Stat, 2 = Priority, 3 = Normal, 4 = Comment
@property (nonatomic) NotificationSettingModel *notificationSettings;

- (void)updateNotificationSettings:(NotificationSettingModel *)serverNotificationSettings forName:(NSString *)name;
- (void)updateNotificationSettingsError:(NSError *)error;
- (void)saveNotificationSettingsSuccess;
- (void)saveNotificationSettingsError:(NSError *)error;

@end
