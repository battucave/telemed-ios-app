//
//  ChatParticipantXMLParser.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/30/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatParticipantModel.h"

@interface ChatParticipantXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) ChatParticipantModel *chatParticipant;
@property (nonatomic) NSMutableArray *chatParticipants;
@property (nonatomic) NSMutableString *currentElementValue;

@end
