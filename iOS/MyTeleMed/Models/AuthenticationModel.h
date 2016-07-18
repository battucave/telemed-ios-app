//
//  AuthenticationModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/22/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AppDelegate;

@interface AuthenticationModel : NSObject

@property (nonatomic) NSString *AccessToken;
@property (nonatomic) NSString *RefreshToken;

@property (nonatomic) NSString *error;
@property (nonatomic) BOOL isWorking;

+ (AuthenticationModel *)sharedInstance;

- (void)getNewTokensWithSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure;
- (BOOL)accessTokenIsValid;
- (void)doLogout;

@end
