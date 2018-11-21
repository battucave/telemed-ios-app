//
//  MessageRedirectInfoModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/09/18.
//  Copyright (c) 2018 SolutionBuilt. All rights reserved.
//

#import "MessageRedirectInfoModel.h"
#import "OnCallSlotModel.h"
#import "MessageRedirectInfoXMLParser.h"

#import "MessageRecipientModel.h"
#import "OnCallSlotModel.h"

@implementation MessageRedirectInfoModel

- (void)getMessageRedirectInfoForMessageDeliveryID:(NSNumber *)messageDeliveryID
{
	[self getMessageRedirectInfoForMessageDeliveryID:messageDeliveryID withCallback:nil];
}

- (void)getMessageRedirectInfoForMessageDeliveryID:(NSNumber *)messageDeliveryID withCallback:(void (^)(BOOL success, MessageRedirectInfoModel *messageRedirectInfo, NSError *error))callback
{
	NSDictionary *parameters = @{
		@"deliveryId"	: messageDeliveryID
	};
	
	[self.operationManager GET:@"MsgRedirectInfo" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		
		// TESTING ONLY
		#ifdef DEBUG
			NSData *xmlData = [@"<MessageRedirectionInfo xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/MyTmd.Models\"><DeliveryID>5891582767355174</DeliveryID><EscalationSlot><CurrentOncall>Jason D Hutchison</CurrentOncall><Description>OnCall Description</Description><Header>OnCall Header</Header><ID>6517</ID><Name>OnCall Name</Name><IsEscalationSlot>true</IsEscalationSlot><SelectRecipient>false</SelectRecipient></EscalationSlot><ForwardRecipients><MsgRecip><ID>604276</ID><Name>Anthony L, Text (EMAIL ONLY)</Name><Type></Type></MsgRecip><MsgRecip><ID>1109552</ID><Name>Demos, Sales</Name><Type></Type></MsgRecip><MsgRecip><ID>1099635</ID><Name>Dental, Aspen</Name><Type></Type></MsgRecip><MsgRecip><ID>1335606</ID><Name>MD, -Matt</Name><Type></Type></MsgRecip><MsgRecip><ID>13788867</ID><Name>O'Houlihan, Tyler \"Patches\"</Name><Type></Type></MsgRecip><MsgRecip><ID>829772</ID><Name>Rogers, Matt</Name><Type></Type></MsgRecip><MsgRecip><ID>829771</ID><Name>Two, Dr (EMAIL ONLY)</Name><Type></Type></MsgRecip><MsgRecip><ID>5085344404480861</ID><Name>Wood, Michelle</Name><Type></Type></MsgRecip><MsgRecip><ID>676469</ID><Name>Yeary, Stephanie (EMAIL ONLY)</Name><Type></Type></MsgRecip></ForwardRecipients><RedirectRecipients><MsgRecip><ID>310619</ID><Name>Amerson (Demo), Karen</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>604276</ID><Name>Anthony L, Text</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>604277</ID><Name>Anthony, Patch</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310612</ID><Name>Armentrout (Demo), Sally</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310609</ID><Name>Auld (Demo), Susie</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310614</ID><Name>Barr (Demo), Veronica</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310620</ID><Name>Barros (Demo), Bonnie</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>933978</ID><Name>Black, Tony</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310622</ID><Name>Blackston (Demo), Lewis</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310611</ID><Name>Brokaw (Demo), Brian</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310625</ID><Name>Bunker (Demo), Roxanne</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>606876</ID><Name>Cash, Bo</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>1109552</ID><Name>Demos, Sales</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>1099635</ID><Name>Dental, Aspen</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310621</ID><Name>Fairfield (Demo), Brent</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310617</ID><Name>Foote (Demo), Deanna</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310623</ID><Name>Hallmark (Demo), Glenn</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310626</ID><Name>Hedges (Demo), Christina</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310615</ID><Name>Hockenberry (Demo), John</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310613</ID><Name>Holm (Demo), Stephen</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310618</ID><Name>Kahle (Demo), Kenneth</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310627</ID><Name>Latham (Demo), Caroline</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>250802</ID><Name>Main Office</Name><Type>Station</Type></MsgRecip><MsgRecip><ID>1335606</ID><Name>MD, -Matt</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>606878</ID><Name>Nickerson, Lewis</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>13788867</ID><Name>O'Houlihan, Tyler \"Patches\"</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>889826</ID><Name>One, Dr </Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310610</ID><Name>Orellana (Demo), Phillip</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310616</ID><Name>Price (Demo), Dennis</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>829772</ID><Name>Rogers, Matt</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>250805</ID><Name>Satellite Office</Name><Type>Station</Type></MsgRecip><MsgRecip><ID>310608</ID><Name>Smyth (Demo), John</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>310624</ID><Name>Sumpter (Demo), Adam</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>752975</ID><Name>Test Paging Group</Name><Type>Station</Type></MsgRecip><MsgRecip><ID>889827</ID><Name>Three, Dr</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>829771</ID><Name>Two, Dr</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>84118</ID><Name>Wells, Abe</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>5085344404480861</ID><Name>Wood, Michelle</Name><Type>Provider</Type></MsgRecip><MsgRecip><ID>676469</ID><Name>Yeary, Stephanie</Name><Type>Provider</Type></MsgRecip></RedirectRecipients><RedirectionSlots><OnCallSlot><CurrentOncall>Selves O/C</CurrentOncall><Description>Backup</Description><Header>Backup</Header><ID>6518</ID><Name>Backup</Name><IsEscalationSlot>false</IsEscalationSlot><SelectRecipient>false</SelectRecipient></OnCallSlot><OnCallSlot><CurrentOncall>Jason D Hutchison</CurrentOncall><Description>OnCall</Description><Header>OnCall</Header><ID>6517</ID><Name>OnCall</Name><IsEscalationSlot>true</IsEscalationSlot><SelectRecipient>false</SelectRecipient></OnCallSlot><OnCallSlot><CurrentOncall>Goto Slot: OnCall</CurrentOncall><Description>Redirect Test</Description><Header>REDIR TEST</Header><ID>5773836252353207</ID><Name>Redirect Test</Name><IsEscalationSlot>false</IsEscalationSlot><SelectRecipient>false</SelectRecipient></OnCallSlot><OnCallSlot><CurrentOncall>Hutchison Family Practice Postable Group</CurrentOncall><Description>Postable Group Test</Description><Header>PG TEST</Header><ID>5773836252353121</ID><Name>Postable Group Test</Name><IsEscalationSlot>false</IsEscalationSlot><SelectRecipient>false</SelectRecipient></OnCallSlot><OnCallSlot><CurrentOncall>Hutchison Family Practice Rotation Group</CurrentOncall><Description>Rotation Group Test</Description><Header>RG TEST</Header><ID>5773836252353123</ID><Name>Rotation Group Test</Name><IsEscalationSlot>false</IsEscalationSlot><SelectRecipient>false</SelectRecipient></OnCallSlot><OnCallSlot><CurrentOncall>Unknown</CurrentOncall><Description>Pick Your Own</Description><Header>Self On-Call</Header><ID>10101010</ID><Name>Self On-Call</Name><IsEscalationSlot>false</IsEscalationSlot><SelectRecipient>true</SelectRecipient></OnCallSlot></RedirectionSlots></MessageRedirectionInfo>" dataUsingEncoding:NSUTF8StringEncoding];
			xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
		#endif
		// END TESTING ONLY
		
		MessageRedirectInfoXMLParser *parser = [[MessageRedirectInfoXMLParser alloc] init];
		
		[parser setMessageRedirectInfo:self];
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			// Handle success via callback
			callback(YES, self, nil);
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Message Redirect Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Message Redirect information.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via callback
			callback(NO, nil, error);
	
			NSLog(@"MessageRedirectInfoModel Error: %@", error);
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageRedirectInfoModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Message Redirect information." andTitle:@"Message Redirect Error"];
		
		// Handle error via callback
		callback(NO, nil, error);
	}];
}

@end
