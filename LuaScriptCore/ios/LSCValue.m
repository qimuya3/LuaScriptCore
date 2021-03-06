//
//  LUAValue.m
//  LuaSample
//
//  Created by vimfung on 16/7/13.
//  Copyright © 2016年 vimfung. All rights reserved.
//

#import "LSCValue.h"
#import "LSCValue_Private.h"
#import "lauxlib.h"

@interface LSCValue ()

/**
 *  数值容器
 */
@property (nonatomic, strong) id valueContainer;

/**
 *  数值类型
 */
@property (nonatomic) LSCValueType valueType;

@end

@implementation LSCValue

+ (instancetype)nilValue
{
    return [[LSCValue alloc] initWithType:LSCValueTypeNil value:[NSNull null]];
}

+ (instancetype)numberValue:(NSNumber *)numberValue
{
    return [[LSCValue alloc] initWithType:LSCValueTypeNumber value:numberValue];
}

+ (instancetype)booleanValue:(BOOL)boolValue
{
    return [[LSCValue alloc] initWithType:LSCValueTypeBoolean value:@(boolValue)];
}

+ (instancetype)stringValue:(NSString *)stringValue
{
    return [[LSCValue alloc] initWithType:LSCValueTypeString value:[stringValue copy]];
}

+ (instancetype)integerValue:(NSInteger)integerValue
{
    return [[LSCValue alloc] initWithType:LSCValueTypeInteger value:@(integerValue)];
}

+ (instancetype)arrayValue:(NSArray *)arrayValue
{
    return [[LSCValue alloc] initWithType:LSCValueTypeTable value:arrayValue];
}

+ (instancetype)dictionaryValue:(NSDictionary *)dictionaryValue
{
    return [[LSCValue alloc] initWithType:LSCValueTypeTable value:dictionaryValue];
}

+ (instancetype)dataValue:(NSData *)dataValue
{
    return [[LSCValue alloc] initWithType:LSCValueTypeData value:dataValue];
}

+ (instancetype)objectValue:(id)objectValue
{
    if ([objectValue isKindOfClass:[NSDictionary class]])
    {
        return [self dictionaryValue:objectValue];
    }
    else if ([objectValue isKindOfClass:[NSArray class]])
    {
        return [self arrayValue:objectValue];
    }
    else if ([objectValue isKindOfClass:[NSNumber class]])
    {
        return [self numberValue:objectValue];
    }
    else if ([objectValue isKindOfClass:[NSString class]])
    {
        return [self stringValue:objectValue];
    }
    else if ([objectValue isKindOfClass:[NSData class]])
    {
        return [self dataValue:objectValue];
    }
    
    return [self nilValue];
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.valueContainer = [NSNull null];
    }
    
    return self;
}

- (void)pushWithState:(NameDef(lua_State) *)state
{
    switch (self.valueType)
    {
        case LSCValueTypeInteger:
            NameDef(lua_pushinteger)(state, [self.valueContainer integerValue]);
            break;
        case LSCValueTypeNumber:
            NameDef(lua_pushnumber)(state, [self.valueContainer doubleValue]);
            break;
        case LSCValueTypeNil:
            NameDef(lua_pushnil)(state);
            break;
        case LSCValueTypeString:
            NameDef(lua_pushstring)(state, [self.valueContainer UTF8String]);
            break;
        case LSCValueTypeBoolean:
            NameDef(lua_pushboolean)(state, [self.valueContainer boolValue]);
            break;
        case LSCValueTypeTable:
        {
            [self pushTable:state value:self.valueContainer];
            break;
        }
        case LSCValueTypeData:
        {
            NameDef(lua_pushlstring)(state, [self.valueContainer bytes], [self.valueContainer length]);
            break;
        }
        default:
            break;
    }
}

- (id)toObject
{
    return self.valueContainer;
}

- (NSString *)toString
{
    return [NSString stringWithFormat:@"%@", self.valueContainer];
}

- (NSNumber *)toNumber
{
    switch (self.valueType)
    {
        case LSCValueTypeNumber:
        case LSCValueTypeInteger:
        case LSCValueTypeBoolean:
            return self.valueContainer;
        case LSCValueTypeString:
            return @([(NSString *)self.valueContainer doubleValue]);
        default:
            return nil;
    }
}

- (NSString *)description
{
    return [self.valueContainer description];
}

#pragma mark - Private

/**
 *  初始化值对象
 *
 *  @param type  类型
 *  @param value 值
 *
 *  @return 值对象
 */
- (instancetype)initWithType:(LSCValueType)type value:(id)value
{
    if (self = [super init])
    {
        self.valueType = type;
        self.valueContainer = value;
    }
    
    return self;
}

/**
 *  压入一个Table类型
 *
 *  @param state Lua解析器
 *  @param value 值
 */
- (void)pushTable:(NameDef(lua_State) *)state value:(id)value
{
    __weak LSCValue *theValue = self;

    if ([value isKindOfClass:[NSDictionary class]])
    {
        lua_newtable(state);
        [(NSDictionary *)value enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            [theValue pushTable:state value:obj];
            NameDef(lua_setfield)(state, - 2, [[NSString stringWithFormat:@"%@", key] UTF8String]);
            
        }];
    }
    else if ([value isKindOfClass:[NSArray class]])
    {
        lua_newtable(state);
        [(NSArray *)value enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            //lua数组下标从1开始
            [theValue pushTable:state value:obj];
            NameDef(lua_rawseti)(state, -2, idx + 1);
            
        }];
    }
    else if ([value isKindOfClass:[NSNumber class]])
    {
        NameDef(lua_pushnumber)(state, [value doubleValue]);
    }
    else if ([value isKindOfClass:[NSString class]])
    {
        NameDef(lua_pushstring)(state, [value UTF8String]);
    }
}

@end
