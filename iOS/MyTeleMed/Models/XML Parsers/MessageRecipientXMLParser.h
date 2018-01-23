//
//  MessageRecipientXMLParser.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageRecipientXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) NSMutableArray *messageRecipients;

@end
