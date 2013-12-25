//
//  Pod+Misc.h
//  CocoaPodsManager
//
//  Created by Andy on 07.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "PodSpec.h"
#import "PodSpec+StdOutParser.h"

@interface PodSpec (Misc) <NSPasteboardWriting, NSPasteboardReading>

-(NSString *) lastVersion;

-(NSMutableArray *) versionsArray;
-(NSMutableArray *) lastVersionYAML;

@end
