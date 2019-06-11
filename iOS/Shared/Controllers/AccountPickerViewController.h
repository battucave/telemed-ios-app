//
//  AccountPickerViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 5/11/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "CoreViewController.h"
#import "AccountModel.h"

@interface AccountPickerViewController : CoreViewController <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSArray *accounts;
@property (nonatomic) AccountModel *selectedAccount;

#ifdef MYTELEMED
	@property (nonatomic) NSString *messageRecipientType; // New (Chat, Forward, and Redirect not used here)
	@property (nonatomic) NSMutableArray *selectedMessageRecipients;
	@property (nonatomic) BOOL shouldSetPreferredAccount;

#elif defined MED2MED
	@property (nonatomic) BOOL shouldCallAccount;
	@property (nonatomic) BOOL shouldSelectAccount;
#endif

@end
