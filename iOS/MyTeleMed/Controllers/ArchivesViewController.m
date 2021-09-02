//
//  ArchivesViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "ArchivesViewController.h"
#import "ArchivesPickerViewController.h"
#import "MessagesTableViewController.h"
#import "SWRevealViewController.h"

@interface ArchivesViewController ()

@property (nonatomic) MessagesTableViewController *messagesTableViewController;
@property (nonatomic) ArchivesPickerViewController *archivesPickerViewController;

@property (weak, nonatomic) IBOutlet UILabel *labelResults;
@property (weak, nonatomic) IBOutlet UIView *viewContainer;
@property (weak, nonatomic) IBOutlet UIView *viewSwipeMessage;

@property (nonatomic) IBOutlet NSLayoutConstraint *constraintLabelResultsBorderHeight;

@property (nonatomic) NSInteger selectedAccountIndex;
@property (nonatomic) NSString *selectedAccount;
@property (nonatomic) NSInteger selectedDateIndex;
@property (nonatomic) NSString *selectedDate;

@end

@implementation ArchivesViewController

- (void)viewWillAppear:(BOOL)animated
{
	NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
	
	// Hide swipe message if it has been disabled (triggering a swipe to open the menu or refresh the table will disable it)
	if ([settings boolForKey:SWIPE_MESSAGE_DISABLED])
	{
		[self.viewSwipeMessage setHidden:YES];
	}
	
	[super viewWillAppear:animated];
	
	// Adjust height of label results border to be 1px regardless of device scale
	[self.constraintLabelResultsBorderHeight setConstant:1.0 / [UIScreen mainScreen].scale];
}

// Unwind segue from ArchivesPickerViewController
- (IBAction)unwindSetArchiveFilter:(UIStoryboardSegue *)segue
{
	// Obtain reference to source view controller
	[self setArchivesPickerViewController:segue.sourceViewController];
	
	// Save selected account and date values
	[self setSelectedAccountIndex:self.archivesPickerViewController.selectedAccountIndex];
	[self setSelectedDateIndex:self.archivesPickerViewController.selectedDateIndex];
	
	NSLog(@"Selected Account Index: %ld", (long)self.selectedAccountIndex);
	NSLog(@"Selected Account: %@", self.archivesPickerViewController.selectedAccount);
	
	if (self.archivesPickerViewController.selectedAccount == nil)
	{
		self.archivesPickerViewController.selectedAccount = [[AccountModel alloc] init];
		
		[self.archivesPickerViewController.selectedAccount setID:0];
		[self.archivesPickerViewController.selectedAccount setName:@"All Accounts"];
		[self.archivesPickerViewController.selectedAccount setPublicKey:@"0"];
	}
	
	// Update results label with selected account and date values
	[self.labelResults setText:[NSString stringWithFormat:@"Results from %@ for %@", self.archivesPickerViewController.selectedDate, self.archivesPickerViewController.selectedAccount.Name]];
	
	// Update MessagesTableViewController with updated messages (viewWillAppear will be called on MessagesTableViewController after this which will re-fetch messages)
	if ([self.messagesTableViewController respondsToSelector:@selector(filterArchivedMessages:startDate:endDate:)])
	{
		[self.messagesTableViewController filterArchivedMessages:self.archivesPickerViewController.selectedAccount.ID startDate:self.archivesPickerViewController.startDate endDate:self.archivesPickerViewController.endDate];
	}
}

// Delegate method from SWRevealController that fires when a recognized gesture has ended
- (void)revealControllerPanGestureEnded:(SWRevealViewController *)revealController
{
	[self performSelector:@selector(SWRevealControllerDidMoveToPosition:) withObject:revealController afterDelay:0.25];
}

// Determine if SWRevealController has opened. This method is only fired after a delay from revealControllerPanGestureEnded delegate method so we can determine if gesture resulted in opening the SWRevealController
- (void)SWRevealControllerDidMoveToPosition:(SWRevealViewController *)revealController
{
	// If position is open
	if (revealController.frontViewPosition == FrontViewPositionRight)
	{
		NSUserDefaults *settings = NSUserDefaults.standardUserDefaults;
		
		[settings setBool:YES forKey:SWIPE_MESSAGE_DISABLED];
		
		[settings synchronize];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"embedArchivedMessagesTable"])
	{
		[self setMessagesTableViewController:segue.destinationViewController];
		
		// Set messages type to archived
		[self.messagesTableViewController setMessagesType:@"Archived"];
	}
	else if ([segue.identifier isEqualToString:@"showArchivesPicker"])
	{
		[self setArchivesPickerViewController:segue.destinationViewController];
		
		// Set selected account and date if previously set
		[self.archivesPickerViewController setSelectedAccountIndex:self.selectedAccountIndex];
		[self.archivesPickerViewController setSelectedDateIndex:self.selectedDateIndex];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
