//
//  Created by Peyman Oreizy on 2/7/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#import <DVCoreDataFinders/DVCoreDataFinders.h>
#import "ObjectToJSONTests.h"
#import "DVAppDelegate.h"
#import "DVJSONMapping.h"
#import "JSONData.h"
#import "Place.h"
#import "Trip.h"

@implementation ObjectToJSONTests
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

#pragma mark - Tests

- (Trip *)simpleTrip
{
  Trip *trip = [[Trip alloc] initWithEntity:[Trip entityInContext:context] insertIntoManagedObjectContext:context];
  trip.name = @"San Francisco";
  trip.duration = @10;
  trip.isDraft = @YES;
  trip.lastModified = [NSDate date];
  trip.description_ = @"This is a description.";

  Place *place1 = [[Place alloc] initWithEntity:[Place entityInContext:context] insertIntoManagedObjectContext:context];
  place1.name = @"Place 1";
  place1.address = @"Address 1";

  Place *place2 = [[Place alloc] initWithEntity:[Place entityInContext:context] insertIntoManagedObjectContext:context];
  place2.name = @"Place 2";
  place2.address = @"Address 2";

  Place *place3 = [[Place alloc] initWithEntity:[Place entityInContext:context] insertIntoManagedObjectContext:context];
  place3.name = @"Place 3";
  place3.address = @"Address 3";

  [trip addPlacesObject:place1];
  [trip addPlacesObject:place2];
  [trip addPlacesObject:place3];

  return trip;
}

- (void)testMappingToJSONNoRelationships
{
  Trip *trip = [self simpleTrip];

  NSError *error;
  NSDictionary *json = [DVJSONMapping mapObject:trip onlyChanges:NO error:&error];
  STAssertNotNil(json, nil);
  STAssertTrue([json isKindOfClass:NSDictionary.class], nil);

  STAssertEqualObjects(json[@"description"], @"This is a description.", nil);
  STAssertEqualObjects(json[@"duration"], @10, nil);
  STAssertEqualObjects(json[@"is_draft"], @"true", nil);
  STAssertEqualObjects(json[@"name"], @"San Francisco", nil);
  STAssertNotNil(json[@"last_modified"], nil);
  STAssertNil(json[@"places"], nil);
}

- (void)testMappingToJSONWithRelationships
{
  DVJSONMapping *mapping = [[DVJSONMapping alloc] initWithContext:context];
  [mapping setAllowedRelationshipsToJSON:@[ @"places" ] forClass:Trip.class];

  Trip *trip = [self simpleTrip];

  NSError *error;
  NSDictionary *json = [mapping mapObject:trip onlyChanges:NO error:&error];
  STAssertNotNil(json, nil);
  STAssertTrue([json isKindOfClass:NSDictionary.class], nil);

  STAssertEqualObjects(json[@"description"], @"This is a description.", nil);
  STAssertEqualObjects(json[@"duration"], @10, nil);
  STAssertEqualObjects(json[@"is_draft"], @"true", nil);
  STAssertEqualObjects(json[@"name"], @"San Francisco", nil);
  STAssertNotNil(json[@"last_modified"], nil);
}

- (void)testMappingToJSONBooleanValues
{
  NSError *error;

  Trip *trip = [self simpleTrip];
  trip.isDraft = @YES;
  NSDictionary *json = [DVJSONMapping mapObject:trip onlyChanges:NO error:&error];

  STAssertEqualObjects(json[@"is_draft"], @"true", nil);

  trip.isDraft = @NO;
  json = [DVJSONMapping mapObject:trip onlyChanges:NO error:&error];

  STAssertEqualObjects(json[@"is_draft"], @"false", nil);
}

@end
