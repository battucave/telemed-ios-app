//
//  ArchivesViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RevealViewController.h"

@interface ArchivesViewController : RevealViewController

- (IBAction)unwindSetArchiveFilter:(UIStoryboardSegue *)segue;

@end
