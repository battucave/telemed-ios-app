//
//  RevealViewController.h
//  TeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CoreViewController.h"
#import "SWRevealViewController.h"

@interface RevealViewController : CoreViewController <SWRevealViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sideNavigationButton;

@end
