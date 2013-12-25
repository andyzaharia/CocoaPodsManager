//
//  PodManager.h
//  CocoaPodsManager
//
//  Created by Andy on 06.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppConstants.h"
#import "PodSpec+Misc.h"

@class PodRepositoryManager;

@protocol PodManagerDelegate <NSObject>

-(void) podManagerUpdateCompleted: (PodRepositoryManager *)sender;

@optional

-(void) podManager: (PodRepositoryManager *)sender isUpdatingWithProgress: (CGFloat) progress;
-(void) podManager: (PodRepositoryManager *)sender didFailedWithError: (NSError *) error;

@end

@interface PodRepositoryManager : NSObject

@property (nonatomic, assign) id <PodManagerDelegate> delegate;

+ (id)sharedPodSpecManager;

-(void) fetchPropertiesForPodSpec: (PodSpec *) pod
                           onDone: (OnDone) onDone
                        onFailure: (OnFailure) onFailure;


-(void) loadPodSpecRespository: (OnDone) onDone;

// Will update the properties only for the Pods that have the flag fetchedDetails set to NO
-(void) updateAllPodProperties: (OnDone) onDone;

-(NSArray *) getPodNameListFromMasterDirectory;

-(void) cancelUpdate;

@end
