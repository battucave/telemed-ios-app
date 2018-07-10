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
@property (nonatomic) IBOutlet UITableView *tableOnCallSlots;
@property (weak, nonatomic) IBOutlet UIView *viewSearchBarContainer;

@property (nonatomic) NSMutableArray *filteredOnCallSlots;
@property (nonatomic) BOOL isLoaded;
@property (nonatomic) NSMutableArray *onCallSlots;
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
		// Add auto-generated constraints that allow Search Bar to animate without disappearing
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
	[self.tableOnCallSlots setTableFooterView:[[UIView alloc] init]];
	
	// Initialize on call slot model
	OnCallSlotModel *onCallSlotModel = [[OnCallSlotModel alloc] init];
	
	// Get list of on call slots
	[onCallSlotModel setDelegate:self];
	[onCallSlotModel getOnCallSlots:self.selectedAccount.ID];
	
	// Add Keyboard Observers
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Return updated form values back to previous screen (only used if user returned to this screen from new message 2 screen)
	if ([self.delegate respondsToSelector:@selector(setFormValues:)])
	{
		[self.delegate setFormValues:self.formValues];
	}
	
	// Return selected message recipients back to previous screen (only used if user returned to this screen from message recipient picker screen)
	if ([self.delegate respondsToSelector:@selector(setSelectedMessageRecipients:)])
	{
		[self.delegate setSelectedMessageRecipients:self.selectedMessageRecipients];
	}
	
	// Return selected on call slot back to previous screen
	if ([self.delegate respondsToSelector:@selector(setSelectedOnCallSlot:)])
	{
		[self.delegate setSelectedOnCallSlot:self.selectedOnCallSlot];
	}
	
	// Remove Keyboard Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

// Go to next controller (message recipient picker)
- (IBAction)saveOnCallSlot:(id)sender
{
	NSLog(@"Save On Call Slot");
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
    	NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
		
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
	NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
	
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

// Return on call slots from on call slot model delegate
- (void)updateOnCallSlots:(NSMutableArray *)newOnCallSlots
{
	[self setOnCallSlots:newOnCallSlots];
	
	self.isLoaded = YES;
	
	// Reload table with updated data and scroll to any previously selected on call slot
	[self.tableOnCallSlots reloadData];
	[self scrollToSelectedOnCallSlot];
}

// Return error from on call slot model delegate
- (void)updateOnCallSlotsError:(NSError *)error
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
		if ([self.filteredOnCallSlots count] == 0)
		{
			return 1;
		}
		
		return [self.filteredOnCallSlots count];
	}
	// On call slots table
	else
	{
		if ([self.onCallSlots count] == 0)
		{
			return 1;
		}
		
		return [self.onCallSlots count];
	}
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 66.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Return default height if no on call slots available
	if ([self.onCallSlots count] == 0)
	{
		return 46.0f;
	}
	
	return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.onCallSlots count] == 0 || (self.searchController.active && self.searchController.searchBar.text.length > 0 && [self.filteredOnCallSlots count] == 0))
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:12.0]];
		[emptyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		// On call slots table
		if ([self.onCallSlots count] == 0)
		{
			[emptyCell.textLabel setText:(self.isLoaded ? @"No on call slots found." : @"Loading...")];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Search results table
	if (self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		// If no filtered on call slots, then user clicked "No results."
		if ([self.filteredOnCallSlots count] == 0)
		{
			// Close search results (must execute before scrolling to selected on call slot)
			[self.searchController setActive:NO];
			
			// Scroll to selected on call slot
			[self scrollToSelectedOnCallSlot];
			
			return;
		}
		
		// Set selected on call slot
		[self setSelectedOnCallSlot:[self.filteredOnCallSlots objectAtIndex:indexPath.row]];
	}
	// Hospitals table
	else
	{
		// Set selected on call slot
		[self setSelectedOnCallSlot:[self.onCallSlots objectAtIndex:indexPath.row]];
	}
	
	// Get cell in on call slots table
	UITableViewCell *cell = [self.tableOnCallSlots cellForRowAtIndexPath:indexPath];
	
	// Add checkmark of selected on call slot
	[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	
	// Close the search results, then execute segue
	if (self.searchController.active && self.definesPresentationContext)
	{
		[self dismissViewControllerAnimated:YES completion:^
		{
			[self performSegueWithIdentifier:@"showMessageRecipientPicker" sender:self];
		}];
	}
	// Execute segue
	else
	{
		[self performSegueWithIdentifier:@"showMessageRecipientPicker" sender:self];
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Get cell in on call slots table
	UITableViewCell *cell = [self.tableOnCallSlots cellForRowAtIndexPath:indexPath];
	
	// Remove checkmark of selected on call slot
	[cell setAccessoryType:UITableViewCellAccessoryNone];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// If no on call slots, ensure nothing happens
	if ([self.onCallSlots count] == 0)
	{
		return;
	}
	
	// Message recipient picker
	if ([segue.identifier isEqualToString:@"showMessageRecipientPicker"])
	{
		NSLog(@"Show Message Recipients Picker");
		
		MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.destinationViewController;
		
		// Add on call slot id to form values
		[self.formValues setValue:self.selectedOnCallSlot.ID forKey:@"OnCallSlotID"];
		
		[messageRecipientPickerViewController setDelegate:self];
		[messageRecipientPickerViewController setFormValues:self.formValues];
		[messageRecipientPickerViewController setSelectedAccount:self.selectedAccount];
		[messageRecipientPickerViewController setSelectedOnCallSlot:self.selectedOnCallSlot];
		[messageRecipientPickerViewController setTitle:@"Choose Recipient"];
		
		// If user returned back to this screen, then he/she may have already selected message recipients so pre-select them on the message recipient picker screen
		[messageRecipientPickerViewController setSelectedMessageRecipients:self.selectedMessageRecipients];
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

@end
