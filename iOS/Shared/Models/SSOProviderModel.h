//
//  SSOProviderModel.h
//  TeleMed
//
//  Created by Shane Goodwin on 6/18/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSOProviderModel : NSObject

@property (nonatomic) NSString *EmailAddress;
@property (nonatomic) NSString *Name;

- (void)validateEmailAddress:(NSString *)newEmailAddress withCallback:(void(^)(BOOL success, NSError *error))callback;
- (void)validateName:(NSString *)newName withCallback:(void(^)(BOOL success, NSError *error))callback; // Deprecated

@end
