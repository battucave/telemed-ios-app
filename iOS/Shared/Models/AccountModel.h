//
//  AccountModel.h
//  TeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Model.h"
#import "TimeZoneModel.h"

@protocol AccountDelegate <NSObject>

@required
- (void)updateAccounts:(NSArray *)accounts;

@optional
- (void)updateAccountsError:(NSError *)error;

@end

@interface AccountModel : Model

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSString *DID; // Med2Med only - Phone number to call TeleMed with
@property (nonatomic) NSString *Name;
@property (nonatomic) NSString *PublicKey;
@property (nonatomic) TimeZoneModel *TimeZone; // MyTeleMed only
@property (nonatomic) NSString *MyAuthorizationStatus; // Med2Med only - Possible values: Authorized, Pending, Unauthorized

- (void)getAccounts;
- (void)getAccountsWithCallback:(void (^)(BOOL success, NSArray *accounts, NSError *error))callback;


#pragma mark - MyTeleMed

#ifdef MYTELEMED
- (void)getAccountByID:(NSNumber *)accountID;
- (void)getAccountByPublicKey:(NSNumber *)publicKey;
#endif


#pragma mark - Med2Med

#ifdef MED2MED
- (void)getAccountsByHospital:(NSNumber *)hospitalID withCallback:(void (^)(BOOL success, NSArray *accounts, NSError *error))callback;
- (BOOL)isAuthorized;
- (BOOL)isPending;
#endif

@end
