//
//  MessageNewViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/5/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreViewController.h"

@interface MessageNewViewController : CoreViewController

- (void)updateAccounts:(NSMutableArray *)newAccounts;
- (void)updateAccountsError:(NSError *)error;
- (void)sendMessageSuccess;
- (void)sendMessageError:(NSError *)error;

@end
