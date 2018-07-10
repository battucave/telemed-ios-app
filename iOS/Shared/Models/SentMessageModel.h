//
//  SentMessageModel.h
//  TeleMed
//
//  Created by Shane Goodwin on 3/22/17.
//  Copyright (c) 2017 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"
#import "AccountModel.h"
#import "MessageProtocol.h"

@protocol SentMessageDelegate <NSObject>

@required
- (void)updateSentMessages:(NSMutableArray *)sentMessages;

@optional
- (void)updateSentMessagesError:(NSError *)error;

@end

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

@property (nonatomic) int messageType; // Always 2 (this property not set by web services)

- (void)getSentMessages;


@end
