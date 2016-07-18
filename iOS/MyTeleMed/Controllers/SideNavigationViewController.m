//
//  SideNavigationViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "SideNavigationViewController.h"
#import "SWRevealViewController.h"
#import "OnCallScheduleViewController.h"
#import "AuthenticationModel.h"
#import "MyStatusModel.h"

@interface SideNavigationViewController ()

@property (nonatomic) MyStatusModel *myStatusModel;

@property (nonatomic) NSArray *menuItems;
@property (nonatomic) int onCallScheduleDefaultSegmentControlIndex;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *labelMessageCount;
@property (weak, nonatomic) IBOutlet UILabel *labelNextOnCallDate;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTableHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintMessageCountsWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintNextOnCallDateRight;

@end

@implementation SideNavigationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	//_menuItems = @[@"Messages", @"Sent", @"Archives", @"On Call Schedule", @"Contact TeleMed", @"Settings"];
	_menuItems = @[@"Messages", @"Archives", @"Chat", @"On Call Schedule", @"Contact TeleMed", @"Settings"];
	
	[self setMyStatusModel:[MyStatusModel sharedInstance]];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Adjust Table Height to match number of Menu Items to avoid extra separator lines
	self.constraintTableHeight.constant = [self.menuItems count] * 44 + 23;
	
	[self.labelMessageCount setHidden:YES];
	
	// Set Initial Message Counts on Messages Row and On Call Date on On Call Schedule Row using MyStatusModel sharedInstance
	[self updateNavigationWithStatus:self.myStatusModel];
	
	// Update Message Counts on Messages Row and On Call Date on On Call Schedule Row
	[self.myStatusModel getWithCallback:^(BOOL success, MyStatusModel *status, NSError *error)
	{
		[self updateNavigationWithStatus:status];
	}];
}

- (void)viewDidLayoutSubviews
{
	// Force left inset of 15.0 for iOS 7
	if([self.tableView respondsToSelector:@selector(setSeparatorInset:)])
	{
		[self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 15.0f, 0, 0)];
	}
	
	// Force left inset of 15.0 for iOS 8
	if([self.tableView respondsToSelector:@selector(setLayoutMargins:)])
	{
		[self.tableView setLayoutMargins:UIEdgeInsetsMake(0, 15.0f, 0, 0)];
	}
}

- (IBAction)doLogout:(id)sender
{
	AuthenticationModel *authenticationModel = [AuthenticationModel sharedInstance];
	
	[authenticationModel doLogout];
}

- (void)updateNavigationWithStatus:(MyStatusModel *)status
{
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.menuItems indexOfObject:@"On Call Schedule"] inSection:0]];
	
	[self.labelMessageCount setText:[NSString stringWithFormat:@"%@/%@", status.UnreadMessageCount, status.ActiveMessageCount]];
	
	[self.labelMessageCount sizeToFit];
	
	CGRect newFrame = self.labelMessageCount.frame;
	self.constraintMessageCountsWidth.constant = newFrame.size.width + 8.0;
	
	[self.labelMessageCount layoutIfNeeded];
	[self.labelMessageCount setHidden:NO];
	
	[cell.textLabel setText:(status.OnCallNow == YES ? @"Currently On Call" : @"Next On Call:" )];
	
	// Set Next On Call
	if(status.OnCallNow == NO)
	{
		// Set Default Segment Control Index
		self.onCallScheduleDefaultSegmentControlIndex = 1;
		
		NSString *nextOnCallDate = @"None";
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		
		// Get Next On Call Date
		if(status.NextOnCall != nil && ! [status.NextOnCall isEqualToString:@"Never"])
		{
			[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
			[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
			NSDate *date = [dateFormatter dateFromString:status.NextOnCall];
			
			// If date is nil, it may have been formatted incorrectly
			if(date == nil)
			{
				[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
				date = [dateFormatter dateFromString:status.NextOnCall];
			}
			
			// Set Next On Call Date
			if(date != nil)
			{
				[dateFormatter setDateFormat:@"M/dd h:mma"];
				nextOnCallDate = [[dateFormatter stringFromDate:date] lowercaseString];
				
				// Set Next On Call Date label trailing constraint to default
				self.constraintNextOnCallDateRight.constant = 65.0f;
			}
		}
		
		// If there is no Next On Call date, then line up Next On Call Date label with Message Counts
		if([nextOnCallDate isEqualToString:@"None"])
		{
			self.constraintNextOnCallDateRight.constant = 88.0f;
		}
		
		[self.labelNextOnCallDate setText:nextOnCallDate];
		[self.labelNextOnCallDate setHidden:NO];
	}
	else
	{
		[self.labelNextOnCallDate setHidden:YES];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.menuItems count];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Fix issue in iPad where background defaulted to White (unfixable in IB because of bug)
	[cell setBackgroundColor:[UIColor clearColor]];
	
	// Force left inset of 15.0 for iOS 7
	if([cell respondsToSelector:@selector(setSeparatorInset:)])
	{
		[cell setSeparatorInset:UIEdgeInsetsMake(0, 15.0f, 0, 0)];
	}
	
	// Force left inset of 15.0 for iOS 8
	if([cell respondsToSelector:@selector(setLayoutMargins:)])
	{
		[cell setLayoutMargins:UIEdgeInsetsMake(0, 15.0f, 0, 0)];
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *CellIdentifier = [self.menuItems objectAtIndex:indexPath.row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	
	// Draw top border only on first cell
	if(indexPath.row == 0)
	{
		UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 0.5)];
		topLineView.backgroundColor = [UIColor colorWithRed:105.0/255.0 green:105.0/255.0 blue:105.0/255.0 alpha:1];
		[cell.contentView addSubview:topLineView];
	}
	
	return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([segue isKindOfClass:[SWRevealViewControllerSegue class]])
	{
		SWRevealViewControllerSegue *swSegue = (SWRevealViewControllerSegue *)segue;
		
		swSegue.performBlock = ^(SWRevealViewControllerSegue *revealViewControllerSegue, UIViewController *sourceViewController, UIViewController *destinationViewController)
		{
			// Set Default Segment Control Index for On Call Schedule
			if([segue.identifier isEqualToString:@"showOnCallSchedule"])
			{
				[(OnCallScheduleViewController *)destinationViewController setDefaultSegmentControlIndex:self.onCallScheduleDefaultSegmentControlIndex];
			}
			
			UINavigationController *navController = (UINavigationController *)self.revealViewController.frontViewController;
			
			// Workaround to remove observers on these view controllers since dealloc is not fired as expected
			if([navController.viewControllers count] > 0)
			{
				[[NSNotificationCenter defaultCenter] removeObserver:[navController.viewControllers objectAtIndex:0]];
			}
			
			[navController setViewControllers:@[destinationViewController] animated:NO];
			[self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
		};
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
