//
//  OnCallScheduleViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "OnCallScheduleViewController.h"
#import "OnCallSummaryCell.h"
#import "MyStatusModel.h"

@interface OnCallScheduleViewController ()

@property (nonatomic) MyStatusModel *myStatusModel;

@property (nonatomic) NSMutableArray *accounts;
@property (nonatomic) NSArray *currentOnCallEntries;
@property (nonatomic) NSArray *futureOnCallEntries;
@property (nonatomic) NSArray *filteredOnCallEntries;

@property (weak, nonatomic) IBOutlet UITableView *tableOnCallSchedule;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (nonatomic) UIColor *segmentedControlColor;
@property (nonatomic) NSString *cellIdentifier;

@end

@implementation OnCallScheduleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Initialize My Status Model
	[self setMyStatusModel:[MyStatusModel sharedInstance]];
	[self.myStatusModel setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Set Segmented Control Index to any default set in SideNavigationViewController
	[self.segmentedControl setSelectedSegmentIndex:self.defaultSegmentControlIndex];
	
	// Set Initialize CellIdentifier
	self.cellIdentifier = ([self.segmentedControl selectedSegmentIndex] == 0 ? @"CurrentOnCallScheduleCell" : @"FutureOnCallScheduleCell");
	
	// Initialize On Call Entries
	[self setCurrentOnCallEntries:nil];
	[self setFutureOnCallEntries:nil];
	
	// Get On Call Entries
	[self.myStatusModel getWithCallback:^(BOOL success, MyStatusModel *status, NSError *error)
	{
		if(success)
		{
			// Populate On Call Now Entries with result
			[self setCurrentOnCallEntries:status.CurrentOnCallEntries];
			
			// Sort On Call Now Entries by StartTime
			self.currentOnCallEntries = [self.currentOnCallEntries sortedArrayUsingComparator:^NSComparisonResult(OnCallEntryModel *onCallEntryModelA, OnCallEntryModel *onCallEntryModelB) {
				return [onCallEntryModelA.WillStart compare:onCallEntryModelB.WillStart];
			}];
			
			// Populate Next On Call Entries with result
			[self setFutureOnCallEntries:status.FutureOnCallEntries];
			
			// Sort Next On Call Entries by StartTime
			self.futureOnCallEntries = [self.futureOnCallEntries sortedArrayUsingComparator:^NSComparisonResult(OnCallEntryModel *onCallEntryModelA, OnCallEntryModel *onCallEntryModelB) {
				return [onCallEntryModelA.WillStart compare:onCallEntryModelB.WillStart];
			}];
			
			[self filterOnCallEntries:[self.segmentedControl selectedSegmentIndex]];
		}
		else
		{
			NSLog(@"OnCallScheduleViewController Error: %@", error);
			
			// If device offline, show offline message
			if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
			{
				return [self.myStatusModel showOfflineError];
			}
		}
	}];
}

// User clicked one of the UISegmented Control options: (Current, Next)
- (IBAction)setOnCallPeriod:(id)sender
{
	// Filter On Call Entries
	[self filterOnCallEntries:[self.segmentedControl selectedSegmentIndex]];
	
	// Update Cell Identifier
	self.cellIdentifier = ([self.segmentedControl selectedSegmentIndex] == 0 ? @"CurrentOnCallScheduleCell" : @"FutureOnCallScheduleCell");
}

- (void)filterOnCallEntries:(NSInteger)onCallPeriod
{
	// Filter to Current On Call Entries
	if(onCallPeriod == 0)
	{
		[self setFilteredOnCallEntries:self.currentOnCallEntries];
	}
	// Filter to Future On Call Entries
	else
	{
		[self setFilteredOnCallEntries:self.futureOnCallEntries];
	}
	
	// Cancel filtering if no Filtered On Call Entries
	if([self.filteredOnCallEntries count] == 0)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[self.tableOnCallSchedule reloadData];
		});
		
		return;
	}
	
	NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
	NSDateFormatter *dateFormatterOnCall = [[NSDateFormatter alloc] init];
	NSDate *datePreviousOnCall = [NSDate dateWithTimeIntervalSinceNow:-24 * 60 * 60]; // Initially set to Yesterday
	
	// Get format for On Call Entry StartTime
	[dateFormatterOnCall setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
	[dateFormatterOnCall setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
	
	NSDate *dateTime = [dateFormatterOnCall dateFromString:[[self.filteredOnCallEntries objectAtIndex:0] WillStart]];
	
	// If date is nil, it may have been formatted incorrectly
	if(dateTime == nil)
	{
		[dateFormatterOnCall setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
	}
	
	// Display Date Grouping only if showing Future On Call entries
	if(onCallPeriod == 1)
	{
		for(OnCallEntryModel *onCallEntry in self.filteredOnCallEntries)
		{
			// Parse and format On Call Entry Start Date to remove time
			NSDate *dateOnCall = [dateFormatterOnCall dateFromString:onCallEntry.WillStart];
			dateOnCall = [calendar dateFromComponents:[calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:dateOnCall]];
			
			// Set Should Display Date property depending on whether On Call date is greater than Previous On Call date
			onCallEntry.shouldDisplayDate = ([datePreviousOnCall compare:dateOnCall] == NSOrderedAscending);
			
			// Update Previous On Call date to current On Call date
			datePreviousOnCall = dateOnCall;
		}
	}
	// Only Show Date for first cell
	else
	{
		OnCallEntryModel *onCallEntry = [self.filteredOnCallEntries objectAtIndex:0];
		
		onCallEntry.shouldDisplayDate = YES;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self.tableOnCallSchedule reloadData];
	});
}

// Calculate Height Difference of Label between original storyboard height and dynamic size that fits height
- (CGFloat)calculateHeightDifference:(UILabel *)label text:(NSString *)textLabel
{
	// Get original width
	CGFloat originalWidth = label.frame.size.width;
	
	// Get original height
	[label setText:@" "];
	
	CGSize originalSizeLabel = [label sizeThatFits:CGSizeMake(originalWidth, MAXFLOAT)];
	
	// Get auto height
	[label setText:textLabel];
	
	CGSize newSizeLabel = [label sizeThatFits:CGSizeMake(originalWidth, MAXFLOAT)];
	
	float heightDifference = newSizeLabel.height - originalSizeLabel.height;
	
	// Fix weird issue where a positive heightDifference is not quite accurate
	return (heightDifference > 0 ? heightDifference - 0.5f : 0);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if([self.filteredOnCallEntries count] == 0)
	{
		return 1;
	}
	
	return [self.filteredOnCallEntries count];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 50.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Return default height if no Filtered On Call Entries available
	if([self.filteredOnCallEntries count] == 0)
	{
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	}
	
	// Manually determine height for < iOS8
	OnCallSummaryCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellIdentifier];
	
	OnCallEntryModel *onCallEntry = [self.filteredOnCallEntries objectAtIndex:indexPath.row];
	
	// Calculate On Call Summary Title height difference between original storyboard height and dynamic size that fits height
	CGFloat heightLabelTitleDifference = [self calculateHeightDifference:cell.labelTitle text:[NSString stringWithFormat:@"%@ %@", onCallEntry.AccountKey, onCallEntry.AccountName]];
	
	// Calculate On Call Summary SlotNames height difference between original storyboard height and dynamic size that fits height
	CGFloat heightLabelSlotNamesDifference = [self calculateHeightDifference:cell.labelSlotNames text:onCallEntry.SlotDesc];
	
	return 83.0f + (onCallEntry.shouldDisplayDate ? 24.0f : 0.0f) + heightLabelTitleDifference + heightLabelSlotNamesDifference;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Set default message if no Filtered On Call Entries available
	if([self.filteredOnCallEntries count] == 0)
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:12.0]];
		[emptyCell.textLabel setText:([self.segmentedControl selectedSegmentIndex] == 0 ? @"You are currently not on call." : @"You have no upcoming on call entries.")];
		
		return emptyCell;
	}
	
	OnCallSummaryCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellIdentifier];
	
	// Set up the cell
	[cell.labelStart setHidden:NO];
	[cell.labelEnd setHidden:NO];
	
	OnCallEntryModel *onCallEntry = [self.filteredOnCallEntries objectAtIndex:indexPath.row];
	BOOL hideSeparator = NO;
	
	if(indexPath.row < [self.filteredOnCallEntries count] - 1)
	{
		hideSeparator =  [[self.filteredOnCallEntries objectAtIndex:indexPath.row + 1] shouldDisplayDate];
	}
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	
	// Set Start and Stop Times
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
	NSDate *startDateTime = [dateFormatter dateFromString:onCallEntry.WillStart];
	NSDate *stopDateTime = [dateFormatter dateFromString:onCallEntry.WillEnd];
	
	// If StartDateTime is nil, it may have been formatted incorrectly
	if(startDateTime == nil)
	{
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
		startDateTime = [dateFormatter dateFromString:onCallEntry.WillStart];
	}
	
	// If StopDateTime is nil, it may have been formatted incorrectly
	if(stopDateTime == nil)
	{
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
		stopDateTime = [dateFormatter dateFromString:onCallEntry.WillEnd];
	}
	
	// Set On Call Summary Start and Stop Dates
	[dateFormatter setDateFormat:@"MMM d, yyyy"];
	NSString *startDate = [dateFormatter stringFromDate:startDateTime];
	NSString *stopDate = [dateFormatter stringFromDate:stopDateTime];
	
	// Set On Call Summary Start and Stop Times
	[dateFormatter setDateFormat:@"h:mma"];
	NSString *startTime = [[dateFormatter stringFromDate:startDateTime] lowercaseString];
	NSString *stopTime = [[dateFormatter stringFromDate:stopDateTime] lowercaseString];
	
	[cell.labelStartTime setText:[NSString stringWithFormat:@"%@, %@", startDate, startTime]];
	[cell.labelStopTime setText:[NSString stringWithFormat:@"%@, %@", stopDate, stopTime]];
	
	// If StartTime is nil, hide start dates (this should never happen)
	if(onCallEntry.WillStart == nil)
	{
		[cell.labelStart setHidden:YES];
		[cell.labelStartTime setText:@""];
	}
	
	// If StopTime is nil, hide stop dates
	if(onCallEntry.WillEnd == nil)
	{
		[cell.labelEnd setHidden:YES];
		[cell.labelStopTime setText:@""];
	}
	
	// Show/Hide Dates
	[cell.viewDateContainer setHidden: ! onCallEntry.shouldDisplayDate];
	
	if(onCallEntry.shouldDisplayDate)
	{
		// Set On Call Summary Day
		[dateFormatter setDateFormat:@"EEEE"];
		[cell.labelDay setText:[dateFormatter stringFromDate:startDateTime]];
		[cell.labelDate setText:startDate];
	}
	
	// Set On Call Summary Title
	[cell.labelTitle setText:[NSString stringWithFormat:@"%@ %@", onCallEntry.AccountKey, onCallEntry.AccountName]];
	
	// Set Auto Height for On Call Summary Title
	CGFloat widthLabelTitle = cell.labelTitle.frame.size.width;
	CGSize newSizeLabelTitle = [cell.labelTitle sizeThatFits:CGSizeMake(widthLabelTitle, MAXFLOAT)];
	cell.constraintLabelTitleHeight.constant = newSizeLabelTitle.height;
	
	// Set On Call Summary Slot Name(s)
	[cell.labelSlotNames setText:onCallEntry.SlotDesc];
	
	// Set Auto Height for On Call Summary Slot Name(s)
	CGFloat widthLabelSlotNames = cell.labelSlotNames.frame.size.width;
	CGSize newSizeLabelSlotNames = [cell.labelSlotNames sizeThatFits:CGSizeMake(widthLabelSlotNames, MAXFLOAT)];
	cell.constraintLabelSlotNamesHeight.constant = newSizeLabelSlotNames.height;
	
	// Show/Hide Separator
	[cell.viewSeparator setHidden:hideSeparator];
	
	return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
