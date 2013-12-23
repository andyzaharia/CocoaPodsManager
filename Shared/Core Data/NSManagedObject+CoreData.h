//
//  NSManagedObject+CoreData.h
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 9/17/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (CoreData)

+ (id) findFirstWithPredicate: (NSPredicate *) predicate;
+ (id) findFirstWithPredicate: (NSPredicate *) predicate inContext: (NSManagedObjectContext *) context;

+ (id) findFirstByAttribute:(NSString *) attribute withValue: (id) value;
+ (id) findFirstByAttribute:(NSString *) attribute withValue: (id) value inContext: (NSManagedObjectContext *) context;

+ (NSArray *) findAll;
+ (NSArray *) findAllInContext: (NSManagedObjectContext *) context;; 

+ (NSArray *) findAllWithPredicate: (NSPredicate *) predicate;
+ (NSArray *) findAllWithPredicate: (NSPredicate *) predicate inContext: (NSManagedObjectContext *) context;

+ (NSArray *) findAllSortedBy:(NSString *) param ascending: (BOOL) ascending;
+ (NSArray *) findAllSortedBy:(NSString *) param ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

+ (id) findByAttribute:(NSString *) attribute withValue:(id) value;

+ (void) deleteAllMatchingPredicate: (NSPredicate *) predicate;
+ (void) deleteAllMatchingPredicate: (NSPredicate *) predicate inContext: (NSManagedObjectContext *) context;

+ (id) createEntityInContext: (NSManagedObjectContext *) context;
+ (id) createEntity;

+(NSUInteger) countOfEntitiesWithPredicate: (NSPredicate *) predicate;

@end
