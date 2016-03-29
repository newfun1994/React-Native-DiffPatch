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
 */

#import "NSMutableDictionary+DMPExtensions.h"

#import "NSString+UnicharUtilities.h"


@implementation NSMutableDictionary (DMPExtensions)

- (void)diff_setIntegerValue:(NSInteger)anInteger forKey:(id)aKey
{
  self[aKey] = @(anInteger);
}

- (void)diff_setIntegerValue:(NSInteger)anInteger forIntegerKey:(NSInteger)keyInteger
{
  self[@(keyInteger)] = @(anInteger);
}


- (void)diff_setUnsignedIntegerValue:(NSUInteger)anUInteger forKey:(id)aKey
{
  self[aKey] = @(anUInteger);
}

- (void)diff_setUnsignedIntegerValue:(NSUInteger)anUInteger forUnsignedIntegerKey:(NSUInteger)keyUInteger
{
  self[@(keyUInteger)] = @(anUInteger);
}

- (void)diff_setUnsignedIntegerValue:(NSUInteger)anUInteger forUnicharKey:(unichar)aUnicharKey
{
  self[[NSString diff_stringFromUnichar:aUnicharKey]] = @(anUInteger);
}

@end
