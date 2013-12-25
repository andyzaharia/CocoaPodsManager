//
//  CPDependency.h
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 12/25/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CPProject, PodSpec;

@interface CPDependency : NSManagedObject

@property (nonatomic, retain) NSString * commit;
@property (nonatomic, retain) NSString * customPodSpec;
@property (nonatomic, retain) NSString * gitSource;
@property (nonatomic, retain) NSNumber * head;
@property (nonatomic, retain) NSString * local;
@property (nonatomic, retain) NSString * versionOperator;
@property (nonatomic, retain) NSString * versionStr;
@property (nonatomic, retain) PodSpec *pod;
@property (nonatomic, retain) CPProject *project;

@end
