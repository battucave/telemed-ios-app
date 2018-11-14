//
//  HospitalPickerViewController.m
//  Med2Med
//
//  Created by Shane Goodwin on 11/28/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "HospitalPickerViewController.h"
#import "ErrorAlertController.h"
#import "MessageNewTableViewController.h"
#import "HospitalCell.h"
#import "HospitalModel.h"

@interface HospitalPickerViewController ()

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableHospitals;
@property (weak, nonatomic) IBOutlet UIView *viewSearchBarContainer;

@property (nonatomic) NSMutableArray *filteredHospitals;
@property (nonatomic) BOOL isLoaded;
@property (nonatomic, strong) UISearchController *searchController;

@end

@implementation HospitalPickerViewController

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
	[self.searchController.searchBar setPlaceholder:@"Search Hospitals"];
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
	[self.tableHospitals setTableFooterView:[[UIView alloc] init]];
	
	// If user navigated from message new screen, remove "+" button
	if (self.shouldSelectHospital)
	{
		[self.navigationItem setRightBarButtonItem:nil];
	}
	// If user navigated from SettingsTableViewController, disallow selection of hospitals
	else
	{
		[self.tableHospitals setAllowsSelection:NO];
	
		// TEMPORARY PHASE 1 (remove in phase 2)
		[self.navigationItem setRightBarButtonItem:nil];
		// END TEMPORARY PHASE 1
	}
	
	// Get list of hospitals if none were passed from previous controller
	if ([self.hospitals count] == 0)
	{
		// Initialize HospitalModel
		HospitalModel *hospitalModel = [[HospitalModel alloc] init];
		
		[hospitalModel setDelegate:self];
		[hospitalModel getHospitals];
	}
	// Reload table with updated data and scroll to any previously selected hospital
	else
	{
		[self.tableHospitals reloadData];
		[self scrollToSelectedHospital];
	}
	
	// Add keyboard observers
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove keyboard observers
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

// Required for unwind compatibility with MessageNewUnauthorizedTableViewController (both unwind from HospitalRequestTableViewController)
- (IBAction)unwindFromHospitalRequest:(UIStoryboardSegue *)segue
{
	NSLog(@"Unwind from Hospital Request");
}

- (void)keyboardWillShow:(NSNotification *)notification
{
	// Obtain keyboard size
	CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	// Convert it to the coordinates of hospitals table
	keyboardFrame = [self.tableHospitals convertRect:keyboardFrame fromView:nil];
	
	// Determine if the keyboard covers the table
    CGRect intersect = CGRectIntersection(keyboardFrame, self.tableHospitals.bounds);
	
	// If the keyboard covers the table
    if (! CGRectIsNull(intersect))
    {
    	// Get details of keyboard animation
    	NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    	NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
		
    	// Animate table above keyboard
    	[UIView animateWithDuration:duration delay:0.0 options:curve animations: ^
    	{
    		[self.tableHospitals setContentInset:UIEdgeInsetsMake(0, 0, intersect.size.height, 0)];
    		[self.tableHospitals setScrollIndicatorInsets:UIEdgeInsetsMake(0, 0, intersect.size.height, 0)];
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
		[self.tableHospitals setContentInset:UIEdgeInsetsZero];
		[self.tableHospitals setScrollIndicatorInsets:UIEdgeInsetsZero];
	} completion:nil];
}

- (void)scrollToSelectedHospital
{
	// Cancel if no hospital is selected
	if (! self.selectedHospital)
	{
		return;
	}
	
	// Find selected hospital in hospitals
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID = %@", self.selectedHospital.ID];
	NSArray *results = [self.hospitals filteredArrayUsingPredicate:predicate];
	
	if ([results count] > 0)
	{
		// Find table cell that contains the hospital
		HospitalModel *hospital = [results objectAtIndex:0];
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.hospitals indexOfObject:hospital] inSection:0];
		
		// Scroll to cell
		if (indexPath)
		{
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self.tableHospitals scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
			});
		}
	}
}

// Return hospitals from HospitalModel delegate
- (void)updateHospitals:(NSMutableArray *)newHospitals
{
	// Filter and store only authenticated or requested hospitals
	NSPredicate *predicate;
	
	// When selecting hospital for new message, only show authenticated hospitals
	if (self.shouldSelectHospital)
	{
		predicate = [NSPredicate predicateWithFormat:@"MyAuthenticationStatus = %@ OR MyAuthenticationStatus = %@", @"OK", @"Admin"];
	}
	// When viewing "My Hospitals", show authenticated and requested hospitals
	else
	{
		predicate = [NSPredicate predicateWithFormat:@"MyAuthenticationStatus = %@ OR MyAuthenticationStatus = %@ OR MyAuthenticationStatus = %@", @"OK", @"Admin", @"Requested"];
	}
	
	[self setHospitals:[[newHospitals filteredArrayUsingPredicate:predicate] mutableCopy]];
	
	self.isLoaded = YES;
	
	// Reload table with updated data and scroll to any previously selected hospital
	[self.tableHospitals reloadData];
	[self scrollToSelectedHospital];
}

// Return error from HospitalModel delegate
- (void)updateHospitalsError:(NSError *)error
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
	
	// Reset filtered hospitals
	[self.filteredHospitals removeAllObjects];
	
	// Filter hospitals if name begins with search text
	predicate = [NSPredicate predicateWithFormat:@"SELF.Name CONTAINS[c] %@", text];
	
	[self setFilteredHospitals:[NSMutableArray arrayWithArray:[self.hospitals filteredArrayUsingPredicate:predicate]]];
	
	[self.tableHospitals reloadData];
}

// Delegate method for clicking cancel button on search results
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	// Close search results
	[self.searchController setActive:NO];
	
	// Scroll to selected hospital
	[self scrollToSelectedHospital];
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
		return MAX([self.filteredHospitals count], 1);
	}
	// Hospitals table
	else
	{
		return MAX([self.hospitals count], 1);
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.hospitals count] == 0 || (self.searchController.active && self.searchController.searchBar.text.length > 0 && [self.filteredHospitals count] == 0))
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:12.0]];
		[emptyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		// Hospitals table
		if ([self.hospitals count] == 0)
		{
			[emptyCell.textLabel setText:(self.isLoaded ? @"No hospitals found." : @"Loading...")];
		}
		// Search results table
		else
		{
			[emptyCell.textLabel setText:@"No results."];
		}
		
		return emptyCell;
	}
	
	static NSString *cellIdentifier = @"HospitalCell";
	static NSString *cellIdentifierRequested = @"HospitalRequestedCell";
	
	HospitalModel *hospital;
	
	// Search results table
	if (self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		hospital = [self.filteredHospitals objectAtIndex:indexPath.row];
	}
	// Hospitals table
	else
	{
		hospital = [self.hospitals objectAtIndex:indexPath.row];
	}
	
	HospitalCell *cell = [self.tableHospitals dequeueReusableCellWithIdentifier:([hospital isRequested] ? cellIdentifierRequested : cellIdentifier)];
	
	// Set up the cell
	[cell setAccessoryType:UITableViewCellAccessoryNone];
	
	// Set previously selected hospital as selected and add checkmark
	if (self.selectedHospital && [hospital.ID isEqualToNumber:self.selectedHospital.ID])
	{
		[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	}
	
	// Set hospital name label
	[cell.hospitalName setText:hospital.Name];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Search results table
	if (self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		// If no filtered hospitals, then user clicked "No results."
		if ([self.filteredHospitals count] == 0)
		{
			// Close search results (must execute before scrolling to selected hospital)
			[self.searchController setActive:NO];
			
			// Scroll to selected hospital
			[self scrollToSelectedHospital];
			
			return;
		}
		
		// Set selected hospital
		[self setSelectedHospital:[self.filteredHospitals objectAtIndex:indexPath.row]];
	}
	// Hospitals table
	else
	{
		// Set selected hospital
		[self setSelectedHospital:[self.hospitals objectAtIndex:indexPath.row]];
	}
	
	// Get cell in hospitals table
	UITableViewCell *cell = [self.tableHospitals cellForRowAtIndexPath:indexPath];
	
	// Add checkmark of selected hospital
	[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	
	// Close the search results, then execute unwind segue
	if (self.searchController.active && self.definesPresentationContext)
	{
		[self dismissViewControllerAnimated:YES completion:^
		{
			[self performSegueWithIdentifier:@"unwindSetHospital" sender:self];
		}];
	}
	// Execute unwind segue
	else
	{
		[self performSegueWithIdentifier:@"unwindSetHospital" sender:self];
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Get cell in hospitals table
	UITableViewCell *cell = [self.tableHospitals cellForRowAtIndexPath:indexPath];
	
	// Remove checkmark of selected hospital
	[cell setAccessoryType:UITableViewCellAccessoryNone];
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
