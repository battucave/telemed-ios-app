//
//  UserProfileModel.h
//  MedToMed
//
//  Created by Shane Goodwin on 11/21/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "Model.h"
#import "ProfileProtocol.h"

@interface UserProfileModel : Model <ProfileProtocol>

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSString *Email;
@property (nonatomic) BOOL IsAuthorized;
@property (nonatomic) BOOL MayDisableTimeout;
@property (nonatomic) NSString *FirstName;
@property (nonatomic) NSString *JobTitlePrefix;
@property (nonatomic) NSString *LastName;
@property (nonatomic) NSDictionary *MyTimeZone;
@property (nonatomic) NSNumber *TimeoutPeriodMins;

+ (id <ProfileProtocol>)sharedInstance;

- (void)getWithCallback:(void (^)(BOOL success, id <ProfileProtocol> profile, NSError *error))callback;

@end
