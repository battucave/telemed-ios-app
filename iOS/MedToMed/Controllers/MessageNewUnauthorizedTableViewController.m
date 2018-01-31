//
//  MessageNewUnauthorizedTableViewController.m
//  MedToMed
//
//  Created by Shane Goodwin on 12/11/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "MessageNewUnauthorizedTableViewController.h"
#import "AccountModel.h"
#import "HospitalModel.h"

@interface MessageNewUnauthorizedTableViewController ()

@property (nonatomic) BOOL didRequestAccount;
@property (nonatomic) BOOL didRequestHospital;
@property (nonatomic) CGFloat headerHeight;
@property (nonatomic) NSString *textDefaultHeader;

@end

@implementation MessageNewUnauthorizedTableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	// Load user's medical groups (accounts)
	AccountModel *accountModel = [[AccountModel alloc] init];
	
	[accountModel getAccountsWithCallback:^(BOOL success, NSMutableArray *accounts, NSError *error)
	{
		if (success)
		{
			// Account is initially only pending if user has already requested a medical group (account)
			BOOL isAccountPending = self.didRequestAccount;
			
			// Check whether user is pending for at least one medical group (account)
			for (AccountModel *account in accounts)
			{
				if ([account isPending])
				{
					isAccountPending = YES;
				}
			}
			
			// If user is pending for at least one medical group (account), then their next step is to wait for approval
			if (isAccountPending)
			{
				// Update header text and resize its frame in main thread
				dispatch_async(dispatch_get_main_queue(), ^
				{
					UITableViewHeaderFooterView *viewHeader = [self.tableView headerViewForSection:0];
					
					[UIView setAnimationsEnabled:NO];
					[self.tableView beginUpdates];
					
					[viewHeader.textLabel setText:[NSString stringWithFormat:@"%@ Your requested Medical Group is currently pending approval.", self.textDefaultHeader]];
					[viewHeader sizeToFit];
					
					// Store view header's height to use in heightForHeaderInSection
					[self setHeaderHeight:viewHeader.frame.size.height];
			
					[self.tableView endUpdates];
					[UIView setAnimationsEnabled:YES];
				});
			}
			// Load user's hospitals
			else
			{
				HospitalModel *hospitalModel = [[HospitalModel alloc] init];
	 
				[hospitalModel getHospitalsWithCallback:^(BOOL success, NSMutableArray *hospitals, NSError *error)
				{
					if (success)
					{
						// Hospital is initially only requested if user has already requested a hospital
						BOOL isHospitalAuthenticated = NO;
						BOOL isHospitalRequested = self.didRequestHospital;
						NSString *textHeader = @"Please get started by requesting access to a Hospital using the button below.";
						
						// Check whether user is authorized or pending for at least one hospital
						for (HospitalModel *hospital in hospitals)
						{
							if ([hospital isAuthenticated])
							{
								isHospitalAuthenticated = YES;
							}
							else if ([hospital isRequested])
							{
								isHospitalRequested = YES;
							}
						}
						
						// If user is authorized for at least one hospital, then their next step is to request a medical group (account)
						if (isHospitalAuthenticated)
						{
							textHeader = @"Please request access to a Medical Group using the button below.";
						}
						// If user is pending for at least one hospital, then their next step is to wait for approval
						else if (isHospitalRequested)
						{
							textHeader = @"Your requested Hospital is currently pending approval.";
						}
						
						// Update header text and resize its frame in main thread
						dispatch_async(dispatch_get_main_queue(), ^
						{
							UITableViewHeaderFooterView *viewHeader = [self.tableView headerViewForSection:0];
						
							[UIView setAnimationsEnabled:NO];
							[self.tableView beginUpdates];
							
							[viewHeader.textLabel setText:[NSString stringWithFormat:@"%@ %@", self.textDefaultHeader, textHeader]];
							[viewHeader sizeToFit];
							
							// Store view header's height to use in heightForHeaderInSection
							[self setHeaderHeight:viewHeader.frame.size.height];
							
							[self.tableView endUpdates];
							[UIView setAnimationsEnabled:YES];
						});
					}
				}];
			}
		}
	}];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// Store default header text
	[self setTextDefaultHeader:[self tableView:self.tableView titleForHeaderInSection:0]];
	
	/*/ TEMPORARY (remove in phase 2)
	UITableViewHeaderFooterView *viewHeader = [self.tableView headerViewForSection:0];

	[UIView setAnimationsEnabled:NO];
	[self.tableView beginUpdates];

	[viewHeader.textLabel setText:[NSString stringWithFormat:@"%@ %@", self.textDefaultHeader, @"Please contact TeleMed for assistance."]];
	[viewHeader sizeToFit];

	[self.tableView endUpdates];
	[UIView setAnimationsEnabled:YES];
	// END TEMPORARY*/
}

// Unwind from account request screen and update header text to show pending medical group (account) message
- (IBAction)unwindFromAccountRequest:(UIStoryboardSegue *)segue
{
	[self setDidRequestAccount:YES];
}

// Unwind from hospital request screen and update header text to show pending hospital message
- (IBAction)unwindFromHospitalRequest:(UIStoryboardSegue *)segue
{
	[self setDidRequestHospital:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	// If header height has been dynamically set, use it instead of automatic
	return (self.headerHeight > 0 ? self.headerHeight : UITableViewAutomaticDimension);
}

// Avoid upper case header
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
	if ([view isKindOfClass:[UITableViewHeaderFooterView class]])
	{
		UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
		
		[headerView.textLabel setText:[super tableView:tableView titleForHeaderInSection:section]];
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
