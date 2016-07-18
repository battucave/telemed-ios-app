//
//  OnCallSummaryCell.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/6/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OnCallSummaryCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *viewDateContainer;
@property (weak, nonatomic) IBOutlet UILabel *labelDay;
@property (weak, nonatomic) IBOutlet UILabel *labelDate;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelSlotNames;
@property (weak, nonatomic) IBOutlet UILabel *labelStart;
@property (weak, nonatomic) IBOutlet UILabel *labelEnd;
@property (weak, nonatomic) IBOutlet UILabel *labelStartTime;
@property (weak, nonatomic) IBOutlet UILabel *labelStopTime;
@property (weak, nonatomic) IBOutlet UIView *viewSeparator;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintLabelTitleHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintLabelSlotNamesHeight;

@end
