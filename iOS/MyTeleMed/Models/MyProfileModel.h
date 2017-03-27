//
//  MyProfileModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"
#import "AccountModel.h"

// Primary Model
@interface MyProfileModel : Model

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID;
@property (nonatomic) BOOL BlockCallerID;
@property (nonatomic) NSString *CallTelemedNumber;
@property (nonatomic) NSString *Email;
@property (nonatomic) BOOL MayDisableTimeout;
@property (nonatomic) AccountModel *MyPreferredAccount;
@property (nonatomic) NSArray *MyRegisteredDevices;
@property (nonatomic) NSDictionary *MyTimeZone;
@property (nonatomic) NSNumber *TimeoutPeriodMins;

+ (MyProfileModel *)sharedInstance;

- (void)getWithCallback:(void (^)(BOOL success, MyProfileModel *profile, NSError *error))callback;
- (void)restoreMyPreferredAccount;

@end
