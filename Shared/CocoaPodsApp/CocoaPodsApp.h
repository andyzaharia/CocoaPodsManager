//
//  CocoaPodsApp.h
//  CocoaPodsManager
//
//  Created by Admin on 17.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppConstants.h"

enum CocoaPodsAppError {
        CocoaPodsAppExecutableNotFound = -1,
        CocoaPodsAppNone = 0
};


@class CPProject;

typedef void (^PodExecOnSucceedBlock) (NSString *);
typedef void (^PodExecOnFailBlock) (NSError *);

@interface CocoaPodsApp : NSObject

-(BOOL)         isInstalled;
-(NSString *)   cocoaPodVersion;

-(void) getOnlineVersionFromGithub: (OnSuccess) onSuccess
                           onError: (OnError) onError;

-(void) installGem: (OnSuccess) onSuccess
           onError: (OnError) onError;

#pragma mark - Class Methods

+ (id)sharedCocoaPodsApp;

+(int) executeWithArguments: (NSArray *) items
       withCurrentDirectory: (NSString *) currentDirectory
              responseBlock: (PodExecOnSucceedBlock) responseBlock
             andOnFailBlock:(PodExecOnFailBlock) failBlock;

// Execute with arguments in the current folder
+(int) executeWithArguments: (NSArray *) items
           andResponseBlock: (PodExecOnSucceedBlock) responseBlock;

+(int) executeWithArguments: (NSArray *) items
              responseBlock: (PodExecOnSucceedBlock) responseBlock
                  failBlock: (PodExecOnFailBlock) failBlock;



+(void) updateProject: (CPProject *) project
          withOptions: (NSArray *) options
            onSuccess: (PodExecOnSucceedBlock) onSuccess
              onError: (PodExecOnFailBlock) errorBlock;

+(void) installCocoaPodsInProject: (CPProject *) project
                        onSuccess: (PodExecOnSucceedBlock) onSuccess
                      withOnError: (PodExecOnFailBlock) errorBlock;

@end
