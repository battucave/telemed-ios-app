//
//  MessageXMLParser.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MessageModel.h"

@interface MessageXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) MessageModel *message;
@property (nonatomic) NSMutableArray *messages;
@property (nonatomic) NSMutableString *currentElementValue;

@end
