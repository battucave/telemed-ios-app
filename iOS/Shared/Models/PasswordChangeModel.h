//
//  PasswordChangeModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 3/27/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "Model.h"

@protocol PasswordChangeDelegate <NSObject>

@optional
- (void)changePasswordPending;
- (void)changePasswordSuccess;
- (void)changePasswordError:(NSError *)error;

@end

@interface PasswordChangeModel : Model

@property (weak) id delegate;

- (void)changePassword:(NSString *)newPassword withOldPassword:(NSString *)oldPassword;

@end
