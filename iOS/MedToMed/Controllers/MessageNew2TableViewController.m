//
//  MessageNew2ViewController.m
//  MedToMed
//
//  Created by Shane Goodwin on 11/22/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "MessageNew2TableViewController.h"
#import "MessageNewTableViewController.h"
#import "NewMessageModel.h"

@interface MessageNew2TableViewController ()

@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;
@property (nonatomic) IBOutlet UITextView *textViewAdditionalInformation;

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
		// Set text field's value if it was previously set (user entered text on this screen, then went back to MessageNewTableViewController, then clicked "Next" to return here again)
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
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
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
}

// Return pending from NewMessageModel delegate
- (void)sendMessagePending
{
	// TEMPORARY (remove when NewMsg web service completed)
	UIAlertController *successAlertController = [UIAlertController alertControllerWithTitle:@"Send Message Incomplete" message:@"Web services are incomplete for sending messages." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		// Unwind to first screen of message new form (assume success)
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
	// END TEMPORARY
}

// Return success from NewMessageModel delegate (this should be called when NewMsg web service completed)
- (void)sendMessageSuccess
{
	UIAlertController *successAlertController = [UIAlertController alertControllerWithTitle:@"New Message" message:@"Message sent successfully." preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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

/*/ Return error from NewMessageModel delegate (no longer used)
- (void)sendMessageError:(NSError *)error
{
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}*/

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
	
	return NO;
}

- (void)textViewDidChange:(UITextView *)textView
{
	// Remove empty value for text view's key from form values
	if ([textView.text isEqualToString:@""])
	{
		[self.formValues removeObjectForKey:textView.accessibilityIdentifier];
	}
	// Add/update value to form values for text view's key
	else
	{
		[self.formValues setValue:textView.text forKey:textView.accessibilityIdentifier];
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

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
