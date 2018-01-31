//
//  AccountModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@protocol AccountDelegate <NSObject>

@required
- (void)updateAccounts:(NSMutableArray *)accounts;

@optional
- (void)updateAccountsError:(NSError *)error;

@end

@interface AccountModel : Model

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSString *Name;
@property (nonatomic) NSString *PublicKey;
@property (nonatomic) NSDictionary *TimeZone;
@property (nonatomic) NSString *MyAuthorizationStatus; // Possible values: Authorized, Pending, Unauthorized

- (void)getAccounts;
- (void)getAccountsWithCallback:(void (^)(BOOL success, NSMutableArray *accounts, NSError *error))callback;


#pragma mark - MyTeleMed

#ifdef MYTELEMED
- (void)getAccountByID:(NSNumber *)accountID;
- (void)getAccountByPublicKey:(NSNumber *)publicKey;
#endif


#pragma mark - MedToMed

#ifdef MEDTOMED
- (void)getAccountsByHospital:(NSNumber *)hospitalID;
- (void)getAccountsByHospital:(NSNumber *)hospitalID withCallback:(void (^)(BOOL success, NSMutableArray *accounts, NSError *error))callback;
- (BOOL)isAuthorized;
- (BOOL)isPending;
#endif

@end
