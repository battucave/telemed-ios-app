//
//  ProfileProtocol.h
//  TeleMed
//
//  Created by Shane Goodwin on 11/21/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccountModel.h"
#import "TimeZoneModel.h"

@protocol ProfileProtocol <NSObject>

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSString *Email;
@property (nonatomic) BOOL IsAuthorized; // Med2Med manually sets this separately from web service
@property (nonatomic) BOOL MayDisableTimeout;
@property (nonatomic) TimeZoneModel *MyTimeZone;
@property (nonatomic) NSNumber *TimeoutPeriodMins;

+ (id <ProfileProtocol>)sharedInstance;

// MyProfileModel only
@optional
@property (nonatomic) BOOL BlockCallerID;
@property (nonatomic) NSString *CallTelemedNumber;
@property (nonatomic) AccountModel *MyPreferredAccount;
@property (nonatomic) NSArray *MyRegisteredDevices;
@property (nonatomic) BOOL PasswordChangeRequired;

// UserProfileModel only
@optional
@property (nonatomic) NSString *FirstName;
@property (nonatomic) NSString *LastName;
@property (nonatomic) NSString *JobTitlePrefix;


@required
- (void)getWithCallback:(void (^)(BOOL success, NSObject <ProfileProtocol> *profile, NSError *error))callback;
- (id)valueForKey:(NSString *)key;

@end
