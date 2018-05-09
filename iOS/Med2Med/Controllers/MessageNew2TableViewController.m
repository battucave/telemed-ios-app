//
//  MessageNew2ViewController.m
//  Med2Med
//
//  Created by Shane Goodwin on 11/22/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "MessageNew2TableViewController.h"
#import "MessageNewTableViewController.h"
#import "NewMessageModel.h"

@interface MessageNew2TableViewController ()

@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;
@property (weak, nonatomic) IBOutlet UITextView *textViewAdditionalInformation;

@property (nonatomic) NSString *textViewAdditionalInformationPlaceholder;

@end

@implementation MessageNew2TableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	// Only set placeholder if it has not already been set
	if ( ! self.textViewAdditionalInformationPlaceholder)
	{
		self.textViewAdditionalInformationPlaceholder = self.textViewAdditionalInformation.text;
	}
	
	for (UITextField *textField in self.textFields)
	{
		// Set text field's value if it was previously set (user entered text on this screen, went back to previous screen, then returned here again)
		[textField setText:[self.formValues objectForKey:textField.accessibilityIdentifier]];
		
		// Programmatically add textFieldDidEditingChange listener to each text field (will be required in future when fields change depending on medical group)
		[textField addTarget:self action:@selector(textFieldDidEditingChange:) forControlEvents:UIControlEventEditingChanged];
	}
	
	// Set additional information's value if it was previously set (user entered text on this screen, then went back to MessageNewTableViewController, then clicked "Next" to return here again)
	NSString *additionalInformationValue = [self.formValues objectForKey:@"Additional Information"];
	
	if (additionalInformationValue)
	{
		[self.textViewAdditionalInformation setText:additionalInformationValue];
		
		// Turn off placeholder styling
		[self.textViewAdditionalInformation setTextColor:[UIColor blackColor]];
		[self.textViewAdditionalInformation setFont:[UIFont systemFontOfSize:14.0]];
	}
	
	// Force user interface changes to take effect
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableView beginUpdates];
		[self.tableView endUpdates];
	});
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Return updated form values back to previous screen
	if ([self.delegate respondsToSelector:@selector(setFormValues:)])
	{
		[self.delegate setFormValues:self.formValues];
	}
}

- (IBAction)sendNewMessage:(id)sender
{
	NewMessageModel *newMessageModel = [[NewMessageModel alloc] init];
	NSMutableArray *sortedKeys = [NSMutableArray array];
	
	// Create custom sort for optional form values
	for (UITextField *textField in self.textFields)
	{
		[sortedKeys addObject:textField.accessibilityIdentifier];
	}
	
	[sortedKeys addObject:@"Additional Information"];
	
	[newMessageModel setDelegate:self];
	[newMessageModel sendNewMessage:self.formValues withOrder:sortedKeys];
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
}

// Return success from NewMessageModel delegate (this logic should only be called after web service completes to avoid issues)
- (void)sendMessageSuccess
{
	UIAlertController *successAlertController = [UIAlertController alertControllerWithTitle:@"New Message" message:@"Thank you. Your message has been sent." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
	{
		// Unwind to first screen of message new form
		[self performSegueWithIdentifier:@"resetMessageNewForm" sender:self];
	}];

	[successAlertController addAction:actionOK];

	// PreferredAction only supported in 9.0+
	if ([successAlertController respondsToSelector:@selector(setPreferredAction:)])
	{
		[successAlertController setPreferredAction:actionOK];
	}

	// Show Alert
	[self presentViewController:successAlertController animated:YES completion:nil];
}

// Return error from NewMessageModel delegate (currently only used for callback number error)
- (void)sendMessageError:(NSError *)error
{
	// Unwind to first screen of message new form to show error for callback number
	if ([error.localizedDescription rangeOfString:@"CallbackPhone"].location != NSNotFound)
	{
		[self performSegueWithIdentifier:@"handleErrorCallbackNumber" sender:self];
	}
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
		[self.textViewAdditionalInformation becomeFirstResponder];
	}
	
	return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
	// Remove leading and trailing whitespace
	NSString *formValue = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	// Remove empty value for text view's key from form values
	if ([formValue isEqualToString:@""])
	{
		[self.formValues removeObjectForKey:textView.accessibilityIdentifier];
	}
	// Add/update value to form values for text view's key
	else
	{
		[self.formValues setValue:formValue forKey:textView.accessibilityIdentifier];
	}
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	// Hide placeholder
	if ([textView.text isEqualToString:self.textViewAdditionalInformationPlaceholder])
	{
		[textView setText:@""];
		[textView setTextColor:[UIColor blackColor]];
		[textView setFont:[UIFont systemFontOfSize:14.0]];
	}
	
	[textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	// Show placeholder
	if ([textView.text isEqualToString:@""])
	{
		[textView setText:self.textViewAdditionalInformationPlaceholder];
		[textView setTextColor:[UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1]];
		[textView setFont:[UIFont systemFontOfSize:15.0]];
	}
	
	[textView resignFirstResponder];
}

@end
