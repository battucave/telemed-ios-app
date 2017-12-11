//
//  HospitalPickerViewController.m
//  TeleMed
//
//  Created by Shane Goodwin on 11/28/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "HospitalPickerViewController.h"
#import "MessageNewTableViewController.h"
#import "HospitalCell.h"
#import "HospitalModel.h"

@interface HospitalPickerViewController ()

@property (nonatomic) HospitalModel *hospitalModel;

@property (nonatomic) IBOutlet UIView *viewSearchBarContainer;
@property (nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic) IBOutlet UITableView *tableHospitals;

@property (nonatomic, strong) UISearchController *searchController;

@property (nonatomic) NSMutableArray *filteredHospitals;
@property (nonatomic) BOOL isLoaded;

@end

@implementation HospitalPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// If hospitals were not pre-loaded (slow connection in MessageNewViewController), then load them here
	if ([self.hospitals count] == 0)
	{
		// Initialize hospital model
		[self setHospitalModel:[[HospitalModel alloc] init]];
		[self.hospitalModel setDelegate:self];
	}
	
	// Initialize search controller
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	
	[self.searchController setDelegate:self];
	[self.searchController setDimsBackgroundDuringPresentation:NO];
	//[self.searchController setHidesNavigationBarDuringPresentation:NO];
	[self.searchController setSearchResultsUpdater:self];
	
	self.definesPresentationContext = YES;
	
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
	
	// Get list of hospitals
	if ([self.hospitals count] == 0)
	{
		[self.hospitalModel getHospitals];
	}
	// If hospital was previously selected, scroll to it
	else
	{
		[self.tableHospitals reloadData];
		
		// Scroll to selected hospital
		[self scrollToSelectedHospital];
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	// Reset search results (put here because it's animation must occur AFTER any segue)
	if (self.searchController.active)
	{
		[self.searchController setActive:NO];
	}
}

// Return hospitals from hospital model delegate
- (void)updateHospitals:(NSMutableArray *)newHospitals
{
	[self setHospitals:newHospitals];
	
	self.isLoaded = YES;
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableHospitals reloadData];
		
		// If hospital was previously selected, scroll to it
		[self scrollToSelectedHospital];
	});
}

// Return error from hospital model delegate
- (void)updateHospitalsError:(NSError *)error
{
	self.isLoaded = YES;
	
	// Show error message
	[self.hospitalModel showError:error];
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
		// Find table cell that contains hospital
		HospitalModel *hospital = [results objectAtIndex:0];
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.hospitals indexOfObject:hospital] inSection:0];
		
		// Scroll to cell
		if (indexPath)
		{
			[self.tableHospitals scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
		}
	}
}

// Delegate method for updating search results
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSPredicate *predicate;
	NSString *text = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	NSLog(@"Text: %@", text);
	
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
		if ([self.filteredHospitals count] == 0)
		{
			return 1;
		}
		
		return [self.filteredHospitals count];
	}
	// Hospitals table
	else
	{
		if ([self.hospitals count] == 0)
		{
			return 1;
		}
		
		return [self.hospitals count];
	}
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 46.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Return default height if no Hospitals available
	if ([self.hospitals count] == 0)
	{
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	}
	
	return UITableViewAutomaticDimension;
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
	HospitalCell *cell = [self.tableHospitals dequeueReusableCellWithIdentifier:cellIdentifier];
	HospitalModel *hospital;
	
	// Set up the cell
	[cell setAccessoryType:UITableViewCellAccessoryNone];
	
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
	UITableViewCell *cell;
	
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
		
		// Set selected hospital (in case user presses back button from next screen)
		[self setSelectedHospital:[self.filteredHospitals objectAtIndex:indexPath.row]];
		
		// Get cell in hospitals table
		int indexRow = (int)[self.hospitals indexOfObject:self.selectedHospital];
		cell = [self.tableHospitals cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0]];
		
		// Select cell (not needed - if user presses back button from next screen, viewWillAppear method handles selecting the selected Hospital)
		//[self.tableHospitals selectRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
	// Hospitals table
	else
	{
		// Set selected hospital (in case user presses back button from next screen)
		[self setSelectedHospital:[self.hospitals objectAtIndex:indexPath.row]];
		
		// Get cell in hospitals table
		cell = [self.tableHospitals cellForRowAtIndexPath:indexPath];
	}
	
	// Add checkmark of selected hospital
	[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	
	// Go to MessageNewViewController
	[self performSegueWithIdentifier:@"showMessageNewFromHospitalPicker" sender:cell];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
	// Search results table
	if (self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		// Close search results
		[self.searchController setActive:NO];
		
		// Get cell in hospitals table
		int indexRow = (int)[self.hospitals indexOfObject:self.selectedHospital];
		cell = [self.tableHospitals cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0]];
		
		// Deselect cell
		[self.tableHospitals deselectRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0] animated:NO];
	}
	// Hospitals table
	else
	{
		// Get cell in hospitals table
		cell = [self.tableHospitals cellForRowAtIndexPath:indexPath];
	}
	
	// Remove selected hospital
	[self setSelectedHospital:nil];
	
	// Remove checkmark of selected hospital
	[cell setAccessoryType:UITableViewCellAccessoryNone];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Set hospital for MessageNewViewController
	if ([[segue identifier] isEqualToString:@"showMessageNewFromHospitalPicker"])
	{
		MessageNewTableViewController *messageNewViewController = segue.destinationViewController;
		
		// Set hospital
		[messageNewViewController setSelectedHospital:self.selectedHospital];
	}
	// If no Hospitals, ensure nothing happens when going back
	else if ([self.hospitals count] == 0)
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
