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

@property (nonatomic, strong) UISearchController *searchController;

@property (nonatomic) NSMutableArray *filteredAccounts;
@property (nonatomic) BOOL isLoaded;
@property (nonatomic) NSString *textAccount;

@end

@implementation AccountPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// MedToMed refers to accounts as medical groups
    #ifdef MEDTOMED
    	[self setTextAccount:@"Medical Group"];
	
	#else
		[self setTextAccount:@"Account"];
	#endif
	
	// Initialize search controller
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	
	[self.searchController setDelegate:self];
	[self.searchController setDimsBackgroundDuringPresentation:NO];
	//[self.searchController setHidesNavigationBarDuringPresentation:NO];
	[self.searchController setSearchResultsUpdater:self];
	
	// Commented out because it causes issues when attempting to navigate to another screen on search result selection
	// self.definesPresentationContext = YES;
	
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
		if ( ! self.selectedAccount)
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
	
	// Get list of accounts
	if ([self.accounts count] == 0)
	{
		// Initialize account model
		AccountModel *accountModel = [[AccountModel alloc] init];
		
		[accountModel setDelegate:self];
		[accountModel getAccounts];
	}
	// If account was previously selected, scroll to it
	else
	{
		[self.tableAccounts reloadData];
		
		[self scrollToSelectedAccount];
	}
	
	#ifdef MEDTOMED
		// If user navigated from settings screen
		if (! self.shouldSelectAccount)
		{
			// Disallow selection of medical groups (accounts)
			[self.tableAccounts setAllowsSelection:NO];
			
			// Add "+" button to allow user to request new medical group (account)
			UIBarButtonItem *buttonSend = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAccountRequest)];
			
			// [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:buttonSend, nil]];
			[self.navigationItem setRightBarButtonItem:buttonSend];
		}
	#endif
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	// Reset search results (put here because its animation must occur AFTER any segue)
	if (self.searchController.active)
	{
		[self.searchController setActive:NO];
	}
}

// Return accounts from account model delegate
- (void)updateAccounts:(NSMutableArray *)accounts
{
	#ifdef MEDTOMED
		// Filter and store only authorized or pending medical groups (accounts)
		NSPredicate *predicate;
	
		// When selecting medical group (account) for new message, only show authorized medical groups
		if (self.shouldSelectAccount)
		{
		 	predicate = [NSPredicate predicateWithFormat:@"MyAuthorizationStatus = %@", @"Authorized"];
		}
		// When viewing "My Medical Groups", show authorized and pending medical groups
		else
		{
			predicate = [NSPredicate predicateWithFormat:@"MyAuthorizationStatus = %@ OR MyAuthorizationStatus = %@", @"Authorized", @"Pending"];
		}
	
		accounts = [[accounts filteredArrayUsingPredicate:predicate] mutableCopy];
	#endif
	
	[self setAccounts:accounts];
	
	self.isLoaded = YES;
	
	// If account was previously selected, scroll to it
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
		// Find table cell that contains selected account
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
		if ([self.filteredAccounts count] == 0)
		{
			return 1;
		}
		
		return [self.filteredAccounts count];
	}
	// Accounts table
	else
	{
		if ([self.accounts count] == 0)
		{
			return 1;
		}
			
		return [self.accounts count];
	}
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 46.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Return default height if no accounts available
	if ([self.accounts count] == 0)
	{
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	}
	
	return UITableViewAutomaticDimension;
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
	
	// MedToMed - Update account number text to medical group number
	#ifdef MEDTOMED
		[cell.labelAccountNumber setText:@"Medical Group Number:"];
	#endif
	
	// MedToMed - Hide authorization pending label if account is not pending
	// MyTeleMed - Always hide authorization pending label
	#ifdef MEDTOMED
	if (! [account isPending])
	{
	#endif
		[cell.labelAuthorizationPending setHidden:YES];
		[cell.constraintAuthorizationPendingHeight setConstant:0.0f];
		[cell.constraintAuthorizationPendingTopSpace setConstant:0.0f];
	#ifdef MEDTOMED
	}
	#endif
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
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
		
		// Set selected account (in case user presses back button from next screen)
		[self setSelectedAccount:[self.filteredAccounts objectAtIndex:indexPath.row]];
		
		// Get cell in accounts table
		int indexRow = (int)[self.accounts indexOfObject:self.selectedAccount];
		cell = [self.tableAccounts cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0]];
		
		// Select cell (not needed - if user presses back button from next screen, viewWillAppear method handles selecting the selected account)
		//[self.tableAccounts selectRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
	// Accounts table
	else
	{
		// Set selected account (in case user presses back button from next screen)
		[self setSelectedAccount:[self.accounts objectAtIndex:indexPath.row]];
		
		// Get cell in accounts table
		cell = [self.tableAccounts cellForRowAtIndexPath:indexPath];
	}
	
	// Add checkmark of selected account
	[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	
	#ifdef MYTELEMED
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
	
	#elif MEDTOMED
		[self performSegueWithIdentifier:@"setAccount" sender:self];
	#endif
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
	// Search results table
	if (self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		// Close search results
		[self.searchController setActive:NO];
		
		// Get cell in message accounts table
		int indexRow = (int)[self.accounts indexOfObject:self.selectedAccount];
		cell = [self.tableAccounts cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0]];
		
		// Deselect cell
		[self.tableAccounts deselectRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0] animated:NO];
	}
	// Accounts table
	else
	{
		// Get cell in accounts table
		cell = [self.tableAccounts cellForRowAtIndexPath:indexPath];
	}
	
	// Remove selected account
	[self setSelectedAccount:nil];
	
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
	
	// MedToMed - Account for MessageNewTableViewController set by unwind segue
	
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


# pragma mark - MedToMed

#ifdef MEDTOMED
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
