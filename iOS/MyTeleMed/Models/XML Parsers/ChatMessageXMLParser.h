//
//  ChatMessageXMLParser.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/30/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatMessageModel.h"

@interface ChatMessageXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) ChatMessageModel *chatMessage;
@property (nonatomic) NSMutableArray *chatMessages;
@property (nonatomic) NSMutableString *currentElementValue;

@end
