//
//  OnCallScheduleViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "RevealViewController.h"

@interface OnCallScheduleViewController : RevealViewController  <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) int defaultSegmentControlIndex;

@end
