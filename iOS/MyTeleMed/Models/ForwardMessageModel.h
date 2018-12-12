//
//  ForwardMessageModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Model.h"
#import "MessageProtocol.h"

@interface ForwardMessageModel : Model

@property (weak) id delegate;

- (void)forwardMessage:(id <MessageProtocol>)message messageRecipientIDs:(NSArray *)messageRecipientIDs withComment:(NSString *)comment;

@end


@protocol ForwardMessageDelegate <NSObject>

@optional
- (void)forwardMessagePending;
- (void)forwardMessageSuccess;
- (void)forwardMessageError:(NSError *)error;

@end
