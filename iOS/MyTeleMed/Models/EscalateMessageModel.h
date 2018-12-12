//
//  EscalateMessageModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 12/11/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "Model.h"
#import "MessageProtocol.h"

@interface EscalateMessageModel : Model

@property (weak) id delegate;

- (void)escalateMessage:(id <MessageProtocol>)message;

@end


@protocol EscalateMessageDelegate <NSObject>

@optional
- (void)escalateMessagePending;
- (void)escalateMessageSuccess;
- (void)escalateMessageError:(NSError *)error;

@end
