//
//  PodTaskOperation.h
//  CocoaPodsManager
//
//  Created by Andy on 11.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppConstants.h"

@interface PodSpecTaskOperation : NSOperation

// If this is not nil, then the operation will just fetch the details for these pods
@property (nonatomic, copy)     NSArray                     *podNameList;

@property (copy)                OnDone                      onDoneBlock;
@property (copy)                OnFailure                   onFailureBlock;
@property (copy)                OnProgress                  onProgressBlock;

-(id) initWithPodNames: (NSArray *) podNames;

+(void) fetchPodSpecWithName: (NSString *) podName onDone: (OnDone) onDone;


@end
