//
//  MessageHistoryViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 1/21/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MessageHistoryViewController.h"
#import "MessageEventCell.h"
#import "MessageEventModel.h"
#import "MessageRecipientModel.h"

@interface MessageHistoryViewController ()

@property (nonatomic) MessageRecipientModel *messageRecipientModel;

@property (weak, nonatomic) IBOutlet UILabel *labelEventsType;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UITableView *tableMessageEvents;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTableMessageEventsBottom;

@property (weak, nonatomic) UIColor *segmentedControlColor;
@property (nonatomic) CGFloat originalTableMessageEventsBottom;
@property (nonatomic) CGFloat originalTableMessageEventsHeight;

@end

@implementation MessageHistoryViewController

- (void)viewDidLoad
{
	// Perform shared logic in MessageDetailParentViewController
	[super viewDidLoad];
	
	// Initialize filtered message events
	for (MessageEventModel *messageEvent in self.messageEvents)
	{
		if (! [messageEvent.Type isEqualToString:@"Comment"])
		{
			[self.filteredMessageEvents addObject:messageEvent];
		}
	}
	
	// Reset message events to not include comments (required for segment control selections)
	[self setMessageEvents:[self.filteredMessageEvents copy]];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Disable forward button if no message recipients available
	if (! self.canForward)
	{
		[self.buttonForward setEnabled:NO];
	}
	
	// Ensure segment control is set to all initially
	[self.segmentedControl setSelectedSegmentIndex:0];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.tableMessageEvents layoutIfNeeded];
	
	self.originalTableMessageEventsBottom = self.constraintTableMessageEventsBottom.constant;
	self.originalTableMessageEventsHeight = self.tableMessageEvents.frame.size.height;
	
	// Auto size table message events to show all rows (in XCode 8+ this needs to be run again after table cells have rendered)
	[self autoSizeTableEvents];
}

// User clicked one of the segment control options
- (IBAction)filterMessageEvents:(id)sender
{
	NSString *messageEventString = nil;
	NSString *eventLabel;
	
	[self.filteredMessageEvents removeAllObjects];
	
	switch ([self.segmentedControl selectedSegmentIndex])
	{
	   // Office events
		case 1:
			messageEventString = @"User";
			eventLabel = @"Office Events";
			break;
		
		// TeleMed events
		case 2:
			messageEventString = @"TeleMed";
			eventLabel = @"TeleMed Events";
			break;
	}
	
	// If basic event set
	if (messageEventString != nil)
	{
		for (MessageEventModel *messageEvent in self.messageEvents)
		{
			if ([messageEvent.Type isEqualToString:messageEventString])
			{
				[self.filteredMessageEvents addObject:messageEvent];
			}
		}
		
		[self.labelEventsType setText:eventLabel];
	}
	// If priority is all or not set
	else
	{
		[self setFilteredMessageEvents:[self.messageEvents mutableCopy]];
		
		[self.labelEventsType setText:@"All Events"];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableMessageEvents reloadData];
		
		// Auto size table message events to show all rows (in XCode 8+ this needs to be run again after table cells have rendered)
		[self autoSizeTableEvents];
	});
}

// Auto size table events height to show all rows
- (void)autoSizeTableEvents
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableMessageEvents layoutIfNeeded];
		
		CGFloat newHeight = self.tableMessageEvents.contentSize.height;
		
		self.constraintTableMessageEventsBottom.constant = (self.originalTableMessageEventsHeight - newHeight > self.originalTableMessageEventsBottom ? self.originalTableMessageEventsHeight - newHeight : self.originalTableMessageEventsBottom);
	});
}

// Go to MessageEscalateViewController (override method from MessageDetailParentViewController)
- (void)showMessageEscalate
{
	[self performSegueWithIdentifier:@"showMessageEscalateFromMessageHistory" sender:self];
}

// Go to MessageForwardViewController (override method from MessageDetailParentViewController)
- (void)showMessageForward
{
	[self performSegueWithIdentifier:@"showMessageForwardFromMessageHistory" sender:self];
}

// Go to MessageRedirectViewController (override method from MessageDetailParentViewController)
- (void)showMessageRedirect
{
	[self performSegueWithIdentifier:@"showMessageRedirectFromMessageHistory" sender:self];
}

// Go to PhoneCallViewController (override method from MessageDetailParentViewController)
- (void)showPhoneCall
{
	[self performSegueWithIdentifier:@"showPhoneCallFromMessageHistory" sender:self];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.filteredMessageEvents count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"MessageEventCell";
	MessageEventCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	// Set up the cell
	MessageEventModel *messageEvent = [self.filteredMessageEvents objectAtIndex:indexPath.row];
	
	// Set message event date and time
	if (messageEvent.Time_LCL)
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
		NSDate *dateTime = [dateFormatter dateFromString:messageEvent.Time_LCL];
		
		// If date is nil, it may have been formatted incorrectly
		if (dateTime == nil)
		{
			[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
			dateTime = [dateFormatter dateFromString:messageEvent.Time_LCL];
		}
		
		[dateFormatter setDateFormat:@"M/dd/yy h:mm a"];
		NSString *date = [dateFormatter stringFromDate:dateTime];
		
		[cell.labelDate setText:date];
	}
	
	// Set message event detail
	[cell.labelDetail setText:messageEvent.Detail];
	
	// Set message event type
	if ([messageEvent.Type isEqualToString:@"User"])
	{
		[cell.labelType setText:@"Office Event"];
	}
	else
	{
		[cell.labelType setText:@"Telemed Event"];
	}
	
	// Auto size table message events to show all rows
	[self autoSizeTableEvents];
	
	return cell;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
