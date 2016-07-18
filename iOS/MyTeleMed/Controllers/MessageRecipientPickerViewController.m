//
//  MessageRecipientPickerViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/7/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "MessageRecipientPickerViewController.h"
#import "ChatParticipantModel.h"
#import "MessageRecipientModel.h"

@interface MessageRecipientPickerViewController ()

@property (nonatomic) ChatParticipantModel *chatParticipantModel;
@property (nonatomic) MessageRecipientModel *messageRecipientModel;

@property (nonatomic) IBOutlet UITableView *tableMessageRecipients;
@property (nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic) NSMutableArray *messageRecipients;
@property (nonatomic) NSMutableArray *filteredMessageRecipients;
@property (nonatomic) BOOL isLoaded;

@end

@implementation MessageRecipientPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Initialize Chat Participant Model (only used for Chat)
	[self setChatParticipantModel:[[ChatParticipantModel alloc] init]];
	[self.chatParticipantModel setDelegate:self];
	
	// Initialize Message Recipient Model (only used for New and Forward Message)
	[self setMessageRecipientModel:[[MessageRecipientModel alloc] init]];
	[self.messageRecipientModel setDelegate:self];
	
	// Initialize selected Recipients
	if(self.selectedMessageRecipients == nil)
	{
		[self setSelectedMessageRecipients:[[NSMutableArray alloc] init]];
	}
	
	// Initialize Filtered Message Recipients
	[self setFilteredMessageRecipients:[[NSMutableArray alloc] init]];
	
	// Load list of Message Recipients
	[self reloadMessageRecipients];
	
	// Set Search Delegates
	self.searchBar.delegate = self;
	self.searchDisplayController.delegate = self;
}

// Get Message Recipients
- (void)reloadMessageRecipients
{
	// Get Participants for Chat
	if([self.messageRecipientType isEqualToString:@"Chat"])
	{
		// TEMPORARY
		//[self.chatParticipantModel getChatParticipants];
		[self.messageRecipientModel getNewMessageRecipients:[NSNumber numberWithInteger:250795]];
	}
	// Get Recipients for Forward Message
	else if([self.messageRecipientType isEqualToString:@"Forward"])
	{
		[self.messageRecipientModel getForwardMessageRecipients:self.message.ID];
	}
	// Get Recipients for New Message
	else
	{
		[self.messageRecipientModel getNewMessageRecipients:self.selectedAccount.ID];
	}
}

// Return Chat Participants from ChatParticipationModel delegate
- (void)updateChatParticipants:(NSMutableArray *)newChatParticipants
{
	[self setMessageRecipients:newChatParticipants];
	
	self.isLoaded = YES;
	
	// Reload table with updated data
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableMessageRecipients reloadData];
	});
}

// Return error from ChatParticipantModel delegate
- (void)updateChatParticipantsError:(NSError *)error
{
	self.isLoaded = YES;
	
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
	{
		return [self.chatParticipantModel showOfflineError];
	}
	
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Participants Error" message:@"There was a problem retrieving Participants for your Chat. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
}

// Return Message Recipients from MessageRecipientModel delegate
- (void)updateMessageRecipients:(NSMutableArray *)newMessageRecipients
{
	[self setMessageRecipients:newMessageRecipients];
	
	self.isLoaded = YES;
	
	// Delete any selected Message Recipients that do not exist in the Message Recipients list (because they belong to a different Account)
	NSMutableIndexSet *removeIndexes = [[NSMutableIndexSet alloc] init];
	
	[self.selectedMessageRecipients enumerateObjectsUsingBlock:^(MessageRecipientModel *selectedMessageRecipient, NSUInteger index, BOOL * _Nonnull stop)
	{
		// Determine if selected Message Recipient exists in Message Recipients
		NSUInteger messageRecipientIndex = [newMessageRecipients indexOfObjectPassingTest:^BOOL(MessageRecipientModel *messageRecipient, NSUInteger foundIndex, BOOL *stop)
		{
			return [messageRecipient.ID isEqualToNumber:selectedMessageRecipient.ID];
		}];
		
		// If selected Message Recipient does not exist in Message Recipients, remove it
		if(messageRecipientIndex == NSNotFound)
		{
			[removeIndexes addIndex:index];
		}
	}];
	
	[self.selectedMessageRecipients removeObjectsAtIndexes:removeIndexes];
	
	// Reload table with updated data
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableMessageRecipients reloadData];
	});
}

// Return error from MessageRecipientModel delegate
- (void)updateMessageRecipientsError:(NSError *)error
{
	self.isLoaded = YES;
	
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
	{
		return [self.messageRecipientModel showOfflineError];
	}
	
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Recipients Error" message:@"There was a problem retrieving Recipients for your Message. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
}

// Filter Search Results
- (void)filterSearchResults:(NSString *)text scope:(NSString *)scope
{
	NSPredicate *predicate;
	text = [[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""];
	
	// Reset Filtered Message Recipients
	[self.filteredMessageRecipients removeAllObjects];
	
	// Filter Message Recipients when search string contains space if First and Last Names begin with the Name parts of search text
	if([text rangeOfString:@" "].location != NSNotFound)
	{
		NSArray *nameParts = [text componentsSeparatedByString:@" "];
		NSString *firstName = [nameParts objectAtIndex:0];
		NSString *lastName = [nameParts objectAtIndex:1];
		predicate = [NSPredicate predicateWithFormat:@"(SELF.FirstName BEGINSWITH[c] %@ AND SELF.LastName BEGINSWITH[c] %@) OR (SELF.FirstName BEGINSWITH[c] %@ AND SELF.LastName BEGINSWITH[c] %@)", firstName, lastName, lastName, firstName];
	}
	// Filter Message Recipients if either First or Last Name begins with search text
	else
	{
		predicate = [NSPredicate predicateWithFormat:@"SELF.FirstName BEGINSWITH[c] %@ OR SELF.LastName BEGINSWITH[c] %@", text, text];
	}
	
	[self setFilteredMessageRecipients:[NSMutableArray arrayWithArray:[self.messageRecipients filteredArrayUsingPredicate:predicate]]];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	// Reload when search text changes
	[self filterSearchResults:searchString scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
	
	return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// Search Results Table
	if(tableView == self.searchDisplayController.searchResultsTableView)
	{
		if([self.filteredMessageRecipients count] == 0)
		{
			return 1;
		}
		
		return [self.filteredMessageRecipients count];
	}
	// Message Recipients Table
	else
	{
		if([self.messageRecipients count] == 0)
		{
			return 1;
		}
		
		return [self.messageRecipients count];
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"MessageRecipientCell";
	UITableViewCell *cell = [self.tableMessageRecipients dequeueReusableCellWithIdentifier:cellIdentifier];
	MessageRecipientModel *messageRecipient;
	
	// Search Results Table
	if(tableView == self.searchDisplayController.searchResultsTableView)
	{
		// If no Filtered Message Recipients, create a not found message
		if([self.filteredMessageRecipients count] == 0)
		{
			[cell.textLabel setText:@"No results."];
			
			return cell;
		}
		
		messageRecipient = [self.filteredMessageRecipients objectAtIndex:indexPath.row];
	}
	// Message Recipients Table
	else
	{
		// If no Message Recipients, create a not found message
		if([self.messageRecipients count] == 0)
		{
			[cell.textLabel setText:(self.isLoaded ? @"No valid recipients available." : @"Loading...")];
			
			return cell;
		}
		
		messageRecipient = [self.messageRecipients objectAtIndex:indexPath.row];
		
		// Set up the cell
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
		[cell setAccessoryType:UITableViewCellAccessoryNone];
		
		// Determine if Message Recipient already exists in selected Recipients
		NSUInteger messageRecipientIndex = [self.selectedMessageRecipients indexOfObjectPassingTest:^BOOL(MessageRecipientModel *messageRecipient2, NSUInteger foundIndex, BOOL *stop)
		{
			return [messageRecipient2.ID isEqualToNumber:messageRecipient.ID];
		}];
		
		// Set previously selected Message Recipients as selected and add checkmark
		if(messageRecipientIndex != NSNotFound)
		{
			[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
			[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
		}
	}
	
	// Set up the cell
	[cell.textLabel setText:messageRecipient.Name];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	MessageRecipientModel *messageRecipient;
	UITableViewCell *cell;
	
	// Search Results Table
	if(tableView == self.searchDisplayController.searchResultsTableView)
	{
		messageRecipient = [self.filteredMessageRecipients objectAtIndex:indexPath.row];
		
		// Get cell in Message Recipients Table
		int indexRow = (int)[self.messageRecipients indexOfObject:messageRecipient];
		cell = [self.tableMessageRecipients cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0]];
		
		// Select cell
		[self.tableMessageRecipients selectRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
		
		// Reset Search Results
		[self.searchDisplayController setActive:NO animated:NO];
	}
	// Message Recipients Table
	else
	{
		messageRecipient = [self.messageRecipients objectAtIndex:indexPath.row];
		
		// Get cell in Message Recipients Table
		cell = [self.tableMessageRecipients cellForRowAtIndexPath:indexPath];
	}
	
	// Add Message Recipient to selected Message Recipients
	[self.selectedMessageRecipients addObject:messageRecipient];
	
	// Add checkmark of selected Message Recipient
	[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	MessageRecipientModel *messageRecipient = [self.messageRecipients objectAtIndex:indexPath.row];
	
	// Should never be possible to Deselect row from Search Results, but just in case
	if(tableView == self.searchDisplayController.searchResultsTableView)
	{
		// Reset Search Results
		[self.searchDisplayController setActive:NO animated:NO];
		
		return;
	}
	
	// Find index of Message Recipient in selected Message Recipients
	NSUInteger messageRecipientIndex = [self.selectedMessageRecipients indexOfObjectPassingTest:^BOOL(MessageRecipientModel *messageRecipient2, NSUInteger foundIndex, BOOL *stop)
	{
		return [messageRecipient2.ID isEqualToNumber:messageRecipient.ID];
	}];
	
	// Remove Message Recipient from selected Message Recipients
	[self.selectedMessageRecipients removeObjectAtIndex:messageRecipientIndex];
	
	// Remove checkmark of selected Message Recipient
	[cell setAccessoryType:UITableViewCellAccessoryNone];
}

// Only Segue for this View is Unwind Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// If no Message Recipients, ensure nothing happens when going back
	if([self.messageRecipients count] == 0)
	{
		return;
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
