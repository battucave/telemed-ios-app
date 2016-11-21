//
//  NewChatMessageModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 9/29/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@protocol NewChatMessageDelegate <NSObject>

@optional
- (void)sendChatMessagePending;
- (void)sendChatMessageSuccess;
- (void)sendChatMessageError:(NSError *)error;

@end

@interface NewChatMessageModel : Model

@property (weak) id delegate;
@property (nonatomic) BOOL Success;
@property (nonatomic) NSString *Message;

- (void)sendNewChatMessage:(NSString *)message chatParticipantIDs:(NSArray *)chatParticipantIDs isGroupChat:(BOOL)isGroupChat;

@end
