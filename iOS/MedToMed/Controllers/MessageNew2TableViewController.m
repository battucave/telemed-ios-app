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
@property (nonatomic) IBOutlet UITextView *textViewMessageText;

@property (nonatomic) NSString *textViewMessageTextPlaceholder;

@end

@implementation MessageNew2TableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	// Only set placeholder if it has not already been set
	if ( ! self.textViewMessageTextPlaceholder)
	{
		self.textViewMessageTextPlaceholder = self.textViewMessageText.text;
	}
	
	// Programmatically add textFieldDidEditingChange listener to each text field (will be needed in future when fields change depending on medical group)
	for (UITextField *textField in self.textFields)
	{
		[textField addTarget:self action:@selector(textFieldDidEditingChange:) forControlEvents:UIControlEventEditingChanged];
	}
}

- (IBAction)sendNewMessage:(id)sender
{
	NewMessageModel *newMessageModel = [[NewMessageModel alloc] init];
	
	[newMessageModel setDelegate:self];
	[newMessageModel sendNewMessage:self.formValues];
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
		[self.textViewMessageText becomeFirstResponder];
	}
	
	return NO;
}

- (void)textViewDidChange:(UITextView *)textView
{
	// Remove empty value for text field's key from form values
	if ([textView.text isEqualToString:@""])
	{
		[self.formValues removeObjectForKey:textView.accessibilityIdentifier];
	}
	// Add/update value to form values for text field's key
	else
	{
		[self.formValues setValue:textView.text forKey:textView.accessibilityIdentifier];
	}
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	// Hide placeholder
	if ([textView.text isEqualToString:self.textViewMessageTextPlaceholder])
	{
		[textView setText:@""];
		[textView setTextColor:[UIColor blackColor]];
		[textView setFont:[UIFont systemFontOfSize:14.0]];
	}
	
	[textView becomeFirstResponder];
}

/*- (void)textViewDidChange:(UITextView *)textView
{
	// Validate form in delegate
	if ([self.delegate respondsToSelector:@selector(validateForm:)])
	{
		[self.delegate validateForm:self.textViewMessage.text];
	}
}*/

- (void)textViewDidEndEditing:(UITextView *)textView
{
	// Show placeholder
	if ([textView.text isEqualToString:@""])
	{
		[textView setText:self.textViewMessageTextPlaceholder];
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
