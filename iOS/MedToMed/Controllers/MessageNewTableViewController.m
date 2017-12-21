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
#import "MessageNew2TableViewController.h"
#import "AccountModel.h"

@interface MessageNewTableViewController ()

@property (nonatomic) AccountModel *accountModel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonNext;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellIntro;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellMedicalGroup;
@property (weak, nonatomic) IBOutlet UILabel *labelHospital;
@property (weak, nonatomic) IBOutlet UILabel *labelMedicalGroup;
@property (weak, nonatomic) IBOutlet UISwitch *switchPriority;
@property (strong, nonatomic) IBOutlet UIView *viewSectionFooter; // Must be a strong reference to show in table section footer

@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *cellFormFields;

@property (nonatomic) NSMutableArray *accounts;
@property (nonatomic) BOOL hasSubmitted;
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
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	// Fix iOS 11+ issue with next button that occurs when returning back from MessageNew2 screen. The next button will be selected, but there is no way to programmatically unselect it (UIBarButtonItem).
	if (self.hasSubmitted)
	{
		if (@available(iOS 11.0, *))
		{
			// Workaround the issue by completely replacing the next button with a brand new one
			[self setButtonNext:[[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(showMessageNew2:)]];
			
			[self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.buttonNext, nil]];
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
		
		// Reset priority switch
		[self.switchPriority setOn:NO];
		
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

- (IBAction)showMessageNew2:(id)sender
{
	[self setHasSubmitted:YES];
	
	[self performSegueWithIdentifier:@"showMessageNew2" sender:self];
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

// Check required fields to determine if form can continue to next page
- (void)validateForm
{
	// Verify that an account and hospital have been selected
	BOOL isValidated = (self.selectedAccount != nil && self.selectedHospital != nil);
	
	if (isValidated)
	{
		for (UITextField *textField in self.textFields)
		{
			// Verify that callback number is a valid phone number
			if ([textField.accessibilityIdentifier isEqualToString:@"CallbackNumber"])
			{
				if ([textField.text length] < 7)
				{
					isValidated = NO;
				}
			}
			// Verify that field is not empty
			else if ([textField.text isEqualToString:@""])
			{
				isValidated = NO;
			}
		}
	}
	
	[self.buttonNext setEnabled:isValidated];
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
	// Message new 2
	else if ([segue.identifier isEqualToString:@"showMessageNew2"])
	{
		MessageNew2TableViewController *messageNew2TableViewController = segue.destinationViewController;
		
		// Update form values with priority value
		[self.formValues setValue:(self.switchPriority.isOn ? @"Stat" : @"Normal") forKey:@"Priority"];
		
		[messageNew2TableViewController setDelegate:self];
		[messageNew2TableViewController setFormValues:self.formValues];
	}
}

@end
