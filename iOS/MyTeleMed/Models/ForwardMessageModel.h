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
@property (nonatomic) BOOL Success;
@property (nonatomic) NSString *Message;

- (void)forwardMessage:(id <MessageProtocol>)message messageRecipientIDs:(NSArray *)messageRecipientIDs withComment:(NSString *)comment;

@end


@protocol ForwardMessageDelegate <NSObject>

@optional
- (void)sendMessagePending;
- (void)sendMessageSuccess;
- (void)sendMessageError:(NSError *)error;

@end
