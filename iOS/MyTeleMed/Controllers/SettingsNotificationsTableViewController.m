//
//  SettingsNotificationsTableViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/11/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "SettingsNotificationsTableViewController.h"
#import "ErrorAlertController.h"
#import "SettingsNotificationsPickerTableViewController.h"
#import "NotificationSettingModel.h"

@interface SettingsNotificationsTableViewController ()

@property (nonatomic) NotificationSettingModel *notificationSettingModel;

@property (weak, nonatomic) IBOutlet UISwitch *switchReminders;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellTone;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellInterval;

@property (nonatomic) NSString *notificationSettingsName;

- (IBAction)setSelectedNotificationSetting:(UIStoryboardSegue *)segue;

@end

@implementation SettingsNotificationsTableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// If notification settings are not nil, then we are returning from SettingsNotificationsPickerViewController and don't want to reset the settings
	if (self.notificationSettings != nil)
	{
		return;
	}
	
	// Set notification settings type as string
	switch (self.notificationSettingsType)
	{
		// Stat message settings
		case 0:
			[self setNotificationSettingsName:@"stat"];
			[self.navigationItem setTitle:@"Stat Messages"];
			break;
		
		// Normal message settings
		case 1:
			[self setNotificationSettingsName:@"normal"];
			[self.navigationItem setTitle:@"Normal Messages"];
			break;
		
		// Chat message settings
		case 2:
			[self setNotificationSettingsName:@"chat"];
			[self.navigationItem setTitle:@"Secure Chat Messages"];
			break;
		
		// Comment settings
		case 3:
			[self setNotificationSettingsName:@"comment"];
			[self.navigationItem setTitle:@"Comments"];
			break;
	}
	
	// Load notification settings for name
	[self setNotificationSettingModel:[[NotificationSettingModel alloc] init]];
	
	[self.notificationSettingModel setDelegate:self];
	[self setNotificationSettings:[self.notificationSettingModel getNotificationSettingsByName:self.notificationSettingsName]];
}

- (IBAction)reminderChanged:(id)sender
{
	[self.notificationSettings setIsReminderOn:self.switchReminders.isOn];
	
	[self.tableView reloadData];
	
	// Save to server
	[self.notificationSettingModel saveNotificationSettingsByName:self.notificationSettingsName settings:self.notificationSettings];
}

// Unwind segue from SettingsNotificationsPickerTableViewController
- (IBAction)setSelectedNotificationSetting:(UIStoryboardSegue *)segue
{
	SettingsNotificationsPickerTableViewController *settingsNotificationsPickerTableViewController = segue.sourceViewController;
	
	NSString *selectedOption = settingsNotificationsPickerTableViewController.selectedOption;
	
	// Set selected notification interval
	if (settingsNotificationsPickerTableViewController.pickerType == 1)
	{
		[self.notificationSettings setInterval:[NSNumber numberWithInteger:[selectedOption integerValue]]];
	}
	// Set selected notification tone
	else
	{
		[self.notificationSettings setToneTitle:selectedOption];
	}
	
	[self.tableView reloadData];
	
	// Save to server
	[self.notificationSettingModel saveNotificationSettingsByName:self.notificationSettingsName settings:self.notificationSettings];
}

// Return server notification settings from NotificationSettingModel delegate
- (void)updateNotificationSettings:(NotificationSettingModel *)serverNotificationSettings forName:(NSString *)name
{
	[self setNotificationSettings:serverNotificationSettings];
	
	[self.tableView reloadData];
}

// Return error from NotificationSettingModel delegate
- (void)updateNotificationSettingsError:(NSError *)error
{
	NSLog(@"Error loading notification settings");
	
	// Show error message only if device offline
	if (error.code == NSURLErrorNotConnectedToInternet)
	{
		ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
		
		[errorAlertController show:error];
	}
}

/*/ Return save success from NotificationSettingModel delegate (no longer used)
- (void)saveNotificationSettingsSuccess
{
	NSLog(@"Notification Settings saved to server successfully");
}

// Return save error from NotificationSettingModel delegate (no longer used)
-(void)saveNotificationSettingsError:(NSError *)error
{
	ErrorAlertController *errorAlertController = [ErrorAlertController sharedInstance];
	
	[errorAlertController show:error];
}*/

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return ([self tableView:tableView titleForHeaderInSection:section] == nil) ? 22.0f : 46.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Hide everything except alert sound for chat and comments
	return (self.notificationSettingsType >= 2 && indexPath.row != 1 ? 0 : UITableViewAutomaticDimension);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	
	switch (indexPath.row)
	{
		// Reminders row
		case 0:
		{
			// Set reminders value
			[self.switchReminders setOn:self.notificationSettings.isReminderOn];
			break;
		}
		
		// Tone row
		case 1:
		{
			// Set tone text
			[cell.detailTextLabel setText:self.notificationSettings.ToneTitle];
			break;
		}
		
		// Interval row
		case 2:
		{
			// Set interval text
			[cell.detailTextLabel setText:[[self.notificationSettings.Interval stringValue] stringByAppendingString:@" min"]];
			break;
		}
	}
	
	// Fix iOS8 Issue that prevents detail text from appearing
	[cell layoutSubviews];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Segue to notification settings picker
	if (indexPath.row > 0)
	{
		[self performSegueWithIdentifier:@"showSettingsNotificationsPicker" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"showSettingsNotificationsPicker"])
	{
		SettingsNotificationsPickerTableViewController *settingsNotificationsPickerTableViewController = segue.destinationViewController;
		UITableViewCell *cell = (UITableViewCell *)sender;
		
		// Set picker type
		[settingsNotificationsPickerTableViewController setPickerType:cell.tag];
		
		// Set selected notification tone
		if (cell.tag == 0)
		{
			[settingsNotificationsPickerTableViewController setSelectedOption:self.notificationSettings.ToneTitle];
		}
		// Set selected notification interval
		else
		{
			[settingsNotificationsPickerTableViewController setSelectedOption:[[self.notificationSettings.Interval stringValue] stringByAppendingFormat:@" minute%@", ([self.notificationSettings.Interval isEqualToNumber:[NSNumber numberWithInt:1]] ? @"" : @"s")]];
		}
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
