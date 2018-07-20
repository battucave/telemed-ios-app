//
//  MessageNewTableViewController.m
//  Med2Med
//
//  Created by Shane Goodwin on 11/22/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "MessageNewTableViewController.h"
#import "AccountPickerViewController.h"
#import "ErrorAlertController.h"
#import "HospitalPickerViewController.h"
#import "OnCallSlotPickerViewController.h"
#import "AccountModel.h"
#import "OnCallSlotModel.h"
#import "UserProfileModel.h"

@interface MessageNewTableViewController ()

@property (nonatomic) AccountModel *accountModel;

@property (weak, nonatomic) IBOutlet UITableViewCell *cellIntro;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellHospital;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellMedicalGroup;
@property (weak, nonatomic) IBOutlet UILabel *labelHospital;
@property (weak, nonatomic) IBOutlet UILabel *labelMedicalGroup;
@property (weak, nonatomic) IBOutlet UILabel *labelUrgencyLevel;
@property (weak, nonatomic) IBOutlet UISwitch *switchUrgencyLevel;
@property (strong, nonatomic) IBOutlet UIView *viewSectionFooter; // Must be a strong reference to show in table section footer

@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *cellFormFields;
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;

@property (nonatomic) NSMutableArray *accounts;
@property (nonatomic) BOOL hasSubmitted;
@property (nonatomic) NSMutableArray *hospitals;
@property (nonatomic) BOOL isLoading;
@property (nonatomic) BOOL shouldInitializeCallbackData;
@property (nonatomic) NSString *textUrgencyLevel;

@end

@implementation MessageNewTableViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Initialize form values
	[self setFormValues:[[NSMutableDictionary alloc] init]];
	
	// Initialize account model
	[self setAccountModel:[[AccountModel alloc] init]];
	[self.accountModel setDelegate:self];
	
	// Initialize hospital model
	HospitalModel *hospitalModel = [[HospitalModel alloc] init];
	
	[hospitalModel setDelegate:self];
	
	// Get list of hospitals (no need to reload these if user revisits this screen so don't put this in viewWillAppear method)
	[hospitalModel getHospitals];
	
	// Update flag to initialize callback data
	[self setShouldInitializeCallbackData:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	// Fix iOS 11+ issue with next button that occurs when returning back from on call slot picker screen. The next button will be selected, but there is no way to programmatically unselect it (UIBarButtonItem).
	if (self.hasSubmitted)
	{
		if (@available(iOS 11.0, *))
		{
			// Workaround the issue by completely replacing the next button with a brand new one
			UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:self.navigationItem.rightBarButtonItem.title style:self.navigationItem.rightBarButtonItem.style target:self action:@selector(showOnCallSlotPicker:)];
			
			[self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:nextButton, nil]];
		}
	}
	
	// Get label urgency level text
	[self setTextUrgencyLevel:[self.labelUrgencyLevel.text substringWithRange:NSMakeRange(0, [self.labelUrgencyLevel.text rangeOfString:@":"].location + 1)]];
	
	// Pre-populate callback data with data from user profile
	if (self.shouldInitializeCallbackData)
	{
		UserProfileModel *profile = [UserProfileModel sharedInstance];
		
		for (UITextField *textField in self.textFields)
		{
			// Callback first name
			if ([textField.accessibilityIdentifier isEqualToString:@"CallbackFirstName"])
			{
				[textField setText:profile.FirstName];
				[self.formValues setValue:textField.text forKey:textField.accessibilityIdentifier];
			}
			// Callback last name
			else if ([textField.accessibilityIdentifier isEqualToString:@"CallbackLastName"])
			{
				[textField setText:profile.LastName];
				[self.formValues setValue:textField.text forKey:textField.accessibilityIdentifier];
			}
			// Callback number
			else if ([textField.accessibilityIdentifier isEqualToString:@"CallbackPhoneNumber"])
			{
				[textField setText:profile.PhoneNumber];
				[self.formValues setValue:textField.text forKey:textField.accessibilityIdentifier];
			}
			// Callback title
			else if ([textField.accessibilityIdentifier isEqualToString:@"CallbackTitle"])
			{
				[textField setText:profile.JobTitlePrefix];
				[self.formValues setValue:textField.text forKey:textField.accessibilityIdentifier];
			}
		}
		
		// Disable initializing callback data if user returns back to this screen from message recipient picker screen
		[self setShouldInitializeCallbackData:NO];
	}
	
	// Validate form in case user return here via error unwind segue
	[self validateForm];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Hide keyboard when leaving view
	[self.view endEditing:YES];
}

// Error Unwind Segue for Callback Number from MessageNew2TableViewController
- (IBAction)handleErrorCallbackNumber:(UIStoryboardSegue *)segue
{
	NSString *callbackPhoneNumberValue = @"";
	
	for (UITextField *textField in self.textFields)
	{
		if ([textField.accessibilityIdentifier isEqualToString:@"CallbackPhoneNumber"])
		{
			// Retrieve existing value for callback number
			callbackPhoneNumberValue = textField.text;
			
			// Reset existing value for callback number
			[textField setText:@""];
		}
	}
	
	// Show error message without title for invalid callback number
	NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"", NSLocalizedFailureReasonErrorKey, [NSString stringWithFormat:@"Callback Number %@ is invalid. Please enter a valid phone number.", callbackPhoneNumberValue], NSLocalizedDescriptionKey, nil]];
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}

// Success Unwind Segue from MessageNew2TableViewController
- (IBAction)resetMessageNewForm:(UIStoryboardSegue *)segue
{
	// NOTE: Static cells do not reset when [self.tableView reloadData] is called. Instead, manually reset all data
	
	// Reset form values
	[self.formValues removeAllObjects];

	// Disable next button
	[self.navigationItem.rightBarButtonItem setEnabled:NO];

	// If user has exactly one hospital, then re-add it to form values
	if ([self.hospitals count] == 1)
	{
		[self.formValues setValue:self.selectedHospital.ID forKey:@"HospitalID"];
	}
	// Otherwise reset selected hospital
	else
	{
		[self setSelectedHospital:nil];
		[self.labelHospital setText:@""];
		
		// Show intro cell
		[self.cellIntro setHidden:NO];
		
		// Hide medical group cell
		[self.cellMedicalGroup setHidden:YES];
	}
	
	// Reset selected medical group (account)
	[self setSelectedAccount:nil];
	[self.labelMedicalGroup setText:@""];
	
	// Reset selected messages recipients
	[self.selectedMessageRecipients removeAllObjects];
	
	// Reset selected on call slot
	[self setSelectedOnCallSlot:nil];

	// Clear form fields
	for (UITextField *textField in self.textFields)
	{
		[textField setText:@""];
	}

	// Reset urgency level switch
	[self.switchUrgencyLevel setOn:NO];
	[self urgencyLevelChanged:self.switchUrgencyLevel];

	// Hide form field cells
	for (UITableViewCell *cellFormField in self.cellFormFields)
	{
		[cellFormField setHidden:YES];
	}
	
	// NOTE: Callback data will be pre-populated in viewWillAppear which runs immediately after this method
	[self setShouldInitializeCallbackData:YES];
	
	// Force user interface changes to take effect
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableView beginUpdates];
		[self.tableView endUpdates];
	});
}

// Unwind segue from AccountPickerViewController
- (IBAction)setAccount:(UIStoryboardSegue *)segue
{
	// Obtain reference to source view controller
	AccountPickerViewController *accountPickerViewController = segue.sourceViewController;
	
	// Save selected medical group (account)
	[self setSelectedAccount:accountPickerViewController.selectedAccount];
	
	// Add/update medical group (account) id to form values
	[self.formValues setValue:self.selectedAccount.ID forKey:@"AccountID"];
	
	[self.tableView beginUpdates];
	
	// Update medical group (account) label with medical group name
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

- (IBAction)textFieldDidEditingChange:(UITextField *)textField
{
	// Remove leading and trailing whitespace
	NSString *formValue = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

	// Remove empty value for text field's key from form values
	if ([formValue isEqualToString:@""])
	{
		[self.formValues removeObjectForKey:textField.accessibilityIdentifier];
	}
	// Add/update value to form values for text field's key
	else
	{
		[self.formValues setValue:formValue forKey:textField.accessibilityIdentifier];
	}
	
	// Validate form
	[self validateForm];
}

- (IBAction)urgencyLevelChanged:(id)sender
{
	// Update label urgency level text
	[self.labelUrgencyLevel setText:[NSString stringWithFormat:@"%@ %@", self.textUrgencyLevel, (self.switchUrgencyLevel.isOn ? @"Stat" : @"Normal")]];
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	// Format phone number as 000-000-0000x000
	if ([textField.accessibilityIdentifier isEqualToString:@"CallbackPhoneNumber"] && string.length > 0)
	{
		/*
		 * When an autocomplete entry is tapped, this method will be called twice: first with just a space character, and then again with the autocomplete value.
		 * The space character cannot be entered manually, so is therefore only used to indicate that autocomplete was used.
		 * Use this indication character to reset the existing text field text (if any) so that the autocomplete value becomes the only text in the field.
		 *   For example, if user begins typing a phone number, then taps an autocomplete entry corresponding to that initial value, then ensure that the autocomplete value does not get appended to the initial value, but instead replaces it.
		 */
		if ([string isEqualToString:@" "])
		{
			[textField setText:@""];
			
			return YES;
		}
		
		// Determine where text was changed
		UITextPosition *replacementStart = [textField positionFromPosition:textField.beginningOfDocument offset:range.location];
		UITextPosition *replacementEnd = [textField positionFromPosition:replacementStart offset:range.length];
		UITextRange *replacementRange = [textField textRangeFromPosition:replacementStart toPosition:replacementEnd];

		// Get the new cursor location after insert/paste/typing
		NSInteger cursorOffset = [textField offsetFromPosition:textField.beginningOfDocument toPosition:replacementStart];
		
		// Remove country code from string (primarily only applies when user taps autocomplete entry)
		NSString *newReplacementString = [string stringByReplacingOccurrencesOfString:@"+1" withString:@""];
		
		// Remove all non-numeric characters from replacement string
		newReplacementString = [NSString stringWithString:[[newReplacementString componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""]];
		
		// Insert replacement string into replacement range and adjust the cursor offset
		[textField replaceRange:replacementRange withText:newReplacementString];
		cursorOffset += newReplacementString.length;
		
		// Remove all non-numeric characters from text field's text so it can be formatted with separator characters
		NSMutableString *phoneNumber = [NSMutableString stringWithString:[[textField.text componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""]];
		NSUInteger phoneNumberLength = phoneNumber.length;
		
		// Adjust the cursor offset to reflect the removed non-numeric characters
		cursorOffset -= (textField.text.length - phoneNumberLength);
		
		if (phoneNumberLength >= 4)
		{
			// Add hyphen separator and adjust the cursor offset
			[phoneNumber insertString:@"-" atIndex:3];
			cursorOffset++;
		}

		if (phoneNumberLength >= 7)
		{
			// Add hyphen separator and adjust the cursor offset
			[phoneNumber insertString:@"-" atIndex:7];
			cursorOffset++;
		}
		
		// If user attempted to enter hash character to start extension, then convert it
		if (phoneNumberLength == 10 && [string isEqualToString:@"#"])
		{
			// Add extension separator and adjust the cursor offset
			[phoneNumber insertString:@"x" atIndex:12];
			cursorOffset++;
		}
		else if (phoneNumberLength >= 11)
		{
			// Add extension separator and adjust the cursor offset
			[phoneNumber insertString:@"x" atIndex:12];
			cursorOffset++;
		}

		// Update callback phone number field with formatted phone number
		[textField setText:phoneNumber];

		// Move the cursor and selected range to their new positions
		UITextPosition *newCursorPosition = [textField positionFromPosition:textField.beginningOfDocument offset:cursorOffset];
		UITextRange *newSelectedRange = [textField textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
		[textField setSelectedTextRange:newSelectedRange];

		// Text field's text was already changed so don't add the replacement string
		return NO;
	}
	
	return YES;
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

- (void)showOnCallSlotPicker:(id)sender
{
	[self performSegueWithIdentifier:@"showOnCallSlotPicker" sender:self];
}

// Return hospitals from hospital model delegate
- (void)updateHospitals:(NSMutableArray *)newHospitals
{
	// Filter and store only authenticated hospitals
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"MyAuthenticationStatus = %@ OR MyAuthenticationStatus = %@", @"OK", @"Admin"];
	
	[self setHospitals:[[newHospitals filteredArrayUsingPredicate:predicate] mutableCopy]];
	
	// If user has exactly one hospital, then set it as the selected hospital
	if ([self.hospitals count] == 1) {
		[self setSelectedHospital:[self.hospitals objectAtIndex:0]];
		
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
				// Strip any non-numeric characters from phone number
				NSString *phoneNumber = [NSString stringWithString:[[textField.text componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""]];
				
				if (phoneNumber.length < 10)
				{
					isValidated = NO;
				}
			}
			// Verify that field is not empty and contains at least one alphanumeric character (NOTE: client requested that callback title be required, but I suspect this will change in the future so the condition is simply commented out)
			else if (/*! [textField.accessibilityIdentifier isEqualToString:@"CallbackTitle"] &&*/ [[textField.text stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] isEqualToString:@""])
			{
				isValidated = NO;
			}
		}
	}
	
	// Re-enable next button
	[self.navigationItem.rightBarButtonItem setEnabled:isValidated];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	return (self.isLoading ? self.viewSectionFooter.frame.size.height : 0.1f);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 0.1f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	
	return (cell.hidden ? 0.0f : UITableViewAutomaticDimension);
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
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
		
		// Set accounts, set selected account, and enable account selection on account picker screen
		[accountPickerViewController setAccounts:self.accounts];
		[accountPickerViewController setSelectedAccount:self.selectedAccount];
		[accountPickerViewController setShouldSelectAccount:YES];
	}
	// Hospital picker
	else if ([segue.identifier isEqualToString:@"showHospitalPickerFromMessageNew"])
	{
		HospitalPickerViewController *hospitalPickerViewController = segue.destinationViewController;
		
		// Set hospitals, set selected hospital, and enable hospital selection on hospital picker screen
		[hospitalPickerViewController setHospitals:self.hospitals];
		[hospitalPickerViewController setSelectedHospital:self.selectedHospital];
		[hospitalPickerViewController setShouldSelectHospital:YES];
	}
	// On call slot picker
	else if ([segue.identifier isEqualToString:@"showOnCallSlotPicker"])
	{
		OnCallSlotPickerViewController *onCallSlotPickerViewController = segue.destinationViewController;
		
		// Add urgency value to form values
		[self.formValues setValue:(self.switchUrgencyLevel.isOn ? @"true" : @"false") forKey:@"STAT"];
		
		[onCallSlotPickerViewController setDelegate:self];
		[onCallSlotPickerViewController setFormValues:self.formValues];
		[onCallSlotPickerViewController setSelectedAccount:self.selectedAccount];
		
		// If user returned back to this screen, then he/she may have already selected message recipients so pre-select them on the message recipient picker screen
		[onCallSlotPickerViewController setSelectedMessageRecipients:self.selectedMessageRecipients];
		
		// If user returned back to this screen, then he/she may have already selected the on call slot so pre-select them on the on call slot picker screen
		[onCallSlotPickerViewController setSelectedOnCallSlot:self.selectedOnCallSlot];
		
		// Update has submitted value to trigger appearance changes if user returns back to this screen
		[self setHasSubmitted:YES];
	}
}

@end
