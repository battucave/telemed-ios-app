//
//  MessageNewTableViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/5/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "MessageNewTableViewController.h"
#import "ErrorAlertController.h"
#import "MessageComposeTableViewController.h"
#import "AccountPickerViewController.h"
#import "MessageRecipientPickerViewController.h"
#import "AccountModel.h"
#import "NewMessageModel.h"

@interface MessageNewTableViewController ()

@property (nonatomic) MessageComposeTableViewController *messageComposeTableViewController;

@property (nonatomic) AccountModel *accountModel;

@property (nonatomic) NSMutableArray *accounts;
@property (nonatomic) AccountModel *selectedAccount;
@property (nonatomic) NSMutableArray *selectedMessageRecipients;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonSend;

@end

@implementation MessageNewTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Initialize Selected Message Recipients Array
	self.selectedMessageRecipients = [[NSMutableArray alloc] init];
	
	// Initialize Account Model
	[self setAccountModel:[[AccountModel alloc] init]];
	[self.accountModel setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Get list of Accounts
	[self.accountModel getAccounts];
}

// Unwind Segue from MessageRecipientPickerViewController
- (IBAction)setMessageRecipients:(UIStoryboardSegue *)segue
{
	// Obtain reference to Source View Controller
	MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.sourceViewController;
	
	// Save selected Account
	[self setSelectedAccount:messageRecipientPickerViewController.selectedAccount];
	
	// Save selected Message Recipients
	[self setSelectedMessageRecipients:messageRecipientPickerViewController.selectedMessageRecipients];
	
	// Update MessageComposeTableViewController with selected Message Recipient Names
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

// Return Accounts from AccountModel delegate
- (void)updateAccounts:(NSMutableArray *)newAccounts
{
	[self setAccounts:newAccounts];
	
	// If user has only one Account, automatically set it as the selected Account
	if ([newAccounts count] == 1)
	{
		self.selectedAccount = (AccountModel *)[newAccounts objectAtIndex:0];
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
- (void)sendMessagePending
{
	// Go back to Messages (assume success)
	[self.navigationController popViewControllerAnimated:YES];
}

/*/ Return success from NewMessageModel delegate (no longer used)
- (void)sendMessageSuccess
{
 
}

// Return error from NewMessageModel delegate (no longer used)
- (void)sendMessageError:(NSError *)error
{
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
 
	[errorAlertController show:error];
}*/

// Fired from MessageComposeTable to perform segue to either AccountPickerTableViewController or MessageRecipientPickerTableViewController - simplifies passing of data to the picker
- (void)performSegueToMessageRecipientPicker:(id)sender
{
	// User only has one Account so skip the Account selection screen and go straight to MessageRecipientPickerTableViewController
	if ([self.accounts count] == 1)
	{
		[self performSegueWithIdentifier:@"showMessageRecipientPickerFromMessageNew" sender:sender];
	}
	// If user has more than one Account (or Accounts haven't loaded yet due to slow connection), then they must first select an Account from AccountPickerTableViewController
	else
	{
		[self performSegueWithIdentifier:@"showAccountPickerFromMessageNew" sender:sender];
	}
}

// Check required fields to determine if Form can be submitted - Fired from setMessageRecipient and MessageComposeTableViewController delegate
- (void)validateForm:(NSString *)messageText
{
	messageText = [messageText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	[self.buttonSend setEnabled:( ! [messageText isEqualToString:@""] && ! [messageText isEqualToString:self.messageComposeTableViewController.textViewMessagePlaceholder] && self.selectedMessageRecipients != nil && [self.selectedMessageRecipients count] > 0)];
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
		
		// Set Accounts
		[accountPickerViewController setAccounts:self.accounts];
		
		// Set Selected Account if previously set
		[accountPickerViewController setSelectedAccount:self.selectedAccount];
		
		// Set selected Message Recipients if previously set (to pass through to MessageRecipientPickerTableViewController)
		[accountPickerViewController setSelectedMessageRecipients:[self.selectedMessageRecipients mutableCopy]];
	}
	else if ([segue.identifier isEqualToString:@"showMessageRecipientPickerFromMessageNew"])
	{
		MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.destinationViewController;
		
		// Set Account
		[messageRecipientPickerViewController setSelectedAccount:self.selectedAccount];
		
		// Set Message Recipient Type
		[messageRecipientPickerViewController setMessageRecipientType:@"New"];
		
		// Set selected Message Recipients if previously set
		[messageRecipientPickerViewController setSelectedMessageRecipients:[self.selectedMessageRecipients mutableCopy]];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
