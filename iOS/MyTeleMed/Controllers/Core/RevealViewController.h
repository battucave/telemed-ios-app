//
//  RevealViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreViewController.h"
#import "SWRevealViewController.h"

@interface RevealViewController : CoreViewController <SWRevealViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *sideNavigationButton;

@end
