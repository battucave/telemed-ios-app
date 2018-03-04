//
//  MessageNewTableViewController.m
//  MedToMed
//
//  Created by Shane Goodwin on 11/22/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "MessageNewTableViewController.h"
#import "AccountPickerViewController.h"
#import "ErrorAlertController.h"
#import "HospitalPickerViewController.h"
#import "MessageRecipientPickerViewController.h"
#import "AccountModel.h"
#import "UserProfileModel.h"

@interface MessageNewTableViewController ()

@property (nonatomic) AccountModel *accountModel;

@property (weak, nonatomic) IBOutlet UITableViewCell *cellIntro;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellHospital;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellMedicalGroup;
@property (weak, nonatomic) IBOutlet UILabel *labelHospital;
@property (weak, nonatomic) IBOutlet UILabel *labelMedicalGroup;
@property (weak, nonatomic) IBOutlet UISwitch *switchUrgencyLevel;
@property (strong, nonatomic) IBOutlet UIView *viewSectionFooter; // Must be a strong reference to show in table section footer

@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *cellFormFields;

@property (nonatomic) NSMutableArray *accounts;
@property (nonatomic) BOOL hasSubmitted;
@property (nonatomic) NSMutableArray *hospitals;
@property (nonatomic) BOOL isLoading;

@end

@implementation MessageNewTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Initialize Account Model
	[self setAccountModel:[[AccountModel alloc] init]];
	[self.accountModel setDelegate:self];
	
	// Initialize form values
	[self setFormValues:[[NSMutableDictionary alloc] init]];
	
	// Get list of hospitals (no need to reload these if user revisits this screen so don't put this in viewWillAppear method)
	// Initialize hospital model
	HospitalModel *hospitalModel = [[HospitalModel alloc] init];
	
	[hospitalModel setDelegate:self];
	[hospitalModel getHospitals];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	// Fix iOS 11+ issue with next button that occurs when returning back from message recipient picker screen. The next button will be selected, but there is no way to programmatically unselect it (UIBarButtonItem).
	if (self.hasSubmitted)
	{
		if (@available(iOS 11.0, *))
		{
			// Workaround the issue by completely replacing the next button with a brand new one
			UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(showMessageRecipientPicker:)];
			
			[self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:nextButton, nil]];
		}
	}
	
	// Pre-populate callback data with data from user profile
	UserProfileModel *profile = [UserProfileModel sharedInstance];
	
	for (UITextField *textField in self.textFields)
	{
		// Callback first name
		if ([textField.accessibilityIdentifier isEqualToString:@"CallbackFirstName"])
		{
			// Verify a value hasn't already been set
			if (! [self.formValues objectForKey:textField.accessibilityIdentifier])
			{
				[textField setText:profile.FirstName];
				[self textFieldDidEditingChange:textField];
			}
		}
		// Callback last name
		else if ([textField.accessibilityIdentifier isEqualToString:@"CallbackLastName"])
		{
			// Verify a value hasn't already been set
			if (! [self.formValues objectForKey:textField.accessibilityIdentifier])
			{
				[textField setText:profile.LastName];
				[self textFieldDidEditingChange:textField];
			}
		}
		// Callback number
		else if ([textField.accessibilityIdentifier isEqualToString:@"CallbackPhoneNumber"])
		{
			// Verify a value hasn't already been set
			if (! [self.formValues objectForKey:textField.accessibilityIdentifier])
			{
				[textField setText:profile.PhoneNumber];
				[self textFieldDidEditingChange:textField];
			}
		}
		// Callback title
		else if ([textField.accessibilityIdentifier isEqualToString:@"CallbackTitle"])
		{
			// Verify a value hasn't already been set
			if (! [self.formValues objectForKey:textField.accessibilityIdentifier])
			{
				[textField setText:profile.JobTitlePrefix];
				[self textFieldDidEditingChange:textField];
			}
		}
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Hide keyboard when leaving view
	[self.view endEditing:YES];
}

// Unwind Segue from MessageNew2TableViewController
- (IBAction)resetMessageNewForm:(UIStoryboardSegue *)segue
{
	// NOTE: Static cells do not reset when [self.tableView reloadData] is called so instead, manually reset all data
	
	// Reset selected medical group (account)
	[self setSelectedAccount:nil];
	
	// Reset selected hospital
	[self setSelectedHospital:nil];
	
	// Reset form values
	[self.formValues removeAllObjects];
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableView beginUpdates];
		
		// Disable next button
		[self.navigationItem.rightBarButtonItem setEnabled:NO];
	
		// Show intro cell
		[self.cellIntro setHidden:NO];
		
		// Clear hospital label
		[self.labelHospital setText:@""];
		
		// Clear medical group label
		[self.labelMedicalGroup setText:@""];
		
		// Clear form fields
		for (UITextField *textField in self.textFields)
		{
			[textField setText:@""];
		}
		
		// Reset urgency level switch
		[self.switchUrgencyLevel setOn:NO];
		
		// Hide medical group cell
		[self.cellMedicalGroup setHidden:YES];
		
		// Hide form field cells
		for (UITableViewCell *cellFormField in self.cellFormFields)
		{
			[cellFormField setHidden:YES];
		}
		
		[self.tableView endUpdates];
	});
}

// Unwind segue from AccountPickerViewController
- (IBAction)setAccount:(UIStoryboardSegue *)segue
{
	// Obtain reference to source view controller
	AccountPickerViewController *accountPickerViewController = segue.sourceViewController;
	
	// Save selected account
	[self setSelectedAccount:accountPickerViewController.selectedAccount];
	
	// Add/update account id to form values
	[self.formValues setValue:self.selectedAccount.ID forKey:@"AccountID"];
	
	[self.tableView beginUpdates];
	
	// Update medical group label with medical group (account) name
	[self.labelMedicalGroup setText:self.selectedAccount.Name];
	
	// Show form field cells
	for (UITableViewCell *cellFormField in self.cellFormFields)
	{
		[cellFormField setHidden:NO];
	}
	
	[self.tableView endUpdates];
	
	// Validate form
	[self validateForm];
}

// Unwind segue from HospitalPickerViewController
- (IBAction)setHospital:(UIStoryboardSegue *)segue
{
	// Obtain reference to source view controller
	HospitalPickerViewController *hospitalPickerViewController = segue.sourceViewController;
	
	// Save selected hospital
	[self setSelectedHospital:hospitalPickerViewController.selectedHospital];
	
	// Update screen with selected hospital information
	[self setHospital];
}

- (IBAction)showMessageRecipientPicker:(id)sender
{
	[self setHasSubmitted:YES];
	
	[self performSegueWithIdentifier:@"showMessageRecipientPicker" sender:self];
}

- (IBAction)textFieldDidEditingChange:(UITextField *)textField
{
	// Remove empty value for text field's key from form values
	if ([textField.text isEqualToString:@""])
	{
		[self.formValues removeObjectForKey:textField.accessibilityIdentifier];
	}
	// Add/update value to form values for text field's key
	else
	{
		[self.formValues setValue:textField.text forKey:textField.accessibilityIdentifier];
	}
	
	// Validate form
	[self validateForm];
}

- (void)setHospital
{
	// Add/update hospital id to form values
	[self.formValues setValue:self.selectedHospital.ID forKey:@"HospitalID"];
	
	[self.tableView beginUpdates];
	
	// Hide intro cell
	[self.cellIntro setHidden:YES];
	
	// Show loading indicator in table footer
	[self setIsLoading:YES];
	
	// Update hospital label with hospital name
	[self.labelHospital setText:self.selectedHospital.Name];
	
	[self.tableView endUpdates];
	
	// Load accounts for hospital
	[self.accountModel getAccountsByHospital:self.selectedHospital.ID withCallback:^(BOOL success, NSMutableArray *accounts, NSError *error)
	{
		if (success)
		{
			// Filter and store only authorized accounts
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"MyAuthorizationStatus = %@", @"Authorized"];
			[self setAccounts:[[accounts filteredArrayUsingPredicate:predicate] mutableCopy]];
			
			dispatch_async(dispatch_get_main_queue(), ^
			{
				// Show medical group cell
				[self.cellMedicalGroup setHidden:NO];
				
				// If medical group (account) already selected, verify that it has access to this hospital
				if (self.selectedAccount)
				{
					// Find selected account in accounts (can be used to find account even if it was not originally extracted from accounts array - i.e. MyProfile.MyPreferredAccount)
					NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ID = %@", self.selectedAccount.ID];
					NSArray *results = [self.accounts filteredArrayUsingPredicate:predicate];
					
					// Selected medical group (account) has no access to hospital so remove it
					if ([results count] == 0)
					{
						[self setSelectedAccount:nil];
						
						// Remove medical group label name
						[self.labelMedicalGroup setText:@""];
					}
				}
				
				// Hide loading indicator in table footer
				[self setIsLoading:NO];
				
				// Force table section footer to update
				[self.tableView reloadData];
			});
		}
		else
		{
			ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
			
			[errorAlertController show:error];
		}
	}];
	
	// Validate form
	[self validateForm];
}

// Return hospitals from hospital model delegate
- (void)updateHospitals:(NSMutableArray *)hospitals
{
	// Filter and store only authenticated hospitals
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"MyAuthenticationStatus = %@ OR MyAuthenticationStatus = %@", @"OK", @"Admin"];
	
	[self setHospitals:[[hospitals filteredArrayUsingPredicate:predicate] mutableCopy]];
	
	// If user has exactly one hospital, then set it as the selected hospital to save user time
	if ([self.hospitals count] == 1) {
		[self setSelectedHospital:[hospitals objectAtIndex:0]];
		
		[self setHospital];
		
		// Prevent user from being able to go to hospital picker screen and hide the cell's disclosure indicator
		[self.cellHospital setAccessoryType:UITableViewCellAccessoryNone];
		[self.cellHospital setUserInteractionEnabled:NO];
	}
}

// Return error from hospital model delegate
- (void)updateHospitalsError:(NSError *)error
{
	// Don't show error here - there will be another chance to load hospitals on hospital picker screen
}

// Check required fields to determine if form can continue to next page
- (void)validateForm
{
	// Verify that an account and hospital have been selected
	BOOL isValidated = (self.selectedAccount != nil && self.selectedHospital != nil);
	
	if (isValidated)
	{
		for (UITextField *textField in self.textFields)
		{
			// Verify that callback phone number is a valid phone number
			if ([textField.accessibilityIdentifier isEqualToString:@"CallbackPhoneNumber"])
			{
				if ([textField.text length] < 10)
				{
					isValidated = NO;
				}
			}
			// Verify that field is not empty
			else if (! [textField.accessibilityIdentifier isEqualToString:@"CallbackTitle"] && [textField.text isEqualToString:@""])
			{
				isValidated = NO;
			}
		}
	}
	
	[self.navigationItem.rightBarButtonItem setEnabled:isValidated];
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
	
	return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	return (self.isLoading ? self.viewSectionFooter.frame.size.height : 0.1);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 0.1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	
	return (cell.hidden ? 0 : [super tableView:tableView heightForRowAtIndexPath:indexPath]);
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	/* if (self.isLoading)
	{
		UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 10.0f, self.tableView.bounds.size.width, 54.0f)];
		
		[activityIndicatorView startAnimating];
		[activityIndicatorView setFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 44.0f)];
		[activityIndicatorView setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
		
		[containerView addSubview:activityIndicatorView];

		return containerView;
	}*/
	
	// Only show table footer if loading is enabled
	return (self.isLoading ? self.viewSectionFooter : nil);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Account picker
	if ([segue.identifier isEqualToString:@"showAccountPickerFromMessageNew"])
	{
		AccountPickerViewController *accountPickerViewController = segue.destinationViewController;
		
		// Update account picker screen title
		[accountPickerViewController setTitle:@"Choose Medical Group"];
		
		// Enable account selection, set accounts, and set selected account on account picker screen
		[accountPickerViewController setShouldSelectAccount:YES];
		[accountPickerViewController setAccounts:self.accounts];
		[accountPickerViewController setSelectedAccount:self.selectedAccount];
	}
	// Hospital picker
	else if ([segue.identifier isEqualToString:@"showHospitalPickerFromMessageNew"])
	{
		HospitalPickerViewController *hospitalPickerViewController = segue.destinationViewController;
		
		// Enable hospital selection and set selected hospital on hospital picker screen
		[hospitalPickerViewController setShouldSelectHospital:YES];
		[hospitalPickerViewController setSelectedHospital:self.selectedHospital];
	}
	// Message recipient picker
	else if ([segue.identifier isEqualToString:@"showMessageRecipientPicker"])
	{
		MessageRecipientPickerViewController *messageRecipientPickerViewController = segue.destinationViewController;
		
		// Update form values with urgency value
		[self.formValues setValue:(self.switchUrgencyLevel.isOn ? @"true" : @"false") forKey:@"STAT"];
		
		[messageRecipientPickerViewController setDelegate:self];
		[messageRecipientPickerViewController setFormValues:self.formValues];
		[messageRecipientPickerViewController setSelectedAccount:self.selectedAccount];
		
		// If user returned back to this screen, then he/she may have already set message recipients so pre-select them on message recipient picker screen
		[messageRecipientPickerViewController setSelectedMessageRecipients:(NSMutableArray *)[self.formValues objectForKey:@"MessageRecipients"]];
	}
}

@end
