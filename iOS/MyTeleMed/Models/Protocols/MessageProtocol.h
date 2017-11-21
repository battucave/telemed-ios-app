//
//  MessageProtocol.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/21/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MessageProtocol <NSObject>

@property (nonatomic) NSString *FormattedMessageText;
@property (nonatomic) NSNumber *MessageDeliveryID;
@property (nonatomic) NSNumber *MessageID;
@property (nonatomic) NSString *PatientName;
@property (nonatomic) NSString *Priority;
@property (nonatomic) NSString *SenderContact;
@property (nonatomic) NSNumber *SenderID;
@property (nonatomic) NSString *SenderName;

@optional
// SentMessageModel only
@property (nonatomic) NSString *FirstSent_LCL;
@property (nonatomic) NSString *FirstSent_UTC;
@property (nonatomic) NSString *LastSent_LCL;
@property (nonatomic) NSString *LastSent_UTC;
@property (nonatomic) NSString *Recipients;

// MessageModel only
@property (nonatomic) NSString *State;
@property (nonatomic) NSString *TimeReceived_LCL;
@property (nonatomic) NSString *TimeReceived_UTC;

@end
