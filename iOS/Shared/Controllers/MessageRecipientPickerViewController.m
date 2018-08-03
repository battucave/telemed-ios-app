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

#elif defined MED2MED
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

@property (nonatomic) NSMutableArray *filteredMessageRecipients;
@property (nonatomic) BOOL hasSubmitted;
@property (nonatomic) BOOL isLoaded;
@property (nonatomic) NSMutableArray *messageRecipients;
@property (nonatomic, strong) UISearchController *searchController;

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
	
	// Present search controller from self
	[self setDefinesPresentationContext:YES];
	
	// Initialize search controller
	[self setSearchController:[[UISearchController alloc] initWithSearchResultsController:nil]];
	
	[self.searchController setDelegate:self];
	[self.searchController setDimsBackgroundDuringPresentation:NO];
	//[self.searchController setHidesNavigationBarDuringPresentation:NO];
	[self.searchController setSearchResultsUpdater:self];
	
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
	
	// Fix iOS 11+ issue with next button that occurs when returning back from another screen. The next button will be selected, but there is no way to programmatically unselect it (UIBarButtonItem). (not currently used - only affects Med2Med if table allows multiple selection)
	if (self.hasSubmitted && self.navigationItem.rightBarButtonItem != nil)
	{
		if (@available(iOS 11.0, *))
		{
			// Workaround the issue by completely replacing the next button with a brand new one
			UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveMessageRecipients:)];
			
			[self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:saveButton, nil]];
		}
	}
	
	// Add keyboard observers
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	#ifdef MED2MED
		// Force single selection of recipients
		[self.tableMessageRecipients setAllowsMultipleSelection:NO];
	
		// Disable next button and change its title if table allows multiple selection
		if (self.tableMessageRecipients.allowsMultipleSelection)
		{
			[self.navigationItem.rightBarButtonItem setEnabled:NO];
			[self.navigationItem.rightBarButtonItem setTitle:@"Next"];
		
			// Re-enable next button if user returned to this screen with recipients still loaded
			if ([self.messageRecipients count] > 0 && [self.selectedMessageRecipients count] > 0)
			{
				[self.navigationItem.rightBarButtonItem setEnabled:YES];
			}
		}
		// Remove right bar button if table is limited to single selection
		else
		{
			[self.navigationItem setRightBarButtonItem:nil];
		}
	
		// Load list of message recipients for new message
		[self.messageRecipientModel getMessageRecipientsForAccountID:self.selectedAccount.ID slotID:self.selectedOnCallSlot.ID];
	
	#else
		// Load list of chat participants
		if ([self.messageRecipientType isEqualToString:@"Chat"])
		{
			[self.chatParticipantModel getChatParticipants];
		}
		// Load list of message recipients for forward message
		else if ([self.messageRecipientType isEqualToString:@"Forward"])
		{
			[self.messageRecipientModel getMessageRecipientsForMessageID:self.message.MessageID];
		}
		// Load list of message recipients for new message
		else
		{
			[self.messageRecipientModel getMessageRecipientsForAccountID:self.selectedAccount.ID];
		}
	#endif
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove keyboard observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	
	#ifdef MED2MED
		// Return updated form values back to previous screen (only used if user returned to this screen from MessageNew2TableViewController)
		if ([self.delegate respondsToSelector:@selector(setFormValues:)])
		{
			[self.delegate setFormValues:self.formValues];
		}
	
		// Return selected message recipients back to previous screen
		if ([self.delegate respondsToSelector:@selector(setSelectedMessageRecipients:)])
		{
			[self.delegate setSelectedMessageRecipients:self.selectedMessageRecipients];
		}
	#endif
}

// MyTeleMed only - Unwind to previous controller (chat message detail, forward message, or new message) or go to next controller (MessageNew2TableViewController)
- (IBAction)saveMessageRecipients:(id)sender
{
	[self setHasSubmitted:YES];
	
	#ifdef MED2MED // (not currently used - only used if table allows multiple selection)
		[self performSegueWithIdentifier:@"showMessageNew2" sender:self];
	
	#else
		// Unwind to ChatMessageDetailViewController
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

- (void)keyboardWillShow:(NSNotification *)notification
{
	// Obtain keyboard size
	CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	// Convert it to the coordinates of message recipients table
	keyboardFrame = [self.tableMessageRecipients convertRect:keyboardFrame fromView:nil];
	
	// Determine if the keyboard covers the table
    CGRect intersect = CGRectIntersection(keyboardFrame, self.tableMessageRecipients.bounds);
	
	// If the keyboard covers the table
    if (! CGRectIsNull(intersect))
    {
    	// Get details of keyboard animation
    	NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    	NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
		
    	// Animate table above keyboard
    	[UIView animateWithDuration:duration delay:0.0 options:curve animations: ^
    	{
    		[self.tableMessageRecipients setContentInset:UIEdgeInsetsMake(0, 0, intersect.size.height, 0)];
    		[self.tableMessageRecipients setScrollIndicatorInsets:UIEdgeInsetsMake(0, 0, intersect.size.height, 0)];
		} completion:nil];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	// Get details of keyboard animation
	NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
	
	// Animate table back down to bottom of screen
	[UIView animateWithDuration:duration delay:0.0 options:curve animations: ^
	{
		[self.tableMessageRecipients setContentInset:UIEdgeInsetsZero];
		[self.tableMessageRecipients setScrollIndicatorInsets:UIEdgeInsetsZero];
	} completion:nil];
}

- (void)scrollToSelectedMessageRecipient
{
	// Cancel if table allows multiple selection or no message recipient is selected
	if (self.tableMessageRecipients.allowsMultipleSelection || [self.selectedMessageRecipients count] == 0)
	{
		return;
	}
	
	// Find selected on call slot in on call slot
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID = %@", [(MessageRecipientModel *)[self.selectedMessageRecipients objectAtIndex:0] ID]];
	NSArray *results = [self.messageRecipients filteredArrayUsingPredicate:predicate];
	
	if ([results count] > 0)
	{
		// Find table cell that contains the message recipient
		MessageRecipientModel *messageRecipient = [results objectAtIndex:0];
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.messageRecipients indexOfObject:messageRecipient] inSection:0];
		
		// Scroll to cell
		if (indexPath)
		{
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self.tableMessageRecipients scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
			});
		}
	}
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
	
	// MyTeleMed only - reload table with updated data
	if (self.tableMessageRecipients.allowsMultipleSelection)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[self.tableMessageRecipients reloadData];
		});
	}
	// Med2Med only - reload table with updated data and scroll to any previously selected message recipient (only if table is limited to single selection)
	else
	{
		[self.tableMessageRecipients reloadData];
		[self scrollToSelectedMessageRecipient];
	}
	
	// Med2Med - Re-enable next button if at least one message recipient is still selected (not currently used - only used if table allows multiple selection)
	#ifdef MED2MED
		if (self.navigationItem.rightBarButtonItem != nil && [self.selectedMessageRecipients count] > 0)
		{
			[self.navigationItem.rightBarButtonItem setEnabled:YES];
		}
	#endif
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

// Delegate method for clicking cancel button on search results
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	// Close search results
	[self.searchController setActive:NO];
	
	// Med2Med only - scroll to selected message recipient (only if table is limited to single selection)
	[self scrollToSelectedMessageRecipient];
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
		return MAX([self.filteredMessageRecipients count], 1);
	}
	// Message recipients table
	else
	{
		return MAX([self.messageRecipients count], 1);
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
	// Med2Med only - Reset selected message recipients
	if (! self.tableMessageRecipients.allowsMultipleSelection)
	{
		[self.selectedMessageRecipients removeAllObjects];
	}

	// Search results table
	if (self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		// If no filtered message recipients, then user clicked "No results."
		if ([self.filteredMessageRecipients count] == 0)
		{
			// Close search results
			[self.searchController setActive:NO];
			
			// Scroll to selected message recipient (only if table is limited to single selection)
			[self scrollToSelectedMessageRecipient];
			
			return;
		}
		
		// Add message recipient to selected message recipients
		[self.selectedMessageRecipients addObject:(MessageRecipientModel *)[self.filteredMessageRecipients objectAtIndex:indexPath.row]];
	}
	// Message recipients table
	else
	{
		// Add message recipient to selected message recipients
		[self.selectedMessageRecipients addObject:(MessageRecipientModel *)[self.messageRecipients objectAtIndex:indexPath.row]];
	}
	
	// Get cell in message recipients table
	UITableViewCell *cell = [self.tableMessageRecipients cellForRowAtIndexPath:indexPath];
	
	// Add checkmark of selected message recipient
	[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	
	#ifdef MED2MED
		// Re-enable next button (not currently used - only used if table allows multiple selection)
		if (self.navigationItem.rightBarButtonItem != nil)
		{
			[self.navigationItem.rightBarButtonItem setEnabled:YES];
		}
		// Execute segue (only used if table is limited to single selection)
		else
		{
			// Close the search results, then execute segue
			if (self.searchController.active && self.definesPresentationContext)
			{
				[self dismissViewControllerAnimated:YES completion:^
				{
					[self performSegueWithIdentifier:@"showMessageNew2" sender:self];
				}];
			}
			// Execute segue
			else
			{
				[self performSegueWithIdentifier:@"showMessageNew2" sender:self];
			}
			
			return;
		}
	#endif
	
	// Close the search results
	if (self.searchController.active)
	{
		[self.searchController setActive:NO];
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Get cell in message recipients table
	UITableViewCell *cell = [self.tableMessageRecipients cellForRowAtIndexPath:indexPath];
	
	// Remove checkmark of selected message recipient
	[cell setAccessoryType:UITableViewCellAccessoryNone];
	
	// MyTeleMed only - If table allows multiple selection, then remove the message recipient from selected message recipients (if not, then this is handled by resetting selected message recipients in didSelectRowAtIndexPath method)
	if (self.tableMessageRecipients.allowsMultipleSelection)
	{
		MessageRecipientModel *messageRecipient;
		
		// Search results table
		if (self.searchController.active && self.searchController.searchBar.text.length > 0)
		{
			messageRecipient = [self.filteredMessageRecipients objectAtIndex:indexPath.row];
		}
		// Message recipients table
		else
		{
			messageRecipient = [self.messageRecipients objectAtIndex:indexPath.row];
		}
		
		// Find index of message recipient in selected message recipients
		NSUInteger messageRecipientIndex = [self.selectedMessageRecipients indexOfObjectPassingTest:^BOOL(MessageRecipientModel *messageRecipient2, NSUInteger foundIndex, BOOL *stop)
		{
			return [messageRecipient2.ID isEqualToNumber:messageRecipient.ID];
		}];
		
		// Remove message recipient from selected message recipients
		if ([self.selectedMessageRecipients count] > messageRecipientIndex)
		{
			[self.selectedMessageRecipients removeObjectAtIndex:messageRecipientIndex];
		}
		
		// Close the search results
		if (self.searchController.active)
		{
			[self.searchController setActive:NO];
		}
		
		// Med2Med - Disable next button if no recipients still selected (not currently used - only used if table allows multiple selection)
		#ifdef MED2MED
			if (self.navigationItem.rightBarButtonItem != nil && [self.selectedMessageRecipients count] == 0)
			{
				[self.navigationItem.rightBarButtonItem setEnabled:NO];
			}
		#endif
	}
}

// Only segue for this view is unwind segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// If no message recipients, ensure nothing happens when going back
	if ([self.messageRecipients count] == 0)
	{
		return;
	}
	
	#ifdef MED2MED
		// Message new 2
		if ([segue.identifier isEqualToString:@"showMessageNew2"])
		{
			MessageNew2TableViewController *messageNew2TableViewController = segue.destinationViewController;
			
			// Add message recipients to form values (not currently used - only used if table allows multiple selection)
			if (self.tableMessageRecipients.allowsMultipleSelection)
			{
				[self.formValues setObject:self.selectedMessageRecipients forKey:@"MessageRecipients"];
			}
			// Add message recipient id to form values (only used if table is limited to single selection)
			else
			{
				[self.formValues setValue:[(MessageRecipientModel *)[self.selectedMessageRecipients objectAtIndex:0] ID] forKey:@"MessageRecipientID"];
			}
			
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


#pragma mark - MyTeleMed

#ifdef MYTELEMED
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
#endif

@end
