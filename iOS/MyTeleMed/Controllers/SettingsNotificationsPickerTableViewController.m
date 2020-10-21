//
//  SettingsNotificationsPickerTableViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/11/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <AudioToolbox/AudioServices.h>

#import "SettingsNotificationsPickerTableViewController.h"
#import "NotificationSettingModel.h"

@interface SettingsNotificationsPickerTableViewController ()

@property (nonatomic) NSArray *pickerOptions;
@property (nonatomic) NSString *selectedTempOption;

@property (nonatomic) SystemSoundID systemSoundID;

@end

@implementation SettingsNotificationsPickerTableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Set selected temp option to selected option
	[self setSelectedTempOption:self.selectedOption];
	
	// Set picker options
	switch (self.pickerType)
	{
		// Subcategories and silent tone
		case 0:
			[self setPickerOptions:[NotificationSettingModel.subCategoryTones arrayByAddingObject:@"Silent"]];
			
			// Hide save button
			[self.navigationItem setRightBarButtonItem:nil];
			break;
		
		// Notification intervals
		case 1:
			[self setPickerOptions:NotificationSettingModel.intervals];
			
			// Hide save button
			[self.navigationItem setRightBarButtonItem:nil];
			break;
		
		// Staff favorite tones
		case 2:
			[self setPickerOptions:NotificationSettingModel.staffFavoriteTones];
			break;
		
		// MyTeleMed tones
		case 3:
			[self setPickerOptions:NotificationSettingModel.myTeleMedTones];
			break;
		
		// Standard tones
		case 4:
			[self setPickerOptions:NotificationSettingModel.standardTones];
			break;
		
		// Classic iOS tones
		case 5:
			[self setPickerOptions:NotificationSettingModel.classicTones];
			break;
	}
	
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Stop sound
	AudioServicesDisposeSystemSoundID(self.systemSoundID);
}

- (void)playNotificationTone:(NSInteger)selectedRow
{
	if ([self.pickerOptions count] <= selectedRow)
	{
		return;
	}
	
	NotificationSettingModel *notificationSettingModel = [[NotificationSettingModel alloc] init];
	NSString *toneName = [notificationSettingModel getToneFromToneTitle:[self.pickerOptions objectAtIndex:selectedRow]];
	NSString *tonePath = [[NSBundle mainBundle] pathForResource:toneName ofType:nil];
	
	NSLog(@"Tone Path: %@", tonePath);
	
	if (tonePath != nil)
	{
		AudioServicesDisposeSystemSoundID(self.systemSoundID);
		
		NSURL *toneURL = [NSURL fileURLWithPath:tonePath];
		AudioServicesCreateSystemSoundID((__bridge CFURLRef)toneURL, &_systemSoundID);
		AudioServicesPlaySystemSound(self.systemSoundID);
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.pickerOptions count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return ([self tableView:tableView titleForHeaderInSection:section] == nil) ? 22.0f : 46.0f;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (self.pickerType)
	{
		case 1:
			return @"REPEAT ALERT INCREMENTS";
			break;
		
		case 2:
		case 3:
		case 4:
		case 5:
		{
			// Get subcategory from array
			if ([NotificationSettingModel.subCategoryTones count] > self.pickerType - 2)
			{
				NSString *subCategory = [NotificationSettingModel.subCategoryTones objectAtIndex:self.pickerType - 2];
				
				// Singularize subcategory
				if ([[subCategory substringFromIndex:subCategory.length - 1] isEqualToString:@"s"])
				{
					subCategory = [subCategory substringToIndex:subCategory.length - 1];
				}
				
				return [NSString stringWithFormat:@"%@ ALERT SOUNDS", subCategory];
			}
			
			return @"ALERT SOUNDS";
			break;
		}
		
		case 0:
		default:
			return @"ALERT SOUNDS";
			break;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SettingsNotificationsCell";
	static NSString *SubcategoryCellIdentifier = @"SettingsNotificationsSubcategoryCell";
	
	NSString *optionText = [self.pickerOptions objectAtIndex:indexPath.row];
	
	UITableViewCell *cell;
	
	// Notification tone subcategory
	if (self.pickerType == 0 && [NotificationSettingModel.subCategoryTones containsObject:optionText])
	{
		NSArray *notificationTonesArray;
		
		cell = [tableView dequeueReusableCellWithIdentifier:SubcategoryCellIdentifier forIndexPath:indexPath];
		
		// Set custom tag value to be used in prepareForSegue for determining which notification tones to display
		[cell setTag:[NotificationSettingModel.subCategoryTones indexOfObject:optionText] + 2];
		
		switch (cell.tag)
		{
			// Staff favorite tones
			case 2:
				notificationTonesArray = NotificationSettingModel.staffFavoriteTones;
				break;
			
			// MyTeleMed tones
			case 3:
				notificationTonesArray = NotificationSettingModel.myTeleMedTones;
				break;
			
			// Standard tones
			case 4:
				notificationTonesArray = NotificationSettingModel.standardTones;
				break;
			
			// Classic iOS tones
			case 5:
				notificationTonesArray = NotificationSettingModel.classicTones;
				break;
		}
		
		// Add checkmark and set detail text on selected subcategory option
		if ([notificationTonesArray containsObject:self.selectedOption])
		{
			[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
			[cell.detailTextLabel setText:self.selectedOption];
			
			[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
	}
	// Notification interval or standard notification tone
	else
	{
	    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	
		// Clear checkmark (as cell is reused, checkmarks will start to show up where they shouldn't)
		[cell setAccessoryType:UITableViewCellAccessoryNone];
		
		// Add checkmark to selected option
		if ([optionText isEqualToString:self.selectedTempOption])
		{
			[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
			
			[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
	}
	
	// Set option text
	[cell.textLabel setText:optionText];
	   
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	// If showing Notification Intervals, make selection final
	if (self.pickerType == 1)
	{
		[self performSegueWithIdentifier:@"unwindSetNotificationSetting" sender:cell];
	}
	// If showing Subcategory and Silent Tones and user selects Silent, make selection final
	else if (self.pickerType == 0 && [self.pickerOptions count] >= indexPath.row && [[self.pickerOptions objectAtIndex:indexPath.row] isEqualToString:@"Silent"])
	{
		[self performSegueWithIdentifier:@"unwindSetNotificationSetting" sender:cell];
	}
	// If showing standard Notification Tones, add checkmark to selected option and play sound
	else if (cell.tag == 0)
	{
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
		[self setSelectedTempOption: [self.pickerOptions objectAtIndex:indexPath.row]];
		[self playNotificationTone:indexPath.row];
	}
	// Do nothing for Subcategory Notification Tones
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	// Replace checkmark with disclosure indicator and remove detail text
	if (cell.tag > 0)
	{
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
		[cell.detailTextLabel setText:@""];
	}
	// Remove checkmark of selected option
	else
	{
		[cell setAccessoryType:UITableViewCellAccessoryNone];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Notification tone subcategory selected
	if ([segue.identifier isEqualToString:@"showSettingsNotificationsSubcategoryPicker"])
	{
		UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
		
		// Set new picker type
		[segue.destinationViewController setPickerType:cell.tag];
		
		// Set selected option on new view controller
		[segue.destinationViewController setSelectedOption:self.selectedOption];
	}
	// Unwind segue
	else
	{
		NSInteger selectedRow = [[self.tableView indexPathForSelectedRow] row];
		
		// Set selected option
		if ([self.pickerOptions count] > selectedRow)
		{
			[self setSelectedOption:[self.pickerOptions objectAtIndex:selectedRow]];
		}
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
