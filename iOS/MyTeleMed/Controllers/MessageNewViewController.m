//
//  MessageNewViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/5/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "MessageNewViewController.h"
#import "MessageComposeTableViewController.h"
#import "MessageAccountPickerViewController.h"
#import "MessageRecipientPickerViewController.h"
#import "AccountModel.h"
#import "NewMessageModel.h"

@interface MessageNewViewController ()

@property (nonatomic) MessageComposeTableViewController *messageComposeTableViewController;

@property (nonatomic, getter=theNewMessageModel) NewMessageModel *newMessageModel;

@property (nonatomic) NSMutableArray *accounts;
@property (nonatomic) AccountModel *selectedAccount;
@property (nonatomic) NSMutableArray *selectedMessageRecipients;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonSend;

@end

@implementation MessageNewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Initialize Selected Message Recipients Array
	self.selectedMessageRecipients = [[NSMutableArray alloc] init];
	
	// Initialize Account Model
	AccountModel *accountModel = [[AccountModel alloc] init];
	accountModel.delegate = self;
	
	// Get list of Accounts
	[accountModel getAccounts];
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
	if([self.messageComposeTableViewController respondsToSelector:@selector(updateSelectedMessageRecipients:)])
	{
		[self.messageComposeTableViewController updateSelectedMessageRecipients:self.selectedMessageRecipients];
	}
	
	// Validate form
	[self validateForm:self.messageComposeTableViewController.textViewMessage.text];
}

- (IBAction)sendNewMessage:(id)sender
{
	[self setNewMessageModel:[[NewMessageModel alloc] init]];
	[self.newMessageModel setDelegate:self];
	
	//NSString *messageText = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self.messageComposeTableViewController.textViewMessage.text, NULL, (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ", CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
	
	[self.newMessageModel sendNewMessage:self.messageComposeTableViewController.textViewMessage.text accountID:self.selectedAccount.ID messageRecipientIDs:[self.selectedMessageRecipients valueForKey:@"ID"]];
}

// Return Accounts from AccountModel delegate
- (void)updateAccounts:(NSMutableArray *)newAccounts
{
	[self setAccounts:newAccounts];
	
	// If user has only one Account, automatically set it as the selected Account
	if([newAccounts count] == 1)
	{
		self.selectedAccount = (AccountModel *)[newAccounts objectAtIndex:0];
	}
}

// Return error from AccountModel delegate
- (void)updateAccountsError:(NSError *)error
{
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
	{
		AccountModel *accountModel = [[AccountModel alloc] init];
		
		return [accountModel showOfflineError];
	}
	
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Accounts Error" message:@"There was a problem retrieving your Accounts." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
}

// Return success from NewMessageModel delegate
- (void)sendMessageSuccess
{
	UIAlertView *successAlertView = [[UIAlertView alloc] initWithTitle:@"New Message" message:@"Message sent successfully." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[successAlertView show];
	
	// Go back to Messages
	[self.navigationController popViewControllerAnimated:YES];
}

// Return error from NewMessageModel delegate
- (void)sendMessageError:(NSError *)error
{
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
	{
		return [self.newMessageModel showOfflineError];
	}
	
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"New Message Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
}

// Fired from MessageComposeTable to perform segue to either MessageAccountPickerTableViewController or MessageRecipientPickerTableViewController - simplifies passing of data to the picker
- (void)performSegueToMessageRecipientPicker:(id)sender
{
	// User only has one Account so skip the Account selection screen and go straight to MessageRecipientPickerTableViewController
	if([self.accounts count] == 1)
	{
		[self performSegueWithIdentifier:@"showMessageRecipientPickerFromMessageNew" sender:sender];
	}
	// If user has more than one Account (or Accounts haven't loaded yet due to slow connection), then they must first select an Account from MessageAccountPickerTableViewController
	else
	{
		[self performSegueWithIdentifier:@"showMessageAccountPickerFromMessageNew" sender:sender];
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
	if([segue.identifier isEqualToString:@"embedMessageNewTable"])
	{
		[self setMessageComposeTableViewController:segue.destinationViewController];
		
		[self.messageComposeTableViewController setDelegate:self];
	}
	else if([segue.identifier isEqualToString:@"showMessageAccountPickerFromMessageNew"])
	{
		MessageAccountPickerViewController *messageAccountPickerViewController = segue.destinationViewController;
		
		// Set Accounts
		[messageAccountPickerViewController setAccounts:self.accounts];
		
		// Set Selected Account if previously set
		[messageAccountPickerViewController setSelectedAccount:self.selectedAccount];
		
		// Set selected Message Recipients if previously set (to pass through to MessageRecipientPickerTableViewController)
		[messageAccountPickerViewController setSelectedMessageRecipients:[self.selectedMessageRecipients mutableCopy]];
	}
	else if([segue.identifier isEqualToString:@"showMessageRecipientPickerFromMessageNew"])
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
