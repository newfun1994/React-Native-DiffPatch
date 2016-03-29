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

#import "DiffMatchPatchTest.h"

#import "DiffMatchPatch.h"
#import "NSMutableDictionary+DMPExtensions.h"

#define stringForBOOL(A)  ([((NSNumber *)A) boolValue] ? @"true" : @"false")

@interface DiffMatchPatchTest (PrivatMethods)
- (NSArray *)diff_rebuildtexts:(NSArray *)diffs;
@end

@implementation DiffMatchPatchTest

- (void)test_diff_commonPrefixTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Detect any common suffix.
  // Null case.
  XCTAssertEqual((NSUInteger)0, [dmp diff_commonPrefixOfFirstString:@"abc" andSecondString:@"xyz"], @"Common suffix null case failed.");

  // Non-null case.
  XCTAssertEqual((NSUInteger)4, [dmp diff_commonPrefixOfFirstString:@"1234abcdef" andSecondString:@"1234xyz"], @"Common suffix non-null case failed.");

  // Whole case.
  XCTAssertEqual((NSUInteger)4, [dmp diff_commonPrefixOfFirstString:@"1234" andSecondString:@"1234xyz"], @"Common suffix whole case failed.");

}

- (void)test_diff_commonSuffixTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Detect any common suffix.
  // Null case.
  XCTAssertEqual((NSUInteger)0, [dmp diff_commonSuffixOfFirstString:@"abc" andSecondString:@"xyz"], @"Detect any common suffix. Null case.");

  // Non-null case.
  XCTAssertEqual((NSUInteger)4, [dmp diff_commonSuffixOfFirstString:@"abcdef1234" andSecondString:@"xyz1234"], @"Detect any common suffix. Non-null case.");

  // Whole case.
  XCTAssertEqual((NSUInteger)4, [dmp diff_commonSuffixOfFirstString:@"1234" andSecondString:@"xyz1234"], @"Detect any common suffix. Whole case.");

}

- (void)test_diff_commonOverlapTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Detect any suffix/prefix overlap.
  // Null case.
  XCTAssertEqual((NSUInteger)0, [dmp diff_commonOverlapOfFirstString:@"" andSecondString:@"abcd"], @"Detect any suffix/prefix overlap. Null case.");

  // Whole case.
  XCTAssertEqual((NSUInteger)3, [dmp diff_commonOverlapOfFirstString:@"abc" andSecondString:@"abcd"], @"Detect any suffix/prefix overlap. Whole case.");

  // No overlap.
  XCTAssertEqual((NSUInteger)0, [dmp diff_commonOverlapOfFirstString:@"123456" andSecondString:@"abcd"], @"Detect any suffix/prefix overlap. No overlap.");

  // Overlap.
  XCTAssertEqual((NSUInteger)3, [dmp diff_commonOverlapOfFirstString:@"123456xxx" andSecondString:@"xxxabcd"], @"Detect any suffix/prefix overlap. Overlap.");

  // Unicode.
  // Some overly clever languages (C#) may treat ligatures as equal to their
  // component letters.  E.g. U+FB01 == 'fi'
  XCTAssertEqual((NSUInteger)0, [dmp diff_commonOverlapOfFirstString:@"fi" andSecondString:@"\U0000fb01i"], @"Detect any suffix/prefix overlap. Unicode.");

}

- (void)test_diff_halfmatchTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];
  dmp.Diff_Timeout = 1;
  NSArray *expectedResult = nil;

  // No match.
  XCTAssertNil([dmp diff_halfMatchOfFirstString:@"1234567890" andSecondString:@"abcdef"], @"No match #1.");

  XCTAssertNil([dmp diff_halfMatchOfFirstString:@"12345" andSecondString:@"23"], @"No match #2.");

  // Single Match.
  expectedResult = @[@"12", @"90", @"a", @"z", @"345678"];
  XCTAssertEqualObjects(expectedResult, [dmp diff_halfMatchOfFirstString:@"1234567890" andSecondString:@"a345678z"], @"Single Match #1.");

  expectedResult = @[@"a", @"z", @"12", @"90", @"345678"];
  XCTAssertEqualObjects(expectedResult, [dmp diff_halfMatchOfFirstString:@"a345678z" andSecondString:@"1234567890"], @"Single Match #2.");

  expectedResult = @[@"abc", @"z", @"1234", @"0", @"56789"];
  XCTAssertEqualObjects(expectedResult, [dmp diff_halfMatchOfFirstString:@"abc56789z" andSecondString:@"1234567890"], @"Single Match #3.");

  expectedResult = @[@"a", @"xyz", @"1", @"7890", @"23456"];
  XCTAssertEqualObjects(expectedResult, [dmp diff_halfMatchOfFirstString:@"a23456xyz" andSecondString:@"1234567890"], @"Single Match #4.");

  // Multiple Matches.
  expectedResult = @[@"12123", @"123121", @"a", @"z", @"1234123451234"];
  XCTAssertEqualObjects(expectedResult, [dmp diff_halfMatchOfFirstString:@"121231234123451234123121" andSecondString:@"a1234123451234z"], @"Multiple Matches #1.");

  expectedResult = @[@"", @"-=-=-=-=-=", @"x", @"", @"x-=-=-=-=-=-=-="];
  XCTAssertEqualObjects(expectedResult, [dmp diff_halfMatchOfFirstString:@"x-=-=-=-=-=-=-=-=-=-=-=-=" andSecondString:@"xx-=-=-=-=-=-=-="], @"Multiple Matches #2.");

  expectedResult = @[@"-=-=-=-=-=", @"", @"", @"y", @"-=-=-=-=-=-=-=y"];
  XCTAssertEqualObjects(expectedResult, [dmp diff_halfMatchOfFirstString:@"-=-=-=-=-=-=-=-=-=-=-=-=y" andSecondString:@"-=-=-=-=-=-=-=yy"], @"Multiple Matches #3.");

  // Non-optimal halfmatch.
  // Optimal diff would be -q+x=H-i+e=lloHe+Hu=llo-Hew+y not -qHillo+x=HelloHe-w+Hulloy
  expectedResult = @[@"qHillo", @"w", @"x", @"Hulloy", @"HelloHe"];
  XCTAssertEqualObjects(expectedResult, [dmp diff_halfMatchOfFirstString:@"qHilloHelloHew" andSecondString:@"xHelloHeHulloy"], @"Non-optimal halfmatch.");

  // Optimal no halfmatch.
  dmp.Diff_Timeout = 0;
  XCTAssertNil([dmp diff_halfMatchOfFirstString:@"qHilloHelloHew" andSecondString:@"xHelloHeHulloy"], @"Optimal no halfmatch.");

}

- (void)test_diff_linesToCharsTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];
  NSArray *result;

  // Convert lines down to characters.
  NSMutableArray *tmpVector = [NSMutableArray array];  // Array of NSString objects.
  [tmpVector addObject:@""];
  [tmpVector addObject:@"alpha\n"];
  [tmpVector addObject:@"beta\n"];
  result = [dmp diff_linesToCharsForFirstString:@"alpha\nbeta\nalpha\n" andSecondString:@"beta\nalpha\nbeta\n"];
  XCTAssertEqualObjects(@"\001\002\001", result[0], @"Shared lines #1.");
  XCTAssertEqualObjects(@"\002\001\002", result[1], @"Shared lines #2.");
  XCTAssertEqualObjects(tmpVector, (NSArray *)result[2], @"Shared lines #3.");

  [tmpVector removeAllObjects];
  [tmpVector addObject:@""];
  [tmpVector addObject:@"alpha\r\n"];
  [tmpVector addObject:@"beta\r\n"];
  [tmpVector addObject:@"\r\n"];
  result = [dmp diff_linesToCharsForFirstString:@"" andSecondString:@"alpha\r\nbeta\r\n\r\n\r\n"];
  XCTAssertEqualObjects(@"", result[0], @"Empty string and blank lines #1.");
  XCTAssertEqualObjects(@"\001\002\003\003", result[1], @"Empty string and blank lines #2.");
  XCTAssertEqualObjects(tmpVector, (NSArray *)result[2], @"Empty string and blank lines #3.");

  [tmpVector removeAllObjects];
  [tmpVector addObject:@""];
  [tmpVector addObject:@"a"];
  [tmpVector addObject:@"b"];
  result = [dmp diff_linesToCharsForFirstString:@"a" andSecondString:@"b"];
  XCTAssertEqualObjects(@"\001", result[0], @"No linebreaks #1.");
  XCTAssertEqualObjects(@"\002", result[1], @"No linebreaks #2.");
  XCTAssertEqualObjects(tmpVector, (NSArray *)result[2], @"No linebreaks #3.");

  // More than 256 to reveal any 8-bit limitations.
  unichar n = 300;
  [tmpVector removeAllObjects];
  NSMutableString *lines = [NSMutableString string];
  NSMutableString *chars = [NSMutableString string];
  NSString *currentLine;
  for (unichar x = 1; x < n + 1; x++) {
    currentLine = [NSString stringWithFormat:@"%d\n", (int)x];
    [tmpVector addObject:currentLine];
    [lines appendString:currentLine];
    [chars appendString:[NSString stringWithFormat:@"%C", x]];
  }
  XCTAssertEqual((NSUInteger)n, tmpVector.count, @"More than 256 #1.");
  XCTAssertEqual((NSUInteger)n, chars.length, @"More than 256 #2.");
  [tmpVector insertObject:@"" atIndex:0];
  result = [dmp diff_linesToCharsForFirstString:lines andSecondString:@""];
  XCTAssertEqualObjects(chars, result[0], @"More than 256 #3.");
  XCTAssertEqualObjects(@"", result[1], @"More than 256 #4.");
  XCTAssertEqualObjects(tmpVector, (NSArray *)result[2], @"More than 256 #5.");

}

- (void)test_diff_charsToLinesTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Convert chars up to lines.
  NSArray *diffs = @[[Diff diffWithOperation:OperationDiffEqual andText:@"\001\002\001"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"\002\001\002"]];
  NSMutableArray *tmpVector = [NSMutableArray array]; // Array of NSString objects.
  [tmpVector addObject:@""];
  [tmpVector addObject:@"alpha\n"];
  [tmpVector addObject:@"beta\n"];
  [dmp diff_chars:diffs toLines:tmpVector];
  NSArray *expectedResult = @[[Diff diffWithOperation:OperationDiffEqual andText:@"alpha\nbeta\nalpha\n"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"beta\nalpha\nbeta\n"]];
  XCTAssertEqualObjects(expectedResult, diffs, @"Shared lines.");

  // More than 256 to reveal any 8-bit limitations.
  unichar n = 300;
  [tmpVector removeAllObjects];
  NSMutableString *lines = [NSMutableString string];
  NSMutableString *chars = [NSMutableString string];
  NSString *currentLine;
  for (unichar x = 1; x < n + 1; x++) {
    currentLine = [NSString stringWithFormat:@"%d\n", (int)x];
    [tmpVector addObject:currentLine];
    [lines appendString:currentLine];
    [chars appendString:[NSString stringWithFormat:@"%C", x]];
  }
  XCTAssertEqual((NSUInteger)n, tmpVector.count, @"More than 256 #1.");
  XCTAssertEqual((NSUInteger)n, chars.length, @"More than 256 #2.");
  [tmpVector insertObject:@"" atIndex:0];
  diffs = @[[Diff diffWithOperation:OperationDiffDelete andText:chars]];
  [dmp diff_chars:diffs toLines:tmpVector];
  XCTAssertEqualObjects(@[[Diff diffWithOperation:OperationDiffDelete andText:lines]], diffs, @"More than 256 #3.");

}

- (void)test_diff_cleanupMergeTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Cleanup a messy diff.
  // Null case.
  NSArray *diffs = [dmp diff_cleanupMerge:@[]];
  XCTAssertEqualObjects(@[], diffs, @"Null case.");

  // No change case.
  diffs = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"a"], [Diff diffWithOperation:OperationDiffDelete andText:@"b"], [Diff diffWithOperation:OperationDiffInsert andText:@"c"], nil];
  diffs = [dmp diff_cleanupMerge:diffs];
  NSArray *expectedResult = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"a"], [Diff diffWithOperation:OperationDiffDelete andText:@"b"], [Diff diffWithOperation:OperationDiffInsert andText:@"c"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"No change case.");

  // Merge equalities.
  diffs = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"a"], [Diff diffWithOperation:OperationDiffEqual andText:@"b"], [Diff diffWithOperation:OperationDiffEqual andText:@"c"], nil];
  diffs = [dmp diff_cleanupMerge:diffs];
  expectedResult = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"abc"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Merge equalities.");

  // Merge deletions.
  diffs = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffDelete andText:@"a"], [Diff diffWithOperation:OperationDiffDelete andText:@"b"], [Diff diffWithOperation:OperationDiffDelete andText:@"c"], nil];
  diffs = [dmp diff_cleanupMerge:diffs];
  expectedResult = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffDelete andText:@"abc"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Merge deletions.");

  // Merge insertions.
  diffs = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffInsert andText:@"a"], [Diff diffWithOperation:OperationDiffInsert andText:@"b"], [Diff diffWithOperation:OperationDiffInsert andText:@"c"], nil];
  diffs = [dmp diff_cleanupMerge:diffs];
  expectedResult = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffInsert andText:@"abc"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Merge insertions.");

  // Merge interweave.
  diffs = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffDelete andText:@"a"], [Diff diffWithOperation:OperationDiffInsert andText:@"b"], [Diff diffWithOperation:OperationDiffDelete andText:@"c"], [Diff diffWithOperation:OperationDiffInsert andText:@"d"], [Diff diffWithOperation:OperationDiffEqual andText:@"e"], [Diff diffWithOperation:OperationDiffEqual andText:@"f"], nil];
  diffs = [dmp diff_cleanupMerge:diffs];
  expectedResult = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffDelete andText:@"ac"], [Diff diffWithOperation:OperationDiffInsert andText:@"bd"], [Diff diffWithOperation:OperationDiffEqual andText:@"ef"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Merge interweave.");

  // Prefix and suffix detection.
  diffs = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffDelete andText:@"a"], [Diff diffWithOperation:OperationDiffInsert andText:@"abc"], [Diff diffWithOperation:OperationDiffDelete andText:@"dc"], nil];
  diffs = [dmp diff_cleanupMerge:diffs];
  expectedResult = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"a"], [Diff diffWithOperation:OperationDiffDelete andText:@"d"], [Diff diffWithOperation:OperationDiffInsert andText:@"b"], [Diff diffWithOperation:OperationDiffEqual andText:@"c"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Prefix and suffix detection.");

  // Prefix and suffix detection with equalities.
  diffs = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"x"], [Diff diffWithOperation:OperationDiffDelete andText:@"a"], [Diff diffWithOperation:OperationDiffInsert andText:@"abc"], [Diff diffWithOperation:OperationDiffDelete andText:@"dc"], [Diff diffWithOperation:OperationDiffEqual andText:@"y"], nil];
  diffs = [dmp diff_cleanupMerge:diffs];
  expectedResult = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"xa"], [Diff diffWithOperation:OperationDiffDelete andText:@"d"], [Diff diffWithOperation:OperationDiffInsert andText:@"b"], [Diff diffWithOperation:OperationDiffEqual andText:@"cy"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Prefix and suffix detection with equalities.");

  // Slide edit left.
  diffs = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"a"], [Diff diffWithOperation:OperationDiffInsert andText:@"ba"], [Diff diffWithOperation:OperationDiffEqual andText:@"c"], nil];
  diffs = [dmp diff_cleanupMerge:diffs];
  expectedResult = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffInsert andText:@"ab"], [Diff diffWithOperation:OperationDiffEqual andText:@"ac"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Slide edit left.");

  // Slide edit right.
  diffs = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"c"], [Diff diffWithOperation:OperationDiffInsert andText:@"ab"], [Diff diffWithOperation:OperationDiffEqual andText:@"a"], nil];
  diffs = [dmp diff_cleanupMerge:diffs];
  expectedResult = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"ca"], [Diff diffWithOperation:OperationDiffInsert andText:@"ba"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Slide edit right.");

  // Slide edit left recursive.
  diffs = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"a"], [Diff diffWithOperation:OperationDiffDelete andText:@"b"], [Diff diffWithOperation:OperationDiffEqual andText:@"c"], [Diff diffWithOperation:OperationDiffDelete andText:@"ac"], [Diff diffWithOperation:OperationDiffEqual andText:@"x"], nil];
  diffs = [dmp diff_cleanupMerge:diffs];
  expectedResult = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffDelete andText:@"abc"], [Diff diffWithOperation:OperationDiffEqual andText:@"acx"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Slide edit left recursive.");

  // Slide edit right recursive.
  diffs = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"x"], [Diff diffWithOperation:OperationDiffDelete andText:@"ca"], [Diff diffWithOperation:OperationDiffEqual andText:@"c"], [Diff diffWithOperation:OperationDiffDelete andText:@"b"], [Diff diffWithOperation:OperationDiffEqual andText:@"a"], nil];
  diffs = [dmp diff_cleanupMerge:diffs];
  expectedResult = [NSArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"xca"], [Diff diffWithOperation:OperationDiffDelete andText:@"cba"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Slide edit right recursive.");

}

- (void)test_diff_cleanupSemanticLosslessTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Slide diffs to match logical boundaries.
  // Null case.
  NSArray *diffs = [dmp diff_cleanupSemanticLossless:@[]];
  XCTAssertEqualObjects(@[], diffs, @"Null case.");

  // Blank lines.
  diffs = [NSMutableArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"AAA\r\n\r\nBBB"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"\r\nDDD\r\n\r\nBBB"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"\r\nEEE"], nil];
  diffs = [dmp diff_cleanupSemanticLossless:diffs];
  NSArray *expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"AAA\r\n\r\n"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"BBB\r\nDDD\r\n\r\n"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"BBB\r\nEEE"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Blank lines.");

  // Line boundaries.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"AAA\r\nBBB"],
      [Diff diffWithOperation:OperationDiffInsert andText:@" DDD\r\nBBB"],
      [Diff diffWithOperation:OperationDiffEqual andText:@" EEE"], nil];
  diffs = [dmp diff_cleanupSemanticLossless:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"AAA\r\n"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"BBB DDD\r\n"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"BBB EEE"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Line boundaries.");

  // Word boundaries.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"The c"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"ow and the c"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"at."], nil];
  diffs = [dmp diff_cleanupSemanticLossless:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"The "],
      [Diff diffWithOperation:OperationDiffInsert andText:@"cow and the "],
      [Diff diffWithOperation:OperationDiffEqual andText:@"cat."], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Word boundaries.");

  // Alphanumeric boundaries.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"The-c"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"ow-and-the-c"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"at."], nil];
  diffs = [dmp diff_cleanupSemanticLossless:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"The-"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"cow-and-the-"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"cat."], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Alphanumeric boundaries.");

  // Hitting the start.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"a"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"a"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"ax"], nil];
  diffs = [dmp diff_cleanupSemanticLossless:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"a"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"aax"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Hitting the start.");

  // Hitting the end.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"xa"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"a"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"a"], nil];
  diffs = [dmp diff_cleanupSemanticLossless:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"xaa"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"a"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Hitting the end.");

  // Alphanumeric boundaries.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"The xxx. The "],
      [Diff diffWithOperation:OperationDiffInsert andText:@"zzz. The "],
      [Diff diffWithOperation:OperationDiffEqual andText:@"yyy."], nil];
  diffs = [dmp diff_cleanupSemanticLossless:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"The xxx."],
      [Diff diffWithOperation:OperationDiffInsert andText:@" The zzz."],
      [Diff diffWithOperation:OperationDiffEqual andText:@" The yyy."], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Sentence boundaries.");

}

- (void)test_diff_cleanupSemanticTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Cleanup semantically trivial equalities.
  // Null case.
  NSArray * diffs = [dmp diff_cleanupSemantic:@[]];
  XCTAssertEqualObjects(@[], diffs, @"Null case.");

  // No elimination #1.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"ab"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"cd"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"12"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"e"], nil];
  diffs = [dmp diff_cleanupSemantic:diffs];
  NSArray *expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"ab"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"cd"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"12"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"e"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"No elimination #1.");

  // No elimination #2.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"abc"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"ABC"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"1234"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"wxyz"], nil];
  diffs = [dmp diff_cleanupSemantic:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"abc"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"ABC"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"1234"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"wxyz"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"No elimination #2.");

  // Simple elimination.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"a"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"b"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"c"], nil];
  diffs = [dmp diff_cleanupSemantic:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"abc"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"b"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Simple elimination.");

  // Backpass elimination.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"ab"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"cd"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"e"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"f"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"g"], nil];
  diffs = [dmp diff_cleanupSemantic:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"abcdef"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"cdfg"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Backpass elimination.");

  // Multiple eliminations.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffInsert andText:@"1"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"A"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"B"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"2"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"_"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"1"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"A"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"B"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"2"], nil];
  diffs = [dmp diff_cleanupSemantic:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"AB_AB"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"1A2_1A2"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Multiple eliminations.");

  // Word boundaries.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"The c"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"ow and the c"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"at."], nil];
  diffs = [dmp diff_cleanupSemantic:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"The "],
      [Diff diffWithOperation:OperationDiffDelete andText:@"cow and the "],
      [Diff diffWithOperation:OperationDiffEqual andText:@"cat."], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Word boundaries.");

  // No overlap elimination.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"abcxx"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"xxdef"], nil];
  diffs = [dmp diff_cleanupSemantic:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"abcxx"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"xxdef"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"No overlap elimination.");

  // Overlap elimination.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"abcxxx"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"xxxdef"], nil];
  diffs = [dmp diff_cleanupSemantic:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"abc"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"xxx"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"def"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Overlap elimination.");

  // Reverse overlap elimination.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"xxxabc"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"defxxx"], nil];
  diffs = [dmp diff_cleanupSemantic:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffInsert andText:@"def"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"xxx"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"abc"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Reverse overlap elimination.");

  // Two overlap eliminations.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"abcd1212"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"1212efghi"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"----"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"A3"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"3BC"], nil];
  diffs = [dmp diff_cleanupSemantic:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"abcd"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"1212"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"efghi"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"----"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"A"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"3"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"BC"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Two overlap eliminations.");

}

- (void)test_diff_cleanupEfficiencyTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Cleanup operationally trivial equalities.
  dmp.Diff_EditCost = 4;
  // Null case.
  NSArray *diffs = [dmp diff_cleanupEfficiency:@[]];
  XCTAssertEqualObjects(@[], diffs, @"Null case.");

  // No elimination.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"ab"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"12"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"wxyz"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"cd"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"34"], nil];
  diffs = [dmp diff_cleanupEfficiency:diffs];
  NSArray *expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"ab"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"12"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"wxyz"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"cd"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"34"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"No elimination.");

  // Four-edit elimination.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"ab"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"12"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"xyz"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"cd"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"34"], nil];
  diffs = [dmp diff_cleanupEfficiency:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"abxyzcd"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"12xyz34"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Four-edit elimination.");

  // Three-edit elimination.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffInsert andText:@"12"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"x"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"cd"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"34"], nil];
  diffs = [dmp diff_cleanupEfficiency:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"xcd"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"12x34"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Three-edit elimination.");

  // Backpass elimination.
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"ab"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"12"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"xy"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"34"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"z"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"cd"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"56"], nil];
  diffs = [dmp diff_cleanupEfficiency:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"abxyzcd"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"12xy34z56"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"Backpass elimination.");

  // High cost elimination.
  dmp.Diff_EditCost = 5;
  diffs = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"ab"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"12"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"wxyz"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"cd"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"34"], nil];
  diffs = [dmp diff_cleanupEfficiency:diffs];
  expectedResult = [NSArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"abwxyzcd"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"12wxyz34"], nil];
  XCTAssertEqualObjects(expectedResult, diffs, @"High cost elimination.");
  dmp.Diff_EditCost = 4;

}

- (void)test_diff_prettyHtmlTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Pretty print.
  NSMutableArray *diffs = [NSMutableArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"a\n"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"<B>b</B>"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"c&d"], nil];
  NSString *expectedResult = @"<span>a&para;<br></span><del style=\"background:#ffe6e6;\">&lt;B&gt;b&lt;/B&gt;</del><ins style=\"background:#e6ffe6;\">c&amp;d</ins>";
  XCTAssertEqualObjects(expectedResult, [dmp diff_prettyHtml:diffs], @"Pretty print.");

}

- (void)test_diff_textTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Compute the source and destination texts.
  NSMutableArray *diffs = [NSMutableArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"jump"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"s"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"ed"],
      [Diff diffWithOperation:OperationDiffEqual andText:@" over "],
      [Diff diffWithOperation:OperationDiffDelete andText:@"the"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"a"],
      [Diff diffWithOperation:OperationDiffEqual andText:@" lazy"], nil];
  XCTAssertEqualObjects(@"jumps over the lazy", [dmp diff_text1:diffs], @"Compute the source and destination texts #1");

  XCTAssertEqualObjects(@"jumped over a lazy", [dmp diff_text2:diffs], @"Compute the source and destination texts #2");

}

- (void)test_diff_deltaTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];
  NSArray *expectedResult = nil;
  NSError *error = nil;

  // Convert a diff into delta string.
  NSArray *diffs = [NSMutableArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"jump"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"s"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"ed"],
      [Diff diffWithOperation:OperationDiffEqual andText:@" over "],
      [Diff diffWithOperation:OperationDiffDelete andText:@"the"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"a"],
      [Diff diffWithOperation:OperationDiffEqual andText:@" lazy"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"old dog"], nil];
  NSString *text1 = [dmp diff_text1:diffs];
  XCTAssertEqualObjects(@"jumps over the lazy", text1, @"Convert a diff into delta string 1.");

  NSString *delta = [dmp diff_toDelta:diffs];
  XCTAssertEqualObjects(@"=4\t-1\t+ed\t=6\t-3\t+a\t=5\t+old dog", delta, @"Convert a diff into delta string 2.");

  // Convert delta string into a diff.
  XCTAssertEqualObjects(diffs, [dmp diff_fromDeltaWithText:text1 andDelta:delta error:NULL], @"Convert delta string into a diff.");

  // Generates error (19 < 20).
  diffs = [dmp diff_fromDeltaWithText:[text1 stringByAppendingString:@"x"] andDelta:delta error:&error];
  if (diffs != nil || error == nil) {
    XCTFail(@"diff_fromDelta: Too long.");
  }
  error = nil;

  // Generates error (19 > 18).
  diffs = [dmp diff_fromDeltaWithText:[text1 substringFromIndex:1] andDelta:delta error:&error];
  if (diffs != nil || error == nil) {
    XCTFail(@"diff_fromDelta: Too short.");
  }
  error = nil;

  // Generates error (%c3%xy invalid Unicode).
  diffs = [dmp diff_fromDeltaWithText:@"" andDelta:@"+%c3%xy" error:&error];
  if (diffs != nil || error == nil) {
    XCTFail(@"diff_fromDelta: Invalid character.");
  }
  error = nil;

  // Test deltas with special characters.
  unichar zero = (unichar)0;
  unichar one = (unichar)1;
  unichar two = (unichar)2;
  diffs = [NSMutableArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:[NSString stringWithFormat:@"\U00000680 %C \t %%", zero]],
      [Diff diffWithOperation:OperationDiffDelete andText:[NSString stringWithFormat:@"\U00000681 %C \n ^", one]],
      [Diff diffWithOperation:OperationDiffInsert andText:[NSString stringWithFormat:@"\U00000682 %C \\ |", two]], nil];
  text1 = [dmp diff_text1:diffs];
  NSString *expectedString = [NSString stringWithFormat:@"\U00000680 %C \t %%\U00000681 %C \n ^", zero, one];
  XCTAssertEqualObjects(expectedString, text1, @"Test deltas with special characters.");

  delta = [dmp diff_toDelta:diffs];
  // Upper case, because to CFURLCreateStringByAddingPercentEscapes() uses upper.
  XCTAssertEqualObjects(@"=7\t-7\t+%DA%82 %02 %5C %7C", delta, @"diff_toDelta: Unicode 1.");

  XCTAssertEqualObjects(diffs, [dmp diff_fromDeltaWithText:text1 andDelta:delta error:NULL], @"diff_fromDelta: Unicode 2.");

  // Verify pool of unchanged characters.
  diffs = [NSMutableArray arrayWithObject:
       [Diff diffWithOperation:OperationDiffInsert andText:@"A-Z a-z 0-9 - _ . ! ~ * ' ( ) ; / ? : @ & = + $ , # "]];
  NSString *text2 = [dmp diff_text2:diffs];
  XCTAssertEqualObjects(@"A-Z a-z 0-9 - _ . ! ~ * ' ( ) ; / ? : @ & = + $ , # ", text2, @"diff_text2: Unchanged characters 1.");

  delta = [dmp diff_toDelta:diffs];
  XCTAssertEqualObjects(@"+A-Z a-z 0-9 - _ . ! ~ * ' ( ) ; / ? : @ & = + $ , # ", delta, @"diff_toDelta: Unchanged characters 2.");

  // Convert delta string into a diff.
  expectedResult = [dmp diff_fromDeltaWithText:@"" andDelta:delta error:NULL];
  XCTAssertEqualObjects(diffs, expectedResult, @"diff_fromDelta: Unchanged characters. Convert delta string into a diff.");

}

- (void)test_diff_xIndexTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Translate a location in text1 to text2.
  NSMutableArray *diffs = [NSMutableArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"a"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"1234"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"xyz"], nil] /* Diff */;
  XCTAssertEqual((NSUInteger)5, [dmp diff_xIndexIn:diffs location:2], @"diff_xIndex: Translation on equality. Translate a location in text1 to text2.");

  diffs = [NSMutableArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"a"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"1234"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"xyz"], nil] /* Diff */;
  XCTAssertEqual((NSUInteger)1, [dmp diff_xIndexIn:diffs location:3], @"diff_xIndex: Translation on deletion.");

}

- (void)test_diff_levenshteinTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  NSMutableArray *diffs = [NSMutableArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"abc"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"1234"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"xyz"], nil] /* Diff */;
  XCTAssertEqual((NSUInteger)4, [dmp diff_levenshtein:diffs], @"diff_levenshtein: Levenshtein with trailing equality.");

  diffs = [NSMutableArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"xyz"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"abc"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"1234"], nil] /* Diff */;
  XCTAssertEqual((NSUInteger)4, [dmp diff_levenshtein:diffs], @"diff_levenshtein: Levenshtein with leading equality.");

  diffs = [NSMutableArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"abc"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"xyz"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"1234"], nil] /* Diff */;
  XCTAssertEqual((NSUInteger)7, [dmp diff_levenshtein:diffs], @"diff_levenshtein: Levenshtein with middle equality.");

}

- (void)diff_bisectTest;
{
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Normal.
  NSString *a = @"cat";
  NSString *b = @"map";
  // Since the resulting diff hasn't been normalized, it would be ok if
  // the insertion and deletion pairs are swapped.
  // If the order changes, tweak this test as required.
  NSMutableArray *diffs = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffDelete andText:@"c"], [Diff diffWithOperation:OperationDiffInsert andText:@"m"], [Diff diffWithOperation:OperationDiffEqual andText:@"a"], [Diff diffWithOperation:OperationDiffDelete andText:@"t"], [Diff diffWithOperation:OperationDiffInsert andText:@"p"], nil];
  XCTAssertEqualObjects(diffs, [dmp diff_bisectOfOldString:a andNewString:b deadline:[[NSDate distantFuture] timeIntervalSinceReferenceDate]], @"Bisect test.");

  // Timeout.
  diffs = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffDelete andText:@"cat"], [Diff diffWithOperation:OperationDiffInsert andText:@"map"], nil];
  XCTAssertEqualObjects(diffs, [dmp diff_bisectOfOldString:a andNewString:b deadline:[[NSDate distantPast] timeIntervalSinceReferenceDate]], @"Bisect timeout.");

}

- (void)test_diff_mainTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Perform a trivial diff.
  NSMutableArray *diffs = [NSMutableArray array];
  XCTAssertEqualObjects(diffs, [dmp diff_mainOfOldString:@"" andNewString:@"" checkLines:NO], @"diff_main: Null case.");

  diffs = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"abc"], nil];
  XCTAssertEqualObjects(diffs, [dmp diff_mainOfOldString:@"abc" andNewString:@"abc" checkLines:NO], @"diff_main: Equality.");

  diffs = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"ab"], [Diff diffWithOperation:OperationDiffInsert andText:@"123"], [Diff diffWithOperation:OperationDiffEqual andText:@"c"], nil];
  XCTAssertEqualObjects(diffs, [dmp diff_mainOfOldString:@"abc" andNewString:@"ab123c" checkLines:NO], @"diff_main: Simple insertion.");

  diffs = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"a"], [Diff diffWithOperation:OperationDiffDelete andText:@"123"], [Diff diffWithOperation:OperationDiffEqual andText:@"bc"], nil];
  XCTAssertEqualObjects(diffs, [dmp diff_mainOfOldString:@"a123bc" andNewString:@"abc" checkLines:NO], @"diff_main: Simple deletion.");

  diffs = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"a"], [Diff diffWithOperation:OperationDiffInsert andText:@"123"], [Diff diffWithOperation:OperationDiffEqual andText:@"b"], [Diff diffWithOperation:OperationDiffInsert andText:@"456"], [Diff diffWithOperation:OperationDiffEqual andText:@"c"], nil];
  XCTAssertEqualObjects(diffs, [dmp diff_mainOfOldString:@"abc" andNewString:@"a123b456c" checkLines:NO], @"diff_main: Two insertions.");

  diffs = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffEqual andText:@"a"], [Diff diffWithOperation:OperationDiffDelete andText:@"123"], [Diff diffWithOperation:OperationDiffEqual andText:@"b"], [Diff diffWithOperation:OperationDiffDelete andText:@"456"], [Diff diffWithOperation:OperationDiffEqual andText:@"c"], nil];
  XCTAssertEqualObjects(diffs, [dmp diff_mainOfOldString:@"a123b456c" andNewString:@"abc" checkLines:NO], @"diff_main: Two deletions.");

  // Perform a real diff.
  // Switch off the timeout.
  dmp.Diff_Timeout = 0;
  diffs = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffDelete andText:@"a"], [Diff diffWithOperation:OperationDiffInsert andText:@"b"], nil];
  XCTAssertEqualObjects(diffs, [dmp diff_mainOfOldString:@"a" andNewString:@"b" checkLines:NO], @"diff_main: Simple case #1.");

  diffs = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffDelete andText:@"Apple"], [Diff diffWithOperation:OperationDiffInsert andText:@"Banana"], [Diff diffWithOperation:OperationDiffEqual andText:@"s are a"], [Diff diffWithOperation:OperationDiffInsert andText:@"lso"], [Diff diffWithOperation:OperationDiffEqual andText:@" fruit."], nil];
  XCTAssertEqualObjects(diffs, [dmp diff_mainOfOldString:@"Apples are a fruit." andNewString:@"Bananas are also fruit." checkLines:NO], @"diff_main: Simple case #2.");

  diffs = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffDelete andText:@"a"], [Diff diffWithOperation:OperationDiffInsert andText:@"\U00000680"], [Diff diffWithOperation:OperationDiffEqual andText:@"x"], [Diff diffWithOperation:OperationDiffDelete andText:@"\t"], [Diff diffWithOperation:OperationDiffInsert andText:[NSString stringWithFormat:@"%C", 0]], nil];
  NSString *aString = [NSString stringWithFormat:@"\U00000680x%C", 0];
  XCTAssertEqualObjects(diffs, [dmp diff_mainOfOldString:@"ax\t" andNewString:aString checkLines:NO], @"diff_main: Simple case #3.");

  diffs = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffDelete andText:@"1"], [Diff diffWithOperation:OperationDiffEqual andText:@"a"], [Diff diffWithOperation:OperationDiffDelete andText:@"y"], [Diff diffWithOperation:OperationDiffEqual andText:@"b"], [Diff diffWithOperation:OperationDiffDelete andText:@"2"], [Diff diffWithOperation:OperationDiffInsert andText:@"xab"], nil];
  XCTAssertEqualObjects(diffs, [dmp diff_mainOfOldString:@"1ayb2" andNewString:@"abxab" checkLines:NO], @"diff_main: Overlap #1.");

  diffs = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffInsert andText:@"xaxcx"], [Diff diffWithOperation:OperationDiffEqual andText:@"abc"], [Diff diffWithOperation:OperationDiffDelete andText:@"y"], nil];
  XCTAssertEqualObjects(diffs, [dmp diff_mainOfOldString:@"abcy" andNewString:@"xaxcxabc" checkLines:NO], @"diff_main: Overlap #2.");

  diffs = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffDelete andText:@"ABCD"], [Diff diffWithOperation:OperationDiffEqual andText:@"a"], [Diff diffWithOperation:OperationDiffDelete andText:@"="], [Diff diffWithOperation:OperationDiffInsert andText:@"-"], [Diff diffWithOperation:OperationDiffEqual andText:@"bcd"], [Diff diffWithOperation:OperationDiffDelete andText:@"="], [Diff diffWithOperation:OperationDiffInsert andText:@"-"], [Diff diffWithOperation:OperationDiffEqual andText:@"efghijklmnopqrs"], [Diff diffWithOperation:OperationDiffDelete andText:@"EFGHIJKLMNOefg"], nil];
  XCTAssertEqualObjects(diffs, [dmp diff_mainOfOldString:@"ABCDa=bcd=efghijklmnopqrsEFGHIJKLMNOefg" andNewString:@"a-bcd-efghijklmnopqrs" checkLines:NO], @"diff_main: Overlap #3.");

  diffs = [NSMutableArray arrayWithObjects:[Diff diffWithOperation:OperationDiffInsert andText:@" "], [Diff diffWithOperation:OperationDiffEqual andText:@"a"], [Diff diffWithOperation:OperationDiffInsert andText:@"nd"], [Diff diffWithOperation:OperationDiffEqual andText:@" [[Pennsylvania]]"], [Diff diffWithOperation:OperationDiffDelete andText:@" and [[New"], nil];
  XCTAssertEqualObjects(diffs, [dmp diff_mainOfOldString:@"a [[Pennsylvania]] and [[New" andNewString:@" and [[Pennsylvania]]" checkLines:NO], @"diff_main: Large equality.");

  dmp.Diff_Timeout = 0.1f;  // 100ms
  NSString *a = @"`Twas brillig, and the slithy toves\nDid gyre and gimble in the wabe:\nAll mimsy were the borogoves,\nAnd the mome raths outgrabe.\n";
  NSString *b = @"I am the very model of a modern major general,\nI've information vegetable, animal, and mineral,\nI know the kings of England, and I quote the fights historical,\nFrom Marathon to Waterloo, in order categorical.\n";
  NSMutableString *aMutable = [NSMutableString stringWithString:a];
  NSMutableString *bMutable = [NSMutableString stringWithString:b];
  // Increase the text lengths by 1024 times to ensure a timeout.
  for (int x = 0; x < 10; x++) {
    [aMutable appendString:aMutable];
    [bMutable appendString:bMutable];
  }
  a = aMutable;
  b = bMutable;
  NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
  [dmp diff_mainOfOldString:a andNewString:b];
  NSTimeInterval endTime = [NSDate timeIntervalSinceReferenceDate];
  // Test that we took at least the timeout period.
  XCTAssertTrue((dmp.Diff_Timeout <= (endTime - startTime)), @"Test that we took at least the timeout period.");
   // Test that we didn't take forever (be forgiving).
   // Theoretically this test could fail very occasionally if the
   // OS task swaps or locks up for a second at the wrong moment.
   // This will fail when running this as PPC code thru Rosetta on Intel.
    // commented out as it failed randomly on travis
//  XCTAssertTrue(((dmp.Diff_Timeout * 2) > (endTime - startTime)), @"Test that we didn't take forever (be forgiving). dmp.Diff_Timeout = %f, (endTime - startTime) = %f", dmp.Diff_Timeout, (endTime - startTime));
  dmp.Diff_Timeout = 0;

  // Test the linemode speedup.
  // Must be long to pass the 200 character cutoff.
  a = @"1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n";
  b = @"abcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\n";
  XCTAssertEqualObjects([dmp diff_mainOfOldString:a andNewString:b checkLines:YES], [dmp diff_mainOfOldString:a andNewString:b checkLines:NO], @"diff_main: Simple line-mode.");

  a = @"1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890";
  b = @"abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij";
  XCTAssertEqualObjects([dmp diff_mainOfOldString:a andNewString:b checkLines:YES], [dmp diff_mainOfOldString:a andNewString:b checkLines:NO], @"diff_main: Single line-mode.");

  a = @"1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n";
  b = @"abcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n";
  NSArray *texts_linemode = [self diff_rebuildtexts:[dmp diff_mainOfOldString:a andNewString:b checkLines:YES]];
  NSArray *texts_textmode = [self diff_rebuildtexts:[dmp diff_mainOfOldString:a andNewString:b checkLines:NO]];
  XCTAssertEqualObjects(texts_textmode, texts_linemode, @"diff_main: Overlap line-mode.");

  // CHANGEME: Test null inputs

}


#pragma mark Match Test Functions
//  MATCH TEST FUNCTIONS


- (void)test_match_alphabetTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Initialise the bitmasks for Bitap.
  NSMutableDictionary *bitmask = [NSMutableDictionary dictionary];

  [bitmask diff_setUnsignedIntegerValue:4 forUnicharKey:'a'];
  [bitmask diff_setUnsignedIntegerValue:2 forUnicharKey:'b'];
  [bitmask diff_setUnsignedIntegerValue:1 forUnicharKey:'c'];
  XCTAssertEqualObjects(bitmask, [dmp match_alphabet:@"abc"], @"match_alphabet: Unique.");

  [bitmask removeAllObjects];
  [bitmask diff_setUnsignedIntegerValue:37 forUnicharKey:'a'];
  [bitmask diff_setUnsignedIntegerValue:18 forUnicharKey:'b'];
  [bitmask diff_setUnsignedIntegerValue:8 forUnicharKey:'c'];
  XCTAssertEqualObjects(bitmask, [dmp match_alphabet:@"abcaba"], @"match_alphabet: Duplicates.");

}

- (void)test_match_bitapTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Bitap algorithm.
  dmp.Match_Distance = 100;
  dmp.Match_Threshold = 0.5f;
  XCTAssertEqual((NSUInteger)5, [dmp match_bitapOfText:@"abcdefghijk" andPattern:@"fgh" near:5], @"match_bitap: Exact match #1.");

  XCTAssertEqual((NSUInteger)5, [dmp match_bitapOfText:@"abcdefghijk" andPattern:@"fgh" near:0], @"match_bitap: Exact match #2.");

  XCTAssertEqual((NSUInteger)4, [dmp match_bitapOfText:@"abcdefghijk" andPattern:@"efxhi" near:0], @"match_bitap: Fuzzy match #1.");

  XCTAssertEqual((NSUInteger)2, [dmp match_bitapOfText:@"abcdefghijk" andPattern:@"cdefxyhijk" near:5], @"match_bitap: Fuzzy match #2.");

  XCTAssertEqual((NSUInteger)NSNotFound, [dmp match_bitapOfText:@"abcdefghijk" andPattern:@"bxy" near:1], @"match_bitap: Fuzzy match #3.");

  XCTAssertEqual((NSUInteger)2, [dmp match_bitapOfText:@"123456789xx0" andPattern:@"3456789x0" near:2], @"match_bitap: Overflow.");

  XCTAssertEqual((NSUInteger)0, [dmp match_bitapOfText:@"abcdef" andPattern:@"xxabc" near:4], @"match_bitap: Before start match.");

  XCTAssertEqual((NSUInteger)3, [dmp match_bitapOfText:@"abcdef" andPattern:@"defyy" near:4], @"match_bitap: Beyond end match.");

  XCTAssertEqual((NSUInteger)0, [dmp match_bitapOfText:@"abcdef" andPattern:@"xabcdefy" near:0], @"match_bitap: Oversized pattern.");

  dmp.Match_Threshold = 0.4f;
  XCTAssertEqual((NSUInteger)4, [dmp match_bitapOfText:@"abcdefghijk" andPattern:@"efxyhi" near:1], @"match_bitap: Threshold #1.");

  dmp.Match_Threshold = 0.3f;
  XCTAssertEqual((NSUInteger)NSNotFound, [dmp match_bitapOfText:@"abcdefghijk" andPattern:@"efxyhi" near:1], @"match_bitap: Threshold #2.");

  dmp.Match_Threshold = 0.0f;
  XCTAssertEqual((NSUInteger)1, [dmp match_bitapOfText:@"abcdefghijk" andPattern:@"bcdef" near:1], @"match_bitap: Threshold #3.");

  dmp.Match_Threshold = 0.5f;
  XCTAssertEqual((NSUInteger)0, [dmp match_bitapOfText:@"abcdexyzabcde" andPattern:@"abccde" near:3], @"match_bitap: Multiple select #1.");

  XCTAssertEqual((NSUInteger)8, [dmp match_bitapOfText:@"abcdexyzabcde" andPattern:@"abccde" near:5], @"match_bitap: Multiple select #2.");

  dmp.Match_Distance = 10;  // Strict location.
  XCTAssertEqual((NSUInteger)NSNotFound, [dmp match_bitapOfText:@"abcdefghijklmnopqrstuvwxyz" andPattern:@"abcdefg" near:24], @"match_bitap: Distance test #1.");

  XCTAssertEqual((NSUInteger)0, [dmp match_bitapOfText:@"abcdefghijklmnopqrstuvwxyz" andPattern:@"abcdxxefg" near:1], @"match_bitap: Distance test #2.");

  dmp.Match_Distance = 1000;  // Loose location.
  XCTAssertEqual((NSUInteger)0, [dmp match_bitapOfText:@"abcdefghijklmnopqrstuvwxyz" andPattern:@"abcdefg" near:24], @"match_bitap: Distance test #3.");

}

- (void)test_match_mainTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  // Full match.
  XCTAssertEqual((NSUInteger)0, [dmp match_mainForText:@"abcdef" pattern:@"abcdef" near:1000], @"match_main: Equality.");

  XCTAssertEqual((NSUInteger)NSNotFound, [dmp match_mainForText:@"" pattern:@"abcdef" near:1], @"match_main: Null text.");

  XCTAssertEqual((NSUInteger)3, [dmp match_mainForText:@"abcdef" pattern:@"" near:3], @"match_main: Null pattern.");

  XCTAssertEqual((NSUInteger)3, [dmp match_mainForText:@"abcdef" pattern:@"de" near:3], @"match_main: Exact match.");

  XCTAssertEqual((NSUInteger)3, [dmp match_mainForText:@"abcdef" pattern:@"defy" near:4], @"match_main: Beyond end match.");

  XCTAssertEqual((NSUInteger)0, [dmp match_mainForText:@"abcdef" pattern:@"abcdefy" near:0], @"match_main: Oversized pattern.");

  dmp.Match_Threshold = 0.7f;
  XCTAssertEqual((NSUInteger)4, [dmp match_mainForText:@"I am the very model of a modern major general." pattern:@" that berry " near:5], @"match_main: Complex match.");
  dmp.Match_Threshold = 0.5f;

  // CHANGEME: Test null inputs

}


#pragma mark Patch Test Functions
//  PATCH TEST FUNCTIONS


- (void)test_patch_patchObjTest {
  // Patch Object.
  Patch *p = [Patch new];
  p.start1 = 20;
  p.start2 = 21;
  p.length1 = 18;
  p.length2 = 17;
  p.diffs = [NSMutableArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffEqual andText:@"jump"],
      [Diff diffWithOperation:OperationDiffDelete andText:@"s"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"ed"],
      [Diff diffWithOperation:OperationDiffEqual andText:@" over "],
      [Diff diffWithOperation:OperationDiffDelete andText:@"the"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"a"],
      [Diff diffWithOperation:OperationDiffEqual andText:@"\nlaz"], nil];
  NSString *strp = @"@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n %0Alaz\n";
  XCTAssertEqualObjects(strp, [p description], @"Patch: description.");
}

- (void)test_patch_fromTextTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  XCTAssertTrue(((NSMutableArray *)[dmp patch_fromText:@"" error:NULL]).count == 0, @"patch_fromText: #0.");

  NSString *strp = @"@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n %0Alaz\n";
  XCTAssertEqualObjects(strp, [[dmp patch_fromText:strp error:NULL][0] description], @"patch_fromText: #1.");

  XCTAssertEqualObjects(@"@@ -1 +1 @@\n-a\n+b\n", [[dmp patch_fromText:@"@@ -1 +1 @@\n-a\n+b\n" error:NULL][0] description], @"patch_fromText: #2.");

  XCTAssertEqualObjects(@"@@ -1,3 +0,0 @@\n-abc\n", [[dmp patch_fromText:@"@@ -1,3 +0,0 @@\n-abc\n" error:NULL][0] description], @"patch_fromText: #3.");

  XCTAssertEqualObjects(@"@@ -0,0 +1,3 @@\n+abc\n", [[dmp patch_fromText:@"@@ -0,0 +1,3 @@\n+abc\n" error:NULL][0] description], @"patch_fromText: #4.");

  // Generates error.
  NSError *error = nil;
  NSArray *patches = [dmp patch_fromText:@"Bad\nPatch\n" error:&error];
  if (patches != nil || error == nil) {
    // Error expected.
    XCTFail(@"patch_fromText: #5.");
  }
  error = nil;

}

- (void)test_patch_toTextTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  NSString *strp = @"@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n  laz\n";
  NSArray *patches = [dmp patch_fromText:strp error:NULL];
  XCTAssertEqualObjects(strp, [dmp patch_toText:patches], @"toText Test #1");

  strp = @"@@ -1,9 +1,9 @@\n-f\n+F\n oo+fooba\n@@ -7,9 +7,9 @@\n obar\n-,\n+.\n  tes\n";
  patches = [dmp patch_fromText:strp error:NULL];
  XCTAssertEqualObjects(strp, [dmp patch_toText:patches], @"toText Test #2");

}

- (void)test_patch_addContextTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  dmp.Patch_Margin = 4;
  Patch *p;
  p = [dmp patch_fromText:@"@@ -21,4 +21,10 @@\n-jump\n+somersault\n" error:NULL][0];
  [dmp patch_addContextToPatch:p sourceText:@"The quick brown fox jumps over the lazy dog."];
  XCTAssertEqualObjects(@"@@ -17,12 +17,18 @@\n fox \n-jump\n+somersault\n s ov\n", [p description], @"patch_addContext: Simple case.");

  p = [dmp patch_fromText:@"@@ -21,4 +21,10 @@\n-jump\n+somersault\n" error:NULL][0];
  [dmp patch_addContextToPatch:p sourceText:@"The quick brown fox jumps."];
  XCTAssertEqualObjects(@"@@ -17,10 +17,16 @@\n fox \n-jump\n+somersault\n s.\n", [p description], @"patch_addContext: Not enough trailing context.");

  p = [dmp patch_fromText:@"@@ -3 +3,2 @@\n-e\n+at\n" error:NULL][0];
  [dmp patch_addContextToPatch:p sourceText:@"The quick brown fox jumps."];
  XCTAssertEqualObjects(@"@@ -1,7 +1,8 @@\n Th\n-e\n+at\n  qui\n", [p description], @"patch_addContext: Not enough leading context.");

  p = [dmp patch_fromText:@"@@ -3 +3,2 @@\n-e\n+at\n" error:NULL][0];
  [dmp patch_addContextToPatch:p sourceText:@"The quick brown fox jumps.  The quick brown fox crashes."];
  XCTAssertEqualObjects(@"@@ -1,27 +1,28 @@\n Th\n-e\n+at\n  quick brown fox jumps. \n", [p description], @"patch_addContext: Ambiguity.");

}

- (void)test_patch_makeTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  NSArray *patches = [dmp patch_makeFromOldString:@"" andNewString:@""];
  XCTAssertEqualObjects(@"", [dmp patch_toText:patches], @"patch_make: Null case.");

  NSString *text1 = @"The quick brown fox jumps over the lazy dog.";
  NSString *text2 = @"That quick brown fox jumped over a lazy dog.";
  NSString *expectedPatch = @"@@ -1,8 +1,7 @@\n Th\n-at\n+e\n  qui\n@@ -21,17 +21,18 @@\n jump\n-ed\n+s\n  over \n-a\n+the\n  laz\n";
  // The second patch must be @"-21,17 +21,18", not @"-22,17 +21,18" due to rolling context.
  patches = [dmp patch_makeFromOldString:text2 andNewString:text1];
  XCTAssertEqualObjects(expectedPatch, [dmp patch_toText:patches], @"patch_make: Text2+Text1 inputs.");

  expectedPatch = @"@@ -1,11 +1,12 @@\n Th\n-e\n+at\n  quick b\n@@ -22,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n  laz\n";
  patches = [dmp patch_makeFromOldString:text1 andNewString:text2];
  XCTAssertEqualObjects(expectedPatch, [dmp patch_toText:patches], @"patch_make: Text1+Text2 inputs.");

  NSArray *diffs = [dmp diff_mainOfOldString:text1 andNewString:text2 checkLines:NO];
  patches = [dmp patch_makeFromDiffs:diffs];
  XCTAssertEqualObjects(expectedPatch, [dmp patch_toText:patches], @"patch_make: Diff input.");

  patches = [dmp patch_makeFromOldString:text1 andDiffs:diffs];
  XCTAssertEqualObjects(expectedPatch, [dmp patch_toText:patches], @"patch_make: Text1+Diff inputs.");

  patches = [dmp patch_makeFromOldString:text1 newString:text2 diffs:diffs];
  XCTAssertEqualObjects(expectedPatch, [dmp patch_toText:patches], @"patch_make: Text1+Text2+Diff inputs (deprecated).");

  patches = [dmp patch_makeFromOldString:@"`1234567890-=[]\\;',./" andNewString:@"~!@#$%^&*()_+{}|:\"<>?"];
  XCTAssertEqualObjects(@"@@ -1,21 +1,21 @@\n-%601234567890-=%5B%5D%5C;',./\n+~!@#$%25%5E&*()_+%7B%7D%7C:%22%3C%3E?\n",
      [dmp patch_toText:patches],
      @"patch_toText: Character encoding.");

  diffs = [NSMutableArray arrayWithObjects:
      [Diff diffWithOperation:OperationDiffDelete andText:@"`1234567890-=[]\\;',./"],
      [Diff diffWithOperation:OperationDiffInsert andText:@"~!@#$%^&*()_+{}|:\"<>?"], nil];
  XCTAssertEqualObjects(diffs,
      ((Patch *)[dmp patch_fromText:@"@@ -1,21 +1,21 @@\n-%601234567890-=%5B%5D%5C;',./\n+~!@#$%25%5E&*()_+%7B%7D%7C:%22%3C%3E?\n" error:NULL][0]).diffs,
      @"patch_fromText: Character decoding.");

  NSMutableString *text1Mutable = [NSMutableString string];
  for (int x = 0; x < 100; x++) {
    [text1Mutable appendString:@"abcdef"];
  }
  text1 = text1Mutable;
  text2 = [text1 stringByAppendingString:@"123"];
  // CHANGEME: Why does this implementation produce a different, more brief patch?
  //expectedPatch = @"@@ -573,28 +573,31 @@\n cdefabcdefabcdefabcdefabcdef\n+123\n";
  expectedPatch = @"@@ -597,4 +597,7 @@\n cdef\n+123\n";
  patches = [dmp patch_makeFromOldString:text1 andNewString:text2];
  XCTAssertEqualObjects(expectedPatch, [dmp patch_toText:patches], @"patch_make: Long string with repeats.");

  // CHANGEME: Test null inputs

}


- (void)test_patch_splitMaxTest {
  // Assumes that Match_MaxBits is 32.
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  NSArray *patches = [dmp patch_makeFromOldString:@"abcdefghijklmnopqrstuvwxyz01234567890" andNewString:@"XabXcdXefXghXijXklXmnXopXqrXstXuvXwxXyzX01X23X45X67X89X0"];
  patches = [dmp patch_splitMax:patches];
  XCTAssertEqualObjects(@"@@ -1,32 +1,46 @@\n+X\n ab\n+X\n cd\n+X\n ef\n+X\n gh\n+X\n ij\n+X\n kl\n+X\n mn\n+X\n op\n+X\n qr\n+X\n st\n+X\n uv\n+X\n wx\n+X\n yz\n+X\n 012345\n@@ -25,13 +39,18 @@\n zX01\n+X\n 23\n+X\n 45\n+X\n 67\n+X\n 89\n+X\n 0\n", [dmp patch_toText:patches], @"Assumes that Match_MaxBits is 32 #1");

  patches = [dmp patch_makeFromOldString:@"abcdef1234567890123456789012345678901234567890123456789012345678901234567890uvwxyz" andNewString:@"abcdefuvwxyz"];
  NSString *oldToText = [dmp patch_toText:patches];
  patches = [dmp patch_splitMax:patches];
  XCTAssertEqualObjects(oldToText, [dmp patch_toText:patches], @"Assumes that Match_MaxBits is 32 #2");

  patches = [dmp patch_makeFromOldString:@"1234567890123456789012345678901234567890123456789012345678901234567890" andNewString:@"abc"];
  patches = [dmp patch_splitMax:patches];
  XCTAssertEqualObjects(@"@@ -1,32 +1,4 @@\n-1234567890123456789012345678\n 9012\n@@ -29,32 +1,4 @@\n-9012345678901234567890123456\n 7890\n@@ -57,14 +1,3 @@\n-78901234567890\n+abc\n", [dmp patch_toText:patches], @"Assumes that Match_MaxBits is 32 #3");

  patches = [dmp patch_makeFromOldString:@"abcdefghij , h : 0 , t : 1 abcdefghij , h : 0 , t : 1 abcdefghij , h : 0 , t : 1" andNewString:@"abcdefghij , h : 1 , t : 1 abcdefghij , h : 1 , t : 1 abcdefghij , h : 0 , t : 1"];
  patches = [dmp patch_splitMax:patches];
  XCTAssertEqualObjects(@"@@ -2,32 +2,32 @@\n bcdefghij , h : \n-0\n+1\n  , t : 1 abcdef\n@@ -29,32 +29,32 @@\n bcdefghij , h : \n-0\n+1\n  , t : 1 abcdef\n", [dmp patch_toText:patches], @"Assumes that Match_MaxBits is 32 #4");

}

- (void)test_patch_addPaddingTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  NSArray *patches = [dmp patch_makeFromOldString:@"" andNewString:@"test"];
  XCTAssertEqualObjects(@"@@ -0,0 +1,4 @@\n+test\n",
      [dmp patch_toText:patches],
      @"patch_addPadding: Both edges full.");
  [dmp patch_addPadding:patches];
  XCTAssertEqualObjects(@"@@ -1,8 +1,12 @@\n %01%02%03%04\n+test\n %01%02%03%04\n",
      [dmp patch_toText:patches],
      @"patch_addPadding: Both edges full.");

  patches = [dmp patch_makeFromOldString:@"XY" andNewString:@"XtestY"];
  XCTAssertEqualObjects(@"@@ -1,2 +1,6 @@\n X\n+test\n Y\n",
      [dmp patch_toText:patches],
      @"patch_addPadding: Both edges partial.");
  [dmp patch_addPadding:patches];
  XCTAssertEqualObjects(@"@@ -2,8 +2,12 @@\n %02%03%04X\n+test\n Y%01%02%03\n",
      [dmp patch_toText:patches],
      @"patch_addPadding: Both edges partial.");

  patches = [dmp patch_makeFromOldString:@"XXXXYYYY" andNewString:@"XXXXtestYYYY"];
  XCTAssertEqualObjects(@"@@ -1,8 +1,12 @@\n XXXX\n+test\n YYYY\n",
      [dmp patch_toText:patches],
      @"patch_addPadding: Both edges none.");
  [dmp patch_addPadding:patches];
  XCTAssertEqualObjects(@"@@ -5,8 +5,12 @@\n XXXX\n+test\n YYYY\n",
      [dmp patch_toText:patches],
      @"patch_addPadding: Both edges none.");

}

- (void)test_patch_applyTest {
  DiffMatchPatch *dmp = [DiffMatchPatch new];

  dmp.Match_Distance = 1000;
  dmp.Match_Threshold = 0.5f;
  dmp.Patch_DeleteThreshold = 0.5f;

  NSArray *patches = [dmp patch_makeFromOldString:@"" andNewString:@""];
  NSArray *results = [dmp patch_apply:patches toString:@"Hello world."];
  NSMutableArray *boolArray = results[1];
  NSString *resultStr = [NSString stringWithFormat:@"%@\t%lu", results[0], (unsigned long)boolArray.count];
  XCTAssertEqualObjects(@"Hello world.\t0", resultStr, @"patch_apply: Null case.");

  patches = [dmp patch_makeFromOldString:@"The quick brown fox jumps over the lazy dog." andNewString:@"That quick brown fox jumped over a lazy dog."];
  results = [dmp patch_apply:patches toString:@"The quick brown fox jumps over the lazy dog."];
  boolArray = results[1];
  resultStr = [NSString stringWithFormat:@"%@\t%@\t%@", results[0], stringForBOOL(boolArray[0]), stringForBOOL(boolArray[1])];
  XCTAssertEqualObjects(@"That quick brown fox jumped over a lazy dog.\ttrue\ttrue", resultStr, @"patch_apply: Exact match.");

  results = [dmp patch_apply:patches toString:@"The quick red rabbit jumps over the tired tiger."];
  boolArray = results[1];
  resultStr = [NSString stringWithFormat:@"%@\t%@\t%@", results[0], stringForBOOL(boolArray[0]), stringForBOOL(boolArray[1])];
  XCTAssertEqualObjects(@"That quick red rabbit jumped over a tired tiger.\ttrue\ttrue", resultStr, @"patch_apply: Partial match.");

  results = [dmp patch_apply:patches toString:@"I am the very model of a modern major general."];
  boolArray = results[1];
  resultStr = [NSString stringWithFormat:@"%@\t%@\t%@", results[0], stringForBOOL(boolArray[0]), stringForBOOL(boolArray[1])];
  XCTAssertEqualObjects(@"I am the very model of a modern major general.\tfalse\tfalse", resultStr, @"patch_apply: Failed match.");

  patches = [dmp patch_makeFromOldString:@"x1234567890123456789012345678901234567890123456789012345678901234567890y" andNewString:@"xabcy"];
  results = [dmp patch_apply:patches toString:@"x123456789012345678901234567890-----++++++++++-----123456789012345678901234567890y"];
  boolArray = results[1];
  resultStr = [NSString stringWithFormat:@"%@\t%@\t%@", results[0], stringForBOOL(boolArray[0]), stringForBOOL(boolArray[1])];
  XCTAssertEqualObjects(@"xabcy\ttrue\ttrue", resultStr, @"patch_apply: Big delete, small change.");

  patches = [dmp patch_makeFromOldString:@"x1234567890123456789012345678901234567890123456789012345678901234567890y" andNewString:@"xabcy"];
  results = [dmp patch_apply:patches toString:@"x12345678901234567890---------------++++++++++---------------12345678901234567890y"];
  boolArray = results[1];
  resultStr = [NSString stringWithFormat:@"%@\t%@\t%@", results[0], stringForBOOL(boolArray[0]), stringForBOOL(boolArray[1])];
  XCTAssertEqualObjects(@"xabc12345678901234567890---------------++++++++++---------------12345678901234567890y\tfalse\ttrue", resultStr, @"patch_apply: Big delete, big change 1.");

  dmp.Patch_DeleteThreshold = 0.6f;
  patches = [dmp patch_makeFromOldString:@"x1234567890123456789012345678901234567890123456789012345678901234567890y" andNewString:@"xabcy"];
  results = [dmp patch_apply:patches toString:@"x12345678901234567890---------------++++++++++---------------12345678901234567890y"];
  boolArray = results[1];
  resultStr = [NSString stringWithFormat:@"%@\t%@\t%@", results[0], stringForBOOL(boolArray[0]), stringForBOOL(boolArray[1])];
  XCTAssertEqualObjects(@"xabcy\ttrue\ttrue", resultStr, @"patch_apply: Big delete, big change 2.");
  dmp.Patch_DeleteThreshold = 0.5f;

  dmp.Match_Threshold = 0.0f;
  dmp.Match_Distance = 0;
  patches = [dmp patch_makeFromOldString:@"abcdefghijklmnopqrstuvwxyz--------------------1234567890" andNewString:@"abcXXXXXXXXXXdefghijklmnopqrstuvwxyz--------------------1234567YYYYYYYYYY890"];
  results = [dmp patch_apply:patches toString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ--------------------1234567890"];
  boolArray = results[1];
  resultStr = [NSString stringWithFormat:@"%@\t%@\t%@", results[0], stringForBOOL(boolArray[0]), stringForBOOL(boolArray[1])];
  XCTAssertEqualObjects(@"ABCDEFGHIJKLMNOPQRSTUVWXYZ--------------------1234567YYYYYYYYYY890\tfalse\ttrue", resultStr, @"patch_apply: Compensate for failed patch.");
  dmp.Match_Threshold = 0.5f;
  dmp.Match_Distance = 1000;

  patches = [dmp patch_makeFromOldString:@"" andNewString:@"test"];
  NSString *patchStr = [dmp patch_toText:patches];
  [dmp patch_apply:patches toString:@""];
  XCTAssertEqualObjects(patchStr, [dmp patch_toText:patches], @"patch_apply: No side effects.");

  patches = [dmp patch_makeFromOldString:@"The quick brown fox jumps over the lazy dog." andNewString:@"Woof"];
  patchStr = [dmp patch_toText:patches];
  [dmp patch_apply:patches toString:@"The quick brown fox jumps over the lazy dog."];
  XCTAssertEqualObjects(patchStr, [dmp patch_toText:patches], @"patch_apply: No side effects with major delete.");

  patches = [dmp patch_makeFromOldString:@"" andNewString:@"test"];
  results = [dmp patch_apply:patches toString:@""];
  boolArray = results[1];
  resultStr = [NSString stringWithFormat:@"%@\t%@", results[0], stringForBOOL(boolArray[0])];
  XCTAssertEqualObjects(@"test\ttrue", resultStr, @"patch_apply: Edge exact match.");

  patches = [dmp patch_makeFromOldString:@"XY" andNewString:@"XtestY"];
  results = [dmp patch_apply:patches toString:@"XY"];
  boolArray = results[1];
  resultStr = [NSString stringWithFormat:@"%@\t%@", results[0], stringForBOOL(boolArray[0])];
  XCTAssertEqualObjects(@"XtestY\ttrue", resultStr, @"patch_apply: Near edge exact match.");

  patches = [dmp patch_makeFromOldString:@"y" andNewString:@"y123"];
  results = [dmp patch_apply:patches toString:@"x"];
  boolArray = results[1];
  resultStr = [NSString stringWithFormat:@"%@\t%@", results[0], stringForBOOL(boolArray[0])];
  XCTAssertEqualObjects(@"x123\ttrue", resultStr, @"patch_apply: Edge partial match.");

}


#pragma mark Test Utility Functions
//  TEST UTILITY FUNCTIONS


- (NSArray *)diff_rebuildtexts:(NSArray *)diffs;
{
  NSArray *text = [NSMutableArray arrayWithObjects:[NSMutableString string], [NSMutableString string], nil];
  for (Diff *myDiff in diffs) {
    if (myDiff.operation != OperationDiffInsert) {
      [text[0] appendString:myDiff.text];
    }
    if (myDiff.operation != OperationDiffDelete) {
      [text[1] appendString:myDiff.text];
    }
  }
  return text;
}

@end
