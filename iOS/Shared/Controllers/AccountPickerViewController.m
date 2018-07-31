//
//  AccountPickerViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 5/11/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "AccountPickerViewController.h"
#import "ErrorAlertController.h"
#import "AccountCell.h"
#import "AccountModel.h"

#ifdef MYTELEMED
	#import "MessageRecipientPickerViewController.h"
	#import "MyProfileModel.h"
	#import "PreferredAccountModel.h"
#endif

@interface AccountPickerViewController ()

@property (nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic) IBOutlet UITableView *tableAccounts;
@property (nonatomic) IBOutlet UIView *viewSearchBarContainer;

@property (nonatomic) NSMutableArray *filteredAccounts;
@property (nonatomic) BOOL isLoaded;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic) NSString *textAccount;

@end

@implementation AccountPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Med2Med refers to accounts as medical groups
    #ifdef MED2MED
    	[self setTextAccount:@"Medical Group"];
	
	#else
		[self setTextAccount:@"Account"];
	#endif
	
	// Present search controller from self
	[self setDefinesPresentationContext:YES];
	
	// Initialize search controller
	[self setSearchController:[[UISearchController alloc] initWithSearchResultsController:nil]];
	
	[self.searchController setDelegate:self];
	[self.searchController setDimsBackgroundDuringPresentation:NO];
	[self.searchController setSearchResultsUpdater:self];
	
	// Initialize search bar
	[self.searchController.searchBar setDelegate:self];
	[self.searchController.searchBar setPlaceholder:[NSString stringWithFormat:@"Search %@s", self.textAccount]];
	[self.searchController.searchBar sizeToFit];
	
	// iOS 11+ navigation bar has support for search controller
	if (@available(iOS 11.0, *))
	{
		[self.navigationItem setSearchController:self.searchController];
		
		[self.viewSearchBarContainer setHidden:YES];
		
		for(NSLayoutConstraint *constraint in self.viewSearchBarContainer.constraints)
		{
			if (constraint.firstAttribute == NSLayoutAttributeHeight)
			{
				[constraint setConstant:0.0f];
				break;
			}
		}
	}
	// iOS < 11 places search controller under navigation bar
	else
	{
		// Add auto-generated constraints that allow search bar to animate without disappearing
		[self.searchController.searchBar setTranslatesAutoresizingMaskIntoConstraints:YES];
		
		// Add search bar to search bar's container view
		[self.viewSearchBarContainer addSubview:self.searchController.searchBar];
		
		// Copy constraints from Storyboard's placeholder search bar onto the search controller's search bar
		for(NSLayoutConstraint *constraint in self.searchBar.superview.constraints)
		{
			if (constraint.firstItem == self.searchBar)
			{
				[self.searchBar.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.searchController.searchBar attribute:constraint.firstAttribute relatedBy:constraint.relation toItem:constraint.secondItem attribute:constraint.secondAttribute multiplier:constraint.multiplier constant:constraint.constant]];
			}
			else if (constraint.secondItem == self.searchBar)
			{
				[self.searchBar.superview addConstraint:[NSLayoutConstraint constraintWithItem:constraint.firstItem attribute:constraint.firstAttribute relatedBy:constraint.relation toItem:self.searchController.searchBar attribute:constraint.secondAttribute multiplier:constraint.multiplier constant:constraint.constant]];
			}
		}
		
		for(NSLayoutConstraint *constraint in self.searchBar.constraints)
		{
			[self.searchController.searchBar addConstraint:[NSLayoutConstraint constraintWithItem:self.searchController.searchBar attribute:constraint.firstAttribute relatedBy:constraint.relation toItem:constraint.secondItem attribute:constraint.secondAttribute multiplier:constraint.multiplier constant:constraint.constant]];
		}
		
		// Hide placeholder search bar from Storyboard (UISearchController and its search bar cannot be implemented in Storyboard so we use a placeholder search bar instead)
		[self.searchBar setHidden:YES];
	}
	
	#ifdef MYTELEMED
		// If selected account not already set, then set it to my profile model's MyPreferredAccount
		if (! self.selectedAccount)
		{
			MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
			
			if (myProfileModel.MyPreferredAccount)
			{
				[self setSelectedAccount:myProfileModel.MyPreferredAccount];
			}
		}
	#endif
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableAccounts setTableFooterView:[[UIView alloc] init]];
	
	// Get list of accounts if none were passed from previous controller
	if ([self.accounts count] == 0)
	{
		// Initialize account model
		AccountModel *accountModel = [[AccountModel alloc] init];
		
		[accountModel setDelegate:self];
		[accountModel getAccounts];
	}
	// Reload table with updated data and scroll to any previously selected account
	else
	{
		[self.tableAccounts reloadData];
		
		[self scrollToSelectedAccount];
	}
	
	// Add Keyboard Observers
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	#ifdef MED2MED
		// If user navigated from settings screen
		if (! self.shouldSelectAccount)
		{
			// Disallow selection of medical groups (accounts)
			[self.tableAccounts setAllowsSelection:NO];
			
			// MED2MED PHASE 2 LOGIC (uncomment in phase 2)
			/*/ Add "+" button to allow user to request new medical group (account)
			UIBarButtonItem *buttonSend = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAccountRequest)];
			
			// [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:buttonSend, nil]];
			[self.navigationItem setRightBarButtonItem:buttonSend];*/
		}
	#endif
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove Keyboard Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
	// Obtain keyboard size
	CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	// Convert it to the coordinates of accounts table
	keyboardFrame = [self.tableAccounts convertRect:keyboardFrame fromView:nil];
	
	// Determine if the keyboard covers the table
    CGRect intersect = CGRectIntersection(keyboardFrame, self.tableAccounts.bounds);
	
	// If the keyboard covers the table
    if (! CGRectIsNull(intersect))
    {
    	// Get details of keyboard animation
    	NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    	NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
		
    	// Animate table above keyboard
    	[UIView animateWithDuration:duration delay:0.0 options:curve animations: ^
    	{
    		[self.tableAccounts setContentInset:UIEdgeInsetsMake(0, 0, intersect.size.height, 0)];
    		[self.tableAccounts setScrollIndicatorInsets:UIEdgeInsetsMake(0, 0, intersect.size.height, 0)];
		} completion:nil];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	// Get details of keyboard animation
	NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
	
	// Animate table back down to bottom of screen
	[UIView animateWithDuration:duration delay:0.0 options:curve animations: ^
	{
		[self.tableAccounts setContentInset:UIEdgeInsetsZero];
		[self.tableAccounts setScrollIndicatorInsets:UIEdgeInsetsZero];
	} completion:nil];
}

// Return accounts from account model delegate
- (void)updateAccounts:(NSMutableArray *)accounts
{
	#ifdef MED2MED
		// Filter and store only authorized or pending medical groups (accounts)
		NSPredicate *predicate;
	
		// When selecting medical group (account) for new message, only show authorized medical groups
		if (self.shouldSelectAccount && ! self.shouldCallAccount)
		{
		 	predicate = [NSPredicate predicateWithFormat:@"MyAuthorizationStatus = %@", @"Authorized"];
		}
		// Otherwise show both authorized and pending medical groups
		else
		{
			predicate = [NSPredicate predicateWithFormat:@"MyAuthorizationStatus = %@ OR MyAuthorizationStatus = %@", @"Authorized", @"Pending"];
		}
	
		accounts = [[accounts filteredArrayUsingPredicate:predicate] mutableCopy];
	#endif
	
	[self setAccounts:accounts];
	
	self.isLoaded = YES;
	
	// Reload table with updated data and scroll to any previously selected account
	[self.tableAccounts reloadData];
	
	[self scrollToSelectedAccount];
}

// Return error from account model delegate
- (void)updateAccountsError:(NSError *)error
{
	self.isLoaded = YES;
	
	// Show error message
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}

// Return pending from preferred account model delegate
- (void)savePreferredAccountPending
{
	// Go back to settings (assume success)
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)scrollToSelectedAccount
{
	// Cancel if no account is selected
	if (! self.selectedAccount)
	{
		return;
	}
	
	// Find selected account in accounts (can be used to find account even if it was not originally extracted from accounts array - i.e. MyProfile.MyPreferredAccount)
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID = %@", self.selectedAccount.ID];
	NSArray *results = [self.accounts filteredArrayUsingPredicate:predicate];
	
	if ([results count] > 0)
	{
		// Find table cell that contains the selected account
		AccountModel *account = [results objectAtIndex:0];
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.accounts indexOfObject:account] inSection:0];
		
		// Scroll to cell
		if (indexPath)
		{
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self.tableAccounts scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
			});
		}
	}
}

// Delegate method for updating search results
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSPredicate *predicate;
	NSString *text = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	// Reset filtered accounts
	[self.filteredAccounts removeAllObjects];
	
	// Filter accounts when search string contains space if name and publickey begin with the parts of search text
	if ([text rangeOfString:@" "].location != NSNotFound)
	{
		NSArray *textParts = [text componentsSeparatedByString:@" "];
		NSString *publicKey = [textParts objectAtIndex:0];
		NSString *name = [textParts objectAtIndex:1];
		predicate = [NSPredicate predicateWithFormat:@"(SELF.Name CONTAINS[c] %@) OR (SELF.Name CONTAINS[c] %@ AND SELF.PublicKey BEGINSWITH[c] %@) OR (SELF.Name CONTAINS[c] %@ AND SELF.PublicKey BEGINSWITH[c] %@)", text, publicKey, name, name, publicKey];
	}
	// Filter accounts if name or publickey begins with search text
	else
	{
		predicate = [NSPredicate predicateWithFormat:@"SELF.Name CONTAINS[c] %@ OR SELF.PublicKey BEGINSWITH[c] %@", text, text];
	}
	
	[self setFilteredAccounts:[NSMutableArray arrayWithArray:[self.accounts filteredArrayUsingPredicate:predicate]]];
	
	[self.tableAccounts reloadData];
}

// Delegate method for clicking cancel button on search results
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	// Close search results
	[self.searchController setActive:NO];
	
	// Scroll to selected account
	[self scrollToSelectedAccount];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// Search results table
	if (self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		return MAX([self.filteredAccounts count], 1);
	}
	// Accounts table
	else
	{
		return MAX([self.accounts count], 1);
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	// Med2Med - Only show a header when calling TeleMed
	#ifdef MED2MED
		if (self.shouldCallAccount)
		{
			return 36.0f;
		}
	#endif
	
	return 0.1f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	// Med2Med - Only show a header when calling TeleMed
	#ifdef MED2MED
		if (self.shouldCallAccount)
		{
			static NSString *cellIdentifier = @"AccountHeader";
			
			return [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		}
	#endif
	
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.accounts count] == 0 || (self.searchController.active && self.searchController.searchBar.text.length > 0 && [self.filteredAccounts count] == 0))
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:12.0]];
		[emptyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		// Accounts table
		if ([self.accounts count] == 0)
		{
			[emptyCell.textLabel setText:(self.isLoaded ? [NSString stringWithFormat: @"No %@s found.", [self.textAccount lowercaseString]] : @"Loading...")];
		}
		// Search results table
		else
		{
			[emptyCell.textLabel setText:@"No results."];
		}
		
		return emptyCell;
	}
	
	AccountModel *account;
	
	// Search results table
	if (self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		account = [self.filteredAccounts objectAtIndex:indexPath.row];
	}
	// Accounts table
	else
	{
		account = [self.accounts objectAtIndex:indexPath.row];
	}
	
	static NSString *cellIdentifier = @"AccountCell";
	AccountCell *cell = [self.tableAccounts dequeueReusableCellWithIdentifier:cellIdentifier];
	
	// Set up the cell
	[cell setAccessoryType:UITableViewCellAccessoryNone];
	
	// Set previously selected account as selected and add checkmark
	if (self.selectedAccount && [account.ID isEqualToNumber:self.selectedAccount.ID])
	{
		[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	}
	
	// Set account name label
	[cell.labelName setText:account.Name];
	
	// Set account number label
	[cell.labelPublicKey setText:account.PublicKey];
	
	// Med2Med - Update account number text to medical group number
	#ifdef MED2MED
		[cell.labelAccountNumber setText:@"Medical Group Number:"];
	#endif
	
	// Med2Med - Hide authorization pending label if account is not pending
	// MyTeleMed - Always hide authorization pending label
	#ifdef MED2MED
	if (! [account isPending])
	{
	#endif
		[cell.labelAuthorizationPending setHidden:YES];
		[cell.constraintAuthorizationPendingHeight setConstant:0.0f];
		[cell.constraintAuthorizationPendingTopSpace setConstant:0.0f];
	#ifdef MED2MED
	}
	#endif
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Search results table
	if (self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		// If no filtered accounts, then user clicked "No results."
		if ([self.filteredAccounts count] == 0)
		{
			// Close search results (must execute before scrolling to selected account)
			[self.searchController setActive:NO];
			
			// Scroll to selected account
			[self scrollToSelectedAccount];
			
			return;
		}
		
		// Set selected account
		[self setSelectedAccount:[self.filteredAccounts objectAtIndex:indexPath.row]];
	}
	// Accounts table
	else
	{
		// Set selected account
		[self setSelectedAccount:[self.accounts objectAtIndex:indexPath.row]];
	}
	
	// Get cell in accounts table
	UITableViewCell *cell = [self.tableAccounts cellForRowAtIndexPath:indexPath];
	
	// Completion block for handling selected row after closing the search results
	void(^completion)(UITableViewCell *) = ^(UITableViewCell *cell)
	{
		#ifdef MYTELEMED
			// Add checkmark of selected account
			[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
		
			// If selecting preferred account
			if (self.shouldSetPreferredAccount)
			{
				// Save preferred account to server
				PreferredAccountModel *preferredAccountModel = [[PreferredAccountModel alloc] init];
				
				[preferredAccountModel setDelegate:self];
				[preferredAccountModel savePreferredAccount:self.selectedAccount];
			}
			// If selecting an account for new message
			else
			{
				// Go to MessageRecipientPickerTableViewController
				[self performSegueWithIdentifier:@"showMessageRecipientPickerFromAccountPicker" sender:cell];
			}
		
		#elif MED2MED
			if (self.shouldCallAccount) {
				NSString *callUnavailableMessage = @"";
				
				// Verify that selected account has a phone number
				if (self.selectedAccount.DID != nil && ! [self.selectedAccount.DID isEqualToString:@""])
				{
					// Use phone dialer to make call. Tel works same as telprompt in iOS 10.3+
					NSURL *urlCallTeleMed = [NSURL URLWithString:[NSString stringWithFormat:@"telprompt:%@", self.selectedAccount.DID]];

					// Verify that device can make phone calls
					if ([[UIApplication sharedApplication] canOpenURL:urlCallTeleMed])
					{
						[[UIApplication sharedApplication] openURL:urlCallTeleMed];
					}
					else
					{
						callUnavailableMessage = @"Telephone service is unavailable.";
					}
				
				} else {
					callUnavailableMessage = [NSString stringWithFormat:@"This %@ has no phone number information. Please select another %@ to call about.", self.textAccount, self.textAccount];
				}
				
				if (! [callUnavailableMessage isEqualToString:@""])
				{
					UIAlertController *callUnavailableAlertController = [UIAlertController alertControllerWithTitle:@"Call TeleMed" message:callUnavailableMessage preferredStyle:UIAlertControllerStyleAlert];
					UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
				
					[callUnavailableAlertController addAction:actionOK];
				
					// PreferredAction only supported in 9.0+
					if ([callUnavailableAlertController respondsToSelector:@selector(setPreferredAction:)])
					{
						[callUnavailableAlertController setPreferredAction:actionOK];
					}
				
					// Show Alert
					[self presentViewController:callUnavailableAlertController animated:YES completion:nil];
				}
			
			} else {
				// Add checkmark of selected account
				[cell setAccessoryType:UITableViewCellAccessoryCheckmark];

				[self performSegueWithIdentifier:@"setAccount" sender:self];
			}
		#endif
	};
	
	// Close the search results and execute completion block
	if (self.searchController.active && self.definesPresentationContext)
	{
		[self dismissViewControllerAnimated:YES completion:^{
			completion(cell);
		}];
	}
	// Execute completion block
	else
	{
		completion(cell);
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Get cell in accounts table
	UITableViewCell *cell = [self.tableAccounts cellForRowAtIndexPath:indexPath];
	
	// Remove checkmark of selected account
	[cell setAccessoryType:UITableViewCellAccessoryNone];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	#ifdef MYTELEMED
		// Set Account for MessageRecipientPickerTableViewController
		if ([segue.identifier isEqualToString:@"showMessageRecipientPickerFromAccountPicker"])
		{
			MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.destinationViewController;
			
			// Set account
			[messageRecipientPickerViewController setSelectedAccount:self.selectedAccount];
			
			// Set selected message recipients if previously set (this is simply passed through from MessageNewTableViewController)
			[messageRecipientPickerViewController setSelectedMessageRecipients:[self.selectedMessageRecipients mutableCopy]];
		}
	#endif
	
	// Med2Med - Account for MessageNewTableViewController set by unwind segue
	
	// If no accounts, ensure nothing happens when going back
	if ([self.accounts count] == 0)
	{
		return;
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
	// Avoid superfluous warning that "Attempting to load the view of a view controller while it is deallocating is not allowed and may result in undefined behavior <UISearchController>"
	[self.searchController.view removeFromSuperview];
}


# pragma mark - Med2Med

#ifdef MED2MED
// Required for unwind compatibility with MessageNewUnauthorizedTableViewController (both unwind from AccountRequestTableViewController)
- (IBAction)unwindFromAccountRequest:(UIStoryboardSegue *)segue
{
	NSLog(@"Unwind from Account Request");
}

- (void)showAccountRequest
{
	[self performSegueWithIdentifier:@"showAccountRequest" sender:self];
}
#endif

@end
