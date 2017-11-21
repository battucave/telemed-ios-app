//
//  MessageModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"
#import "MessageProtocol.h"

@protocol MessageDelegate <NSObject>

@required
- (void)updateMessages:(NSMutableArray *)messages;

@optional
- (void)updateMessagesError:(NSError *)error;
- (void)modifyMessageStatePending:(NSString *)state;
- (void)modifyMessageStateSuccess:(NSString *)state;
- (void)modifyMessageStateError:(NSError *)error forState:(NSString *)state;
- (void)modifyMultipleMessagesStatePending:(NSString *)state;
- (void)modifyMultipleMessagesStateSuccess:(NSString *)state;
- (void)modifyMultipleMessagesStateError:(NSArray *)failedMessageIDs forState:(NSString *)state;

@end

@interface MessageModel : Model <MessageProtocol>

@property (weak) id delegate;

// Any additional properties added here must also be added to MessageStub

@property (nonatomic) NSNumber *ID; // Deprecated in favor of MessageDeliveryID (they are identical)
@property (nonatomic) NSString *FormattedMessageText;
@property (nonatomic) NSNumber *MessageDeliveryID;
@property (nonatomic) NSNumber *MessageID;
@property (nonatomic) NSString *PatientName;
@property (nonatomic) NSString *Priority;
@property (nonatomic) NSString *SenderContact;
@property (nonatomic) NSNumber *SenderID;
@property (nonatomic) NSString *SenderName;
@property (nonatomic) NSString *State;
@property (nonatomic) NSString *TimeReceived_LCL;
@property (nonatomic) NSString *TimeReceived_UTC;

@property (nonatomic) int messageType; // 0 = Active, 1 = Archived (This property not set by web service)

- (void)getActiveMessages;
- (void)getArchivedMessages:(NSNumber *)accountID startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
//- (void)getMessageByID:(NSNumber *)messageID;
- (void)modifyMessageState:(NSNumber *)messageID state:(NSString *)state;
- (void)modifyMultipleMessagesState:(NSArray *)messages state:(NSString *)state;


@end
