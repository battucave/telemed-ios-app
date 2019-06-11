//
//  NewChatMessageModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 9/29/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "Model.h"

@interface NewChatMessageModel : Model

@property (weak) id delegate;

//- (void)sendNewChatMessage:(NSString *)message chatParticipantIDs:(NSArray *)chatParticipantIDs isGroupChat:(BOOL)isGroupChat;
- (void)sendNewChatMessage:(NSString *)message chatParticipantIDs:(NSArray *)chatParticipantIDs isGroupChat:(BOOL)isGroupChat withPendingID:(NSNumber *)pendingID;

@end


@protocol NewChatMessageDelegate <NSObject>

@optional
- (void)sendChatMessagePending:(NSString *)message withPendingID:(NSNumber *)pendingID;
- (void)sendChatMessageSuccess:(NSString *)message withPendingID:(NSNumber *)pendingID;
- (void)sendChatMessageError:(NSError *)error withPendingID:(NSNumber *)pendingID;

@end
