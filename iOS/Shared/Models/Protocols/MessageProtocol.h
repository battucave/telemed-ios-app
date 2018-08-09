//
//  MessageProtocol.h
//  TeleMed
//
//  Created by Shane Goodwin on 11/21/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AccountModel.h"

@protocol MessageProtocol <NSObject>

@property (nonatomic) AccountModel *Account;
@property (nonatomic) NSString *FormattedMessageText;
@property (nonatomic) NSNumber *MessageID;
@property (nonatomic) NSString *PatientName;
@property (nonatomic) NSString *Priority;
@property (nonatomic) NSString *SenderContact;
@property (nonatomic) NSNumber *SenderID;
@property (nonatomic) NSString *SenderName;

@property (nonatomic) NSString *MessageType; // Active, Archived, Sent (this property not set by web service)

// MessageModel only
@optional
@property (nonatomic) NSNumber *MessageDeliveryID;
@property (nonatomic) NSString *State; // Archived, Read, ReadAndArchived, Unread
@property (nonatomic) NSString *TimeReceived_LCL;
@property (nonatomic) NSString *TimeReceived_UTC;

// SentMessageModel only
@optional
@property (nonatomic) NSString *FirstSent_LCL;
@property (nonatomic) NSString *FirstSent_UTC;
@property (nonatomic) NSString *LastSent_LCL;
@property (nonatomic) NSString *LastSent_UTC;
@property (nonatomic) NSString *Recipients;

@end
