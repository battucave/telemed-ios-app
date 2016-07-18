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
- (void)updateAccountsError:(NSError *)error;

@end

@interface AccountModel : Model

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSString *Name;
@property (nonatomic) NSString *PublicKey;
@property (nonatomic) NSDictionary *TimeZone;

- (void)getAccounts;
//- (void)getAccountByID:(NSNumber *)accountID;
//- (void)getAccountByPublicKey:(NSNumber *)publicKey;

@end
