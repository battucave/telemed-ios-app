//
//  NotificationSettingModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@protocol NotificationSettingDelegate <NSObject>

@required
- (void)updateNotificationSettings:(id)serverNotificationSettings forName:(NSString *)name;
- (void)updateNotificationSettingsError:(NSError *)error;
- (void)saveNotificationSettingsSuccess;
- (void)saveNotificationSettingsError:(NSError *)error;

@end

@interface NotificationSettingModel : Model

@property (weak) id delegate;

@property (nonatomic) BOOL Enabled;
@property (nonatomic) BOOL isReminderOn; // Not passed from Web Service
@property (nonatomic) NSNumber *Interval;
@property (nonatomic) NSString *Name;
@property (nonatomic) NSString *Tone;
@property (nonatomic) NSString *ToneTitle; // Not passed from Web Service

- (NSString *)getToneFromToneTitle:(NSString *)toneTitle;
- (NotificationSettingModel *)getNotificationSettingsByName:(NSString *)name;
- (void)saveNotificationSettingsByName:(NSString *)name settings:(NotificationSettingModel *)notificationSettings;

@end
