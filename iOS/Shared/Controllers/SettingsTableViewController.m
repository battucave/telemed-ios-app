//
//  SettingsTableViewController.m
//  TeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>

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

@property (nonatomic) NSString *defaultTimeoutFooterTitle;
@property (nonatomic) BOOL mayDisableTimeout;
@property (nonatomic) id <ProfileProtocol> profile;
@property (nonatomic) NSInteger sectionAboutTeleMed;
@property (nonatomic) NSInteger sectionNotifications;
@property (nonatomic) NSInteger sectionSessionTimeout;

#ifdef MYTELEMED
	@property (weak, nonatomic) IBOutlet UISwitch *switchNotifications;

	@property (nonatomic) NotificationSettingModel *chatMessageNotificationSettings;
	@property (nonatomic) NotificationSettingModel *commentNotificationSettings;
	@property (nonatomic) NotificationSettingModel *normalMessageNotificationSettings;
	@property (nonatomic) NotificationSettingModel *statMessageNotificationSettings;
	@property (nonatomic) BOOL areNotificationsEnabled;
#endif

@end

@implementation SettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Initialize may disable timeout value
	[self setMayDisableTimeout:NO];
	
	// Initialize sections
	[self setSectionSessionTimeout:0];
	
	#ifdef MED2MED
		[self setSectionAboutTeleMed:2];
	
	#elif defined MYTELEMED
		[self setSectionAboutTeleMed:3];
		[self setSectionNotifications:1];
	
		// Initialize notifications enabled value
		[self setAreNotificationsEnabled:YES];
	
		// Add application will enter foreground observer to refresh notifications section when user returns from Settings app
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	#endif
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	#ifdef MYTELEMED
		[self setProfile:[MyProfileModel sharedInstance]];
	
		// Load notification settings for each type
		NotificationSettingModel *notificationSettingModel = [[NotificationSettingModel alloc] init];
	
		[notificationSettingModel setDelegate:self];
	
		[self setChatMessageNotificationSettings:[notificationSettingModel getNotificationSettingsByName:@"chat"]];
		[self setCommentNotificationSettings:[notificationSettingModel getNotificationSettingsByName:@"comment"]];
		[self setNormalMessageNotificationSettings:[notificationSettingModel getNotificationSettingsByName:@"normal"]];
		[self setStatMessageNotificationSettings:[notificationSettingModel getNotificationSettingsByName:@"stat"]];
	
		// Determine whether notifications are enabled
		UNUserNotificationCenter *userNotificationCenter = [UNUserNotificationCenter currentNotificationCenter];
	
		[userNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings)
		{
			if (settings.authorizationStatus != UNAuthorizationStatusAuthorized)
			{
				[self setAreNotificationsEnabled:NO];
				
				// Reload notification cells
				dispatch_async(dispatch_get_main_queue(), ^
				{
					[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.sectionNotifications] withRowAnimation:UITableViewRowAnimationNone];
				});
			}
		}];

	#elif defined MED2MED
		[self setProfile:[UserProfileModel sharedInstance]];
	#endif
	
	// Set may disable timeout value
	if (self.profile)
	{
		self.mayDisableTimeout = self.profile.MayDisableTimeout;
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// Store default timeout footer title
	[self setDefaultTimeoutFooterTitle:[super tableView:self.tableView titleForFooterInSection:0]];
}

- (IBAction)timeoutChanged:(id)sender
{
	// If remember me option is enabled
	if (self.switchTimeout.isOn)
	{
		UIAlertController *updateTimeoutAlertController = [UIAlertController alertControllerWithTitle:@"Confirm Time-Out is Disabled" message:@"HIPAA standards mandate a timeout. If this feature is disabled, please utilize your phone's lock settings to manually enforce this." preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
		{
			[self.switchTimeout setOn:NO];
		}];
		UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
		{
			NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
			
			[settings setBool:NO forKey:@"enableTimeout"];
			[settings synchronize];
		
			// Toggle title of footer in timeout section
			[self toggleSectionTimeoutFooterTitle:NO];
		}];
	
		[updateTimeoutAlertController addAction:confirmAction];
		[updateTimeoutAlertController addAction:cancelAction];
	
		// Set preferred action
		[updateTimeoutAlertController setPreferredAction:cancelAction];
	
		// Show alert
		[self presentViewController:updateTimeoutAlertController animated:YES completion:nil];
	}
	// If remember me option is disabled
	else
	{
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		
		[settings setBool:YES forKey:@"enableTimeout"];
		[settings synchronize];
		
		// Toggle title of footer in timeout section
		[self toggleSectionTimeoutFooterTitle:YES];
	}
}

- (NSString *)getSectionTimeoutFooterTitle:(BOOL)isTimeoutEnabled
{
	if (isTimeoutEnabled)
	{
		NSNumber *timeoutPeriodMins = (self.profile ? self.profile.TimeoutPeriodMins : [NSNumber numberWithInteger:30]);
		
		return [self.defaultTimeoutFooterTitle stringByReplacingOccurrencesOfString:@"%d" withString:[timeoutPeriodMins stringValue]];
	}
	else
	{
		return @"Your login session will not expire.";
	}
}

- (void)toggleSectionTimeoutFooterTitle: (BOOL)isTimeoutEnabled
{
	UITableViewHeaderFooterView *footerView = [self.tableView footerViewForSection:self.sectionSessionTimeout];
	
	[UIView setAnimationsEnabled:NO];
	[self.tableView beginUpdates];

	[footerView.textLabel setText:[self getSectionTimeoutFooterTitle:isTimeoutEnabled]];
	[footerView sizeToFit];

	[self.tableView endUpdates];
	[UIView setAnimationsEnabled:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// If user's account settings prevent MayDisableTimeout, hide session timeout section
    if (section == self.sectionSessionTimeout && ! self.mayDisableTimeout)
	{
		return 0;
	}
	
	return [super tableView:tableView numberOfRowsInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	// If user's account settings prevent MayDisableTimeout, hide session timeout section by setting its header height to 0
	return (section == self.sectionSessionTimeout && ! self.mayDisableTimeout ? 0.1f : ([self tableView:tableView titleForHeaderInSection:section] == nil ? 22.0f : 46.0f));
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	// If user's account settings prevent MayDisableTimeout, hide session timeout section by setting its footer height to 0
	if (section == self.sectionSessionTimeout && ! self.mayDisableTimeout)
	{
		return 0.1f;
	}
	
	#ifdef MYTELEMED
		// If notifications are disabled, hide notifications section by setting its footer height to 0
		if (section == self.sectionNotifications && ! self.areNotificationsEnabled)
		{
			return 0.1f;
		}
	#endif
	
	return [super tableView:tableView heightForFooterInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	// If user's account settings prevent MayDisableTimeout, hide session timeout section by clearing its header title
	// Note: it is not enough to simply set the header height to 0.1 because user can still drag the screen down and see the text
	return (section == self.sectionSessionTimeout && ! self.mayDisableTimeout ? @"" : [super tableView:tableView titleForHeaderInSection:section]);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (section == self.sectionSessionTimeout)
	{
		// If user's account settings prevent MayDisableTimeout, hide session timeout section by clearing its footer title
		if (! self.mayDisableTimeout)
		{
			return @"";
		}
		// Update default footer title with user's account TimeoutPeriodMins
		else
		{
			NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
			
			return [self getSectionTimeoutFooterTitle:[settings boolForKey:@"enableTimeout"]];
		}
	}
	
	#ifdef MYTELEMED
		// If notifications are disabled, hide notifications section by clearing its footer title
		if (section == self.sectionNotifications && ! self.areNotificationsEnabled)
		{
			return @"";
		}
	#endif
	
	return [super tableView:tableView titleForFooterInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	
	// Set timeout value
	if (indexPath.section == self.sectionSessionTimeout)
	{
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		
		[self.switchTimeout setOn:! [settings boolForKey:@"enableTimeout"]];
	}
	// Add version and build numbers to version cell
	else if (indexPath.section == self.sectionAboutTeleMed)
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
	
	#ifdef MYTELEMED
	// Set notification settings in cell's detail
	else if (indexPath.section == self.sectionNotifications)
	{
		if (indexPath.row == 0)
		{
			// Set notifications enabled visibility
			[cell setHidden:self.areNotificationsEnabled];
			
			// Set notifications enabled value
			[self.switchNotifications setOn:self.areNotificationsEnabled];
		}
		else
		{
			NSString *detailText;
			
			switch (indexPath.row)
			{
				// Stat message settings
				case 1:
					detailText = self.statMessageNotificationSettings.ToneTitle;
					
					// Append repeat details
					if (self.statMessageNotificationSettings.isReminderOn)
					{
						detailText = [detailText stringByAppendingFormat:@", %@ min repeat", self.statMessageNotificationSettings.Interval];
					}
					break;
				
				// Normal message settings
				case 2:
					detailText = self.normalMessageNotificationSettings.ToneTitle;
					
					// Append repeat details
					if (self.normalMessageNotificationSettings.isReminderOn)
					{
						detailText = [detailText stringByAppendingFormat:@", %@ min repeat", self.normalMessageNotificationSettings.Interval];
					}
					break;
				
				// Chat message settings (repeat notifications are not used)
				case 3:
					detailText = self.chatMessageNotificationSettings.ToneTitle;
					break;
				
				// Comment settings (repeat notifications are not used)
				case 4:
					detailText = self.commentNotificationSettings.ToneTitle;
					break;
			}
			
			[cell setHidden:! self.areNotificationsEnabled];
			[cell.detailTextLabel setText:detailText];
		}
	}
	#endif
	
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
			[settingsNotificationsTableViewController setNotificationSettingsType:indexPath.row  - 1];
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
-(IBAction)notificationsChanged:(id)sender
{
	// Instruct user how to enable notifications
	if (self.switchNotifications.isOn)
	{
		UIAlertController *allowNotificationsAlertController = [UIAlertController alertControllerWithTitle:@"Enable Notifications" message:@"Please confirm your preference to enable notifications.\n\n1) Press the Settings button\n2) Tap Notifications\n3) Set 'Allow Notifications' to On" preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
		{
			// Notifications are still disabled so disable switch
			[self.switchNotifications setOn:NO];
		}];
		UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
		{
			// Open settings app for user to enable notifications
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
		}];

		[allowNotificationsAlertController addAction:settingsAction];
		[allowNotificationsAlertController addAction:cancelAction];

		// PreferredAction only supported in 9.0+
		if ([allowNotificationsAlertController respondsToSelector:@selector(setPreferredAction:)])
		{
			[allowNotificationsAlertController setPreferredAction:settingsAction];
		}

		// Show alert
		[self presentViewController:allowNotificationsAlertController animated:YES completion:nil];
	}
}

- (void)viewDidBecomeActive:(NSNotification *)notification
{
	// Refresh notifications enabled status when app returns from Settings app
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
	{
		UNUserNotificationCenter *userNotificationCenter = [UNUserNotificationCenter currentNotificationCenter];

		[userNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings)
		{
			[self setAreNotificationsEnabled:(settings.authorizationStatus == UNAuthorizationStatusAuthorized)];
			
			// Reload notification cells
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.sectionNotifications] withRowAnimation:UITableViewRowAnimationNone];
		}];
	});
}

// Return server notification settings from NotificationSettingModel delegate
- (void)updateNotificationSettings:(NotificationSettingModel *)serverNotificationSettings forName:(NSString *)name
{
	NSNumber *row;
	
	// Chat message settings
	if ([name isEqualToString:@"chat"])
	{
		[self setChatMessageNotificationSettings:serverNotificationSettings];
		
		row = @3;
	}
	// Comment settings
	else if ([name isEqualToString:@"comment"])
	{
		[self setCommentNotificationSettings:serverNotificationSettings];
		
		row = @4;
	}
	// Normal message settings
	else if ([name isEqualToString:@"normal"])
	{
		[self setNormalMessageNotificationSettings:serverNotificationSettings];
		
		row = @2;
	}
	// Stat message settings
	else if ([name isEqualToString:@"stat"])
	{
		[self setStatMessageNotificationSettings:serverNotificationSettings];
		
		row = @1;
	}
	
	// Reload corresponding notification cell
	if (row != NULL)
	{
		[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[row integerValue] inSection:self.sectionNotifications]] withRowAnimation:UITableViewRowAnimationNone];
	}
}

// Return error from NotificationSettingModel delegate
- (void)updateNotificationSettingsError:(NSError *)error
{
	NSLog(@"Error loading notification settings");
	
	// Fail silently and let SettingsNotificationsTableViewController handle
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == self.sectionNotifications)
	{
		// If notifications are enabled, hide the notifications enabled row. Or if notifications are disabled, hide the rest of the notification rows
		if ((self.areNotificationsEnabled && indexPath.row == 0) || (! self.areNotificationsEnabled && indexPath.row > 0))
		{
			return 0.1f;
		}
	}
	
	return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == self.sectionNotifications)
	{
		// Segue to notification settings
		if (indexPath.row > 0 )
		{
			[self performSegueWithIdentifier:@"showSettingsNotifications" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
		}
	}
	
	// Note: MyProfile cells use segues directly from table cell
}

-(void)dealloc
{
	// Remove notification observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
#endif

@end
