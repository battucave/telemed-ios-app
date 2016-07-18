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
- (void)updateChatMessages:(NSMutableArray *)chatMessages;
- (void)updateChatMessagesError:(NSError *)error;
- (void)deleteChatMessageSuccess;
- (void)deleteChatMessageError:(NSError *)error;
- (void)deleteMultipleChatMessagesSuccess;
- (void)deleteMultipleChatMessagesError:(NSArray *)failedChatMessageIDs;

@end

@interface ChatMessageModel : Model

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSString *Text;
@property (nonatomic) NSNumber *SenderID;
@property (nonatomic) NSString *SenderName;
@property (nonatomic) NSString *State;
@property (nonatomic) NSString *TimeReceived_LCL;
@property (nonatomic) NSString *TimeReceived_UTC;

- (void)getChatMessages;
- (void)getChatMessageByID:(NSNumber *)chatMessageID;
- (void)deleteChatMessage:(NSNumber *)chatMessageID;
- (void)deleteMultipleChatMessages:(NSArray *)chatMessages;


@end
