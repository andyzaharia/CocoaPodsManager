//
//  Dependency.h
//  CocoaPodsManager
//
//  Created by Andy on 11.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "PodSpec+Misc.h"

@interface Dependency : NSObject

@property (nonatomic, strong)   PodSpec       *pod;
@property (nonatomic, copy)     NSString      *versionOperator;
@property (nonatomic, copy)     NSString      *versionStr;
@property (nonatomic, copy)     NSString      *gitSource;
@property (nonatomic, copy)     NSString      *local;
@property (nonatomic, copy)     NSString      *customPodSpec;
@property (nonatomic, copy)     NSString      *commit;
@property (nonatomic)           BOOL           head;

+(Dependency *) dependencyWithPod: (PodSpec *) pod;

-(NSString *) podLineRepresentation;

@end
