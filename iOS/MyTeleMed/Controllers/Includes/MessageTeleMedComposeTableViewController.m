//
//  MessageTeleMedComposeTableViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 5/3/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "MessageTeleMedComposeTableViewController.h"
#import "MyProfileModel.h"

@interface MessageTeleMedComposeTableViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *cellMessageRecipient;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellMessageSender;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellMessage;

@end

@implementation MessageTeleMedComposeTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Set User Email Address
	MyProfileModel *myProfileModel = [MyProfileModel sharedInstance];
	
	[self.textFieldSender setText:myProfileModel.Email];
}

- (CGFloat)calculateCellMessageHeight:(CGFloat)keyboardHeight
{
	return self.parentViewController.view.frame.size.height - keyboardHeight - self.cellMessageRecipient.bounds.size.height - self.cellMessageSender.bounds.size.height;
}

- (IBAction)textFieldDidChangeEditing:(UITextField *)textField
{
	// Validate form in delegate
	if([self.delegate respondsToSelector:@selector(validateForm:senderEmailAddress:)])
	{
		[self.delegate validateForm:self.textViewMessage.text senderEmailAddress:self.textFieldSender.text];
	}
}

- (void)textViewDidChange:(UITextView *)textView
{
	// Validate form in delegate
	if([self.delegate respondsToSelector:@selector(validateForm:senderEmailAddress:)])
	{
		[self.delegate validateForm:self.textViewMessage.text senderEmailAddress:self.textFieldSender.text];
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.row == 2)
	{
		return self.cellMessageHeight;
	}
	
	// Can't use super here because it would call MessageComposeTableViewController which has different heights
	return [[[UITableViewController alloc] init] tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
	// Remove Notification Observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
