//
//  MessageEscalateViewController.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/20/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "CoreViewController.h"
#import "MessageProtocol.h"
#import "OnCallSlotModel.h"

@interface MessageEscalateViewController : CoreViewController

@property (nonatomic) id <MessageProtocol> message;
@property (nonatomic) NSArray *messageRecipients;
@property (nonatomic) OnCallSlotModel *selectedOnCallSlot;

@end
