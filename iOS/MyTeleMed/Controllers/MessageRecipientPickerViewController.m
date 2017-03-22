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

@property (nonatomic) IBOutlet UIView *viewSearchBarContainer;
@property (nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic) IBOutlet UITableView *tableMessageRecipients;

@property (nonatomic, strong) UISearchController *searchController;

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
	
	// Initialize Search Controller
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	
	[self.searchController setDelegate:self];
	[self.searchController setDimsBackgroundDuringPresentation:NO];
	//[self.searchController setHidesNavigationBarDuringPresentation:NO];
	[self.searchController setSearchResultsUpdater:self];
	
	self.definesPresentationContext = YES;
	
	// Initialize Search Bar
	[self.searchController.searchBar setDelegate:self];
	[self.searchController.searchBar setPlaceholder:@"Search Recipients"];
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
	
	// Load list of Message Recipients
	[self reloadMessageRecipients];
}

// Unwind to previous controller (Chat Message Detail, Forward Message, or New Message)
- (IBAction)unwind:(id)sender
{
	// Unwind to Chat Message Detail
	if([self.messageRecipientType isEqualToString:@"Chat"])
	{
		if([self.selectedMessageRecipients count] > 1)
		{
			UIAlertController *confirmGroupChatController = [UIAlertController alertControllerWithTitle:@"New Chat Message" message:@"Would you like to start a Group Chat?" preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *actionNo = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
			{
				// Disable Group Chat
				self.isGroupChat = NO;
				
				// Execute unwind segue
				[self performSegueWithIdentifier:@"setChatParticipants" sender:self];
			}];
			UIAlertAction *actionYes = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
			{
				// Enable Group Chat
				self.isGroupChat = YES;
				
				// Execute unwind segue
				[self performSegueWithIdentifier:@"setChatParticipants" sender:self];
			}];
			
			[confirmGroupChatController addAction:actionNo];
			[confirmGroupChatController addAction:actionYes];
			[confirmGroupChatController setPreferredAction:actionYes];
			
			// Show Alert
			[self presentViewController:confirmGroupChatController animated:YES completion:nil];
		}
		else
		{
			// Disable Group Chat
			self.isGroupChat = NO;
			
			// Execute unwind segue
			[self performSegueWithIdentifier:@"setChatParticipants" sender:self];
		}
	}
	// Unwind to Forward Message or New Message
	else
	{
		// Execute unwind segue
		[self performSegueWithIdentifier:@"setMessageRecipients" sender:self];
	}
}

// Get Message Recipients
- (void)reloadMessageRecipients
{
	// Get Participants for Chat
	if([self.messageRecipientType isEqualToString:@"Chat"])
	{
		[self.chatParticipantModel getChatParticipants];
	}
	// Get Recipients for Forward Message
	else if([self.messageRecipientType isEqualToString:@"Forward"])
	{
		[self.messageRecipientModel getMessageRecipientsForMessageDeliveryID:self.message.MessageDeliveryID];
	}
	// Get Recipients for New Message
	else
	{
		[self.messageRecipientModel getMessageRecipientsForAccountID:self.selectedAccount.ID];
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
	
	// Show error message
	[self.chatParticipantModel showError:error];
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
	
	// Show error message
	[self.messageRecipientModel showError:error];
}

// Delegate Method for Updating Search Results
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSPredicate *predicate;
	NSString *text = [[searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""];
	
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
	
	[self.tableMessageRecipients reloadData];
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
	
	// Set up the cell
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	[cell setAccessoryType:UITableViewCellAccessoryNone];
	
	// Search Results Table
	if(self.searchController.active && self.searchController.searchBar.text.length > 0)
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
	}
	
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
	
	// Set cell label
	[cell.textLabel setText:messageRecipient.Name];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	MessageRecipientModel *messageRecipient;
	UITableViewCell *cell;
	
	// Search Results Table
	if(self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		messageRecipient = [self.filteredMessageRecipients objectAtIndex:indexPath.row];
		
		// Get cell in Message Recipients Table
		int indexRow = (int)[self.messageRecipients indexOfObject:messageRecipient];
		cell = [self.tableMessageRecipients cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0]];
		
		// Select cell
		[self.tableMessageRecipients selectRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
	// Message Recipients Table
	else
	{
		messageRecipient = [self.messageRecipients objectAtIndex:indexPath.row];
		
		// Get cell in Message Recipients Table
		cell = [self.tableMessageRecipients cellForRowAtIndexPath:indexPath];
	}
	
	// Reset Search Results (put here because it's possible for it to be active, but without any entered text)
	if(self.searchController.active)
	{
		[self.searchController setActive:NO];
	}
	
	// Add Message Recipient to selected Message Recipients
	[self.selectedMessageRecipients addObject:messageRecipient];
	
	// Add checkmark of selected Message Recipient
	[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	MessageRecipientModel *messageRecipient;
	UITableViewCell *cell;
	
	// Search Results Table
	if(self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		messageRecipient = [self.filteredMessageRecipients objectAtIndex:indexPath.row];
		
		// Get cell in Message Recipients Table
		int indexRow = (int)[self.messageRecipients indexOfObject:messageRecipient];
		cell = [self.tableMessageRecipients cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0]];
		
		// Deselect cell
		[self.tableMessageRecipients deselectRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0] animated:NO];
	}
	// Message Recipients Table
	else
	{
		messageRecipient = [self.messageRecipients objectAtIndex:indexPath.row];
		
		// Get cell in Message Recipients Table
		cell = [self.tableMessageRecipients cellForRowAtIndexPath:indexPath];
	}
	
	// Reset Search Results (put here because it's possible for it to be active, but without any entered text)
	if(self.searchController.active)
	{
		[self.searchController setActive:NO];
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

- (void)dealloc
{
	// Avoid superfluous warning that "Attempting to load the view of a view controller while it is deallocating is not allowed and may result in undefined behavior <UISearchController>"
	[self.searchController.view removeFromSuperview];
}

@end
