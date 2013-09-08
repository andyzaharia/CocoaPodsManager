//
//  PodManager.h
//  CocoaPodsManager
//
//  Created by Andy on 06.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppConstants.h"

@class PodSpecManager;

@protocol PodManagerDelegate <NSObject>

-(void) podManagerUpdateCompleted: (PodSpecManager *)sender;

@optional

-(void) podManager: (PodSpecManager *)sender isUpdatingWithProgress: (CGFloat) progress;
-(void) podManager: (PodSpecManager *)sender didFailedWithError: (NSError *) error;

@end

@interface PodSpecManager : NSObject

@property (nonatomic, assign) id <PodManagerDelegate> delegate;

+ (id)sharedPodSpecManager;

-(void) fetchPropertiesForPodSpec: (PodSpec *) pod
                           onDone: (OnDone) onDone
                        onFailure: (OnFailure) onFailure;


// Will update the properties only for the Pods that have the flag fetchedDetails set to NO
-(void) updateAllPodProperties;

-(void) cancelUpdate;

@end
