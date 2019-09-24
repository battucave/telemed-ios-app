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

+ (instancetype)sharedInstance;

- (BOOL)hasSkippedRegistration;
- (BOOL)isRegistered;
- (void)registerDeviceWithCallback:(void(^)(BOOL success, NSError *error))callback;
- (void)setCurrentDevice:(RegisteredDeviceModel *)registeredDevice;

@end
