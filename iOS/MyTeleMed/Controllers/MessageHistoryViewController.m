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

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (weak, nonatomic) IBOutlet UILabel *labelEventsType;

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
	
	// Initialize Filtered Message Events
	for(MessageEventModel *messageEvent in self.messageEvents)
	{
		if( ! [messageEvent.Type isEqualToString:@"Comment"])
		{
			[self.filteredMessageEvents addObject:messageEvent];
		}
	}
	
	// Reset Message Events to not include comments (required for Segment Control selections)
	[self setMessageEvents:[self.filteredMessageEvents copy]];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Disable Forward Button if no Message Recipients available
	if( ! self.canForward)
	{
		[self.buttonForward setEnabled:NO];
	}
	
	// Ensure Segment Control is set to all initially
	[self.segmentedControl setSelectedSegmentIndex:0];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.tableMessageEvents layoutIfNeeded];
	
	self.originalTableMessageEventsBottom = self.constraintTableMessageEventsBottom.constant;
	self.originalTableMessageEventsHeight = self.tableMessageEvents.frame.size.height;
	
	// Auto size Table Message Events to show all rows (in XCode 8+ this needs to be run again after table cells have rendered)
	[self autoSizeTableEvents];
}

// User Clicked one of the UISegmented Control options: (All, Office Events, Comment, Telemed Events)
- (IBAction)filterMessageEvents:(id)sender
{
	NSString *messageEventString = nil;
	NSString *eventLabel;
	
	[self.filteredMessageEvents removeAllObjects];
	
	switch([self.segmentedControl selectedSegmentIndex])
	{
	   // Office Events
		case 1:
			messageEventString = @"User";
			eventLabel = @"Office Events";
			break;
		
		// TeleMed Events
		case 2:
			messageEventString = @"TeleMed";
			eventLabel = @"TeleMed Events";
			break;
	}
	
	// If Basic Event set
	if(messageEventString != nil)
	{
		for(MessageEventModel *messageEvent in self.messageEvents)
		{
			if([messageEvent.Type isEqualToString:messageEventString])
			{
				[self.filteredMessageEvents addObject:messageEvent];
			}
		}
		
		[self.labelEventsType setText:eventLabel];
	}
	// If Priority All or not set
	else
	{
		[self setFilteredMessageEvents:[self.messageEvents mutableCopy]];
		
		[self.labelEventsType setText:@"All Events"];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableMessageEvents reloadData];
		
		// Auto size Table Message Events to show all rows (in XCode 8+ this needs to be run again after table cells have rendered)
		[self autoSizeTableEvents];
	});
}

// Auto size Table Events height to show all rows
- (void)autoSizeTableEvents
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableMessageEvents layoutIfNeeded];
		
		CGFloat newHeight = self.tableMessageEvents.contentSize.height;
		
		self.constraintTableMessageEventsBottom.constant = (self.originalTableMessageEventsHeight - newHeight > self.originalTableMessageEventsBottom ? self.originalTableMessageEventsHeight - newHeight : self.originalTableMessageEventsBottom);
	});
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.filteredMessageEvents count];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 52.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// iOS8+ Auto Height
	return UITableViewAutomaticDimension;
	
	// Deprecated: Manually determine height for < iOS8
	/*static NSString *cellIdentifier = @"MessageEventCell";
	MessageEventCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	MessageEventModel *messageEvent = [self.filteredMessageEvents objectAtIndex:indexPath.row];
	
	// Calculate Auto Height of Table Cell
	[cell.labelDetail setText:messageEvent.Detail];
	
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	
	// Determine the new height - add 1.0 to the height to account for the cell separator
	CGFloat cellHeight = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0f;
	
	// If height is less than 40, constraints will break
	if(cellHeight < 40.0f)
	{
		cellHeight = 40.0f;
	}
	
	return cellHeight;*/
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"MessageEventCell";
	MessageEventCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	// Set up the cell
	MessageEventModel *messageEvent = [self.filteredMessageEvents objectAtIndex:indexPath.row];
	
	// Set Message Event Date and Time
	if(messageEvent.Time_LCL)
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
		NSDate *dateTime = [dateFormatter dateFromString:messageEvent.Time_LCL];
		
		// If date is nil, it may have been formatted incorrectly
		if(dateTime == nil)
		{
			[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
			dateTime = [dateFormatter dateFromString:messageEvent.Time_LCL];
		}
		
		[dateFormatter setDateFormat:@"M/dd/yy h:mm a"];
		NSString *date = [dateFormatter stringFromDate:dateTime];
		
		[cell.labelDate setText:date];
	}
	
	// Set Message Event Detail
	[cell.labelDetail setText:messageEvent.Detail];
	
	// Set Message Event Type
	if([messageEvent.Type isEqualToString:@"User"])
	{
		[cell.labelType setText:@"Office Event"];
	}
	else
	{
		[cell.labelType setText:@"Telemed Event"];
	}
	
	// Auto size Table Message Events to show all rows
	[self autoSizeTableEvents];
	
	return cell;
}

@end
