//
//  SettingsNotificationsPickerTableViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/11/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreTableViewController.h"

@interface SettingsNotificationsPickerTableViewController : CoreTableViewController

@property (nonatomic) NSInteger pickerType; // 0 = Subcategory Tone, 1 = Interval, 2 = Staff Favorite Tone, 3 = MyTeleMed Tone, 4 = Standard Tone, 5 = Classic Tone
@property (nonatomic) NSString *selectedOption;

@end
