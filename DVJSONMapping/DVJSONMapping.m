//
//  Created by Peyman Oreizy on 1/1/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#import <DVCoreDataFinders/DVCoreDataFinders.h>
#import "DVJSONMapping.h"
#import "DVJSONMapping+TypeConversion.h"
#import "ISO8601DateFormatter.h"
#import "NSString+DVJSONMapping.h"

NSString * const DVJSONMappingErrorDomain = @"DVJSONMappingErrorDomain";

static NSString * const kDefaultPrimaryKey = @"id";


@interface DVJSONMapping ()

@property(nonatomic,strong,readwrite) NSManagedObjectContext *context;
@property(nonatomic,strong) NSMutableArray *mutableExpectedObjectsFromJSON;

// For the 4 dictionaries used for allowed attributes/relationships to/from JSON:
//   key: the class name (a NSString)
//   value: an array of property names (a NSArray of NSStrings)
//
@property(nonatomic,strong) NSMutableDictionary *allowedAttributesFromJSON;
@property(nonatomic,strong) NSMutableDictionary *allowedRelationshipsFromJSON;
@property(nonatomic,strong) NSMutableDictionary *allowedAttributesToJSON;
@property(nonatomic,strong) NSMutableDictionary *allowedRelationshipsToJSON;

@end


@implementation DVJSONMapping

#pragma mark - Class methods

+ (NSArray *)mapJSON:(id)json context:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)errorPtr;
{
  DVJSONMapping *mapping = [[self alloc] initWithContext:context];
  return [mapping mapJSON:json error:errorPtr];
}

+ (NSArray *)mapJSON:(id)json expectingObject:(NSManagedObject *)expectingObject error:(NSError *__autoreleasing *)errorPtr;
{
  NSParameterAssert(expectingObject);

  DVJSONMapping *mapping = [[self alloc] initWithContext:expectingObject.managedObjectContext];
  [mapping setExpectedObjectsFromJSON:@[ expectingObject ]];
  return [mapping mapJSON:json error:errorPtr];
}

+ (NSDictionary *)mapObject:(NSManagedObject *)object onlyChanges:(BOOL)onlyChanges error:(NSError **)errorPtr;
{
  DVJSONMapping *mapping = [[self alloc] initWithContext:object.managedObjectContext];
  return [mapping mapObject:object onlyChanges:onlyChanges error:errorPtr];
}

#pragma mark - Lifecycle

- (id)initWithContext:(NSManagedObjectContext *)context
{
  self = [super init];
  if (self) {
    self.allowedAttributesFromJSON = [[NSMutableDictionary alloc] init];
    self.allowedRelationshipsFromJSON = [[NSMutableDictionary alloc] init];
    self.allowedAttributesToJSON = [[NSMutableDictionary alloc] init];
    self.allowedRelationshipsToJSON = [[NSMutableDictionary alloc] init];
    self.context = context;
    self.mappableClasses = nil;
    self.mutableExpectedObjectsFromJSON = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)setExpectedObjectsFromJSON:(NSArray *)expectedObjects;
{
  self.mutableExpectedObjectsFromJSON = [expectedObjects mutableCopy];
}

#pragma mark - Delegate hooks

- (Class)classForJSONKey:(NSString *)jsonKey
{
  if ([self.delegate respondsToSelector:@selector(JSONMapping:classForJSONKey:)]) {
    return [self.delegate JSONMapping:self classForJSONKey:jsonKey];
  }

  return [jsonKey dv_classify];
}

- (void)didMapJSONObject:(NSDictionary *)jsonObject toObject:(id)object;
{
  if ([self.delegate respondsToSelector:@selector(JSONMapping:didMapJSONObject:toObject:)]) {
    [self.delegate JSONMapping:self didMapJSONObject:jsonObject toObject:object];
  }
}

- (void)didMapObject:(NSManagedObject *)object toJSON:(NSMutableDictionary *)json
{
  if ([self.delegate respondsToSelector:@selector(JSONMapping:didMapObject:toJSON:)]) {
    [self.delegate JSONMapping:self didMapObject:object toJSON:json];
  }
}

- (id)findOrCreateObjectForJSONObject:(NSDictionary *)aJSONObject ofClass:(Class)aClass error:(NSError **)errorPtr;
{
  if ([self.delegate respondsToSelector:@selector(JSONMapping:findOrCreateObjectForJSONObject:ofClass:error:)]) {
    return [self.delegate JSONMapping:self findOrCreateObjectForJSONObject:aJSONObject ofClass:aClass error:errorPtr];
  }

  NSString *primaryKey = [self primaryKeyForClass:aClass];
  if (primaryKey == nil) {
    if (errorPtr) {
      *errorPtr = [self errorWithCode:DVJSONMappingErrorNoPrimaryKeyForClass_1,NSStringFromClass(aClass)];
    }
    return nil;
  }

  NSString *primaryKeyValue = [aJSONObject objectForKey:primaryKey];
  if (primaryKeyValue == nil) {
    if (errorPtr) {
      *errorPtr = [self errorWithCode:DVJSONMappingErrorNoPrimaryKeyValueForClass_2,NSStringFromClass(aClass),primaryKey];
    }
    return nil;
  }

  // First, search the store for an object with the same primary key

  __block id object;

  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", primaryKey, primaryKeyValue];

  object = [aClass findFirstWithPredicate:predicate inContext:self.context error:errorPtr];
  if (object) {
    return object;
  }

  // Second, check our "expected objects" pool for an object with the same type

  NSUInteger index = [self.mutableExpectedObjectsFromJSON indexOfObjectPassingTest:^BOOL(NSManagedObject *candidateObject, NSUInteger idx, BOOL *stop) {
    return [candidateObject isKindOfClass:aClass];
  }];

  if (index != NSNotFound) {
    object = self.mutableExpectedObjectsFromJSON[index];
    [self.mutableExpectedObjectsFromJSON removeObjectAtIndex:index];
    return object;
  }

  // Third, insert an object into the store

  NSEntityDescription* entity = [aClass entityInContext:self.context];
  return [[aClass alloc] initWithEntity:entity insertIntoManagedObjectContext:self.context];
}

- (NSString *)primaryKeyForClass:(Class)aClass
{
  if ([self.delegate respondsToSelector:@selector(JSONMapping:primaryKeyForClass:)]) {
    return [self.delegate JSONMapping:self primaryKeyForClass:aClass];
  }

  return kDefaultPrimaryKey;
}

- (void)updateObject:(id)object setJSONObject:(id)jsonObject forJSONKey:(NSString *)jsonKey error:(NSError **)errorPtr;
{
  if ([self.delegate respondsToSelector:@selector(JSONMapping:updateObject:setJSONObject:forJSONKey:)]) {
    [self.delegate JSONMapping:self updateObject:object setJSONObject:jsonObject forJSONKey:jsonKey];
    return;
  }

  // Find the object property that correspondes to `jsonKey`

  NSPropertyDescription *property = [self propertyOfClass:((NSObject *)object).class forJSONKey:jsonKey];
  if (property == nil) {
    // No corresponding property; ignore
    return;
  }

  // Verify that we can map it

  if ([self canMapPropertyFromJSON:property ofClass:((NSObject *)object).class] == NO) {
    return;
  }

  // Map it

  if ([property isKindOfClass:[NSAttributeDescription class]]) {
    NSAttributeDescription *attribute = (NSAttributeDescription *)property;
    [self assignJSONValue:jsonObject toAttribute:attribute ofObject:object];
  }
  else if ([property isKindOfClass:[NSRelationshipDescription class]]) {
    NSRelationshipDescription *relationship = (NSRelationshipDescription *)property;
    [self assignJSONValue:jsonObject toRelationship:relationship ofObject:object error:errorPtr];
  }
  else {
    if (errorPtr) {
      *errorPtr = [self errorWithCode:DVJSONMappingErrorBadPropertyType_2,property.name,NSStringFromClass(((NSObject *)object).class)];
    }
    return;
  }
}

- (void)willMapJSONObject:(NSMutableDictionary *)jsonObject ofClass:(Class)aClass;
{
  if ([self.delegate respondsToSelector:@selector(JSONMapping:willMapJSONObject:ofClass:)]) {
    [self.delegate JSONMapping:self willMapJSONObject:jsonObject ofClass:aClass];
  }
}

- (void)willMapObject:(NSManagedObject *)object toJSON:(NSMutableDictionary *)json
{
  if ([self.delegate respondsToSelector:@selector(JSONMapping:willMapObject:toJSON:)]) {
    [self.delegate JSONMapping:self willMapObject:object toJSON:json];
  }
}

#pragma mark - Methods

+ (BOOL)isReservedPropertyName:(NSString *)name
{
  static dispatch_once_t onceToken;
  static NSArray *reservedNames = nil;

  dispatch_once(&onceToken, ^{
    reservedNames = @[
                      // Reserved names from the NSObject class
                      @"alloc", @"autoContentAccessingProxy", @"classForCoder", @"classForKeyedArchiver",
                      @"dealloc", @"finalize"@"copy", @"init", @"mutableCopy",

                      // Reserved names from the NSObject protocol
                      @"autorelease",@"class",@"description",@"hash",@"isProxy",@"release",@"retain",
                      @"retainCount",@"self",@"superclass",@"zone",

                      // Reserved names from NSManagedObject class
                      @"awakeFromFetch", @"awakeFromInsert", @"changedValues", @"changedValuesForCurrentEvent",
                      @"didSave", @"didTurnIntoFault", @"entity", @"objectID", @"faultingState", @"hasChanges",
                      @"isFault", @"isDeleted", @"isInserted", @"isUpdated", @"managedObjectContext",
                      @"observationInfo", @"prepareForDeletion", @"willSave", @"willTurnIntoFault"
                      ];
  });

  return [reservedNames containsObject:name];
}

- (BOOL)canMapClass:(Class)aClass
{
  if (self.mappableClasses) {
    NSString *className = NSStringFromClass(aClass);
    return [self.mappableClasses containsObject:className];
  }
  else {
    return [aClass isSubclassOfClass:NSManagedObject.class];
  }
}

- (BOOL)canMapPropertyFromJSON:(NSPropertyDescription *)property ofClass:(Class)aClass
{
  NSString *className = NSStringFromClass(aClass);

  NSArray *mappableNames = nil;

  if ([property isKindOfClass:NSAttributeDescription.class]) {
    mappableNames = self.allowedAttributesFromJSON[className];
  }
  else if ([property isKindOfClass:NSRelationshipDescription.class]) {
    mappableNames = self.allowedRelationshipsFromJSON[className];
  }
  else {
    return NO;
  }

  if (mappableNames == nil) {
    return YES; // by default, all properties are mappable from JSON
  }

  return [mappableNames containsObject:property.name];
}

- (BOOL)canMapPropertyToJSON:(NSPropertyDescription *)property ofClass:(Class)aClass
{
  NSString *className = NSStringFromClass(aClass);

  NSArray *mappableNames = nil;

  if ([property isKindOfClass:NSAttributeDescription.class]) {
    mappableNames = self.allowedAttributesToJSON[className];
  }
  else if ([property isKindOfClass:NSRelationshipDescription.class]) {
    mappableNames = self.allowedRelationshipsToJSON[className];
  }
  else {
    return NO;
  }

  if (mappableNames == nil) {
    return YES; // by default, all properties are mappable to JSON
  }

  return [mappableNames containsObject:property.name];
}

- (NSError *)errorWithCode:(NSInteger)code,...
{
  NSString *format;

  switch (code) {
    case DVJSONMappingErrorExpectedJSONDictionary:
      format = @"Expected `json` to be a NSDictionary";
      break;

    case DVJSONMappingErrorExpectedJSONCollection:
      format = @"Expected JSON to be an NSArray or NSDictionary";
      break;

    case DVJSONMappingErrorBadAttributeName_1:
      format = @"Bad attribute named `%@`";
      break;

    case DVJSONMappingErrorBadAttributeType_1:
      format = @"Bad attribute type for attribute `%@`";
      break;

    case DVJSONMappingErrorNoPrimaryKeyForClass_1:
      format = @"No primary key for class `%@`";
      break;

    case DVJSONMappingErrorNoPrimaryKeyValueForClass_2:
      format = @"JSON for class `%@` lacks primary key property `%@`";
      break;

    case DVJSONMappingErrorBadPropertyType_2:
      format = @"Property `%@` of class `%@` is not supported";
      break;

    case DVJSONMappingErrorExpectedJSONDictionaryForProperty_1_ButJSONWasOfClass_2_:
      format = @"Expected JSON to be a NSDictionary for property `%@`, but JSON was of class `%@`.";
      break;

    default:
      break;
  }

  va_list argumentList;
  va_start(argumentList, code);
  NSString *description = [[NSString alloc] initWithFormat:format arguments:argumentList];
  va_end(argumentList);

  return [NSError errorWithDomain:DVJSONMappingErrorDomain code:code userInfo:@{ NSLocalizedDescriptionKey: description }];
}

- (ISO8601DateFormatter *)iso8601DateFormatter
{
  if (_iso8601DateFormatter == nil) {
    _iso8601DateFormatter = [[ISO8601DateFormatter alloc] init];
  }
  return _iso8601DateFormatter;
}

- (void)logWarning:(NSString *)message
{
  NSLog(@"DVJSONMapping: Warning: %@", message);
}

- (NSMutableDictionary *)mappableObjectAttributesForEntity:(NSEntityDescription *)entity
{
  NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

  NSDictionary *attributes = [entity attributesByName];

  NSArray *allowedAttributesFromJSON = self.allowedAttributesFromJSON[NSStringFromClass(entity.class)];
  if (allowedAttributesFromJSON == nil) {

    // by default, all attributes are mappable
    [result addEntriesFromDictionary:attributes];

  }
  else {

    [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSAttributeDescription *attributeDescription, BOOL *stop) {
      if ([allowedAttributesFromJSON containsObject:name]) {
        // not mappable; skip it
      }
      else {
        result[name] = attributeDescription;
      }
    }];

  }

  return result;
}

- (void)mappableObjectPropertiesForClass:(Class)aClass attributes:(NSMutableDictionary **)attributesPtr relationships:(NSMutableDictionary **)relationshipsPtr
{
  NSEntityDescription *entity = [aClass entityInContext:self.context];

  if (attributesPtr) {
    *attributesPtr = [self mappableObjectAttributesForEntity:entity];
  }

  if (relationshipsPtr) {
    *relationshipsPtr = [self mappableObjectRelationshipsForEntity:entity];
  }
}

- (NSMutableDictionary *)mappableObjectRelationshipsForEntity:(NSEntityDescription *)entity
{
  NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

  NSArray *allowedRelationshipsFromJSON = self.allowedRelationshipsFromJSON[NSStringFromClass(entity.class)];
  if (allowedRelationshipsFromJSON == nil) {

    // by default, relationships are not mappable

  }
  else {

    NSDictionary *relationships = [entity relationshipsByName];
    [relationships enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSAttributeDescription *relationshipsDescription, BOOL *stop) {
      if ([allowedRelationshipsFromJSON containsObject:name] == NSNotFound) {
        // not mappable; skip it
      }
      else {
        result[name] = relationshipsDescription;
      }
    }];

  }

  return result;
}

- (NSPropertyDescription *)propertyOfClass:(Class)aClass forJSONKey:(NSString *)jsonKey;
{
  NSEntityDescription *entity = [aClass entityInContext:self.context];

  NSDictionary *properties = [entity propertiesByName];

  jsonKey = [jsonKey dv_camelString];

  if ([self.class isReservedPropertyName:jsonKey]) {
    jsonKey = [jsonKey stringByAppendingString:@"_"];
  }

  return [properties objectForKey:jsonKey];
}

- (void)setAllowedAttributesFromJSON:(NSArray *)attributesNamed forClass:(Class)aClass;
{
  [self updateAllowedProperties:attributesNamed forClass:aClass inDictionary:self.allowedAttributesFromJSON];
}

- (void)setAllowedRelationshipsFromJSON:(NSArray *)relationshipsNamed forClass:(Class)aClass;
{
  [self updateAllowedProperties:relationshipsNamed forClass:aClass inDictionary:self.allowedRelationshipsFromJSON];
}

- (void)setAllowedAttributesToJSON:(NSArray *)attributesNamed forClass:(Class)aClass;
{
  [self updateAllowedProperties:attributesNamed forClass:aClass inDictionary:self.allowedAttributesToJSON];
}

- (void)setAllowedRelationshipsToJSON:(NSArray *)relationshipsNamed forClass:(Class)aClass;
{
  [self updateAllowedProperties:relationshipsNamed forClass:aClass inDictionary:self.allowedRelationshipsToJSON];
}

- (void)updateAllowedProperties:(NSArray *)properties forClass:(Class)aClass inDictionary:(NSMutableDictionary *)dictionary
{
  dictionary[NSStringFromClass(aClass)] = [properties copy];
}

#pragma mark - JSON-to-Object

//
// expects a JSON dictionary, where keys correspond to classes and values correspond to objects
//
- (NSArray *)mapJSON:(id)json error:(NSError **)errorPtr;
{
  if ([json isKindOfClass:NSDictionary.class] == NO) {
    if (errorPtr) {
      *errorPtr = [self errorWithCode:DVJSONMappingErrorExpectedJSONDictionary];
    }
    return nil;
  }

  NSDictionary *jsonObject = json;

  NSMutableDictionary *objectDictionary = [[NSMutableDictionary alloc] init];

  __block NSError *error = nil;

  //
  // map to objects
  //

  [jsonObject enumerateKeysAndObjectsUsingBlock:^(id jsonKey, id jsonValue, BOOL *stop) {

    if ([jsonKey isKindOfClass:NSString.class] == NO) {
      // ignore non-string keys
      return;
    }

    Class aClass = [self classForJSONKey:jsonKey];
    if (aClass == nil) {
      // ignore a key if it doesn't correspond to an object
      return;
    }

    if ([self canMapClass:aClass] == NO) {
      // ignore a key if it's not allowed
      return;
    }

    NSArray *objects = [self mapJSON:jsonValue ofClass:aClass error:&error];
    if (error) {
      *stop = YES;
      return;
    }

    NSString *className = NSStringFromClass(aClass);
    if ([objectDictionary objectForKey:className]) {
      [objectDictionary[className] addObjectsFromArray:objects];
    }
    else {
      objectDictionary[className] = [NSMutableArray arrayWithArray:objects];
    }

  }];

  if (error) {
    if (errorPtr) {
      *errorPtr = error;
    }
    return nil;
  }

  //
  // resolve relationships
  //

  [self resolveRelationshipsForObjectDictionary:objectDictionary];

  //
  // return a flat array of objects
  //

  NSMutableArray *result = [[NSMutableArray alloc] init];
  [objectDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *className, NSMutableArray *objects, BOOL *stop) {
    [result addObjectsFromArray:objects];
  }];

  return [NSArray arrayWithArray:result];
}

- (NSArray *)mapJSON:(id)json ofClass:(Class)aClass error:(NSError **)errorPtr;
{
  if ([json isKindOfClass:NSArray.class]) {

    return [self mapJSONArray:json ofClass:aClass error:errorPtr];

  }
  else if ([json isKindOfClass:NSDictionary.class]) {

    id object = [self mapJSONObject:json ofClass:aClass error:errorPtr];
    if (object == nil) {
      return @[];
    }

    return @[ object ];

  }
  else {

    if (errorPtr) {
      *errorPtr = [self errorWithCode:DVJSONMappingErrorExpectedJSONCollection];
    }
    return nil;

  }
}

- (NSArray *)mapJSONArray:(NSArray *)jsonArray ofClass:(Class)aClass error:(NSError **)errorPtr;
{
  if ([self canMapClass:aClass] == NO) {
    return nil;
  }

  __block NSMutableArray *result = [NSMutableArray arrayWithCapacity:jsonArray.count];

  __block NSError *error = nil;

  [jsonArray enumerateObjectsUsingBlock:^(NSDictionary *jsonObject, NSUInteger idx, BOOL *stop) {

    id object = [self mapJSONObject:jsonObject ofClass:aClass error:&error];

    if (error) {
      *stop = YES;
    }
    else {
      if (object) {
        [result addObject:object];
      }
    }

  }];

  if (error) {
    *errorPtr = error;
    return nil;
  }

  return [NSArray arrayWithArray:result];
}

- (id)mapJSONObject:(NSDictionary *)aJSONObject ofClass:(Class)aClass error:(NSError **)errorPtr;
{
  if ([self canMapClass:aClass] == NO) {
    return nil;
  }

  NSMutableDictionary *jsonObject = [NSMutableDictionary dictionaryWithDictionary:aJSONObject];

  [self willMapJSONObject:jsonObject ofClass:aClass];

  id object = [self findOrCreateObjectForJSONObject:jsonObject ofClass:aClass error:errorPtr];

  [self updateObject:object fromJSONObject:jsonObject error:errorPtr];

  [self didMapJSONObject:jsonObject toObject:object];

  return object;
}

- (void)resolveRelationshipsForObjectDictionary:(NSDictionary *)objectDictionary
{
  if ([self.delegate respondsToSelector:@selector(JSONMapping:resolveRelationshipsForObjectsByClassName:)]) {
    [self.delegate JSONMapping:self resolveRelationshipsForObjectDictionary:objectDictionary];
  }
}

- (void)updateObject:(id)object fromJSONObject:(NSDictionary *)jsonObject error:(NSError **)errorPtr;
{
  __block NSError *error = nil;

  [jsonObject enumerateKeysAndObjectsUsingBlock:^(id jsonKey, id jsonValue, BOOL *stop) {

    [self updateObject:object setJSONObject:jsonValue forJSONKey:jsonKey error:&error];

    if (error) {
      *stop = YES;
      return;
    }

  }];

  if (error) {
    if (errorPtr) {
      *errorPtr = error;
    }
    return;
  }
}

#pragma mark - Object-to-JSON

- (void)updateJSON:(NSMutableDictionary *)json fromObject:(NSManagedObject *)object onlyChanges:(BOOL)onlyChanges error:(NSError **)errorPtr
{
  NSMutableDictionary *attributes = nil;
  NSMutableDictionary *relationships = nil;

  [self mappableObjectPropertiesForClass:object.class attributes:&attributes relationships:&relationships];

  if (onlyChanges) {

    // remove attributes & relationships that haven't changed

    NSSet *changedKeys = [NSSet setWithArray:object.changedValues.allKeys];

    NSMutableSet *attributeKeysToRemove = [NSMutableSet setWithArray:attributes.allKeys];
    [attributeKeysToRemove minusSet:changedKeys];
    [attributes removeObjectsForKeys:attributeKeysToRemove.allObjects];

    NSMutableSet *relationshipKeysToRemove = [NSMutableSet setWithArray:relationships.allKeys];
    [relationshipKeysToRemove minusSet:changedKeys];
    [relationships removeObjectsForKeys:relationshipKeysToRemove.allObjects];

  }

  // map attributes

  __block NSError *error = nil;

  [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, NSAttributeDescription *attributeDescription, BOOL *stop) {

    if ([self canMapPropertyToJSON:attributeDescription ofClass:((NSObject *)object).class] == NO) {
      return;
    }

    id value = [object valueForKey:attributeName];

    [self assignObjectValue:value ofAttribute:attributeDescription toJSON:json error:&error];

    if (error) {
      *stop = YES;
      return;
    }

  }];

  if (error) {
    *errorPtr = error;
    return;
  }

  // map relationships

  [relationships enumerateKeysAndObjectsUsingBlock:^(NSString *relationshipName, NSRelationshipDescription *relationshipDescription, BOOL *stop) {

    if ([self canMapPropertyToJSON:relationshipDescription ofClass:((NSObject *)object).class] == NO) {
      return;
    }

    id value = [object valueForKey:relationshipName];

    [self assignObjectValue:value ofRelationship:relationshipDescription onlyChanges:onlyChanges toJSON:json error:&error];

    if (error) {
      *stop = YES;
      return;
    }

  }];

  if (error) {
    *errorPtr = error;
    return;
  }

}

- (NSDictionary *)mapObject:(NSManagedObject *)object onlyChanges:(BOOL)onlyChanges error:(NSError **)errorPtr;
{
  if ([self canMapClass:object.class] == NO) {
    return nil;
  }

  NSMutableDictionary *json = [[NSMutableDictionary alloc] init];

  [self willMapObject:object toJSON:json];

  [self updateJSON:json fromObject:object onlyChanges:onlyChanges error:errorPtr];

  [self didMapObject:object toJSON:json];

  return json;
}

@end
