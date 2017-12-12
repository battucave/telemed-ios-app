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

@property (nonatomic) NSString *textDefaultHeader;

@end

@implementation MessageNewUnauthorizedTableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Remove empty separator lines (By default, UITableView adds empty cells until bottom of screen without this)
	[self.tableView setTableFooterView:[[UIView alloc] init]];
	
	// TEMPORARY (uncomment code below in phase 2)
	/*/ Load user's medical groups (accounts)
	AccountModel *accountModel = [[AccountModel alloc] init];
	
	[accountModel getAccountsWithCallback:^(BOOL success, NSMutableArray *accounts, NSError *error)
	{
		if (success)
		{
			BOOL isAccountPending = NO;
			
			// Check if user is pending for at least one account
			for (AccountModel *account in accounts)
			{
				if ([accountModel isAccountPending:account])
				{
					//isAccountPending = YES;
				}
			}
			
			// If user is pending for at least one account, then their next step is to wait for approval
			if (isAccountPending)
			{
				// Update header text and resize its frame in main thread
				dispatch_async(dispatch_get_main_queue(), ^
				{
					UITableViewHeaderFooterView *viewHeader = [self.tableView headerViewForSection:0];
					
					[UIView setAnimationsEnabled:NO];
					[self.tableView beginUpdates];
					
					[viewHeader.textLabel setText:[NSString stringWithFormat:@"%@ Your requested Medical Group is still pending approval.", self.textDefaultHeader]];
					[viewHeader sizeToFit];
					
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
						BOOL isHospitalAuthorized = NO;
						BOOL isHospitalPending = NO;
						NSString *textHeader = @"Please get started by requesting access to a Hospital using the button below.";
						
						// Check if user is authorized or pending for at least one hospital
						for (HospitalModel *hospital in hospitals)
						{
							if ([hospitalModel isHospitalAuthorized:hospital])
							{
								isHospitalAuthorized = YES;
							}
							else if ([hospitalModel isHospitalPending:hospital])
							{
								isHospitalPending = YES;
							}
						}
						
						// If user is authorized for at least one hospital, then their next step is to request a medical group
						if (isHospitalAuthorized)
						{
							textHeader = @"Please request access to a Medical Group using the button below.";
						}
						// If user is pending for at least one hospital, then their next step is to wait for approval
						else if (isHospitalPending)
						{
							textHeader = @"Your requested Hospital is still pending approval.";
						}
						
						// Update header text and resize its frame in main thread
						dispatch_async(dispatch_get_main_queue(), ^
						{
							UITableViewHeaderFooterView *viewHeader = [self.tableView headerViewForSection:0];
							
							[UIView setAnimationsEnabled:NO];
							[self.tableView beginUpdates];
							
							[viewHeader.textLabel setText:[NSString stringWithFormat:@"%@ %@", self.textDefaultHeader, textHeader]];
							[viewHeader sizeToFit];
							
							[self.tableView endUpdates];
							[UIView setAnimationsEnabled:YES];
						});
					}
				}];
			}
		}
	}];*/
	// END TEMPORARY
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// Store default header text
	[self setTextDefaultHeader:[self.tableView headerViewForSection:0].textLabel.text];
	
	// TEMPORARY (remove in phase 2)
	UITableViewHeaderFooterView *viewHeader = [self.tableView headerViewForSection:0];

	[UIView setAnimationsEnabled:NO];
	[self.tableView beginUpdates];

	[viewHeader.textLabel setText:[NSString stringWithFormat:@"%@ %@", self.textDefaultHeader, @"Please contact TeleMed for assistance."]];
	[viewHeader sizeToFit];

	[self.tableView endUpdates];
	[UIView setAnimationsEnabled:YES];
	// END TEMPORARY
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
