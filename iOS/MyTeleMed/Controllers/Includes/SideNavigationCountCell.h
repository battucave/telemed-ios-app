//
//  SideNavigationCountCell.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/4/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SideNavigationCountCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *labelCounts;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintCountsWidth;

@end
