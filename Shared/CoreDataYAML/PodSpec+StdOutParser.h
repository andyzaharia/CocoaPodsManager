//
//  PodSpec+StdOutParser.h
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 2/28/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "PodSpec.h"

@interface PodSpec (StdOutParser)

-(NSMutableArray *) fetchPropertiesInContext: (NSManagedObjectContext *) context withVersion: (NSString *) version;


-(void) fetchPropertiesInContext: (NSManagedObjectContext *) context;

// Launched from main thread only
-(void) fetchPropertiesWithVersion: (NSString *) version
                            onDone: (OnDone) onDone;

@end
