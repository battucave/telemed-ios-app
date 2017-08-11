//
//  AccountPickerViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 5/11/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "AccountPickerViewController.h"
#import "MessageRecipientPickerViewController.h"
#import "PreferredAccountCell.h"
#import "AccountModel.h"
#import "MyProfileModel.h"
#import "PreferredAccountModel.h"

@interface AccountPickerViewController ()

@property (nonatomic) AccountModel *accountModel;

@property (nonatomic) IBOutlet UIView *viewSearchBarContainer;
@property (nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic) IBOutlet UITableView *tableAccounts;

@property (nonatomic, strong) UISearchController *searchController;

@property (nonatomic) NSMutableArray *filteredAccounts;
@property (nonatomic) NSString *storyboardID;
@property (nonatomic) BOOL isLoaded;

@end

@implementation AccountPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Initialize Storyboard ID
	[self setStoryboardID:[self valueForKey:@"storyboardIdentifier"]];
	
	// If accounts were not pre-loaded (slow connection in MessageNewViewController), then load them here
	if([self.accounts count] == 0)
	{
		// Initialize Account Model
		[self setAccountModel:[[AccountModel alloc] init]];
		[self.accountModel setDelegate:self];
		
		// Get list of Accounts
		[self.accountModel getAccounts];
	}
	
	// If Selected Account not already set, then set it to MyProfileModel's MyPreferredAccount
	if( ! self.selectedAccount)
	{
		MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
		
		if(myProfileModel.MyPreferredAccount)
		{
			[self setSelectedAccount:myProfileModel.MyPreferredAccount];
		}
	}
	
	// Initialize Search Controller
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	
	[self.searchController setDelegate:self];
	[self.searchController setDimsBackgroundDuringPresentation:NO];
	//[self.searchController setHidesNavigationBarDuringPresentation:NO];
	[self.searchController setSearchResultsUpdater:self];
	
	self.definesPresentationContext = YES;
	
	// Initialize Search Bar
	[self.searchController.searchBar setDelegate:self];
	[self.searchController.searchBar setPlaceholder:@"Search Accounts"];
	[self.searchController.searchBar sizeToFit];
	
	// Add auto-generated constraints that allow Search Bar to animate without disappearing
	//[self.searchController.searchBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	[self.searchController.searchBar setTranslatesAutoresizingMaskIntoConstraints:YES];
	
	// Add Search Bar to Search Bar's Container View
	[self.viewSearchBarContainer addSubview:self.searchController.searchBar];
	
	// Copy constraints from Storyboard's placeholder Search Bar onto the Search Controller's Search Bar
	for(NSLayoutConstraint *constraint in self.searchBar.superview.constraints)
	{
		if(constraint.firstItem == self.searchBar)
		{
			[self.searchBar.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.searchController.searchBar attribute:constraint.firstAttribute relatedBy:constraint.relation toItem:constraint.secondItem attribute:constraint.secondAttribute multiplier:constraint.multiplier constant:constraint.constant]];
		}
		else if(constraint.secondItem == self.searchBar)
		{
			[self.searchBar.superview addConstraint:[NSLayoutConstraint constraintWithItem:constraint.firstItem attribute:constraint.firstAttribute relatedBy:constraint.relation toItem:self.searchController.searchBar attribute:constraint.secondAttribute multiplier:constraint.multiplier constant:constraint.constant]];
		}
	}
	
	for(NSLayoutConstraint *constraint in self.searchBar.constraints)
	{
		[self.searchController.searchBar addConstraint:[NSLayoutConstraint constraintWithItem:self.searchController.searchBar attribute:constraint.firstAttribute relatedBy:constraint.relation toItem:constraint.secondItem attribute:constraint.secondAttribute multiplier:constraint.multiplier constant:constraint.constant]];
	}
	
	// Hide placholder Search Bar from Storyboard (UISearchController and its SearchBar cannot be implemented in Storyboard so we use a placeholder SearchBar instead)
	[self.searchBar setHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// If account was previously selected, scroll to it
	if(self.selectedAccount && [self.accounts count] > 0)
	{
		[self.tableAccounts reloadData];
		
		// Scroll to selected Account
		[self scrollToSelectedAccount];
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	// Reset Search Results (put here because it's animation must occur AFTER any segue)
	if(self.searchController.active)
	{
		[self.searchController setActive:NO];
	}
}

// Return Accounts from AccountModel delegate
- (void)updateAccounts:(NSMutableArray *)newAccounts
{
	[self setAccounts:newAccounts];
	
	self.isLoaded = YES;
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableAccounts reloadData];
		
		// If account was previously selected, scroll to it
		if(self.selectedAccount)
		{
			// Scroll to selected Account
			[self scrollToSelectedAccount];
		}
	});
}

// Return error from AccountModel delegate
- (void)updateAccountsError:(NSError *)error
{
	self.isLoaded = YES;
	
	// Show error message
	[self.accountModel showError:error];
}

// Return pending from PreferredAccountModel delegate
- (void)savePreferredAccountPending
{
	// Go back to Settings (assume success)
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)scrollToSelectedAccount
{
	// Find Selected Account in Accounts (can be used to find Account even if it was not originally extracted from Accounts array - i.e. MyProfile.MyPreferredAccount)
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID = %@", self.selectedAccount.ID];
	NSArray *results = [self.accounts filteredArrayUsingPredicate:predicate];
	
	if([results count] > 0)
	{
		// Find and delete table cell that contains Comment
		AccountModel *account = [results objectAtIndex:0];
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.accounts indexOfObject:account] inSection:0];
		
		// Scroll to cell
		if(indexPath)
		{
			[self.tableAccounts scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
		}
	}
}

// Delegate Method for Updating Search Results
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSPredicate *predicate;
	NSString *text = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	NSLog(@"Text: %@", text);
	
	// Reset Filtered Message Recipients
	[self.filteredAccounts removeAllObjects];
	
	// Filter Accounts when search string contains space if Name and PublicKey begin with the parts of search text
	if([text rangeOfString:@" "].location != NSNotFound)
	{
		NSArray *textParts = [text componentsSeparatedByString:@" "];
		NSString *publicKey = [textParts objectAtIndex:0];
		NSString *name = [textParts objectAtIndex:1];
		predicate = [NSPredicate predicateWithFormat:@"(SELF.Name CONTAINS[c] %@) OR (SELF.Name CONTAINS[c] %@ AND SELF.PublicKey BEGINSWITH[c] %@) OR (SELF.Name CONTAINS[c] %@ AND SELF.PublicKey BEGINSWITH[c] %@)", text, publicKey, name, name, publicKey];
	}
	// Filter Accounts if Name or PublicKey begins with search text
	else
	{
		predicate = [NSPredicate predicateWithFormat:@"SELF.Name CONTAINS[c] %@ OR SELF.PublicKey BEGINSWITH[c] %@", text, text];
	}
	
	[self setFilteredAccounts:[NSMutableArray arrayWithArray:[self.accounts filteredArrayUsingPredicate:predicate]]];
	
	[self.tableAccounts reloadData];
}

// Delegate Method for clicking Cancel button on Search Results
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	// Close Search Results
	[self.searchController setActive:NO];
	
	// Scroll to selected Account
	[self scrollToSelectedAccount];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// Search Results Table
	if(self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		if([self.filteredAccounts count] == 0)
		{
			return 1;
		}
		
		return [self.filteredAccounts count];
	}
	// Accounts Table
	else
	{
		if([self.accounts count] == 0)
		{
			return 1;
		}
			
		return [self.accounts count];
	}
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 58.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Return default height if no Account available
	if([self.accounts count] == 0)
	{
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	}
	
	return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([self.accounts count] == 0 || (self.searchController.active && self.searchController.searchBar.text.length > 0 && [self.filteredAccounts count] == 0))
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:12.0]];
		// [emptyCell.textLabel setText:(self.isLoaded ? @"No messages found." : @"Loading...")];
		[emptyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		// Message recipients table
		if([self.accounts count] == 0)
		{
			[emptyCell.textLabel setText:(self.isLoaded ? @"No messages found." : @"Loading...")];
		}
		// Search results table
		else
		{
			[emptyCell.textLabel setText:@"No results."];
		}
		
		return emptyCell;
	}
	
	static NSString *cellIdentifier = @"PreferredAccountCell";
	PreferredAccountCell *cell = [self.tableAccounts dequeueReusableCellWithIdentifier:cellIdentifier];
	AccountModel *account;
	
	// Set up the cell
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	[cell setAccessoryType:UITableViewCellAccessoryNone];
	
	// Search Results table
	if(self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		account = [self.filteredAccounts objectAtIndex:indexPath.row];
	}
	// Message Recipients table
	else
	{
		account = [self.accounts objectAtIndex:indexPath.row];
	}
	
	// Set previously selected Account as selected and add checkmark
	if(self.selectedAccount && [account.ID isEqualToNumber:self.selectedAccount.ID])
	{
		[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	}
	
	// Set Account Name label
	[cell.accountName setText:account.Name];
	
	// Set Account Number label
	[cell.accountPublicKey setText:account.PublicKey];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
	// Search Results Table
	if(self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		// If no Filtered Message Recipients, then user clicked "No results."
		if([self.filteredAccounts count] == 0)
		{
			// Close Search Results (must execute before scrolling to selected Account
			[self.searchController setActive:NO];
			
			// Scroll to selected Account
			[self scrollToSelectedAccount];
			
			return;
		}
		
		// Set selected Account (in case user presses back button from next screen)
		[self setSelectedAccount:[self.filteredAccounts objectAtIndex:indexPath.row]];
		
		// Get cell in Accounts Table
		int indexRow = (int)[self.accounts indexOfObject:self.selectedAccount];
		cell = [self.tableAccounts cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0]];
		
		// Select cell (not needed - if user presses back button from next screen, viewWillAppear method handles selecting the selected Account)
		//[self.tableAccounts selectRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
	// Message Recipients Table
	else
	{
		// Set selected Account (in case user presses back button from next screen)
		[self setSelectedAccount:[self.accounts objectAtIndex:indexPath.row]];
		
		// Get cell in Message Recipients Table
		cell = [self.tableAccounts cellForRowAtIndexPath:indexPath];
	}
	
	// Add checkmark of selected Account
	[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	
	// If using NewMessageAccountPicker view from storyboard
	if([self.storyboardID isEqualToString:@"NewMessageAccountPicker"])
	{
		// Go to MessageRecipientPickerTableViewController
		[self performSegueWithIdentifier:@"showMessageRecipientPickerFromAccountPicker" sender:cell];
	}
	// If using SettingsPreferredAccountPicker view from storyboard
	else if([self.storyboardID isEqualToString:@"SettingsPreferredAccountPicker"])
	{
		// Save Preferred Account to server
		PreferredAccountModel *preferredAccountModel = [[PreferredAccountModel alloc] init];
		
		[preferredAccountModel setDelegate:self];
		[preferredAccountModel savePreferredAccount:self.selectedAccount];
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
	// Search Results Table
	if(self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		// Close Search Results
		[self.searchController setActive:NO];
		
		// Get cell in Message Accounts Table
		int indexRow = (int)[self.accounts indexOfObject:self.selectedAccount];
		cell = [self.tableAccounts cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0]];
		
		// Deselect cell
		[self.tableAccounts deselectRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0] animated:NO];
	}
	// Message Recipients Table
	else
	{
		// Get cell in Message Accounts Table
		cell = [self.tableAccounts cellForRowAtIndexPath:indexPath];
	}
	
	// Remove selected Account
	[self setSelectedAccount:nil];
	
	// Remove checkmark of selected Message Recipient
	[cell setAccessoryType:UITableViewCellAccessoryNone];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Set Account for MessageRecipientPickerTableViewController
	if([[segue identifier] isEqualToString:@"showMessageRecipientPickerFromAccountPicker"])
	{
		MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.destinationViewController;
		
		// Set Account
		[messageRecipientPickerViewController setSelectedAccount:self.selectedAccount];
		
		// Set selected Message Recipients if previously set (this is simply passed through from Message New)
		[messageRecipientPickerViewController setSelectedMessageRecipients:[self.selectedMessageRecipients mutableCopy]];
	}
	// If no Accounts, ensure nothing happens when going back
	else if([self.accounts count] == 0)
	{
		return;
	}}

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

@end
