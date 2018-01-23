//
//  SentMessageXMLParser.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 3/22/17.
//  Copyright (c) 2017 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SentMessageXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) NSMutableArray *sentMessages;

@end
