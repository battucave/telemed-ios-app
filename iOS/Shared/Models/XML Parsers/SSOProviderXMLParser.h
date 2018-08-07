//
//  SSOProviderXMLParser.h
//  TeleMed
//
//  Created by SolutionBuilt on 6/18/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SSOProviderModel.h"

@interface SSOProviderXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) SSOProviderModel *ssoProvider;

@end
