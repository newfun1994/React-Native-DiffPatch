/*
 * Diff Match and Patch
 *
 * Copyright 2010 geheimwerk.de.
 * http://code.google.com/p/google-diff-match-patch/
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Author: fraser@google.com (Neil Fraser)
 * ObjC port: jan@geheimwerk.de (Jan Weiß)
 * ObjC ARC port: Nick Ager
 */

#import "NSDictionary+DMPExtensions.h"

#import "NSString+UnicharUtilities.h"

@implementation NSDictionary (DMPExtensions)

- (id)diff_objectForIntegerKey:(NSInteger)keyInteger
{
    return self[@(keyInteger)];
}

- (id)diff_objectForUnsignedIntegerKey:(NSUInteger)keyUInteger
{
    return self[@(keyUInteger)];
}

- (id)diff_objectForUnicharKey:(unichar)aUnicharKey
{
    return self[[NSString diff_stringFromUnichar:aUnicharKey]];
}


- (NSInteger)diff_integerForKey:(id)aKey
{
    return ((NSNumber *)self[aKey]).integerValue;
}

- (NSUInteger)diff_unsignedIntegerForKey:(id)aKey
{
    return ((NSNumber *)self[aKey]).unsignedIntegerValue;
}

- (NSInteger)diff_integerForIntegerKey:(NSInteger)keyInteger
{
    return ((NSNumber *)self[@(keyInteger)]).integerValue;
}

- (NSUInteger)diff_unsignedIntegerForUnicharKey:(unichar)aUnicharKey
{
    return ((NSNumber *)[self diff_objectForUnicharKey:aUnicharKey]).unsignedIntegerValue;
}


- (BOOL)diff_containsObjectForKey:(id)aKey
{
    return (self[aKey] != nil);
}

- (BOOL)containsObjectForIntegerKey:(NSInteger)keyInteger
{
    return (self[@(keyInteger)] != nil);
}

- (BOOL)diff_containsObjectForUnicharKey:(unichar)aUnicharKey
{
    return ([self diff_objectForUnicharKey:aUnicharKey] != nil);
}

@end
