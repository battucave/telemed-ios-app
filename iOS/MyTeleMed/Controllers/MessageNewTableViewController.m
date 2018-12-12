//
//  MessageNewTableViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/5/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "MessageNewTableViewController.h"
#import "AccountPickerViewController.h"
#import "ErrorAlertController.h"
#import "MessageComposeTableViewController.h"
#import "MessageRecipientPickerViewController.h"
#import "AccountModel.h"
#import "NewMessageModel.h"

@interface MessageNewTableViewController ()

@property (nonatomic) MessageComposeTableViewController *messageComposeTableViewController;

@property (nonatomic) AccountModel *accountModel;

@property (nonatomic) NSArray *accounts;
@property (nonatomic) AccountModel *selectedAccount;
@property (nonatomic) NSMutableArray *selectedMessageRecipients;

@end

@implementation MessageNewTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Initialize selected message recipients array
	self.selectedMessageRecipients = [[NSMutableArray alloc] init];
	
	// Initialize AccountModel
	[self setAccountModel:[[AccountModel alloc] init]];
	[self.accountModel setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Get list of accounts
	[self.accountModel getAccounts];
}

// Unwind segue from MessageRecipientPickerViewController
- (IBAction)unwindSetMessageRecipients:(UIStoryboardSegue *)segue
{
	// Obtain reference to source view controller
	MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.sourceViewController;
	
	// Save selected account
	[self setSelectedAccount:messageRecipientPickerViewController.selectedAccount];
	
	// Save selected message recipients
	[self setSelectedMessageRecipients:messageRecipientPickerViewController.selectedMessageRecipients];
	
	// Update MessageComposeTableViewController with selected message recipient names
	if ([self.messageComposeTableViewController respondsToSelector:@selector(updateSelectedMessageRecipients:)])
	{
		[self.messageComposeTableViewController updateSelectedMessageRecipients:self.selectedMessageRecipients];
	}
	
	// Validate form
	[self validateForm:self.messageComposeTableViewController.textViewMessage.text];
}

- (IBAction)sendNewMessage:(id)sender
{
	NewMessageModel *newMessageModel = [[NewMessageModel alloc] init];
	
	[newMessageModel setDelegate:self];
	[newMessageModel sendNewMessage:self.messageComposeTableViewController.textViewMessage.text accountID:self.selectedAccount.ID messageRecipientIDs:[self.selectedMessageRecipients valueForKey:@"ID"]];
}

// Return accounts from AccountModel delegate
- (void)updateAccounts:(NSArray *)accounts
{
	[self setAccounts:accounts];
	
	// If user has only one account, automatically set it as the selected account
	if ([accounts count] == 1)
	{
		self.selectedAccount = (AccountModel *)[accounts objectAtIndex:0];
	}
}

// Return error from AccountModel delegate
- (void)updateAccountsError:(NSError *)error
{
	// Show error message
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}

// Return pending from NewMessageModel delegate
- (void)sendNewMessagePending
{
	// Go back to MessagesViewController (assume success)
	[self.navigationController popViewControllerAnimated:YES];
}

/*/ Return success from NewMessageModel delegate (no longer used)
- (void)sendNewMessageSuccess
{
 
}

// Return error from NewMessageModel delegate (no longer used)
- (void)sendNewMessageError:(NSError *)error
{
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
 
	[errorAlertController show:error];
}*/

// Fired from MessageComposeTableViewController to perform segue to either AccountPickerViewController or MessageRecipientPickerViewController - simplifies passing of data to the picker
- (void)performSegueToMessageRecipientPicker:(id)sender
{
	// User only has one account so skip the AccountPickerViewController and go straight to MessageRecipientPickerViewController
	if ([self.accounts count] == 1)
	{
		[self performSegueWithIdentifier:@"showMessageRecipientPickerFromMessageNew" sender:sender];
	}
	// If user has more than one account (or accounts haven't loaded yet due to slow connection), then they must first select an account from AccountPickerViewController
	else
	{
		[self performSegueWithIdentifier:@"showAccountPickerFromMessageNew" sender:sender];
	}
}

// Check required fields to determine if form can be submitted - Fired from setMessageRecipient and MessageComposeTableViewController delegate
- (void)validateForm:(NSString *)messageText
{
	messageText = [messageText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	[self.navigationItem.rightBarButtonItem setEnabled:(! [messageText isEqualToString:@""] && ! [messageText isEqualToString:self.messageComposeTableViewController.textViewMessagePlaceholder] && self.selectedMessageRecipients != nil && [self.selectedMessageRecipients count] > 0)];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"embedMessageNewTable"])
	{
		[self setMessageComposeTableViewController:segue.destinationViewController];
		
		[self.messageComposeTableViewController setDelegate:self];
	}
	else if ([segue.identifier isEqualToString:@"showAccountPickerFromMessageNew"])
	{
		AccountPickerViewController *accountPickerViewController = segue.destinationViewController;
		
		// Set accounts
		[accountPickerViewController setAccounts:self.accounts];
		
		// Set selected account if previously set
		[accountPickerViewController setSelectedAccount:self.selectedAccount];
		
		// Set selected message recipients if previously set (to pass through to MessageRecipientPickerViewController)
		[accountPickerViewController setSelectedMessageRecipients:[self.selectedMessageRecipients mutableCopy]];
	}
	else if ([segue.identifier isEqualToString:@"showMessageRecipientPickerFromMessageNew"])
	{
		MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.destinationViewController;
		
		// Set account
		[messageRecipientPickerViewController setSelectedAccount:self.selectedAccount];
		
		// Set message recipient type
		[messageRecipientPickerViewController setMessageRecipientType:@"New"];
		
		// Set selected message recipients if previously set
		[messageRecipientPickerViewController setSelectedMessageRecipients:[self.selectedMessageRecipients mutableCopy]];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
