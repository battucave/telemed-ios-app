//
//  PreferredAccountCell.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 8/11/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreferredAccountCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *accountName;
@property (weak, nonatomic) IBOutlet UILabel *accountPublicKey;

@end
