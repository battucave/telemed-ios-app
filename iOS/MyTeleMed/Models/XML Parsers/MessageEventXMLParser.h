//
//  MessageEventXMLParser.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MessageEventModel.h"

@interface MessageEventXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) MessageEventModel *messageEvent;
@property (nonatomic) NSMutableArray *messageEvents;
@property (nonatomic) NSMutableString *currentElementValue;

@end
