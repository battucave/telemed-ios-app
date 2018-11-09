//
//  ChatMessageModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/30/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Model.h"

@protocol ChatMessageDelegate <NSObject>

@required
- (void)updateChatMessages:(NSArray *)chatMessages;

@optional
- (void)updateChatMessagesError:(NSError *)error;
- (void)deleteChatMessagePending;
- (void)deleteChatMessageSuccess;
- (void)deleteChatMessageError:(NSError *)error;
- (void)deleteMultipleChatMessagesPending;
- (void)deleteMultipleChatMessagesSuccess;
- (void)deleteMultipleChatMessagesError:(NSArray *)failedChatMessages;

@end

@interface ChatMessageModel : Model

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSNumber *SenderID;
@property (nonatomic) NSString *Text;
@property (nonatomic) NSString *TimeSent_LCL;
@property (nonatomic) NSString *TimeSent_UTC;
@property (nonatomic) BOOL Unopened;

@property (nonatomic) NSArray *ChatParticipants;

- (void)getChatMessages;
- (void)getChatMessagesByID:(NSNumber *)chatMessageID;
- (void)getChatMessagesByID:(NSNumber *)chatMessageID withCallback:(void (^)(BOOL success, NSArray *chatMessages, NSError *error))callback;
- (void)deleteChatMessage:(NSNumber *)chatMessageID;
- (void)deleteMultipleChatMessages:(NSArray *)chatMessages;


@end
