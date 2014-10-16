//
//  RUDiskImageFetchingController.h
//  VibeWithIt
//
//  Created by Benjamin Maer on 10/15/14.
//  Copyright (c) 2014 VibeWithIt. All rights reserved.
//

#import <Foundation/Foundation.h>





typedef NS_ENUM(NSInteger, RUDiskImageFetchingController_FetchedSourceType) {
	RUDiskImageFetchingController_FetchedSourceType_None = 0,

	RUDiskImageFetchingController_FetchedSourceType_Disk = 100,
	RUDiskImageFetchingController_FetchedSourceType_Cache,
};





typedef void(^RUDiskImageFetchingController_QueryCompletedBlock)(UIImage *image, RUDiskImageFetchingController_FetchedSourceType fetchedSourceType);





@interface RUDiskImageFetchingController : NSObject

-(NSOperation*)fetchImageFromDiskWithPath:(NSString*)path completion:(RUDiskImageFetchingController_QueryCompletedBlock)completion;

+(instancetype)sharedInstance;

@end