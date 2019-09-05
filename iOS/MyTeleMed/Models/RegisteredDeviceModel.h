//
//  RegisteredDeviceModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "Model.h"

@interface RegisteredDeviceModel : Model

@property (nonatomic) NSString *ID;
@property (nonatomic) NSString *AppVersionInfo;
@property (nonatomic) NSString *PhoneNumber;
@property (nonatomic) NSString *PlatformID;
@property (nonatomic) NSString *Token;

@property (nonatomic) BOOL shouldRegister; // This property not set by web service

+ (instancetype)sharedInstance;

- (BOOL)didSkipRegistration;
- (BOOL)isRegistered;
- (void)registerDeviceWithCallback:(void(^)(BOOL success, NSError *error))callback;
- (void)setCurrentDevice:(RegisteredDeviceModel *)registeredDevice;

@end
