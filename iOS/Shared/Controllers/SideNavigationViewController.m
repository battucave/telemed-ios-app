//
//  SideNavigationViewController.m
//  TeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "SideNavigationViewController.h"
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "SideNavigationCountCell.h"
#import "AuthenticationModel.h"

#if MYTELEMED
	#import "OnCallScheduleViewController.h"
	#import "MyStatusModel.h"
#endif

#if MED2MED
	#import "UserProfileModel.h"
#endif

@interface SideNavigationViewController ()

@property (nonatomic) NSArray *menuItems;
@property (nonatomic) int onCallScheduleDefaultSegmentControlIndex;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

#if MYTELEMED
	@property (nonatomic) MyStatusModel *myStatusModel;

	@property (nonatomic) BOOL isStatusLoaded;
#endif

@end

@implementation SideNavigationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	#if MED2MED
		[self setMenuItems:@[@"New Message", @"Sent Messages", @"Settings", @"Log Out", @"Help"]];
	
	#elif MYTELEMED
		[self setMenuItems:@[@"Messages", @"Sent Messages", @"Archives", @"Secure Chat", @"On Call Schedule", @"Contact TeleMed", @"Settings"]];
	
		[self setMyStatusModel:MyStatusModel.sharedInstance];
	#endif
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	#if MYTELEMED
		// Update message counts on messages row and on call date on on call schedule row
		[self loadMyStatus];
		
		// Add application did become active observer to update message counts on messages row and on call date on on call schedule row (only while screen is visible)
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(loadMyStatus) name:UIApplicationDidBecomeActiveNotification object:nil];
	#endif
}

- (IBAction)doLogout:(id)sender
{
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	
	// Go to login screen
	[appDelegate goToLoginScreen];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    #if MED2MED
		// Log out has padding above it
		if ([[self.menuItems objectAtIndex:indexPath.row] isEqualToString:@"Log Out"])
		{
			return 64;
		}
	#endif
	
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Fix issue in iPad where background defaulted to White (unfixable in IB because of bug)
	[cell setBackgroundColor:[UIColor clearColor]];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *CellIdentifier = [self.menuItems objectAtIndex:indexPath.row];
	SideNavigationCountCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	
	// Draw top border only on first cell
	if (indexPath.row == 0)
	{
		UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 0.5)];
		topLineView.backgroundColor = [UIColor systemGrayColor];
		
		[cell.contentView addSubview:topLineView];
	}
	
	#if MYTELEMED
		// Reset text label's font size
		UIFont *fontTextLabel = cell.textLabel.font;

		[cell.textLabel setFont:[fontTextLabel fontWithSize:18.0f]];
	
		// If cell is for secure chat or messages
		if ([cell.reuseIdentifier isEqualToString:@"Secure Chat"] || [cell.reuseIdentifier isEqualToString:@"Messages"])
		{
			// Hide message counts by default
			[cell.labelCounts setHidden:YES];
			
			// If StatusModel has finished loading
			if (self.isStatusLoaded)
			{
				// If cell is for secure chat, set chat counts
				if ([cell.reuseIdentifier isEqualToString:@"Secure Chat"])
				{
					[cell.labelCounts setText:[NSString stringWithFormat:@"%ld/%ld", MIN(self.myStatusModel.UnopenedChatConvoCount.integerValue, 99), MIN(self.myStatusModel.ActiveChatConvoCount.integerValue, 99)]];
				}
				// If cell is for messages, set message counts
				else if ([cell.reuseIdentifier isEqualToString:@"Messages"])
				{
					[cell.labelCounts setText:[NSString stringWithFormat:@"%ld/%ld", MIN(self.myStatusModel.UnreadMessageCount.integerValue, 99), MIN(self.myStatusModel.ActiveMessageCount.integerValue, 99)]];
				}
                
                /*/ TESTING ONLY (set counts to random numbers)
                #if DEBUG
					[cell.labelCounts setText:[NSString stringWithFormat:@"%d/%d", arc4random() % 19 + 1, arc4random() % 99 + 1]];
				#endif
                // END TESTING ONLY */
				
				// Store old frame size
				CGRect oldFrame = cell.labelCounts.frame;
				
				// Resize message count label to fit updated text
				[cell.labelCounts sizeToFit];
				
				CGRect newFrame = cell.labelCounts.frame;
				
				// Increase new frame size and restore its old height
				newFrame.size.width = newFrame.size.width + 22.0;
				newFrame.size.height = oldFrame.size.height;
				
				[cell.labelCounts setFrame:newFrame];
				[cell.constraintCountsWidth setConstant:newFrame.size.width];
				
				// Show message counts
				[cell.labelCounts setHidden:NO];
			}
		}
		// If cell is for on call schedule and StatusModel has finished loading
		else if ([cell.reuseIdentifier isEqualToString:@"On Call Schedule"] && self.isStatusLoaded)
		{
			// If user is currently on call
			if (self.myStatusModel.OnCallNow)
			{
				// Direct users to "Current" on call items on OnCallScheduleViewController
				self.onCallScheduleDefaultSegmentControlIndex = 0;
				
				[cell.textLabel setText:@"Currently On Call"];
				
				[cell.detailTextLabel setHidden:YES];
			}
			
			// Set next on call
			else
			{
				// Direct users to "Next" on call items on OnCallScheduleViewController
				self.onCallScheduleDefaultSegmentControlIndex = 1;
				
				NSString *nextOnCallDate = @"None";
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				
				[cell.textLabel setText:@"Next On Call:"];
			
				if (self.myStatusModel.NextOnCall != nil)
				{
					[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
					[dateFormatter setDateFormat:@"M/dd h:mma"];
					nextOnCallDate = [[dateFormatter stringFromDate:self.myStatusModel.NextOnCall] lowercaseString];
					
					// Decrease text label's font size slightly to make more room for the date
					[cell.textLabel setFont:[fontTextLabel fontWithSize:17.0f]];
				}
				
				[cell.detailTextLabel setText:nextOnCallDate];
				[cell.detailTextLabel setHidden:NO];
			}
		}
	#endif
	
	return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue isKindOfClass:SWRevealViewControllerSegue.class])
	{
		SWRevealViewControllerSegue *swSegue = (SWRevealViewControllerSegue *)segue;
		
		swSegue.performBlock = ^(SWRevealViewControllerSegue *revealViewControllerSegue, UIViewController *sourceViewController, UIViewController *destinationViewController)
		{
			// MyTeleMed - Set default segment control Index for OnCallScheduleViewController
			#if MYTELEMED
				if ([segue.identifier isEqualToString:@"showOnCallSchedule"])
				{
					[(OnCallScheduleViewController *)destinationViewController setDefaultSegmentControlIndex:self.onCallScheduleDefaultSegmentControlIndex];
				}
			#endif
			
			UINavigationController *navController = (UINavigationController *)self.revealViewController.frontViewController;
			
			// Workaround to remove observers on these view controllers since dealloc is not fired as expected
			if ([navController.viewControllers count] > 0)
			{
				[NSNotificationCenter.defaultCenter removeObserver:[navController.viewControllers objectAtIndex:0]];
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


#pragma mark - MyTeleMed

#if MYTELEMED
- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Remove application did become active observer
	[NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)loadMyStatus
{
	[self.myStatusModel getWithCallback:^(BOOL success, MyStatusModel *status, NSError *error)
	{
		[self setIsStatusLoaded:YES];
		
		[self.tableView reloadData];
	}];
}
#endif


#pragma mark - Med2Med

#if MED2MED
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	// New message: determine which screen to go to depending on whether user is authorized
	if ([cell.reuseIdentifier isEqualToString:@"New Message"])
	{
		// Show MessageNewTableViewController
		if ([UserProfileModel.sharedInstance isAuthorized])
		{
			[self performSegueWithIdentifier:@"showMessageNew" sender:cell];
		}
		// Show MessageNewUnauthorizedTableViewController
		else
		{
			[self performSegueWithIdentifier:@"showMessageNewUnauthorized" sender:cell];
		}
	}
	// Log out (based on cell's identifier instead of row's indexPath for future compatibility in event that rows change in the future)
	else if ([cell.reuseIdentifier isEqualToString:@"Log Out"])
	{
		[self doLogout:cell];
	}
}
#endif

@end
