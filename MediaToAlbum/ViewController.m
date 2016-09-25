//
//  ViewController.m
//  MediaToAlbum
//
//  Created by 马汝军 on 2016/9/25.
//  Copyright © 2016年 JiZhi. All rights reserved.
//

#import "ViewController.h"
#import "ZipArchive.h"
#import "USImagePickerController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *msgLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.msgLabel.text = @"数据加载中";
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self unzipMediaFile];
}

- (void)unzipMediaFile
{
    NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"media" ofType:@"zip"];
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    [[NSFileManager defaultManager] removeItemAtPath:documentPath error:nil];
    
    self.msgLabel.text = @"开始解压缩…";
    
    [SSZipArchive unzipFileAtPath:zipPath toDestination:documentPath progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
        self.msgLabel.text = [NSString stringWithFormat:@"解压缩进度： %ld / %ld", entryNumber, total];
    } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nonnull error) {
        self.msgLabel.text = @"解压缩完成，准备导入到相册";
        
        [[NSFileManager defaultManager] removeItemAtPath:[documentPath stringByAppendingPathComponent:@"__MACOSX"] error:nil];
        
        [self enumeratorFilesAtDirPath:documentPath];
    }];
}

- (void)enumeratorFilesAtDirPath:(NSString *)dirPath
{
    NSDirectoryEnumerator<NSString *> *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:dirPath];
    
    NSString *item = nil;
    NSMutableArray *filesArray = [NSMutableArray array];
    
    while ((item = [dirEnum nextObject]) != nil) {
        NSArray *components = [item componentsSeparatedByString:@"/"];
        
        if (components.count == 2 && ![components.lastObject isEqualToString:@".DS_Store"]) {
            [filesArray addObject:item];
        }
    }
    
    [self importFilesToAlbum:filesArray index:0 dir:dirPath];
}

- (void)importFilesToAlbum:(NSArray *)filesArray index:(int)index dir:(NSString *)dirPath
{
    if (index >= filesArray.count) {
        self.msgLabel.text = @"所有照片都已导入到相册";
        return;
    }
    
    NSString *filePath = [filesArray objectAtIndex:index];
    NSArray *components = [filePath componentsSeparatedByString:@"/"];
    filePath = [dirPath stringByAppendingPathComponent:filePath];
    
    self.msgLabel.text = [NSString stringWithFormat:@"正在导入照片： %zd / %zd", index+1, filesArray.count];
    
    if (NSClassFromString(@"PHPhotoLibrary")) {
        [PHPhotoLibrary writeImageFromFilePath:filePath toAlbum:[components firstObject] completionHandler:^(PHAsset *asset, NSError *error) {
            [self importFilesToAlbum:filesArray index:index+1 dir:dirPath];
        }];
    }
    else {
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        [ALAssetsLibrary writeImage:image toAlbum:[components firstObject] completionHandler:^(ALAsset *asset, NSError *error) {
            [self importFilesToAlbum:filesArray index:index+1 dir:dirPath];
        }];
    }
}

@end
