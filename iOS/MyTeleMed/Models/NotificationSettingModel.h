//
//  NotificationSettingModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "Model.h"

@interface NotificationSettingModel : Model

@property (weak) id delegate;

// Class variables
@property (class, nonatomic, readonly) NSArray *classicTones;
@property (class, nonatomic, readonly) NSString *defaultTone;
@property (class, nonatomic, readonly) NSArray *intervals;
@property (class, nonatomic, readonly) NSArray *myTeleMedTones;
@property (class, nonatomic, readonly) NSArray *staffFavoriteTones;
@property (class, nonatomic, readonly) NSArray *standardTones;
@property (class, nonatomic, readonly) NSArray *subCategoryTones;

// Instance variables
@property (nonatomic) BOOL Enabled;
@property (nonatomic) BOOL isReminderOn; // Not passed from web service
@property (nonatomic) NSNumber *Interval;
@property (nonatomic) NSString *Name;
@property (nonatomic) NSString *Tone;
@property (nonatomic) NSString *ToneTitle; // Not passed from web service

- (NSString *)getToneFromToneTitle:(NSString *)toneTitle;
- (NotificationSettingModel *)getNotificationSettingsByName:(NSString *)name;
- (void)saveNotificationSettingsByName:(NSString *)name settings:(NotificationSettingModel *)notificationSettings;

@end


@protocol NotificationSettingDelegate <NSObject>

@required
- (void)updateNotificationSettings:(id)serverNotificationSettings forName:(NSString *)name;

@optional
- (void)updateNotificationSettingsError:(NSError *)error;
- (void)saveNotificationSettingsPending;
- (void)saveNotificationSettingsSuccess;
- (void)saveNotificationSettingsError:(NSError *)error;

@end
