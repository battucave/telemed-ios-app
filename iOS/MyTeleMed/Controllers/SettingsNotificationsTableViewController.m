//
//  SettingsNotificationsTableViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/11/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "SettingsNotificationsTableViewController.h"
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

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// If Notification Settings are not nil, then we are returning from MessageRecipientPickerViewController and don't want to reset the settings
	if(self.notificationSettings != nil)
	{
		return;
	}
	
	// Set Notification Settings Type as string
	switch(self.notificationSettingsType)
	{
		// Stat Settings
		case 1:
			[self setNotificationSettingsName:@"stat"];
			[self.navigationItem setTitle:@"Stat Messages"];
			break;
		
		// Priority Settings
		case 2:
			[self setNotificationSettingsName:@"priority"];
			[self.navigationItem setTitle:@"Priority Messages"];
			break;
		
		// Normal Settings
		case 3:
			[self setNotificationSettingsName:@"normal"];
			[self.navigationItem setTitle:@"Normal Messages"];
			break;
		
		// Chat Settings
		case 4:
			[self setNotificationSettingsName:@"chat"];
			[self.navigationItem setTitle:@"Chat Messages"];
			break;
		
		// Comment Settings
		case 5:
			[self setNotificationSettingsName:@"comment"];
			[self.navigationItem setTitle:@"Comment Messages"];
			break;
	}
	
	// Load Notification Settings for name
	[self setNotificationSettingModel:[[NotificationSettingModel alloc] init]];
	
	[self.notificationSettingModel setDelegate:self];
	[self setNotificationSettings:[self.notificationSettingModel getNotificationSettingsByName:self.notificationSettingsName]];
}

- (IBAction)updateReminder:(id)sender
{
	[self.notificationSettings setIsReminderOn:self.switchReminders.isOn];
	
	[self.tableView reloadData];
	
	// Save to server
	[self.notificationSettingModel saveNotificationSettingsByName:self.notificationSettingsName settings:self.notificationSettings];
}

// Unwind Segue from SettingsNotificationsPickerTableViewController
- (IBAction)setSelectedNotificationSetting:(UIStoryboardSegue *)segue
{
	SettingsNotificationsPickerTableViewController *settingsNotificationsPickerTableViewController = segue.sourceViewController;
	
	NSString *selectedOption = settingsNotificationsPickerTableViewController.selectedOption;
	
	// Set selected Notification Interval
	if(settingsNotificationsPickerTableViewController.pickerType == 1)
	{
		[self.notificationSettings setInterval:[NSNumber numberWithInteger:[selectedOption integerValue]]];
	}
	// Set selected Notification Tone
	else
	{
		[self.notificationSettings setToneTitle:selectedOption];
	}
	
	[self.tableView reloadData];
	
	// Save to server
	[self.notificationSettingModel saveNotificationSettingsByName:self.notificationSettingsName settings:self.notificationSettings];
}

// Return Server Notification Settings from NotificationSettingModel delegate
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
	if(error.code == NSURLErrorNotConnectedToInternet)
	{
		[self.notificationSettingModel showError:error];
	}
}

/*/ Return Save success from NotificationSettingModel delegate (no longer used)
- (void)saveNotificationSettingsSuccess
{
	NSLog(@"Notification Settings saved to server successfully");
}

// Return Save error from NotificationSettingModel delegate (no longer used)
-(void)saveNotificationSettingsError:(NSError *)error
{
	// If device offline, show offline message
	if(error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut)
	{
		return [self.notificationSettingModel showOfflineError];
	}
	
	UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Notification Settings Error" message:@"There was a problem saving your Notification Settings. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[errorAlertView show];
}*/

/*- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	// Set Notification Settings Type as string
	switch(self.notificationSettingsType)
	{
		// Stat Settings
		case 1:
			return @"Stat Messages";
			break;
		
		// Priority Settings
		case 2:
			return @"Priority Messages";
			break;
		
		// Normal Settings
		case 3:
			return @"Normal Messages";
			break;
		
		// Comment Settings
		case 4:
			return @"Chat Messages";
			break;
		
		// Comment Settings
		case 5:
			return @"Comments";
			break;
	}
	
	return @"";
}*/

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return ([self tableView:tableView titleForHeaderInSection:section] == nil) ? 22.0 : 46.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Hide everything except Alert Sound for Comments
	return (self.notificationSettingsType == 5 && indexPath.row != 1 ? 0 : [super tableView:tableView heightForRowAtIndexPath:indexPath]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	
	switch(indexPath.row)
	{
		// Reminders Row
		case 0:
		{
			// Set Reminders value
			[self.switchReminders setOn:self.notificationSettings.isReminderOn];
			
			// Prevent cell selection
			[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
			break;
		}
		
		// Tone Row
		case 1:
		{
			// Set Tone text
			[cell.detailTextLabel setText:self.notificationSettings.ToneTitle];
			break;
		}
		
		// Interval Row
		case 2:
		{
			// Set Interval text
			[cell.detailTextLabel setText:[[self.notificationSettings.Interval stringValue] stringByAppendingString:@" min"]];
			break;
		}
	}
	
	// Fix iOS8 Issue that prevents detailText from appearing
	[cell layoutSubviews];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Segue to Notification Settings Picker
	if(indexPath.row > 0)
	{
		[self performSegueWithIdentifier:@"showSettingsNotificationsPicker" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([segue.identifier isEqualToString:@"showSettingsNotificationsPicker"])
	{
		SettingsNotificationsPickerTableViewController *settingsNotificationsPickerTableViewController = segue.destinationViewController;
		UITableViewCell *cell = (UITableViewCell *)sender;
		
		// Set Picker Type
		[settingsNotificationsPickerTableViewController setPickerType:cell.tag];
		
		// Set selected Notification Tone
		if(cell.tag == 0)
		{
			[settingsNotificationsPickerTableViewController setSelectedOption:self.notificationSettings.ToneTitle];
		}
		// Set selected Notification Interval
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
