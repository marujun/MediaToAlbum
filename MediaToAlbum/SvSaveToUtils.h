//
//  SvSaveToUtils.h
//  MediaToAlbum
//
//  Created by 马汝军 on 15/9/18.
//  Copyright © 2015年 marujun. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SvSaveToDelegate <NSObject>

- (void)saveToUtilStartCopy:(NSInteger)itemCount;

/*
 * @brief invoke each media item copied
 */
- (void)mediaItemCopiedIsSuccess:(BOOL)success;


- (void)savetoUtilCopyFinished;

@end


@interface SvSaveToUtils : NSObject

@property (nonatomic, assign) id<SvSaveToDelegate> delegate;

/*
 * @brief method to save all media item to camera roll
 */
- (void)saveMediaToCameraRoll;

@end

