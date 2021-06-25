//
//  PreferredAccountModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 3/27/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "Model.h"
#import "AccountModel.h"

@interface PreferredAccountModel : Model

@property (weak) id delegate;

- (void)savePreferredAccount:(AccountModel *)account;

@end


@protocol PreferredAccountDelegate <NSObject>

@optional
- (void)savePreferredAccountError:(NSError *)error;
- (void)savePreferredAccountPending;
- (void)savePreferredAccountSuccess;

@end
