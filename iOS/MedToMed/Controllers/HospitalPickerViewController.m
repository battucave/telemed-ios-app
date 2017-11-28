//
//  HospitalPickerViewController.m
//  TeleMed
//
//  Created by Shane Goodwin on 11/28/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "HospitalPickerViewController.h"
#import "HospitalCell.h"
//#import "HospitalModel.h"

@interface HospitalPickerViewController ()

//@property (nonatomic) HospitalModel *hospitalModel;

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
	if([self.hospitals count] == 0)
	{
		// Initialize Hospital Model
		/*[self setHospitalModel:[[HospitalModel alloc] init]];
		[self.hospitalModel setDelegate:self];
		
		// Get list of Hospitals
		[self.hospitalModel getHospitals];*/
	}
	
	// Initialize Search Controller
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	
	[self.searchController setDelegate:self];
	[self.searchController setDimsBackgroundDuringPresentation:NO];
	//[self.searchController setHidesNavigationBarDuringPresentation:NO];
	[self.searchController setSearchResultsUpdater:self];
	
	self.definesPresentationContext = YES;
	
	// Initialize Search Bar
	[self.searchController.searchBar setDelegate:self];
	[self.searchController.searchBar setPlaceholder:@"Search Hospitals"];
	[self.searchController.searchBar sizeToFit];
	
	// iOS 11+ navigation bar has support for search controller
	if(@available(iOS 11.0, *))
	{
		[self.navigationItem setSearchController:self.searchController];
		
		[self.viewSearchBarContainer setHidden:YES];
		
		for(NSLayoutConstraint *constraint in self.viewSearchBarContainer.constraints)
		{
			if(constraint.firstAttribute == NSLayoutAttributeHeight)
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
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	// Reset Search Results (put here because it's animation must occur AFTER any segue)
	if(self.searchController.active)
	{
		[self.searchController setActive:NO];
	}
}

// Return Hospitals from HospitalModel delegate
- (void)updateHospitals:(NSMutableArray *)newHospitals
{
	[self setHospitals:newHospitals];
	
	self.isLoaded = YES;
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableHospitals reloadData];
	});
}

// Return error from HospitalModel delegate
- (void)updateHospitalsError:(NSError *)error
{
	self.isLoaded = YES;
	
	// Show error message
	//[self.hospitalModel showError:error];
}

// Delegate Method for Updating Search Results
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSPredicate *predicate;
	NSString *text = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	NSLog(@"Text: %@", text);
	
	// Reset Filtered Hospitals
	[self.filteredHospitals removeAllObjects];
	
	// Filter Hospitals when search string contains space if Name and PublicKey begin with the parts of search text
	if([text rangeOfString:@" "].location != NSNotFound)
	{
		NSArray *textParts = [text componentsSeparatedByString:@" "];
		NSString *publicKey = [textParts objectAtIndex:0];
		NSString *name = [textParts objectAtIndex:1];
		predicate = [NSPredicate predicateWithFormat:@"(SELF.Name CONTAINS[c] %@) OR (SELF.Name CONTAINS[c] %@ AND SELF.PublicKey BEGINSWITH[c] %@) OR (SELF.Name CONTAINS[c] %@ AND SELF.PublicKey BEGINSWITH[c] %@)", text, publicKey, name, name, publicKey];
	}
	// Filter Hospitals if Name or PublicKey begins with search text
	else
	{
		predicate = [NSPredicate predicateWithFormat:@"SELF.Name CONTAINS[c] %@ OR SELF.PublicKey BEGINSWITH[c] %@", text, text];
	}
	
	[self setFilteredHospitals:[NSMutableArray arrayWithArray:[self.hospitals filteredArrayUsingPredicate:predicate]]];
	
	[self.tableHospitals reloadData];
}

// Delegate Method for clicking Cancel button on Search Results
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	// Close Search Results
	[self.searchController setActive:NO];
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
		if([self.filteredHospitals count] == 0)
		{
			return 1;
		}
		
		return [self.filteredHospitals count];
	}
	// Hospitals Table
	else
	{
		if([self.hospitals count] == 0)
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
	if([self.hospitals count] == 0)
	{
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	}
	
	return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([self.hospitals count] == 0 || (self.searchController.active && self.searchController.searchBar.text.length > 0 && [self.filteredHospitals count] == 0))
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:12.0]];
		// [emptyCell.textLabel setText:(self.isLoaded ? @"No messages found." : @"Loading...")];
		[emptyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		// Hospitals table
		if([self.hospitals count] == 0)
		{
			[emptyCell.textLabel setText:(self.isLoaded ? @"No messages found." : @"Loading...")];
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
	
	// Search Results table
	if(self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		hospital = [self.filteredHospitals objectAtIndex:indexPath.row];
	}
	// Hospitals table
	else
	{
		hospital = [self.hospitals objectAtIndex:indexPath.row];
	}
	
	// Set previously selected Hospital as selected and add checkmark
	if(self.selectedHospital && [hospital.ID isEqualToNumber:self.selectedHospital.ID])
	{
		[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	}
	
	// Set Hospital Name label
	[cell.hospitalName setText:hospital.Name];
	
	// Set Hospital Number label
	[cell.hospitalPublicKey setText:hospital.PublicKey];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
	// Search Results Table
	if(self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		// If no Filtered Hospitals, then user clicked "No results."
		if([self.filteredHospitals count] == 0)
		{
			// Close Search Results (must execute before scrolling to selected Hospital
			[self.searchController setActive:NO];
			
			// Scroll to selected Hospital
			[self scrollToSelectedHospital];
			
			return;
		}
		
		// Set selected Hospital (in case user presses back button from next screen)
		[self setSelectedHospital:[self.filteredHospitals objectAtIndex:indexPath.row]];
		
		// Get cell in Hospitals Table
		int indexRow = (int)[self.hospitals indexOfObject:self.selectedHospital];
		cell = [self.tableHospitals cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0]];
		
		// Select cell (not needed - if user presses back button from next screen, viewWillAppear method handles selecting the selected Hospital)
		//[self.tableHospitals selectRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
	// Hospitals Table
	else
	{
		// Set selected Hospital (in case user presses back button from next screen)
		[self setSelectedHospital:[self.hospitals objectAtIndex:indexPath.row]];
		
		// Get cell in Hospitals Table
		cell = [self.tableHospitals cellForRowAtIndexPath:indexPath];
	}
	
	// Add checkmark of selected Hospital
	[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	
	// If using SettingsPreferredHospitalPicker view from storyboard
	if(self.shouldSetPreferredHospital)
	{
		// Save Preferred Hospital to server
		PreferredHospitalModel *preferredHospitalModel = [[PreferredHospitalModel alloc] init];
		
		[preferredHospitalModel setDelegate:self];
		[preferredHospitalModel savePreferredHospital:self.selectedHospital];
	}
	// If using NewMessageHospitalPicker view from storyboard
	else
	{
		// Go to MessageRecipientPickerTableViewController
		[self performSegueWithIdentifier:@"showMessageRecipientPickerFromHospitalPicker" sender:cell];
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
	// Search Results Table
	if(self.searchController.active && self.searchController.searchBar.text.length > 0)
	{
		// Close Search Results
		[self.searchController setActive:NO];
		
		// Get cell in Message Hospitals Table
		int indexRow = (int)[self.hospitals indexOfObject:self.selectedHospital];
		cell = [self.tableHospitals cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0]];
		
		// Deselect cell
		[self.tableHospitals deselectRowAtIndexPath:[NSIndexPath indexPathForRow:indexRow inSection:0] animated:NO];
	}
	// Hospitals Table
	else
	{
		// Get cell in Hospitals Table
		cell = [self.tableHospitals cellForRowAtIndexPath:indexPath];
	}
	
	// Remove selected Hospital
	[self setSelectedHospital:nil];
	
	// Remove checkmark of selected Hospital
	[cell setAccessoryType:UITableViewCellAccessoryNone];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Set Hospital for MessageRecipientPickerTableViewController
	if([[segue identifier] isEqualToString:@"showMessageRecipientPickerFromHospitalPicker"])
	{
		MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.destinationViewController;
		
		// Set Hospital
		[messageRecipientPickerViewController setSelectedHospital:self.selectedHospital];
		
		// Set selected Message Recipients if previously set (this is simply passed through from Message New)
		[messageRecipientPickerViewController setSelectedMessageRecipients:[self.selectedMessageRecipients mutableCopy]];
	}
	// If no Hospitals, ensure nothing happens when going back
	else if([self.hospitals count] == 0)
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
