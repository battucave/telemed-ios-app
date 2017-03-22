//
//  SentMessageModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 3/22/17.
//  Copyright (c) 2017 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@protocol SentMessageDelegate <NSObject>

@required
- (void)updateSentMessages:(NSMutableArray *)sentMessages;

@optional
- (void)updateSentMessagesError:(NSError *)error;

@end

@interface SentMessageModel : Model

@property (weak) id delegate;

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

- (void)getSentMessages;


@end
