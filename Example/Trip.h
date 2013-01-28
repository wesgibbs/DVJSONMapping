//
//  Trip.h
//  Example
//
//  Created by Peyman Oreizy on 1/27/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Place;

@interface Trip : NSManagedObject

@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * isDraft;
@property (nonatomic, retain) NSDate * lastModified;
@property (nonatomic, retain) NSString * description_;
@property (nonatomic, retain) NSSet *places;
@end

@interface Trip (CoreDataGeneratedAccessors)

- (void)addPlacesObject:(Place *)value;
- (void)removePlacesObject:(Place *)value;
- (void)addPlaces:(NSSet *)values;
- (void)removePlaces:(NSSet *)values;

@end
