//
//  OnCallSlotPickerViewController.m
//  Med2Med
//
//  Created by Shane Goodwin on 4/16/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "OnCallSlotPickerViewController.h"
#import "ErrorAlertController.h"
#import "MessageRecipientPickerViewController.h"
#import "OnCallSlotCell.h"
#import "OnCallSlotModel.h"

@interface OnCallSlotPickerViewController ()

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableOnCallSlots;
@property (weak, nonatomic) IBOutlet UIView *viewSearchBarContainer;

@property (nonatomic) NSMutableArray *filteredOnCallSlots;
@property (nonatomic) BOOL isLoaded;
@property (nonatomic, strong) UISearchController *searchController;

@end

@implementation OnCallSlotPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
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
	[self.searchController.searchBar setPlaceholder:@"Search On Call Slots"];
	[self.searchController.searchBar sizeToFit];
	
	// iOS 11+ navigation bar has support for search controller
	if (@available(iOS 11.0, *))
	{
		[self.navigationItem setSearchController:self.searchController];
		
		[self.viewSearchBarContainer setHidden:YES];
		
		for (NSLayoutConstraint *constraint in self.viewSearchBarContainer.constraints)
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
		// Add auto-generated constraints that allow Search Bar to animate without disappearing
		[self.searchController.searchBar setTranslatesAutoresizingMaskIntoConstraints:YES];
		
		// Add search bar to search bar's container view
		[self.viewSearchBarContainer addSubview:self.searchController.searchBar];
		
		// Copy constraints from storyboard's placeholder search bar onto the search controller's search bar
		for (NSLayoutConstraint *constraint in self.searchBar.superview.constraints)
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
		
		for (NSLayoutConstraint *constraint in self.searchBar.constraints)
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
	[self.tableOnCallSlots setTableFooterView:[[UIView alloc] init]];
	
	// Add keyboard observers
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	#ifdef MED2MED
		// Initialize OnCallSlotModel
		OnCallSlotModel *onCallSlotModel = [[OnCallSlotModel alloc] init];
	
		// Get list of on call slots
		[onCallSlotModel setDelegate:self];
		[onCallSlotModel getOnCallSlots:self.selectedAccount.ID];
	
		// Remove right bar button
		[self.navigationItem setRightBarButtonItem:nil];
	
	#else
		// On call slots will always be pre-populated for redirect message
		self.isLoaded = YES;
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
	
		// Return selected message recipients back to previous screen (only used if user returned to this screen from MessageRecipientPickerViewController)
		if ([self.delegate respondsToSelector:@selector(setSelectedMessageRecipients:)])
		{
			[self.delegate setSelectedMessageRecipients:self.selectedMessageRecipients];
		}
	
		// Return selected on call slot back to previous screen
		if ([self.delegate respondsToSelector:@selector(setSelectedOnCallSlot:)])
		{
			[self.delegate setSelectedOnCallSlot:self.selectedOnCallSlot];
		}
	#endif
}

// MyTeleMed only - Send message from MessageRedirectTableViewController
- (IBAction)saveOnCallSlot:(id)sender
{
	#ifdef MYTELEMED
		if (self.delegate && [self.delegate respondsToSelector:@selector(redirectMessageToOnCallSlot:)])
		{
			// Verify that on call slot is selected
			if (self.selectedOnCallSlot)
			{
				[self.delegate redirectMessageToOnCallSlot:self.selectedOnCallSlot];
			}
		}
	#endif
}

- (void)keyboardWillShow:(NSNotification *)notification
{
	// Obtain keyboard size
	CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	// Convert it to the coordinates of on call slots table
	keyboardFrame = [self.tableOnCallSlots convertRect:keyboardFrame fromView:nil];
	
	// Determine if the keyboard covers the table
    CGRect intersect = CGRectIntersection(keyboardFrame, self.tableOnCallSlots.bounds);
	
	// If the keyboard covers the table
    if (! CGRectIsNull(intersect))
    {
    	// Get details of keyboard animation
    	NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    	NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16;
		
    	// Animate table above keyboard
    	[UIView animateWithDuration:duration delay:0.0 options:curve animations: ^
    	{
    		[self.tableOnCallSlots setContentInset:UIEdgeInsetsMake(0, 0, intersect.size.height, 0)];
    		[self.tableOnCallSlots setScrollIndicatorInsets:UIEdgeInsetsMake(0, 0, intersect.size.height, 0)];
		} completion:nil];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	// Get details of keyboard animation
	NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16;
	
	// Animate table back down to bottom of screen
	[UIView animateWithDuration:duration delay:0.0 options:curve animations: ^
	{
		[self.tableOnCallSlots setContentInset:UIEdgeInsetsZero];
		[self.tableOnCallSlots setScrollIndicatorInsets:UIEdgeInsetsZero];
	} completion:nil];
}

- (void)scrollToSelectedOnCallSlot
{
	// Cancel if no on call slot is selected
	if (! self.selectedOnCallSlot)
	{
		return;
	}
	
	// Find selected on call slot in on call slot
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID = %@", self.selectedOnCallSlot.ID];
	NSArray *results = [self.onCallSlots filteredArrayUsingPredicate:predicate];
	
	if ([results count] > 0)
	{
		// Find table cell that contains the on call slot
		OnCallSlotModel *onCallSlot = [results objectAtIndex:0];
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.onCallSlots indexOfObject:onCallSlot] inSection:0];
		
		// Scroll to cell
		if (indexPath)
		{
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self.tableOnCallSlots scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
			});
		}
	}
}

// Delegate method for updating search results
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSPredicate *predicate;
	NSString *text = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	// Reset filtered on call slots
	[self.filteredOnCallSlots removeAllObjects];
	
	// Filter on call slots if name begins with search text
	predicate = [NSPredicate predicateWithFormat:@"SELF.Name CONTAINS[c] %@", text];
	
	[self setFilteredOnCallSlots:[NSMutableArray arrayWithArray:[self.onCallSlots filteredArrayUsingPredicate:predicate]]];
	
	[self.tableOnCallSlots reloadData];
}

// Delegate method for clicking cancel button on search results
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	// Close search results
	[self.searchController setActive:NO];
	
	// Scroll to selected on call slot
	[self scrollToSelectedOnCallSlot];
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
		return MAX([self.filteredOnCallSlots count], 1);
	}
	// On call slots table
	else
	{
		return MAX([self.onCallSlots count], 1);
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.onCallSlots count] == 0 || (self.searchController.active && self.searchController.searchBar.text.length > 0 && [self.filteredOnCallSlots count] == 0))
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		// iOS 13+ - Support dark mode
		if (@available(iOS 13.0, *))
		{
			[emptyCell setBackgroundColor:[UIColor secondarySystemGroupedBackgroundColor]];
		}
		
		[emptyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:17.0]];
		
		// On call slots table
		if ([self.onCallSlots count] == 0)
		{
			[emptyCell.textLabel setText:(self.isLoaded ? @"No on call slots available." : @"Loading...")];
		}
		// Search results table
		else
		{
			[emptyCell.textLabel setText:@"No results."];
		}
		
		return emptyCell;
	}
	
	static NSString *cellIdentifier = @"OnCallSlotCell";
	
	OnCallSlotModel *onCallSlot;
	
	// Search results table
	if (self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		onCallSlot = [self.filteredOnCallSlots objectAtIndex:indexPath.row];
	}
	// On call slots table
	else
	{
		onCallSlot = [self.onCallSlots objectAtIndex:indexPath.row];
	}
	
	OnCallSlotCell *cell = [self.tableOnCallSlots dequeueReusableCellWithIdentifier:cellIdentifier];
	
	// Set up the cell
	[cell setAccessoryType:UITableViewCellAccessoryNone];
	
	// Set previously selected on call slot (if any) as selected and add checkmark
	if (self.selectedOnCallSlot && [onCallSlot.ID isEqualToNumber:self.selectedOnCallSlot.ID])
	{
		[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	}
	
	// Set on call slot current on call and name labels
	[cell.labelCurrentOnCall setText:onCallSlot.CurrentOncall];
	[cell.labelOnCallSlotName setText:onCallSlot.Name];
	
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If there are no on call slots, then user clicked the no on call slots cell
	if ([self.onCallSlots count] <= indexPath.row)
	{
		return nil;
	}
	// If search is active and there are no filtered on call slots, then user clicked the no results cell
	else if (self.searchController.active && self.searchController.searchBar.text.length > 0 && [self.filteredOnCallSlots count] <= indexPath.row)
	{
		// Close search results
		[self.searchController setActive:NO];
	
		// Scroll to selected on call slot (only if table is limited to single selection)
		[self scrollToSelectedOnCallSlot];
	
		return nil;
	}
	
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Set selected on call slot from search results table
	if (self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		[self setSelectedOnCallSlot:[self.filteredOnCallSlots objectAtIndex:indexPath.row]];
	}
	// Set selected on call slot from on call slots table
	else
	{
		[self setSelectedOnCallSlot:[self.onCallSlots objectAtIndex:indexPath.row]];
	}
	
	// Get cell in on call slots table
	UITableViewCell *cell = [self.tableOnCallSlots cellForRowAtIndexPath:indexPath];
	
	// Add checkmark of selected on call slot
	[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	
	// Define callback to execute either immediately or after search search results have closed
	void (^callback)(void);
	
	#ifdef MED2MED
		callback = ^
		{
			// Go to MessageRecipientPickerTableViewController
			[self performSegueWithIdentifier:@"showMessageRecipientPickerFromOnCallSlotPicker" sender:self];
		};
	
	#else
		callback = ^
		{
			// If selected on call slot is the self on call slot, then go to MessageRecipientPickerViewController
			if (self.selectedOnCallSlot.SelectRecipient)
			{
				if (self.navigationItem.rightBarButtonItem != nil)
				{
					[self.navigationItem.rightBarButtonItem setEnabled:NO];
				}
				
				[self performSegueWithIdentifier:@"showMessageRecipientPickerFromOnCallSlotPicker" sender:self];
			}
			// Enable next button
			else if (self.navigationItem.rightBarButtonItem != nil)
			{
				[self.navigationItem.rightBarButtonItem setEnabled:YES];
			}
		};
	#endif
	
	// Close the search results, then execute the callback
	if (self.searchController.active && self.definesPresentationContext)
	{
		[self dismissViewControllerAnimated:YES completion:^
		{
			callback();
		}];
	}
	// Execute on call slot
	else
	{
		callback();
	}
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Get cell in on call slots table
	UITableViewCell *cell = [self.tableOnCallSlots cellForRowAtIndexPath:indexPath];
	
	// Remove checkmark of selected on call slot
	[cell setAccessoryType:UITableViewCellAccessoryNone];
	
	#ifdef MYTELEMED
		// MyTeleMed - Disable send button if no on call slot selected
		if (self.navigationItem.rightBarButtonItem != nil && ! self.selectedOnCallSlot)
		{
			[self.navigationItem.rightBarButtonItem setEnabled:NO];
		}
	#endif
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// If no on call slots, ensure nothing happens
	if ([self.onCallSlots count] == 0)
	{
		return;
	}
	
	// Message recipient picker
	if ([segue.identifier isEqualToString:@"showMessageRecipientPickerFromOnCallSlotPicker"])
	{
		MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.destinationViewController;
		
		[messageRecipientPickerViewController setSelectedOnCallSlot:self.selectedOnCallSlot];
		[messageRecipientPickerViewController setTitle:@"Choose Recipient"];
		
		#ifdef MED2MED
			// Add on call slot id to form values
			[self.formValues setValue:self.selectedOnCallSlot.ID forKey:@"OnCallSlotID"];
		
			[messageRecipientPickerViewController setDelegate:self];
			[messageRecipientPickerViewController setFormValues:self.formValues];
			[messageRecipientPickerViewController setSelectedAccount:self.selectedAccount];
		
			// If user returned back to this screen, then he/she may have already selected message recipients so pre-select them on the MessageRecipientPickerViewController
			[messageRecipientPickerViewController setSelectedMessageRecipients:self.selectedMessageRecipients];
		
		// Handle self on call slot which allows user to select a recipient
		#elif defined MYTELEMED
			[messageRecipientPickerViewController setDelegate:self.delegate];
			[messageRecipientPickerViewController setMessageRecipients:self.messageRecipients];
			[messageRecipientPickerViewController setMessageRecipientType:@"Redirect"];
		#endif
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Med2Med

#ifdef MED2MED
// Return on call slots from OnCallSlotModel delegate
- (void)updateOnCallSlots:(NSArray *)onCallSlots
{
	[self setOnCallSlots:onCallSlots];
	
	self.isLoaded = YES;
	
	// Reload table with updated data and scroll to any previously selected on call slot
	[self.tableOnCallSlots reloadData];
	[self scrollToSelectedOnCallSlot];
}

// Return error from OnCallSlotModel delegate
- (void)updateOnCallSlotsError:(NSError *)error
{
	self.isLoaded = YES;
	
	// Show error message
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}
#endif

@end
