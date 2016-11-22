//
//  ChatMessageXMLParser.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/30/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatMessageModel.h"
#import "ChatParticipantModel.h"

@interface ChatMessageXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) ChatMessageModel *chatMessage;
@property (nonatomic) ChatParticipantModel *chatParticipant;
@property (nonatomic) NSMutableArray *chatMessages;
@property (nonatomic) NSMutableArray *chatParticipants;
@property (nonatomic) NSMutableString *currentElementValue;

@end
