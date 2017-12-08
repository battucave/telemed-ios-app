//
//  SentMessageXMLParser.h
//  TeleMed
//
//  Created by Shane Goodwin on 3/22/17.
//  Copyright (c) 2017 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SentMessageModel.h"

@interface SentMessageXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) SentMessageModel *sentMessage;
@property (nonatomic) NSMutableArray *sentMessages;
@property (nonatomic) NSMutableString *currentElementValue;

@end
