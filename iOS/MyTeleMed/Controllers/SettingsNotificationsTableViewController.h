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

@property (nonatomic) NSInteger notificationSettingsType; // 0 = Stat Messages, 1 = PriorityMessages, 2 = NormalMessages, 3 = ChatMessages, 4 = Comments
@property (nonatomic) NotificationSettingModel *notificationSettings;

@end
