//
//  AccountCell.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 8/11/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AccountCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *labelAccountNumber;
@property (weak, nonatomic) IBOutlet UILabel *labelAuthorizationPending;
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UILabel *labelPublicKey;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintAuthorizationPendingHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintAuthorizationPendingTopSpace;

@end
