//
//  SettingsPasswordTableViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/11/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsPasswordTableViewController : UITableViewController <UITextFieldDelegate>

- (void)updateSecuritySuccess;
- (void)updateSecurityError:(NSError *)error;
- (void)updateSecurityInvalidError:(NSError *)error;

@end
