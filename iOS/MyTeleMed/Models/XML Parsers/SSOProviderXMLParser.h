//
//  SSOProviderXMLParser.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 6/18/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSOProviderModel.h"

@interface SSOProviderXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) SSOProviderModel *ssoProvider;

@end
