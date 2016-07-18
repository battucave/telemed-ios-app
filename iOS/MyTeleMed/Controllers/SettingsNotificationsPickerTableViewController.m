//
//  SettingsNotificationsPickerTableViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/11/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "SettingsNotificationsPickerTableViewController.h"
#import "NotificationSettingModel.h"
#import <AudioToolbox/AudioServices.h>

@interface SettingsNotificationsPickerTableViewController ()

@property (nonatomic) NSArray *subCategories;
@property (nonatomic) NSArray *pickerOptions;
@property (nonatomic) NSString *selectedTempOption;

@property (nonatomic) SystemSoundID toneSound;

@end

@implementation SettingsNotificationsPickerTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Store Notification Tone Subcategories as array
	[self setSubCategories:[[NSArray alloc] initWithObjects:NOTIFICATION_TONES_SUBCATEGORIES, nil]];
	
	// Set Selected Temp Option to Selected Option
	[self setSelectedTempOption:self.selectedOption];
	
	// Set Picker Options
	switch(self.pickerType)
	{
		// Subcategory Tones
		case 0:
			[self setPickerOptions:[[NSArray alloc] initWithObjects:NOTIFICATION_TONES_SUBCATEGORIES, @"Silent", nil]];
			
			// Hide Done Button
			[self.navigationItem setRightBarButtonItem:nil];
			break;
		
		// Notification Intervals
		case 1:
			[self setPickerOptions:[[NSArray alloc] initWithObjects:NOTIFICATION_INTERVALS, nil]];
			
			// Hide Done Button
			[self.navigationItem setRightBarButtonItem:nil];
			break;
		
		// Staff Favorite Tones
		case 2:
			[self setPickerOptions:[[NSArray alloc] initWithObjects:NOTIFICATION_TONES_STAFF_FAVORITES, nil]];
			break;
		
		// MyTeleMed Tones
		case 3:
			[self setPickerOptions:[[NSArray alloc] initWithObjects:NOTIFICATION_TONES_MYTELEMED, nil]];
			break;
		
		// iOS7 Tones
		case 4:
			[self setPickerOptions:[[NSArray alloc] initWithObjects:NOTIFICATION_TONES_IOS7, nil]];
			break;
		
		// Classic iOS Tones
		case 5:
			[self setPickerOptions:[[NSArray alloc] initWithObjects:NOTIFICATION_TONES_CLASSIC_IOS, nil]];
			break;
	}
	
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Stop sound
	AudioServicesDisposeSystemSoundID(self.toneSound);
}

- (void)playNotificationTone:(NSInteger)selectedRow
{
	if([self.pickerOptions count] <= selectedRow)
	{
		return;
	}
	
	NotificationSettingModel *notificationSettingModel = [[NotificationSettingModel alloc] init];
	NSString *toneName = [notificationSettingModel getToneFromToneTitle:[self.pickerOptions objectAtIndex:selectedRow]];
	NSString *tonePath = [[NSBundle mainBundle] pathForResource:toneName ofType:nil];
	
	NSLog(@"Tone Path: %@", tonePath);
	
	if(tonePath != nil)
	{
		AudioServicesDisposeSystemSoundID(self.toneSound);
		
		NSURL *toneURL = [NSURL fileURLWithPath:tonePath];
		AudioServicesCreateSystemSoundID((__bridge CFURLRef)toneURL, &_toneSound);
		AudioServicesPlaySystemSound(self.toneSound);
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
	return ([self tableView:tableView titleForHeaderInSection:section] == nil) ? 22.0 : 46.0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch(self.pickerType)
	{
		case 1:
			return @"REPEAT ALERT INCREMENTS";
			break;
		
		case 2:
		case 3:
		case 4:
		case 5:
		{
			// Get Subcategory from array
			if([self.subCategories count] > self.pickerType - 2)
			{
				NSString *subCategory = [self.subCategories objectAtIndex:self.pickerType - 2];
				
				// Singularize Subcategory
				if([[subCategory substringFromIndex:[subCategory length] - 1] isEqualToString:@"s"])
				{
					subCategory = [subCategory substringToIndex:[subCategory length] - 1];
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
	
	// Notification Tone Subcategory
	if(self.pickerType == 0 && [self.subCategories containsObject:optionText])
	{
		NSArray *notificationTonesArray;
		
		cell = [tableView dequeueReusableCellWithIdentifier:SubcategoryCellIdentifier forIndexPath:indexPath];
		
		// Set custom tag value to be used in prepareForSegue for determining which Notification Tones to display
		[cell setTag:[self.subCategories indexOfObject:optionText] + 2];
		
		switch(cell.tag)
		{
			case 2:
				notificationTonesArray = [[NSArray alloc] initWithObjects:NOTIFICATION_TONES_STAFF_FAVORITES, nil];
				break;
			
			case 3:
				notificationTonesArray = [[NSArray alloc] initWithObjects:NOTIFICATION_TONES_MYTELEMED, nil];
				break;
			
			case 4:
				notificationTonesArray = [[NSArray alloc] initWithObjects:NOTIFICATION_TONES_IOS7, nil];
				break;
			
			case 5:
				notificationTonesArray = [[NSArray alloc] initWithObjects:NOTIFICATION_TONES_CLASSIC_IOS, nil];
				break;
		}
		
		// Add checkmark and set Detail Text on selected subcategory option
		if([notificationTonesArray containsObject:self.selectedOption])
		{
			[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
			[cell.detailTextLabel setText:self.selectedOption];
			
			[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
	}
	// Notification Interval or standard Notification Tone
	else
	{
	    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	
		// Clear checkmark (as cell is reused, checkmarks will start to show up where they shouldn't)
		[cell setAccessoryType:UITableViewCellAccessoryNone];
		
		// Add checkmark to selected option
		if([optionText isEqualToString:self.selectedTempOption])
		{
			[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
			
			[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
	}
	
	// Set option text
	[cell.textLabel setText:optionText];
	
	// Remove selection style
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	
	// Fix iOS8 Issue that prevents detailText from appearing
	[cell layoutSubviews];
	   
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	// If showing Notification Intervals, make selection final
	if(self.pickerType == 1)
	{
		[self performSegueWithIdentifier:@"unwindToSettingsNotifications" sender:cell];
	}
	// If showing standard Notification Tones, add checkmark to selected option and play sound
	else if(cell.tag == 0)
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
	if(cell.tag > 0)
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
	// Notification Tone Subcategory selected
	if([segue.identifier isEqualToString:@"showSettingsNotificationsSubcategoryPicker"])
	{
		UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
		
		// Set new Picker Type
		[segue.destinationViewController setPickerType:cell.tag];
		
		// Set Selected Option on new View Controller
		[segue.destinationViewController setSelectedOption:self.selectedOption];
	}
	// Unwind Segue
	else
	{
		NSInteger selectedRow = [[self.tableView indexPathForSelectedRow] row];
		
		// Set Selected Option
		if([self.pickerOptions count] > selectedRow)
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
