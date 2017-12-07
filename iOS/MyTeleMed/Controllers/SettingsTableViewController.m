//
//  SettingsTableViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "AccountPickerViewController.h"
#import "SettingsNotificationsTableViewController.h"
#import "ProfileProtocol.h"

#ifdef MYTELEMED
	#import "MyProfileModel.h"
#endif

#ifdef MEDTOMED
	#import "UserProfileModel.h"
#endif

@interface SettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *switchTimeout;

@property (nonatomic) BOOL mayDisableTimeout;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Initialize May Disable Timeout value
	self.mayDisableTimeout = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Set May Disable Timeout value
	id <ProfileProtocol> profileProtocol;
	
	#ifdef MYTELEMED
		profileProtocol = [MyProfileModel sharedInstance];

	#elif defined MEDTOMED
		profileProtocol = [UserProfileModel sharedInstance];
	#endif
	
	if(profileProtocol)
	{
		self.mayDisableTimeout = profileProtocol.MayDisableTimeout;
	}
}

- (IBAction)updateTimeout:(id)sender
{
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	
	if(self.switchTimeout.isOn)
	{
		[preferences setBool:YES forKey:@"enableTimeout"];
	}
	else
	{
		if( ! [preferences boolForKey:@"timeoutAlert"])
		{
			UIAlertController *updateTimeoutAlertController = [UIAlertController alertControllerWithTitle:@"Confirm Time-Out is Disabled" message:@"HIPAA standards mandate a timeout. If this feature is disabled, please utilize your phone's lock settings to manually enforce this." preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
			{
				[self.switchTimeout setOn:YES];
			}];
			UIAlertAction *actionConfirm = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
			{
				NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
				
				[preferences setBool:YES forKey:@"timeoutAlert"];
				[preferences setBool:NO forKey:@"enableTimeout"];
				[preferences synchronize];
			}];
		
			[updateTimeoutAlertController addAction:actionCancel];
			[updateTimeoutAlertController addAction:actionConfirm];
		
			// PreferredAction only supported in 9.0+
			if([updateTimeoutAlertController respondsToSelector:@selector(setPreferredAction:)])
			{
				[updateTimeoutAlertController setPreferredAction:actionCancel];
			}
		
			// Show Alert
			[self presentViewController:updateTimeoutAlertController animated:YES completion:nil];
		}
		else
		{
			[preferences setBool:NO forKey:@"enableTimeout"];
		}
	}
	
	[preferences synchronize];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// If user's account settings prevent MayDisableTimeout, hide Session Timeout section
    if(section == 0 && ! self.mayDisableTimeout)
	{
		return 0;
	}
	
	return [super tableView:tableView numberOfRowsInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	// If user's account settings prevent MayDisableTimeout, hide Session Timeout section by setting its header height to 0.1 (0.0 doesn't work)
	return (section == 0 && ! self.mayDisableTimeout ? 0.1 : ([self tableView:tableView titleForHeaderInSection:section] == nil ? 22.0 : 46.0));
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	// If user's account settings prevent MayDisableTimeout, hide Session Timeout section by setting its footer height to 0.1 (0.0 doesn't work)
	return (section == 0 && ! self.mayDisableTimeout ? 0.1 : [super tableView:tableView heightForFooterInSection:section]);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	// If user's account settings prevent MayDisableTimeout, hide Session Timeout section by clearing its header title
	// Note: it is not enough to simply set the header height to 0.1 because user can still drag the screen down and see the text
	return (section == 0 && ! self.mayDisableTimeout ? @"" : [super tableView:tableView titleForHeaderInSection:section]);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	// If user's account settings prevent MayDisableTimeout, hide Session Timeout section by clearing its footer title
	// Note: it is not enough to simply set the footer height to 0.1 because user can still drag the screen down and see the text
	return (section == 0 && ! self.mayDisableTimeout ? @"" : [super tableView:tableView titleForFooterInSection:section]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
	// Set Timeout Value
	if(indexPath.section == 0)
	{
		NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
		
		[self.switchTimeout setOn:[preferences boolForKey:@"enableTimeout"]];
	}
	// Add Version Number to Version cell
	else if(indexPath.section == 3)
	{
		[cell.detailTextLabel setText:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
	}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSLog(@"Section: %ld", (long)indexPath.section);
	
	// Segue to Notification Settings
	if(indexPath.section == 1)
	{
		[self performSegueWithIdentifier:@"showSettingsNotifications" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
	}
	// Segue to Change Password
	else if(indexPath.section == 2 && indexPath.row == 0)
	{
		[self performSegueWithIdentifier:@"showSettingsPassword" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
	}
	// Segue to Preferred Account
	else if(indexPath.section == 2 && indexPath.row == 1)
	{
		[self performSegueWithIdentifier:@"showAccountPickerFromSettings" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Embedded Table View Controller inside Container
	if([segue.identifier isEqualToString:@"showSettingsNotifications"])
	{
		SettingsNotificationsTableViewController *settingsNotificationsTableViewController = segue.destinationViewController;
		NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
		
		// Set Notification Settings Type
		[settingsNotificationsTableViewController setNotificationSettingsType:indexPath.row];
	// Update title of AccountsPickerViewController
	} else if([segue.identifier isEqualToString:@"showAccountPickerFromSettings"]) {
		AccountPickerViewController *accountPickerViewController = segue.destinationViewController;
		
		[accountPickerViewController setTitle:@"Preferred Account"];
		[accountPickerViewController setShouldSetPreferredAccount:YES];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
