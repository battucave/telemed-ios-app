//
//  MessageModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "Model.h"
#import "MessageProtocol.h"
#import "AccountModel.h"

// Define the number of items to load per page
extern int const MessagesPerPage;

@interface MessageModel : Model <MessageProtocol>

@property (weak) id delegate;

// Any additional properties added here must also be added to message protocol

@property (nonatomic) NSNumber *ID; // Deprecated in favor of message delivery id (they are identical)
@property (nonatomic) AccountModel *Account;
@property (nonatomic) NSString *FormattedMessageText;
@property (nonatomic) NSNumber *MessageDeliveryID;
@property (nonatomic) NSNumber *MessageID;
@property (nonatomic) NSString *PatientName;
@property (nonatomic) NSString *Priority;
@property (nonatomic) NSString *SenderContact;
@property (nonatomic) NSNumber *SenderID;
@property (nonatomic) NSString *SenderName;
@property (nonatomic) NSString *State; // Archived, Read, ReadAndArchived, Unread
@property (nonatomic) NSString *TimeReceived_LCL;
@property (nonatomic) NSString *TimeReceived_UTC;

@property (nonatomic) NSString *MessageType; // Active, Archived (this property not set by web service)

- (void)getActiveMessages:(NSInteger)page;
- (void)getArchivedMessages:(NSInteger)page forAccount:(NSNumber *)accountID startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
- (void)getMessageByDeliveryID:(NSNumber *)messageDeliveryID withCallback:(void (^)(BOOL success, MessageModel *message, NSError *error))callback;
- (void)modifyMessageState:(NSNumber *)messageDeliveryID state:(NSString *)state;
- (void)modifyMultipleMessagesState:(NSArray *)messages state:(NSString *)state;


@end


@protocol MessageDelegate <NSObject>

@required
- (void)updateMessages:(NSArray *)messages forPage:(NSInteger)page;

@optional
- (void)updateMessagesError:(NSError *)error;
- (void)modifyMessageStatePending:(NSString *)state;
- (void)modifyMessageStateSuccess:(NSString *)state;
- (void)modifyMessageStateError:(NSError *)error forState:(NSString *)state;
- (void)modifyMultipleMessagesStatePending:(NSString *)state;
- (void)modifyMultipleMessagesStateSuccess:(NSString *)state;
- (void)modifyMultipleMessagesStateError:(NSArray *)failedMessageIDs forState:(NSString *)state;

@end
