//
//  RegisteredDeviceModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@interface RegisteredDeviceModel : Model

@property (nonatomic) NSString *ID;
@property (nonatomic) NSString *AppVersionInfo;
@property (nonatomic) NSString *PhoneNumber;
@property (nonatomic) NSString *PlatformID;
@property (nonatomic) NSString *Token;

@property (nonatomic) BOOL hasRegistered; // This property not set by web service
@property (nonatomic) BOOL shouldRegister; // This property not set by web service

+ (instancetype)sharedInstance;

- (void)registerDeviceWithCallback:(void(^)(BOOL success, NSError *error))callback;

@end
