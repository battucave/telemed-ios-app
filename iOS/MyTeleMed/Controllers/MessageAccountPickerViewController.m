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

@property (nonatomic) IBOutlet UITableView *tableAccounts;

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
		AccountModel *accountModel = [[AccountModel alloc] init];
		accountModel.delegate = self;
		
		// Get list of Accounts
		[accountModel getAccounts];
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
	
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
	{
		AccountModel *accountModel = [[AccountModel alloc] init];
		
		return [accountModel showOfflineError];
	}
	
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Accounts Error" message:@"There was a problem retrieving your Accounts." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if([self.accounts count] == 0)
	{
		return 1;
	}
		
	return [self.accounts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"AccountCell";
	UITableViewCell *cell = [self.tableAccounts dequeueReusableCellWithIdentifier:cellIdentifier];
	AccountModel *account;
	
	// If no Accounts, create a not found message
	if([self.accounts count] == 0)
	{
		[cell.textLabel setText:(self.isLoaded ? @"No valid accounts available." : @"Loading...")];
		
		return cell;
	}
	
	account = [self.accounts objectAtIndex:indexPath.row];
	
	// Set up the cell
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	[cell setAccessoryType:UITableViewCellAccessoryNone];
	
	// Set previously selected Account as selected and add checkmark
	if(self.selectedAccount && [account.ID isEqualToNumber:self.selectedAccount.ID])
	{
		[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	}
	
	// Set up the cell
	[cell.textLabel setText:[NSString stringWithFormat:@"%@ - %@", account.PublicKey, account.Name]];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Get cell in Accounts Table
	UITableViewCell *cell = [self.tableAccounts cellForRowAtIndexPath:indexPath];
	
	// Add checkmark of selected Account
	[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	
	// Set selected Account (in case user presses back button from next screen)
	[self setSelectedAccount:[self.accounts objectAtIndex:indexPath.row]];
	
	// Go to MessageRecipientPickerTableViewController
	[self performSegueWithIdentifier:@"showMessageRecipientPickerFromMessageAccountPicker" sender:cell];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
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
