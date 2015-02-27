//
//  UIView+RUSnapshot.m
//  Pineapple
//
//  Created by Benjamin Maer on 5/16/14.
//  Copyright (c) 2014 Pineapple. All rights reserved.
//

#import "UIView+RUSnapshot.h"





@implementation UIView (RUSnapshot)

-(UIImage*)ruGetSnapshotFromWindow
{
	return [self.window ruGetSnapshot];
}

-(UIImage*)ruGetSnapshot
{
	UIView* viewToMakeImage = self;
	
	UIGraphicsBeginImageContextWithOptions(viewToMakeImage.bounds.size, viewToMakeImage.opaque, 0.0f);
	
	if ([viewToMakeImage respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)])
	{
		[viewToMakeImage drawViewHierarchyInRect:viewToMakeImage.bounds afterScreenUpdates:NO];
	}
	else
	{
		[viewToMakeImage.layer renderInContext:UIGraphicsGetCurrentContext()];
	}
	
    UIImage* snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

	return snapshotImage;
}

@end
