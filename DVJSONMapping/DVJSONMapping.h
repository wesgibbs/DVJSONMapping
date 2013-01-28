//
//  Created by Peyman Oreizy on 1/1/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

// Errors

extern NSString * const DVJSONMappingErrorDomain;

enum {
  DVJSONMappingErrorExpectedJSONDictionary = 1,
  DVJSONMappingErrorExpectedJSONCollection = 2,
  DVJSONMappingErrorBadAttributeName_1 = 3,
  DVJSONMappingErrorBadAttributeType_1 = 4,
  DVJSONMappingErrorNoPrimaryKeyForClass_1 = 5,
  DVJSONMappingErrorNoPrimaryKeyValueForClass_2 = 6,
  DVJSONMappingErrorBadPropertyType_2 = 7,
};

@protocol DVJSONMappingDelegate;
@class ISO8601DateFormatter;

////////////////////////////////////////////////////////////////////////

@interface DVJSONMapping : NSObject
{
  ISO8601DateFormatter *_iso8601DateFormatter;
}

+ (NSArray *)mapJSON:(id)json expectingObject:(NSManagedObject *)expectingObject error:(NSError *__autoreleasing *)errorPtr;

+ (NSDictionary *)mapObject:(NSManagedObject *)object onlyChanges:(BOOL)onlyChanges error:(NSError **)errorPtr;

@property(nonatomic,strong,readonly) NSManagedObjectContext *context;
@property(nonatomic,weak) id<DVJSONMappingDelegate> delegate;
@property(nonatomic,strong) NSArray *mappableClasses; // array of NSStrings

- (id)initWithContext:(NSManagedObjectContext *)context;

// JSON-to-Object

- (void)setAllowedAttributesFromJSON:(NSArray *)attributesNamed forClass:(Class)aClass;
- (void)setAllowedRelationshipsFromJSON:(NSArray *)relationshipsNamed forClass:(Class)aClass;
- (void)setExpectedObjectsFromJSON:(NSArray *)expectedObjects;

- (NSArray *)mapJSON:(id)json error:(NSError **)errorPtr;
- (NSArray *)mapJSON:(id)json ofClass:(Class)aClass error:(NSError **)errorPtr;
- (NSArray *)mapJSONArray:(NSArray *)jsonArray ofClass:(Class)aClass error:(NSError **)errorPtr;
- (id)mapJSONObject:(NSDictionary *)aJSONObject ofClass:(Class)aClass error:(NSError **)errorPtr;

// Object-to-JSON

- (void)setAllowedAttributesToJSON:(NSArray *)attributesNamed forClass:(Class)aClass;
- (void)setAllowedRelationshipsToJSON:(NSArray *)relationshipsNamed forClass:(Class)aClass;

- (NSDictionary *)mapObject:(NSManagedObject *)object onlyChanges:(BOOL)onlyChanges error:(NSError **)errorPtr;

@end

/////////////////////////////////////////////////////////////////////////

@protocol DVJSONMappingDelegate <NSObject>

@optional

// before/after JSON-to-Object mapping

- (void)JSONMapping:(DVJSONMapping *)mapping willMapJSONObject:(NSMutableDictionary *)jsonObject ofClass:(Class)aClass;

- (void)JSONMapping:(DVJSONMapping *)mapping didMapJSONObject:(NSDictionary *)jsonObject toObject:(id)object;

- (void)JSONMapping:(DVJSONMapping *)mapping resolveRelationshipsForObjectDictionary:(NSDictionary *)objectDictionary;

// before/after Object-to-JSON mapping

- (void)JSONMapping:(DVJSONMapping *)mapping willMapObject:(NSManagedObject *)object toJSON:(NSMutableDictionary *)json;

- (void)JSONMapping:(DVJSONMapping *)mapping didMapObject:(NSManagedObject *)object toJSON:(NSMutableDictionary *)json;

// hooks for each step of JSON-to-Object mapping

- (Class)JSONMapping:(DVJSONMapping *)mapping classForJSONKey:(NSString *)jsonKey;

- (NSString *)JSONMapping:(DVJSONMapping *)mapping primaryKeyForClass:(Class)klass;

- (id)JSONMapping:(DVJSONMapping *)mapping findOrCreateObjectForJSONObject:(NSDictionary *)jsonObject ofClass:(Class)aClass error:(NSError **)errorPtr;

- (void)JSONMapping:(DVJSONMapping *)mapping updateObject:(id)object setJSONObject:(id)jsonObject forJSONKey:(NSString *)jsonKey;

@end