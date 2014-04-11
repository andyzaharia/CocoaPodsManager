//
//  PodSpec.h
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 1/17/14.
//  Copyright (c) 2014 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CPDependency, CPProject;

@interface PodSpec : NSManagedObject

@property (nonatomic, retain) NSString * childDescription;
@property (nonatomic, retain) NSString * childHomePage;
@property (nonatomic, retain) NSNumber * childLoading;
@property (nonatomic, retain) NSString * childSourcePage;
@property (nonatomic, retain) NSString * childVersions;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSNumber * fetchedDetails;
@property (nonatomic, retain) NSString * homePage;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) NSString * versions;
@property (nonatomic, retain) NSSet *dependencies;
@property (nonatomic, retain) NSSet *projects;
@end

@interface PodSpec (CoreDataGeneratedAccessors)

- (void)addDependenciesObject:(CPDependency *)value;
- (void)removeDependenciesObject:(CPDependency *)value;
- (void)addDependencies:(NSSet *)values;
- (void)removeDependencies:(NSSet *)values;

- (void)addProjectsObject:(CPProject *)value;
- (void)removeProjectsObject:(CPProject *)value;
- (void)addProjects:(NSSet *)values;
- (void)removeProjects:(NSSet *)values;

@end
