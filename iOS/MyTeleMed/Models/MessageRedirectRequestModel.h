//
//  MessageRedirectRequestModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 12/11/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "Model.h"
#import "MessageProtocol.h"
#import "MessageRecipientModel.h"
#import "OnCallSlotModel.h"

@interface MessageRedirectRequestModel : Model

@property (weak) id delegate;

- (void)escalateMessage:(id <MessageProtocol>)message;
- (void)escalateMessage:(id <MessageProtocol>)message withMessageRecipient:(MessageRecipientModel *)messageRecipient;
- (void)redirectMessage:(id <MessageProtocol>)message messageRecipient:(MessageRecipientModel *)messageRecipient onCallSlot:(OnCallSlotModel *)onCallSlot;

@end


@protocol MessageRedirectRequestDelegate <NSObject>

@optional
- (void)redirectMessagePending;
- (void)redirectMessageSuccess;
- (void)redirectMessageError:(NSError *)error;

@end
