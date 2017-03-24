//
//  MessageStub.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 3/23/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

@interface MessageStub : NSObject

// Properties listed here exist in either MessageModel and/or SentMessageMode

@property (nonatomic) NSString *FirstSent_LCL;
@property (nonatomic) NSString *FirstSent_UTC;
@property (nonatomic) NSString *FormattedMessageText;
@property (nonatomic) NSString *LastSent_LCL;
@property (nonatomic) NSString *LastSent_UTC;
@property (nonatomic) NSNumber *MessageDeliveryID;
@property (nonatomic) NSNumber *MessageID;
@property (nonatomic) NSString *PatientName;
@property (nonatomic) NSString *Priority;
@property (nonatomic) NSString *Recipients;
@property (nonatomic) NSString *SenderContact;
@property (nonatomic) NSNumber *SenderID;
@property (nonatomic) NSString *SenderName;
@property (nonatomic) NSString *State;
@property (nonatomic) NSString *TimeReceived_LCL;
@property (nonatomic) NSString *TimeReceived_UTC;

@property (nonatomic) int messageType; // 0 = Active, 1 = Archived, 2 = Archived (This property not set by web service)

@end
