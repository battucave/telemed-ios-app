//
//  MessageAccountPickerViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 5/11/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "MessageAccountPickerViewController.h"
#import "MessageRecipientPickerViewController.h"
#import "AccountModel.h"

@interface MessageAccountPickerViewController ()

@property (nonatomic) AccountModel *accountModel;

@property (nonatomic) IBOutlet UIView *viewSearchBarContainer;
@property (nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic) IBOutlet UITableView *tableAccounts;

@property (nonatomic, strong) UISearchController *searchController;

@property (nonatomic) NSMutableArray *filteredAccounts;
@property (nonatomic) BOOL isLoaded;

@end

@implementation MessageAccountPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// If accounts were not loaded in MessageNewViewController (slow connection), then load them here
	if([self.accounts count] == 0)
	{
		// Initialize Account Model
		[self setAccountModel:[[AccountModel alloc] init]];
		[self.accountModel setDelegate:self];
		
		// Get list of Accounts
		[self.accountModel getAccounts];
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
	if(self.selectedAccount)
	{
		[self.tableAccounts reloadData];
		
		// Get cell for selected Account in Accounts Table
		int indexRow = (int)[self.accounts indexOfObject:self.selectedAccount];
		
		// Scroll to cell
		[self.tableAccounts scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	// Reset Search Results (put here because it's animation must occur AFTER segue to Message Recipient Picker)
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
	});
}

// Return error from AccountModel delegate
- (void)updateAccountsError:(NSError *)error
{
	self.isLoaded = YES;
	
	// Show error message
	[self.accountModel showError:error];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"AccountCell";
	UITableViewCell *cell = [self.tableAccounts dequeueReusableCellWithIdentifier:cellIdentifier];
	AccountModel *account;
	
	// Set up the cell
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	[cell setAccessoryType:UITableViewCellAccessoryNone];
	
	// Search Results Table
	if(self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		// If no Filtered Message Recipients, create a not found message
		if([self.filteredAccounts count] == 0)
		{
			[cell.textLabel setText:@"No results."];
			
			return cell;
		}
		
		account = [self.filteredAccounts objectAtIndex:indexPath.row];
	}
	// Message Recipients Table
	else
	{
		// If no Accounts, create a not found message
		if([self.accounts count] == 0)
		{
			[cell.textLabel setText:(self.isLoaded ? @"No valid accounts available." : @"Loading...")];
			
			return cell;
		}
		
		account = [self.accounts objectAtIndex:indexPath.row];
	}
	
	// Set previously selected Account as selected and add checkmark
	if(self.selectedAccount && [account.ID isEqualToNumber:self.selectedAccount.ID])
	{
		[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	}
	
	// Set cell label
	[cell.textLabel setText:[NSString stringWithFormat:@"%@ - %@", account.PublicKey, account.Name]];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
	// Search Results Table
	if(self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		// Set selected Account (in case user presses back button from next screen)
		[self setSelectedAccount:[self.filteredAccounts objectAtIndex:indexPath.row]];
		
		// Get cell in Accounts Table
		int indexRow = (int)[self.accounts indexOfObject:self.selectedAccount];
		cell = [self.tableAccounts cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0]];
		
		// Select cell
		[self.tableAccounts selectRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
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
	
	// Go to MessageRecipientPickerTableViewController
	[self performSegueWithIdentifier:@"showMessageRecipientPickerFromMessageAccountPicker" sender:cell];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
	// Search Results Table
	if(self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
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
	if([[segue identifier] isEqualToString:@"showMessageRecipientPickerFromMessageAccountPicker"])
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

@end
