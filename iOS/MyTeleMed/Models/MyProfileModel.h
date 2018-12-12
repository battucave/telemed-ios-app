//
//  MyProfileModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "Model.h"
#import "ProfileProtocol.h"
#import "AccountModel.h"
#import "TimeZoneModel.h"

@interface MyProfileModel : Model <ProfileProtocol>

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID;
@property (nonatomic) BOOL BlockCallerID;
@property (nonatomic) NSString *CallTelemedNumber;
@property (nonatomic) NSString *Email;
@property (nonatomic) BOOL IsAuthorized;
@property (nonatomic) BOOL MayDisableTimeout;
@property (nonatomic) AccountModel *MyPreferredAccount;
@property (nonatomic) NSArray *MyRegisteredDevices;
@property (nonatomic) TimeZoneModel *MyTimeZone;
@property (nonatomic) BOOL PasswordChangeRequired;
@property (nonatomic) NSNumber *TimeoutPeriodMins;

+ (id <ProfileProtocol>)sharedInstance;

- (void)getWithCallback:(void (^)(BOOL success, id <ProfileProtocol> profile, NSError *error))callback;
- (void)restoreMyPreferredAccount;

@end
