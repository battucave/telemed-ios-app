//
//  SentMessageModel.h
//  TeleMed
//
//  Created by Shane Goodwin on 3/22/17.
//  Copyright (c) 2017 SolutionBuilt. All rights reserved.
//

#import "Model.h"
#import "MessageProtocol.h"
#import "AccountModel.h"

@interface SentMessageModel : Model <MessageProtocol>

@property (weak) id delegate;

// Any additional properties added here must also be added to MessageProtocol

@property (nonatomic) AccountModel *Account;
@property (nonatomic) NSString *FirstSent_LCL;
@property (nonatomic) NSString *FirstSent_UTC;
@property (nonatomic) NSString *FormattedMessageText;
@property (nonatomic) NSString *LastSent_LCL;
@property (nonatomic) NSString *LastSent_UTC;
@property (nonatomic) NSNumber *MessageID;
@property (nonatomic) NSString *PatientName;
@property (nonatomic) NSString *Priority;
@property (nonatomic) NSString *Recipients;
@property (nonatomic) NSString *SenderContact;
@property (nonatomic) NSNumber *SenderID;
@property (nonatomic) NSString *SenderName;

@property (nonatomic) NSString *MessageType; // Always Sent (this property not set by web services)

- (void)getSentMessages;
- (void)getSentMessageByID:(NSNumber *)messageID withCallback:(void (^)(BOOL success, SentMessageModel *message, NSError *error))callback;

@end


@protocol SentMessageDelegate <NSObject>

@required
- (void)updateSentMessages:(NSArray *)sentMessages;

@optional
- (void)updateSentMessagesError:(NSError *)error;

@end