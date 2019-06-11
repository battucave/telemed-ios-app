//
//  MessageEventModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "Model.h"

@interface MessageEventModel : Model

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSString *Detail;
@property (nonatomic) NSString *EnteredBy;
@property (nonatomic) NSNumber *EnteredByID;
@property (nonatomic) NSNumber *MessageID;
@property (nonatomic) NSString *Type;
@property (nonatomic) NSString *Time_LCL;
@property (nonatomic) NSString *Time_UTC;

- (void)getMessageEventsForMessageDeliveryID:(NSNumber *)messageDeliveryID withCallback:(void (^)(BOOL success, NSArray *messageEvents, NSError *error))callback;
- (void)getMessageEventsForMessageID:(NSNumber *)messageID withCallback:(void (^)(BOOL success, NSArray *messageEvents, NSError *error))callback;

@end
