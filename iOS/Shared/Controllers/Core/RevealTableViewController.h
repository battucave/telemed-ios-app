//
//  RevealTableViewController.h
//  TeleMed
//
//  Created by SolutionBuilt on 11/9/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CoreTableViewController.h"
#import "SWRevealViewController.h"

@interface RevealTableViewController : CoreTableViewController <SWRevealViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *sideNavigationButton;

@end
