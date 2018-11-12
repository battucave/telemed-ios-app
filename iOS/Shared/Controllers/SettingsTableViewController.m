//
//  SettingsTableViewController.m
//  TeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "AccountPickerViewController.h"
#import "ProfileProtocol.h"

#ifdef MYTELEMED
	#import "SettingsNotificationsTableViewController.h"
	#import "MyProfileModel.h"
#endif

#ifdef MED2MED
	#import "HospitalPickerViewController.h"
	#import "UserProfileModel.h"
#endif

@interface SettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *switchTimeout;

@property (nonatomic) BOOL mayDisableTimeout;
@property (nonatomic) NSInteger aboutTeleMedSection;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Initialize may disable timeout value
	self.mayDisableTimeout = NO;
	
	#ifdef MED2MED
		[self setAboutTeleMedSection:2];
	
	#else
		[self setAboutTeleMedSection:3];
	#endif
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Set may disable timeout value
	id <ProfileProtocol> profile;
	
	#ifdef MYTELEMED
		profile = [MyProfileModel sharedInstance];

	#elif defined MED2MED
		profile = [UserProfileModel sharedInstance];
	#endif
	
	if (profile)
	{
		self.mayDisableTimeout = profile.MayDisableTimeout;
	}
}

- (IBAction)timeoutChanged:(id)sender
{
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	if (self.switchTimeout.isOn)
	{
		[settings setBool:YES forKey:@"enableTimeout"];
	}
	else
	{
		if (! [settings boolForKey:@"timeoutAlert"])
		{
			UIAlertController *updateTimeoutAlertController = [UIAlertController alertControllerWithTitle:@"Confirm Time-Out is Disabled" message:@"HIPAA standards mandate a timeout. If this feature is disabled, please utilize your phone's lock settings to manually enforce this." preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
			{
				[self.switchTimeout setOn:YES];
			}];
			UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
			{
				NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
				
				[settings setBool:YES forKey:@"timeoutAlert"];
				[settings setBool:NO forKey:@"enableTimeout"];
				[settings synchronize];
			}];
		
			[updateTimeoutAlertController addAction:cancelAction];
			[updateTimeoutAlertController addAction:confirmAction];
		
			// PreferredAction only supported in 9.0+
			if ([updateTimeoutAlertController respondsToSelector:@selector(setPreferredAction:)])
			{
				[updateTimeoutAlertController setPreferredAction:cancelAction];
			}
		
			// Show alert
			[self presentViewController:updateTimeoutAlertController animated:YES completion:nil];
		}
		else
		{
			[settings setBool:NO forKey:@"enableTimeout"];
		}
	}
	
	[settings synchronize];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// If user's account settings prevent MayDisableTimeout, hide session timeout section
    if (section == 0 && ! self.mayDisableTimeout)
	{
		return 0;
	}
	
	return [super tableView:tableView numberOfRowsInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	// If user's account settings prevent MayDisableTimeout, hide session timeout section by setting its header height to 0
	return (section == 0 && ! self.mayDisableTimeout ? 0.1f : ([self tableView:tableView titleForHeaderInSection:section] == nil ? 22.0f : 46.0f));
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	// If user's account settings prevent MayDisableTimeout, hide session timeout section by setting its footer height to 0
	return (section == 0 && ! self.mayDisableTimeout ? 0.1f : [super tableView:tableView heightForFooterInSection:section]);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	// If user's account settings prevent MayDisableTimeout, hide session timeout section by clearing its header title
	// Note: it is not enough to simply set the header height to 0.1 because user can still drag the screen down and see the text
	return (section == 0 && ! self.mayDisableTimeout ? @"" : [super tableView:tableView titleForHeaderInSection:section]);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	// If user's account settings prevent MayDisableTimeout, hide session timeout section by clearing its footer title
	// Note: it is not enough to simply set the footer height to 0.1 because user can still drag the screen down and see the text
	return (section == 0 && ! self.mayDisableTimeout ? @"" : [super tableView:tableView titleForFooterInSection:section]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
	// Set timeout value
	if (indexPath.section == 0)
	{
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		
		[self.switchTimeout setOn:[settings boolForKey:@"enableTimeout"]];
	}
	// Add version and build numbers to version cell
	else if (indexPath.section == self.aboutTeleMedSection)
	{
		if (indexPath.row == 0)
		{
			NSString *buildNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
			NSString *versionNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
			
			// Show only the version number for release version to eliminate confusion for TeleMed's support staff
			#if RELEASE
				[cell.detailTextLabel setText:versionNumber];
			
			// Also show build number for debug and beta versions
			#else
				[cell.detailTextLabel setText:[NSString stringWithFormat:@"%@ (%@)", versionNumber, buildNumber]];
			#endif
		}
	}
	
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Update title of AccountsPickerViewController
	if ([segue.identifier isEqualToString:@"showAccountPickerFromSettings"])
	{
		AccountPickerViewController *accountPickerViewController = segue.destinationViewController;
		
		#ifdef MYTELEMED
			[accountPickerViewController setTitle:@"Preferred Account"];
			[accountPickerViewController setShouldSetPreferredAccount:YES];
		
		#elif defined MED2MED
			[accountPickerViewController setTitle:@"My Medical Groups"];
			[accountPickerViewController setShouldSelectAccount:NO];
		#endif
	}
	
	#ifdef MYTELEMED
		// Embedded table view controller inside container
		else if ([segue.identifier isEqualToString:@"showSettingsNotifications"])
		{
			SettingsNotificationsTableViewController *settingsNotificationsTableViewController = segue.destinationViewController;
			NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
			
			// Set notification settings type
			[settingsNotificationsTableViewController setNotificationSettingsType:indexPath.row];
		}
	
	#elif defined MED2MED
		// Update title of HospitalsPickerViewController
		else if ([segue.identifier isEqualToString:@"showHospitalPickerFromSettings"]) {
			HospitalPickerViewController *hospitalPickerViewController = segue.destinationViewController;
			
			[hospitalPickerViewController setTitle:@"My Hospitals"];
		}
	#endif
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - MyTeleMed

#ifdef MYTELEMED
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Segue to notification settings
	if (indexPath.section == 1)
	{
		[self performSegueWithIdentifier:@"showSettingsNotifications" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
	}
	
	// Note: MyProfile cells use segues directly from table cell
}
#endif

@end
