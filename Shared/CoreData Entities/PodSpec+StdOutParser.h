//
//  PodSpec+StdOutParser.h
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 2/28/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "PodSpec.h"

@interface PodSpec (StdOutParser)

-(void) applyProperties: (NSDictionary *) properties;

-(NSMutableArray *) fetchYamlPropertiesWithVersion: (NSString *) version;

-(void) fetchPropertiesInContext: (NSManagedObjectContext *) context;

// Launched from main thread only
-(void) fetchPropertiesAsyncWithVersion: (NSString *) version
                                 onDone: (OnDoneEx) onDone
                              onFailure: (OnError) onFailure;

@end
