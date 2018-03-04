//
//  MessageRecipientPickerViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/7/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "MessageRecipientPickerViewController.h"
#import "ErrorAlertController.h"
#import "MessageRecipientModel.h"

#ifdef MYTELEMED
	#import "ChatParticipantModel.h"

#elif defined MEDTOMED
	#import "MessageNew2TableViewController.h"
#endif

@interface MessageRecipientPickerViewController ()

#ifdef MYTELEMED
	@property (nonatomic) ChatParticipantModel *chatParticipantModel;
#endif

@property (nonatomic) MessageRecipientModel *messageRecipientModel;

@property (nonatomic) IBOutlet UIView *viewSearchBarContainer;
@property (nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic) IBOutlet UITableView *tableMessageRecipients;

@property (nonatomic, strong) UISearchController *searchController;

@property (nonatomic) NSMutableArray *filteredMessageRecipients;
@property (nonatomic) BOOL hasSubmitted;
@property (nonatomic) BOOL isLoaded;
@property (nonatomic) NSMutableArray *messageRecipients;

@end

@implementation MessageRecipientPickerViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Initialize chat participant model (only used for chat)
	#ifdef MYTELEMED
		[self setChatParticipantModel:[[ChatParticipantModel alloc] init]];
		[self.chatParticipantModel setDelegate:self];
	#endif
	
	// Initialize message recipient model (only used for new and forward message)
	[self setMessageRecipientModel:[[MessageRecipientModel alloc] init]];
	[self.messageRecipientModel setDelegate:self];
	
	// Initialize selected recipients
	if (self.selectedMessageRecipients == nil)
	{
		[self setSelectedMessageRecipients:[[NSMutableArray alloc] init]];
	}
	
	// Initialize filtered message recipients
	[self setFilteredMessageRecipients:[[NSMutableArray alloc] init]];
	
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
	[self.searchController.searchBar setPlaceholder:@"Search Recipients"];
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
		
		// Copy constraints from storyboard's placeholder search bar onto the search controller's search bar
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
		
		// Hide placeholder search bar from storyboard (UISearchController and its search bar cannot be implemented in storyboard so we use a placeholder search bar instead)
		[self.searchBar setHidden:YES];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableMessageRecipients setTableFooterView:[[UIView alloc] init]];
	
	// Fix iOS 11+ issue with next button that occurs when returning back from another screen. The next button will be selected, but there is no way to programmatically unselect it (UIBarButtonItem). Only affects MedToMed at this time
	if (self.hasSubmitted)
	{
		if (@available(iOS 11.0, *))
		{
			// Workaround the issue by completely replacing the next button with a brand new one
			UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveMessageRecipients:)];
			
			[self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:saveButton, nil]];
		}
	}
	
	// Change save button title
	#ifdef MEDTOMED
		[self.navigationItem.rightBarButtonItem setTitle:@"Next"];
	
	// Load list of chat participants
	#elif defined MYTELEMED
		if ([self.messageRecipientType isEqualToString:@"Chat"])
		{
			[self.chatParticipantModel getChatParticipants];
		}
		else
	#endif
	
	// Load list of message recipients for forward message
	if ([self.messageRecipientType isEqualToString:@"Forward"])
	{
		[self.messageRecipientModel getMessageRecipientsForMessageID:self.message.MessageID];
	}
	// Load list of message recipients for new message
	else
	{
		[self.messageRecipientModel getMessageRecipientsForAccountID:self.selectedAccount.ID];
	}
}

// Unwind to previous controller (chat message detail, forward message, or new message) or go to next controller (message new 2)
- (IBAction)saveMessageRecipients:(id)sender
{
	[self setHasSubmitted:YES];
	
	#ifdef MEDTOMED
		[self performSegueWithIdentifier:@"showMessageNew2" sender:self];
	
	#else
		// Unwind to chat message detail
		if ([self.messageRecipientType isEqualToString:@"Chat"])
		{
			if ([self.selectedMessageRecipients count] > 1)
			{
				UIAlertController *groupChatAlertController = [UIAlertController alertControllerWithTitle:@"New Chat Message" message:@"Would you like to start a Group Chat?" preferredStyle:UIAlertControllerStyleAlert];
				UIAlertAction *actionNo = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
				{
					// Disable group chat
					self.isGroupChat = NO;
					
					// Execute unwind segue
					[self performSegueWithIdentifier:@"setChatParticipants" sender:self];
				}];
				UIAlertAction *actionYes = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
				{
					// Enable group chat
					self.isGroupChat = YES;
					
					// Execute unwind segue
					[self performSegueWithIdentifier:@"setChatParticipants" sender:self];
				}];
				
				[groupChatAlertController addAction:actionNo];
				[groupChatAlertController addAction:actionYes];
				
				// PreferredAction only supported in 9.0+
				if ([groupChatAlertController respondsToSelector:@selector(setPreferredAction:)])
				{
					[groupChatAlertController setPreferredAction:actionYes];
				}
				
				// Show alert
				[self presentViewController:groupChatAlertController animated:YES completion:nil];
			}
			else
			{
				// Disable group chat
				self.isGroupChat = NO;
				
				// Execute unwind segue
				[self performSegueWithIdentifier:@"setChatParticipants" sender:self];
			}
		}
		// Unwind to forward message or new message
		else
		{
			// Execute unwind segue
			[self performSegueWithIdentifier:@"setMessageRecipients" sender:self];
		}
	#endif
}

// Return chat participants from chat participation model delegate
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

// Return error from chat participation model delegate
- (void)updateChatParticipantsError:(NSError *)error
{
	self.isLoaded = YES;
	
	// Show error message
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}

// Return message recipients from message recipient model delegate
- (void)updateMessageRecipients:(NSMutableArray *)newMessageRecipients
{
	[self setMessageRecipients:newMessageRecipients];
	
	self.isLoaded = YES;
	
	// Delete any selected message recipients that do not exist in the message recipients list (because they belong to a different account)
	NSMutableIndexSet *removeIndexes = [[NSMutableIndexSet alloc] init];
	
	[self.selectedMessageRecipients enumerateObjectsUsingBlock:^(MessageRecipientModel *selectedMessageRecipient, NSUInteger index, BOOL * _Nonnull stop)
	{
		// Determine if selected message recipient exists in message recipients
		NSUInteger messageRecipientIndex = [newMessageRecipients indexOfObjectPassingTest:^BOOL(MessageRecipientModel *messageRecipient, NSUInteger foundIndex, BOOL *stop)
		{
			return [messageRecipient.ID isEqualToNumber:selectedMessageRecipient.ID];
		}];
		
		// If selected message recipient does not exist in message recipients, remove it
		if (messageRecipientIndex == NSNotFound)
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

// Return error from message recipient model delegate
- (void)updateMessageRecipientsError:(NSError *)error
{
	self.isLoaded = YES;
	
	// Show error message
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}

// Delegate method for updating search results
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSPredicate *predicate;
	NSString *text = [[searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""];
	
	// Reset filtered message recipients
	[self.filteredMessageRecipients removeAllObjects];
	
	// Filter message recipients when search string contains space if first and last names begin with the name parts of search text
	if ([text rangeOfString:@" "].location != NSNotFound)
	{
		NSArray *nameParts = [text componentsSeparatedByString:@" "];
		NSString *firstName = [nameParts objectAtIndex:0];
		NSString *lastName = [nameParts objectAtIndex:1];
		predicate = [NSPredicate predicateWithFormat:@"(SELF.FirstName BEGINSWITH[c] %@ AND SELF.LastName BEGINSWITH[c] %@) OR (SELF.FirstName BEGINSWITH[c] %@ AND SELF.LastName BEGINSWITH[c] %@)", firstName, lastName, lastName, firstName];
	}
	// Filter message recipients if either first or last name begins with search text
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
	// Search results table
	if (self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		if ([self.filteredMessageRecipients count] == 0)
		{
			return 1;
		}
		
		return [self.filteredMessageRecipients count];
	}
	// Message recipients table
	else
	{
		if ([self.messageRecipients count] == 0)
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
	[cell setAccessoryType:UITableViewCellAccessoryNone];
	
	// Search results table
	if (self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		// If no filtered message recipients, create a not found message
		if ([self.filteredMessageRecipients count] == 0)
		{
			[cell.textLabel setText:@"No results."];
			
			return cell;
		}
		
		messageRecipient = [self.filteredMessageRecipients objectAtIndex:indexPath.row];
	}
	// Message recipients table
	else
	{
		// If no message recipients, create a not found message
		if ([self.messageRecipients count] == 0)
		{
			[cell.textLabel setText:(self.isLoaded ? @"No valid recipients available." : @"Loading...")];
			
			return cell;
		}
		
		messageRecipient = [self.messageRecipients objectAtIndex:indexPath.row];
	}
	
	// Determine if message recipient already exists in selected recipients
	NSUInteger messageRecipientIndex = [self.selectedMessageRecipients indexOfObjectPassingTest:^BOOL(MessageRecipientModel *messageRecipient2, NSUInteger foundIndex, BOOL *stop)
	{
		return [messageRecipient2.ID isEqualToNumber:messageRecipient.ID];
	}];
	
	// Set previously selected message recipients as selected and add checkmark
	if (messageRecipientIndex != NSNotFound)
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
	
	// Search results table
	if (self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		// If no filtered message recipients, then user clicked "No results."
		if ([self.filteredMessageRecipients count] == 0)
		{
			// Close search results
			[self.searchController setActive:NO];
			
			return;
		}
		
		// Set message recipient
		messageRecipient = [self.filteredMessageRecipients objectAtIndex:indexPath.row];
		
		// Close search results
		[self.searchController setActive:NO];
		
		// Get cell in message recipients table
		int indexRow = (int)[self.messageRecipients indexOfObject:messageRecipient];
		cell = [self.tableMessageRecipients cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0]];
		
		// Select cell
		[self.tableMessageRecipients selectRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
	// Message recipients table
	else
	{
		// Set message recipient
		messageRecipient = [self.messageRecipients objectAtIndex:indexPath.row];
		
		// Get cell in message recipients table
		cell = [self.tableMessageRecipients cellForRowAtIndexPath:indexPath];
	}
	
	// Add message recipient to selected message recipients
	[self.selectedMessageRecipients addObject:messageRecipient];
	
	// Add checkmark of selected message recipient
	[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	MessageRecipientModel *messageRecipient;
	UITableViewCell *cell;
	
	// Search results table
	if (self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		// Close search results
		[self.searchController setActive:NO];
		
		messageRecipient = [self.filteredMessageRecipients objectAtIndex:indexPath.row];
		
		// Get cell in message recipients table
		int indexRow = (int)[self.messageRecipients indexOfObject:messageRecipient];
		cell = [self.tableMessageRecipients cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0]];
		
		// Deselect cell
		[self.tableMessageRecipients deselectRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0] animated:NO];
	}
	// Message recipients table
	else
	{
		messageRecipient = [self.messageRecipients objectAtIndex:indexPath.row];
		
		// Get cell in message recipients table
		cell = [self.tableMessageRecipients cellForRowAtIndexPath:indexPath];
	}
	
	// Find index of message recipient in selected message recipients
	NSUInteger messageRecipientIndex = [self.selectedMessageRecipients indexOfObjectPassingTest:^BOOL(MessageRecipientModel *messageRecipient2, NSUInteger foundIndex, BOOL *stop)
	{
		return [messageRecipient2.ID isEqualToNumber:messageRecipient.ID];
	}];
	
	// Remove message recipient from selected message recipients
	[self.selectedMessageRecipients removeObjectAtIndex:messageRecipientIndex];
	
	// Remove checkmark of selected message recipient
	[cell setAccessoryType:UITableViewCellAccessoryNone];
}

// Only segue for this view is unwind segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// If no message recipients, ensure nothing happens when going back
	if ([self.messageRecipients count] == 0)
	{
		return;
	}
	
	#ifdef MEDTOMED
		// Message new 2
		if ([segue.identifier isEqualToString:@"showMessageNew2"])
		{
			// Add message recipients to form values
			[self.formValues setObject:self.selectedMessageRecipients forKey:@"MessageRecipients"];
			
			MessageNew2TableViewController *messageNew2TableViewController = segue.destinationViewController;
			
			[messageNew2TableViewController setDelegate:self];
			[messageNew2TableViewController setFormValues:self.formValues];
		}
	#endif
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

#ifdef MEDTOMED
- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Return updated form values back to new message screen (only useful if user returned to this screen from new message 2 screen)
	if ([self.delegate respondsToSelector:@selector(setFormValues:)])
	{
		[self.delegate setFormValues:self.formValues];
	}
}
#endif

@end
