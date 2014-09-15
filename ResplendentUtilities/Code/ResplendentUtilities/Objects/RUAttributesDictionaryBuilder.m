//
//  RUAttributesDictionaryBuilder.m
//  Qude
//
//  Created by Benjamin Maer on 8/5/14.
//  Copyright (c) 2014 QudeLLC. All rights reserved.
//

#import "RUAttributesDictionaryBuilder.h"
#import "NSMutableDictionary+RUUtil.h"





@implementation RUAttributesDictionaryBuilder

#pragma mark - Absorb
-(void)absorbPropertiesFromLabel:(UILabel*)label
{
	[self setFont:label.font];
	[self setLineBreakMode:label.lineBreakMode];
}

-(void)absorbPropertiesFromButton:(UIButton*)button
{
	[self absorbPropertiesFromLabel:button.titleLabel];
}

#pragma mark - Create Attributes Dictionary
-(NSDictionary*)createAttributesDictionary
{
	NSMutableDictionary* attributesDictionary = [NSMutableDictionary dictionary];

	[attributesDictionary setObjectOrRemoveIfNil:self.font forKey:NSFontAttributeName];

	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[style setLineBreakMode:self.lineBreakMode];

	if (self.lineSpacing)
	{
		[style setLineSpacing:self.lineSpacing.floatValue];
	}

	[attributesDictionary setObjectOrRemoveIfNil:style forKey:NSParagraphStyleAttributeName];
	
	return [attributesDictionary copy];
}

/*
 NSInteger strLength = [myString length];
 NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
 [style setLineSpacing:24];
 [attString addAttribute:NSParagraphStyleAttributeName
 value:style
 range:NSMakeRange(0, strLength)];
 */
@end