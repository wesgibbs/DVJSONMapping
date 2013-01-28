//
//  Created by Peyman Oreizy on 1/23/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#import "StringTests.h"
#import "NSString+DVJSONMapping.h"
#import "Trip.h"
#import "Place.h"
#import "JournalEntry.h"

@implementation StringTests

- (void)testClassify
{
  Class tripClass = NSClassFromString( NSStringFromClass(Trip.class) );
  Class placeClass = NSClassFromString( NSStringFromClass(Place.class) );

  STAssertEqualObjects([@"trip" dv_classify], tripClass, nil);
  STAssertEqualObjects([@"trips" dv_classify], tripClass, nil);
  STAssertEqualObjects([@"place" dv_classify], placeClass, nil);
  STAssertEqualObjects([@"places" dv_classify], placeClass, nil);
  STAssertEqualObjects([@"journal_entry" dv_classify], JournalEntry.class, nil);
  STAssertEqualObjects([@"journal_entries" dv_classify], JournalEntry.class, nil);
}

- (void)testCamelString
{
  STAssertEqualObjects([@"abc" dv_camelString], @"abc", nil);
  STAssertEqualObjects([@"abc_def" dv_camelString], @"abcDef", nil);
  STAssertEqualObjects([@"abc_def_hij" dv_camelString], @"abcDefHij", nil);
  STAssertEqualObjects([@"abc_def_hij_url" dv_camelString], @"abcDefHijURL", nil);
}

- (void)testPluralString
{
  STAssertEqualObjects([@"trip" dv_pluralString], @"trips", nil);
  STAssertEqualObjects([@"place" dv_pluralString], @"places", nil);
  STAssertEqualObjects([@"trips" dv_pluralString], @"trips", nil);
}

- (void)testSentenceCaseString
{
  STAssertEqualObjects([@"trip" dv_sentenceCaseString], @"Trip", nil);
  STAssertEqualObjects([@"Trip" dv_sentenceCaseString], @"Trip", nil);
  STAssertEqualObjects([@"packAndGo" dv_sentenceCaseString], @"PackAndGo", nil);
  STAssertEqualObjects([@"PackAndGo" dv_sentenceCaseString], @"PackAndGo", nil);
}

- (void)testSingularString
{
  STAssertEqualObjects([@"places" dv_singularString], @"place", nil);
  STAssertEqualObjects([@"trips" dv_singularString], @"trip", nil);
  STAssertEqualObjects([@"trip" dv_singularString], @"trip", nil);
}

- (void)testUnderscoreString
{
  STAssertEqualObjects([@"trip" dv_underscoreString], @"trip", nil);
  STAssertEqualObjects([@"Trip" dv_underscoreString], @"trip", nil);
  STAssertEqualObjects([@"packAndGo" dv_underscoreString], @"pack_and_go", nil);
  STAssertEqualObjects([@"PackAndGo" dv_underscoreString], @"pack_and_go", nil);
}

@end
