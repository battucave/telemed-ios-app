//
//  MessagesViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "RevealViewController.h"

@interface MessagesViewController : RevealViewController

- (void)setSelectedMessages:(NSArray *)theSelectedMessages;
- (void)modifyMultipleMessagesStateSuccess:(NSString *)state;
- (void)modifyMultipleMessagesStateError:(NSArray *)failedMessageIDs forState:(NSString *)state;

@end
