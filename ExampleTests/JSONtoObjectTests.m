//
//  Created by Peyman Oreizy on 1/1/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#import <DVCoreDataFinders/DVCoreDataFinders.h>
#import "JSONtoObjectTests.h"

#import "DVAppDelegate.h"
#import "DVJSONMapping.h"
#import "JSONData.h"
#import "MappingDelegate.h"
#import "Place.h"
#import "Trip.h"


@implementation JSONtoObjectTests
{
  NSManagedObjectContext *context;
}

#pragma mark - Lifecycle

- (void)setUp
{
  [super setUp];

  // Set-up code here.
  DVAppDelegate *appDelegate = (DVAppDelegate *)[UIApplication sharedApplication].delegate;
  context = appDelegate.managedObjectContext;
  [context reset];
}

- (void)tearDown
{
  // Tear-down code here.

  [super tearDown];
}

#pragma mark - Helpers

- (Trip *)mapNewYorkCityWithMapping:(DVJSONMapping *)mapping hasObjects:(BOOL)hasObjects
{
  NSDictionary *json = [JSONData newYorkCityTripJSON];
  STAssertNotNil(json, nil);

  NSError *error;
  NSArray *objects = [mapping mapJSON:json error:&error];
  STAssertNotNil(objects, nil);
  STAssertTrue([objects isKindOfClass:NSArray.class], nil);

  if (hasObjects) {
    STAssertTrue(objects.count == 1, nil);

    NSManagedObject *object = objects[0];
    STAssertEqualObjects(NSStringFromClass(object.class), @"Trip", nil);

    return (Trip *)object;
  }
  else {
    STAssertTrue(objects.count == 0, nil);
    return nil;
  }
}

#pragma mark - Tests

- (void)testCanParseNewYorkCityJSON
{
  NSDictionary *json = [JSONData newYorkCityTripJSON];
  STAssertNotNil(json, @"can't be nil");
}

- (void)testCanParseThreeTripJSON
{
  NSDictionary *json = [JSONData threeTripsJSON];
  STAssertNotNil(json, @"can't be nil");
}

- (void)testJSONObjectWithRelationships
{
  DVJSONMapping *mapping = [[DVJSONMapping alloc] initWithContext:context];
  [mapping setAllowedRelationshipsFromJSON:@[ @"places" ] forClass:Trip.class];
  
  Trip *trip = [self mapNewYorkCityWithMapping:mapping hasObjects:YES];
  STAssertEqualObjects(trip.name, @"NYC", nil);
  STAssertEqualObjects(trip.duration, @(10), nil);
  STAssertEqualObjects(trip.isDraft, @(YES), nil);
  STAssertEqualObjects(trip.description_, @"A list of places in New York City", nil);
  STAssertTrue(trip.places.count == 3, nil);
  STAssertNotNil(trip.lastModified, nil);

  NSArray *places = [trip.places sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES] ]];

  STAssertEqualObjects([places[0] name], @"Empire State Building", nil);
  STAssertEqualObjects([places[0] address], @"350 W 34th St, New York, NY 10118", nil);

  STAssertEqualObjects([places[1] name], @"Grand Central Station", nil);
  STAssertEqualObjects([places[1] address], @"15 Vanderbilt Avenue, New York, NY 10017", nil);

  STAssertEqualObjects([places[2] name], @"New York Grand Central Library", nil);
  STAssertEqualObjects([places[2] address], @"135 East 46th Street, New York, NY 10017", nil);
}

- (void)testMultipleObjectMapping
{
  NSDictionary *json = [JSONData threeTripsJSON];
  DVJSONMapping *mapping = [[DVJSONMapping alloc] initWithContext:context];

  NSError *error;
  NSArray *objects = [mapping mapJSON:json error:&error];
  STAssertNotNil(objects, nil);
  STAssertTrue(objects.count == 3, nil);

  [objects enumerateObjectsUsingBlock:^(NSManagedObject *object, NSUInteger idx, BOOL *stop) {
    STAssertEqualObjects(NSStringFromClass(object.class), @"Trip", nil);
  }];
}

- (void)testDirectMappingOfClass
{
  NSDictionary *json = [JSONData newYorkCityTripJSON];
  DVJSONMapping *mapping = [[DVJSONMapping alloc] initWithContext:context];

  NSError *error;
  NSArray *objects = [mapping mapJSON:json[@"trip"] ofClass:Trip.class error:&error];
  STAssertNotNil(objects, nil);
  STAssertTrue(objects.count == 1, nil);

  NSManagedObject *object = objects[0];
  STAssertEqualObjects(NSStringFromClass(object.class), @"Trip", nil);
}

- (void)testMappableClasses
{
  DVJSONMapping *mapping = [[DVJSONMapping alloc] initWithContext:context];
  mapping.mappableClasses = @[ @"Trip" ]; // trip, but not place

  Trip *trip = [self mapNewYorkCityWithMapping:mapping hasObjects:YES];
  STAssertTrue(trip.places.count == 0, nil);
}

- (void)testEmptyMappableClasses
{
  DVJSONMapping *mapping = [[DVJSONMapping alloc] initWithContext:context];
  mapping.mappableClasses = @[]; // no classes are mappable
  Trip *trip = [self mapNewYorkCityWithMapping:mapping hasObjects:NO];
  STAssertNil(trip, nil);
}

- (void)testMappableProperties
{
  DVJSONMapping *mapping = [[DVJSONMapping alloc] initWithContext:context];
  [mapping setAllowedAttributesFromJSON:@[ @"id", @"description_" ] forClass:Trip.class];
  Trip *trip = [self mapNewYorkCityWithMapping:mapping hasObjects:YES];

  STAssertEqualObjects(trip.id, @"301", nil);
  STAssertEqualObjects(trip.description_, @"A list of places in New York City", nil);
  STAssertNil(trip.name, nil);
  STAssertNil(trip.duration, nil);
  STAssertNil(trip.isDraft, nil);
  STAssertTrue(trip.places.count == 3, nil);
}

- (void)testMappablePropertiesWithNestedObjects
{
  DVJSONMapping *mapping = [[DVJSONMapping alloc] initWithContext:context];
  [mapping setAllowedAttributesFromJSON:@[ @"id", @"description_", @"places" ] forClass:Trip.class];
  [mapping setAllowedRelationshipsFromJSON:@[ @"places" ] forClass:Trip.class];
  [mapping setAllowedAttributesFromJSON:@[ @"id", @"name" ] forClass:Place.class];
  
  Trip *trip = [self mapNewYorkCityWithMapping:mapping hasObjects:YES];

  STAssertEqualObjects(trip.id, @"301", nil);
  STAssertEqualObjects(trip.description_, @"A list of places in New York City", nil);
  STAssertNil(trip.name, nil);
  STAssertNil(trip.duration, nil);
  STAssertNil(trip.isDraft, nil);
  STAssertTrue(trip.places.count == 3, nil);

  [trip.places enumerateObjectsUsingBlock:^(Place *place, BOOL *stop) {
    STAssertNotNil(place.id, nil);
    STAssertNotNil(place.name, nil); // place.name not affected by trip.name being excluded
  }];
}

#pragma mark - Test delegate methods

- (Trip *)makeSanFranciscoTrip
{
  Trip *trip = [Trip insertIntoContext:context];
  trip.name = @"San Francisco";
  trip.duration = @10;
  trip.isDraft = @YES;
  trip.lastModified = [NSDate date];
  trip.description_ = @"This is a description.";
  return trip;
}

- (void)testWithoutDelegateWillRemoveObjectsFromRelationship
{
  Trip *trip = [self makeSanFranciscoTrip];
  Place *place1 = [Place insertIntoContext:context];
  place1.name = @"Golden Gate Bridge";
  [trip addPlacesObject:place1];

  DVJSONMapping *mapping = [[DVJSONMapping alloc] initWithContext:context];
  [mapping setExpectedObjectsFromJSON:@[ trip ]];

  NSDictionary *json = [JSONData newYorkCityTripJSON];
  NSArray *objects = [mapping mapJSON:json error:nil];

  STAssertTrue([objects containsObject:trip], nil);
  STAssertFalse([trip.places containsObject:place1], nil);
}

- (void)testWithDelegateWillRemoveObjectsFromRelationship
{
  Trip *trip = [self makeSanFranciscoTrip];
  Place *place1 = [Place insertIntoContext:context];
  place1.name = @"Golden Gate Bridge";
  [trip addPlacesObject:place1];

  MappingDelegate *delegate = [[MappingDelegate alloc] init];
  DVJSONMapping *mapping = [[DVJSONMapping alloc] initWithContext:context];
  mapping.delegate = delegate;
  [mapping setExpectedObjectsFromJSON:@[ trip ]];

  NSDictionary *json = [JSONData newYorkCityTripJSON];
  NSArray *objects = [mapping mapJSON:json error:nil];

  STAssertTrue([objects containsObject:trip], nil);
  STAssertTrue([trip.places containsObject:place1], nil);
}

@end
