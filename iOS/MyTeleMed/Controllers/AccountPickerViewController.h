//
//  AccountPickerViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 5/11/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreViewController.h"
#import "AccountModel.h"

// NOTE: This ViewController is shared by 2 different Storyboard Views: New Message Account Picker and Settings Preferred Account

@interface AccountPickerViewController : CoreViewController <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) BOOL shouldSetPreferredAccount;
@property (nonatomic) NSMutableArray *accounts;
@property (nonatomic) AccountModel *selectedAccount;
@property (nonatomic) NSMutableArray *selectedMessageRecipients;

@end
