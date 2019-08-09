//
//  OnCallScheduleViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "OnCallScheduleViewController.h"
#import "ErrorAlertController.h"
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
@property (nonatomic) BOOL isLoaded;

@end

@implementation OnCallScheduleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Initialize MyStatusModel
	[self setMyStatusModel:[MyStatusModel sharedInstance]];
	[self.myStatusModel setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableOnCallSchedule setTableFooterView:[[UIView alloc] init]];
	
	// Set segmented control index to any default set by SideNavigationViewController
	[self.segmentedControl setSelectedSegmentIndex:self.defaultSegmentControlIndex];
	
	// Set initial cell identifier
	self.cellIdentifier = ([self.segmentedControl selectedSegmentIndex] == 0 ? @"CurrentOnCallScheduleCell" : @"FutureOnCallScheduleCell");
	
	// Initialize on call entries
	[self setCurrentOnCallEntries:nil];
	[self setFutureOnCallEntries:nil];
	
	// Get on call entries
	[self.myStatusModel getWithCallback:^(BOOL success, MyStatusModel *status, NSError *error)
	{
		self.isLoaded = YES;
		
		if (success)
		{
			// Populate on call now entries with result
			[self setCurrentOnCallEntries:status.CurrentOnCallEntries];
			
			// Populate next on call entries with result
			[self setFutureOnCallEntries:status.FutureOnCallEntries];
			
			[self filterOnCallEntries:[self.segmentedControl selectedSegmentIndex]];
		}
		else
		{
			NSLog(@"OnCallScheduleViewController Error: %@", error);
			
			// Show error message
			ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
			
			[errorAlertController show:error];
		}
	}];
}

// User clicked one of the segmented control options: (Current, Next)
- (IBAction)setOnCallPeriod:(id)sender
{
	// Filter on call entries
	[self filterOnCallEntries:[self.segmentedControl selectedSegmentIndex]];
	
	// Update cell identifier
	self.cellIdentifier = ([self.segmentedControl selectedSegmentIndex] == 0 ? @"CurrentOnCallScheduleCell" : @"FutureOnCallScheduleCell");
}

- (void)filterOnCallEntries:(NSInteger)onCallPeriod
{
	NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
	NSDate *datePreviousOnCall = [NSDate dateWithTimeIntervalSinceNow:-24 * 60 * 60]; // Initially set to Yesterday
	
	NSDate *dateTime;
	
	// Filter to current on call entries
	if (onCallPeriod == 0)
	{
		[self setFilteredOnCallEntries:self.currentOnCallEntries];
		
		if ([self.filteredOnCallEntries count] > 0)
		{
			dateTime = [[self.filteredOnCallEntries objectAtIndex:0] Started];
		}
	}
	// Filter to future on call entries
	else
	{
		[self setFilteredOnCallEntries:self.futureOnCallEntries];
		
		if ([self.filteredOnCallEntries count] > 0)
		{
			dateTime = [[self.filteredOnCallEntries objectAtIndex:0] WillStart];
		}
	}
	
	// Cancel filtering if no filtered on call entries
	if ([self.filteredOnCallEntries count] == 0)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[self.tableOnCallSchedule reloadData];
		});
		
		return;
	}
	
	// Display date grouping only if showing future on call entries
	if (onCallPeriod == 1)
	{
		for (OnCallEntryModel *onCallEntry in self.filteredOnCallEntries)
		{
			// Parse and format on call entry start date to remove time
			NSDate *dateOnCall = [calendar dateFromComponents:[calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:onCallEntry.WillStart]];
			
			// Set should display date property depending on whether on call date is greater than previous on call date
			onCallEntry.shouldDisplayDate = ([datePreviousOnCall compare:dateOnCall] == NSOrderedAscending);
			
			// Update previous on call date to current on call date
			datePreviousOnCall = dateOnCall;
		}
	}
	// Only show date for first cell
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return MAX([self.filteredOnCallEntries count], 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Set default message if no filtered on call entries available
	if ([self.filteredOnCallEntries count] == 0)
	{
		UITableViewCell *emptyCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
		
		[emptyCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		[emptyCell.textLabel setFont:[UIFont systemFontOfSize:17.0]];
		[emptyCell.textLabel setText:(self.isLoaded ? ([self.segmentedControl selectedSegmentIndex] == 0 ? @"You are not currently on call." : @"You have no upcoming on call entries.") : @"Loading...")];
		
		return emptyCell;
	}
	
	OnCallSummaryCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellIdentifier];
	
	[cell setSeparatorInset:UIEdgeInsetsZero];
	
	// Hide cell's separator if the next row will display a date
	if (indexPath.row < [self.filteredOnCallEntries count] - 1 && [[self.filteredOnCallEntries objectAtIndex:indexPath.row + 1] shouldDisplayDate])
	{
		[cell setSeparatorInset:UIEdgeInsetsMake(0.0f, cell.bounds.size.width, 0.0f, 0.0f)];
	}
	
	// Set up the cell
	[cell.labelStart setHidden:NO];
	[cell.labelEnd setHidden:NO];
	
	// Initialize on call entry
	OnCallEntryModel *onCallEntry = [self.filteredOnCallEntries objectAtIndex:indexPath.row];
	
	// Set on call summary title and slot name(s)
	[cell.labelTitle setText:[NSString stringWithFormat:@"%@ %@", onCallEntry.AccountKey, onCallEntry.AccountName]];
	[cell.labelSlotNames setText:onCallEntry.SlotDesc];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSDate *startDateRaw = (onCallEntry.Started ?: onCallEntry.WillStart);
	
	[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
	
	// Set on call summary start and stop dates
	[dateFormatter setDateFormat:@"MMM d, yyyy"];
	NSString *startDate = [dateFormatter stringFromDate:startDateRaw];
	NSString *stopDate = [dateFormatter stringFromDate:onCallEntry.WillEnd];
	
	// Set on call summary start and stop times
	[dateFormatter setDateFormat:@"h:mma"];
	NSString *startTime = [[dateFormatter stringFromDate:startDateRaw] lowercaseString];
	NSString *stopTime = [[dateFormatter stringFromDate:onCallEntry.WillEnd] lowercaseString];
	
	if (onCallEntry.shouldDisplayDate)
	{
		// Set on call summary day
		[dateFormatter setDateFormat:@"EEEE"];
		[cell.labelDay setText:[dateFormatter stringFromDate:startDateRaw]];
		[cell.labelDate setText:startDate];
		
		// Show date container
		[cell.viewDateContainer setHidden:NO];
		[cell.constraintViewDateContainerHeight setConstant:24.0f];
	}
	else
	{
		// Hide date container
		[cell.viewDateContainer setHidden:YES];
		[cell.constraintViewDateContainerHeight setConstant:0.0f];
	}
	
	[cell.labelStartTime setText:[NSString stringWithFormat:@"%@, %@", startDate, startTime]];
	[cell.labelStopTime setText:[NSString stringWithFormat:@"%@, %@", stopDate, stopTime]];
	
	// If start time is nil, hide start dates (this should never happen)
	if (startDateRaw == nil)
	{
		[cell.labelStart setHidden:YES];
		[cell.labelStartTime setText:@""];
	}
	
	// If stop time is nil, hide stop dates
	if (onCallEntry.WillEnd == nil)
	{
		[cell.labelEnd setHidden:YES];
		[cell.labelStopTime setText:@""];
	}
	
	[cell layoutIfNeeded];
	
	return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
