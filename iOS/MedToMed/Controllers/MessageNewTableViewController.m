//
//  MessageNewTableViewController.m
//  MedToMed
//
//  Created by Shane Goodwin on 11/22/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "MessageNewTableViewController.h"
#import "HospitalPickerViewController.h"

@interface MessageNewTableViewController ()

@property (nonatomic) IBOutlet UILabel *labelHospital;
@property (nonatomic) IBOutlet UILabel *labelMedicalGroup;
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;

@end

@implementation MessageNewTableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	// TEST - Get text field identifier by its accessibility identifier (see SettingsProfileTableViewController's setTextFieldValues)
	for (UITextField *textField in self.textFields)
	{
		NSLog(@"Identifier: %@", textField.accessibilityIdentifier);
	}
	
	/*UIView *leftPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 154, 22)];
	
	for(UITextField *textField in self.textFields)
{
		[textField setLeftView:leftPaddingView];
		[textField setLeftViewMode:UITextFieldViewModeAlways];
	}*/
}

// Unwind Segue from HospitalPickerViewController
- (IBAction)setHospital:(UIStoryboardSegue *)segue
{
	// Obtain reference to source view controller
	HospitalPickerViewController *hospitalPickerViewController = segue.sourceViewController;
	
	// Save selected hospital
	[self setSelectedHospital:hospitalPickerViewController.selectedHospital];
	
	// Update hospital label with hospital name
	[self.labelHospital setText:self.selectedHospital.Name];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSUInteger currentIndex = [self.textFields indexOfObject:textField];
	NSUInteger nextIndex = currentIndex + 1;
	
	if (nextIndex < [self.textFields count])
	{
		[[self.textFields objectAtIndex:nextIndex] becomeFirstResponder];
	}
	else
	{
		[[self.textFields objectAtIndex:currentIndex] resignFirstResponder];
	}
	
	return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showMyHospitalsFromMessageNew"])
	{
		HospitalPickerViewController *hospitalPickerViewController = segue.destinationViewController;
		
		// Enable hospital selection on hospital picker screen
		[hospitalPickerViewController setShouldSetHospital:YES];
		
		// Set selected hospital if previously set
		[hospitalPickerViewController setSelectedHospital:self.selectedHospital];
	}
}

@end
