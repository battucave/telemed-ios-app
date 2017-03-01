//
//  ChatMessageCell.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 6/28/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatMessageCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *viewUnopened;
@property (weak, nonatomic) IBOutlet UILabel *labelChatParticipants;
@property (weak, nonatomic) IBOutlet UILabel *labelDate;
@property (weak, nonatomic) IBOutlet UILabel *labelTime;
@property (weak, nonatomic) IBOutlet UILabel *labelMessage;

@end
