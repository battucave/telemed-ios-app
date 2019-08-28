//
//  UserProfileModel.h
//  Med2Med
//
//  Created by Shane Goodwin on 11/21/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "Model.h"
#import "ProfileProtocol.h"
#import "TimeZoneModel.h"

@interface UserProfileModel : Model <ProfileProtocol>

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSString *Email;
@property (nonatomic) NSString *FirstName;
@property (nonatomic) BOOL IsAuthorized; // Use isAuthorized: as getter
@property (nonatomic) NSString *JobTitlePrefix;
@property (nonatomic) NSString *LastName;
@property (nonatomic) BOOL MayDisableTimeout;
@property (nonatomic) TimeZoneModel *MyTimeZone;
@property (nonatomic) NSString *PhoneNumber; // Stored locally on device instead of web service
@property (nonatomic) NSNumber *TimeoutPeriodMins;

+ (id <ProfileProtocol>)sharedInstance;

- (void)doLogout;
- (void)getWithCallback:(void (^)(BOOL success, id <ProfileProtocol> profile, NSError *error))callback;
- (BOOL)isAuthenticated;
- (BOOL)isAuthorized;

@end
