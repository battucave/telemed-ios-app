//
//  MessageEventCell.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/6/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageEventCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *labelType;
@property (weak, nonatomic) IBOutlet UILabel *labelDate;
@property (weak, nonatomic) IBOutlet UILabel *labelDetail;

@end
