//
//  NotificationSettingXMLParser.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 8/16/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NotificationSettingModel.h"

@class NotificationSettingModel;

@interface NotificationSettingXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) NotificationSettingModel *notificationSetting;
@property (nonatomic) NSMutableArray *notificationSettings;

@end
