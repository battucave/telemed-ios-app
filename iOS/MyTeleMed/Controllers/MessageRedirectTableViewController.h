//
//  MessageRedirectTableViewController.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/21/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "CoreTableViewController.h"
#import "MessageProtocol.h"
#import "MessageRecipientModel.h"

@interface MessageRedirectTableViewController : CoreTableViewController

@property (nonatomic) id <MessageProtocol> message;

@property (nonatomic) NSArray *messageRecipients;
@property (nonatomic) NSArray *onCallSlots;

@end
