//
//  CPTarget.h
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 1/17/14.
//  Copyright (c) 2014 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CPDependency, CPProject;

@interface CPTarget : NSManagedObject

@property (nonatomic, retain) NSString * deploymentString;
@property (nonatomic, retain) NSNumber * inhibit_all_warnings;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * platformString;
@property (nonatomic, retain) NSString * xcodeproj;
@property (nonatomic, retain) NSOrderedSet *dependencies;
@property (nonatomic, retain) CPProject *project;
@end

@interface CPTarget (CoreDataGeneratedAccessors)

- (void)insertObject:(CPDependency *)value inDependenciesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromDependenciesAtIndex:(NSUInteger)idx;
- (void)insertDependencies:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeDependenciesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInDependenciesAtIndex:(NSUInteger)idx withObject:(CPDependency *)value;
- (void)replaceDependenciesAtIndexes:(NSIndexSet *)indexes withDependencies:(NSArray *)values;
- (void)addDependenciesObject:(CPDependency *)value;
- (void)removeDependenciesObject:(CPDependency *)value;
- (void)addDependencies:(NSOrderedSet *)values;
- (void)removeDependencies:(NSOrderedSet *)values;
@end
