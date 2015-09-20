//
//  SvSaveToUtils.m
//  MediaToAlbum
//
//  Created by 马汝军 on 15/9/18.
//  Copyright © 2015年 marujun. All rights reserved.
//

#import "SvSaveToUtils.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface SvSaveToUtils () {
    NSInteger   _mediaItemCount;        // the count of all media item wait to save
    NSMutableArray *picArray;
    NSMutableArray *videoArray;
    ALAssetsLibrary *assetsLibrary;
}

@end


@implementation SvSaveToUtils

@synthesize delegate;

- (id)init
{
    self = [super init];
    if (self) {
        delegate = nil;
    }
    
    return self;
}

- (void)saveMediaToCameraRoll
{
    // // traverse the main bundle to find out all image files
    picArray = [NSMutableArray arrayWithCapacity:3];
    
    NSArray *jpgFiles = [[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:nil];
    [picArray addObjectsFromArray:jpgFiles];
    
    jpgFiles = [[NSBundle mainBundle] pathsForResourcesOfType:@"JPG" inDirectory:nil];
    [picArray addObjectsFromArray:jpgFiles];
    
    NSArray *pngArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"png" inDirectory:nil];
    [picArray addObjectsFromArray:pngArray];
    
    pngArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"PNG" inDirectory:nil];
    [picArray addObjectsFromArray:pngArray];
    
    // exclude launch image of this project
    NSMutableArray *picExcludeDefault = [NSMutableArray arrayWithArray:picArray];
    for (NSString *path in picArray) {
        NSArray *pathCom = [path pathComponents];
        if ([pathCom containsObject:@"Default-568h@2x.png"]
            || [pathCom containsObject:@"Default.png"]
            || [pathCom containsObject:@"Default@2x.png"]) {
            [picExcludeDefault removeObject:path];
        }
    }
    picArray = picExcludeDefault;
    
    assetsLibrary = [[ALAssetsLibrary alloc]init];
    
    // traverse the main bundle to find out all mov files
    videoArray = [NSMutableArray arrayWithCapacity:3];
    
    NSArray *movs = [[NSBundle mainBundle] pathsForResourcesOfType:@"mov" inDirectory:nil];
    [videoArray addObjectsFromArray:movs];
    
    movs = [[NSBundle mainBundle] pathsForResourcesOfType:@"MOV" inDirectory:nil];
    [videoArray addObjectsFromArray:movs];
    
    _mediaItemCount = picArray.count + videoArray.count;
    
    if (delegate && [delegate respondsToSelector:@selector(saveToUtilStartCopy:)]) {
        [delegate saveToUtilStartCopy:_mediaItemCount];
    }
    
    [self saveImage];
    // save pic to camera roll
//    NSData *data = nil;
//    for (id item in picArray) {
//        data = [NSData dataWithContentsOfFile:item];
//        
//        [assetsLibrary writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
//            [self updateProcessWithError:error];
//        }];
//    }
    
    // save video to camera roll
//    for (id item in videoArray) {
//        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(item)) {
//            
//            // Note：save to camera roll is async, so the later item may copy complete than previous item
//            UISaveVideoAtPathToSavedPhotosAlbum(item, self, @selector(video:didFinishSavingWithError:contextInfo:), NULL);
//        }
//        else {
//            [self updateProcessWithError:[NSError errorWithDomain:@"copy video error" code:-1 userInfo:nil]];
//        }
//    }
}

- (void)saveImage
{
    if (!picArray.count) {
        [self saveVodeo];
        return;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:picArray[0]];
    [picArray removeObjectAtIndex:0];
    [assetsLibrary writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        [self updateProcessWithError:error];
        [self saveImage];
    }];
}

- (void)saveVodeo
{
    if (!videoArray.count) {
        return;
    }
    
    NSURL *url = [NSURL fileURLWithPath:videoArray[0]];
    [videoArray removeObjectAtIndex:0];
    [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error) {
        [self updateProcessWithError:error];
        [self saveVodeo];
    }];
}


#pragma mark -
#pragma mark selector to observe save to process

- (void)               video: (NSString *) videoPath
    didFinishSavingWithError: (NSError *) error
                 contextInfo: (void *) contextInfo
{
    [self updateProcessWithError:error];
}

- (void)updateProcessWithError:(NSError *)error
{
    BOOL isSuccess = YES;
    if (error) {
        isSuccess = NO;
        NSLog(@"%@", [error localizedDescription]);
    }
    
    if (delegate && [delegate respondsToSelector:@selector(mediaItemCopiedIsSuccess:)]) {
        [delegate mediaItemCopiedIsSuccess:isSuccess];
    }
    
    static int index = 0;
    index += 1;     // caculte copied item count
    if (index == _mediaItemCount) {
        if (delegate && [delegate respondsToSelector:@selector(savetoUtilCopyFinished)]) {
            [delegate savetoUtilCopyFinished];
        }
    }
}



@end
