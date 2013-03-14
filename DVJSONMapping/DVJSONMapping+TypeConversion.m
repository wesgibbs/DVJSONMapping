//
//  Created by Peyman Oreizy on 1/26/13.
//  Copyright 2013 Dynamic Variable LLC. All rights reserved.
//

#import "DVJSONMapping+Internal.h"
#import "DVJSONMapping+TypeConversion.h"
#import "ISO8601DateFormatter.h"
#import "NSString+DVJSONMapping.h"

@implementation DVJSONMapping (TypeConversion)

#pragma mark - JSON-to-Object

- (NSObject *)nullValueForAttribute:(NSAttributeDescription *)attribute
{
  if (attribute.isOptional) {
    return nil;
  }

  if (attribute.defaultValue) {
    return attribute.defaultValue;
  }

  // pick a reasonble value based on the attribute's type

  switch (attribute.attributeType) {
    case NSInteger16AttributeType:
    case NSInteger32AttributeType:
    case NSInteger64AttributeType:
      return [NSNumber numberWithInteger:0];

    case NSDecimalAttributeType:
    case NSDoubleAttributeType:
    case NSFloatAttributeType:
      return [NSNumber numberWithDouble:0.0];

    case NSStringAttributeType:
      return [NSString string];

    case NSBooleanAttributeType:
      return [NSNumber numberWithBool:NO];

    case NSDateAttributeType:
      return [NSDate date];

    case NSUndefinedAttributeType:
    case NSBinaryDataAttributeType:
    case NSTransformableAttributeType:
    case NSObjectIDAttributeType:
    default:
      return nil;
  }
}

- (void)assignJSONValue:(id)jsonValue toAttribute:(NSAttributeDescription *)attribute ofObject:(id)object;
{
  NSObject *value = nil;

  if ([jsonValue isKindOfClass:[NSNull class]]) {
    value = [self nullValueForAttribute:attribute];
    [object setValue:value forKey:attribute.name];
    return;
  }

  switch (attribute.attributeType) {
    case NSInteger16AttributeType:
    case NSInteger32AttributeType:
    case NSInteger64AttributeType:
      if ([jsonValue isKindOfClass:[NSNumber class]]) {
        value = jsonValue;
      }
      else if ([jsonValue isKindOfClass:[NSString class]]) {
        int intValue = [jsonValue intValue];
        value = [NSNumber numberWithInteger:intValue];
      }
      else {
        NSObject *jsonObject = jsonValue;
        [self logWarning:[NSString stringWithFormat:@"Can't assign JSON value of type '%@' to an integer attribute '%@'.", NSStringFromClass(jsonObject.class), attribute.name]];
      }
      break;

    case NSDecimalAttributeType:
    case NSDoubleAttributeType:
    case NSFloatAttributeType:
      if ([jsonValue isKindOfClass:[NSNumber class]]) {
        value = jsonValue;
      }
      else if ([jsonValue isKindOfClass:[NSString class]]) {
        double doubleValue = [jsonValue doubleValue];
        value = [NSNumber numberWithDouble:doubleValue];
      }
      else {
        NSObject *jsonObject = jsonValue;
        [self logWarning:[NSString stringWithFormat:@"Can't assign JSON value of type '%@' to an integer attribute '%@'.", NSStringFromClass(jsonObject.class), attribute.name]];
      }
      break;

    case NSStringAttributeType:
      if ([jsonValue isKindOfClass:[NSNumber class]]) {
        value = [jsonValue stringValue];
      }
      else if ([jsonValue isKindOfClass:[NSString class]]) {
        value = jsonValue;
      }
      else {
        NSObject *jsonObject = jsonValue;
        [self logWarning:[NSString stringWithFormat:@"Can't assign JSON value of type '%@' to a string attribute '%@'.", NSStringFromClass(jsonObject.class), attribute.name]];
      }
      break;

    case NSBooleanAttributeType:
      if ([jsonValue isKindOfClass:[NSNumber class]] || [jsonValue isKindOfClass:[NSString class]]) {
        BOOL boolValue = [jsonValue boolValue];
        value = [NSNumber numberWithBool:boolValue];
      }
      else {
        NSObject *jsonObject = jsonValue;
        [self logWarning:[NSString stringWithFormat:@"Can't assign JSON value of type '%@' to a boolean attribute '%@'.", NSStringFromClass(jsonObject.class), attribute.name]];
      }
      break;

    case NSDateAttributeType:
      if ([jsonValue isKindOfClass:[NSString class]]) {
        value = [self.iso8601DateFormatter dateFromString:jsonValue];
      }
      else {
        NSObject *jsonObject = jsonValue;
        [self logWarning:[NSString stringWithFormat:@"Can't assign JSON value of type '%@' to a date attribute '%@'.", NSStringFromClass(jsonObject.class), attribute.name]];
      }
      break;

    case NSUndefinedAttributeType:
    case NSBinaryDataAttributeType:
    case NSTransformableAttributeType:
    case NSObjectIDAttributeType:
    default: {
      NSObject *jsonObject = jsonValue;
      [self logWarning:[NSString stringWithFormat:@"Can't assign JSON value of type '%@' to attribute '%@'.", NSStringFromClass(jsonObject.class), attribute.name]];
      break;
    }
  }

  [object setValue:value forKey:attribute.name];
}

- (void)assignJSONValue:(id)jsonValue toRelationship:(NSRelationshipDescription *)relationship ofObject:(id)object error:(NSError **)errorPtr;
{
  Class destinationClass = NSClassFromString(relationship.destinationEntity.managedObjectClassName);

  if (relationship.isToMany) {

    NSMutableSet *resultSet = [[NSMutableSet alloc] init];

    NSArray *jsonArray = [jsonValue isKindOfClass:[NSArray class]] ? (NSArray *)jsonValue : @[ jsonValue ];

    __block NSError *error = nil;

    [jsonArray enumerateObjectsUsingBlock:^(id jsonObject, NSUInteger idx, BOOL *stop) {

      if ([jsonObject isKindOfClass:[NSDictionary class]] == NO) {
        error = [self errorWithCode:DVJSONMappingErrorExpectedJSONDictionary];
        return;
      }

      id object = [self mapJSONObject:jsonObject ofClass:destinationClass error:&error];
      if (object == nil || error) {
        *stop = YES;
        return;
      }

      [resultSet addObject:object];

    }];

    if (error) {
      if (errorPtr) {
        *errorPtr = error;
      }
      return;
    }

    [object setValue:resultSet forKey:relationship.name];

  }
  else { // to-one relationship

    NSError *error = nil;

    if ([jsonValue isKindOfClass:[NSNull class]]) {
      [object setValue:nil forKey:relationship.name];
      return;
    }

    if ([jsonValue isKindOfClass:[NSDictionary class]] == NO) {
      NSObject *jsonObject = jsonValue;
      error = [self errorWithCode:DVJSONMappingErrorExpectedJSONDictionaryForProperty_1_ButJSONWasOfClass_2_,relationship.name,NSStringFromClass(jsonObject.class)];
      if (errorPtr) {
        *errorPtr = error;
      }
      return;
    }

    id resultObject = [self mapJSONObject:jsonValue ofClass:destinationClass error:&error];
    if (resultObject == nil || error) {
      if (errorPtr) {
        *errorPtr = error;
      }
      return;
    }

    [object setValue:resultObject forKey:relationship.name];

  }
}

#pragma mark - Object-to-JSON

- (NSString *)jsonKeyForPropertyName:(NSString *)jsonKey
{
  if ([jsonKey hasSuffix:@"_"]) {
    jsonKey = [jsonKey substringToIndex:(jsonKey.length - 1)];
  }

  jsonKey = [jsonKey dv_underscoreString];

  return jsonKey;
}

- (id)jsonValueForObjectAttributeValue:(id)value
{
  if ([value isKindOfClass:[NSDictionary class]]) {

    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

    [value enumerateKeysAndObjectsUsingBlock:^(NSString *name, id value, BOOL *stop) {

      NSString *jsonKey = [self jsonKeyForPropertyName:name];
      id jsonValue = [self jsonValueForObjectAttributeValue:value];

      if (jsonKey == nil || jsonValue == nil) {
        *stop = YES;
        return;
      }

      [result setObject:jsonValue forKey:jsonKey];

    }];

    return result;

  }
  else if ([value isKindOfClass:[NSArray class]]) {

    NSMutableArray *result = [[NSMutableArray alloc] init];

    [value enumerateObjectsUsingBlock:^(id value, NSUInteger idx, BOOL *stop) {

      id jsonValue = [self jsonValueForObjectAttributeValue:value];
      if (jsonValue == nil) {
        *stop = YES;
        return;
      }

      [result addObject:jsonValue];

    }];

    return result;

  }
  else {

    return value;

  }
}

- (void)assignObjectValue:(id)value ofAttribute:(NSAttributeDescription *)attribute toJSON:(NSMutableDictionary *)json error:(NSError **)errorPtr;
{
  NSString *jsonKey = [self jsonKeyForPropertyName:attribute.name];
  if (jsonKey.length == 0) {
    if (errorPtr) {
      *errorPtr = [self errorWithCode:DVJSONMappingErrorBadAttributeName_1,attribute.name];
    }
    return;
  }

  if (value == nil || value == [NSNull null]) {
    [json setValue:[NSNull null] forKey:jsonKey];
    return;
  }

  id jsonValue;

  switch (attribute.attributeType) {
    case NSInteger16AttributeType:
    case NSInteger32AttributeType:
    case NSInteger64AttributeType:
    case NSDecimalAttributeType:
    case NSDoubleAttributeType:
    case NSFloatAttributeType:
    case NSStringAttributeType:
    case NSBooleanAttributeType:
      jsonValue = value;
      break;

    case NSDateAttributeType:
      jsonValue = [self.iso8601DateFormatter stringFromDate:value];
      break;

    case NSUndefinedAttributeType:
    case NSBinaryDataAttributeType:
    case NSTransformableAttributeType:
    case NSObjectIDAttributeType:
    default:
      if (errorPtr) {
        *errorPtr = [self errorWithCode:DVJSONMappingErrorBadAttributeType_1,attribute.name];
      }
      break;
  }

  [json setObject:jsonValue forKey:jsonKey];
}

- (void)assignObjectValue:(id)objectValue ofRelationship:(NSRelationshipDescription *)relationship onlyChanges:(BOOL)onlyChanges toJSON:(NSMutableDictionary *)json error:(NSError **)errorPtr;
{
  NSString *jsonKey = [self jsonKeyForPropertyName:relationship.name];

  if (relationship.isToMany) {

    NSMutableArray *resultArray = [[NSMutableArray alloc] init];

    __block NSError *error = nil;

    NSSet *jsonSet = objectValue;
    [jsonSet enumerateObjectsUsingBlock:^(id object, BOOL *stop) {

      NSDictionary *jsonValue = [self mapObject:object onlyChanges:onlyChanges error:&error];
      if (jsonValue == nil || error) {
        *stop = YES;
        return;
      }

      [resultArray addObject:jsonValue];

    }];

    if (error) {
      if (errorPtr) {
        *errorPtr = error;
      }
      return;
    }

    [json setObject:resultArray forKey:jsonKey];

  }
  else {

    NSError *error = nil;

    NSDictionary *jsonValue = [self mapObject:objectValue onlyChanges:onlyChanges error:&error];
    if (jsonValue == nil || error) {
      if (errorPtr) {
        *errorPtr = error;
      }
      return;
    }

    [json setObject:jsonValue forKey:jsonKey];

  }
}

@end
