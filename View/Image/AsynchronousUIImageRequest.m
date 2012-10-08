//
//  AsynchronousUIImageRequest.m
//  Crapple
//
//  Created by Benjamin Maer on 5/3/12.
//  Copyright (c) 2012 Syracuse University. All rights reserved.
//

#import "AsynchronousUIImageRequest.h"

@implementation AsynchronousUIImageRequest

@synthesize url = _url;
//@synthesize cacheName = _cacheName;

static NSMutableDictionary* fetchedImages;

+(void)initialize
{
    if (self == [AsynchronousUIImageRequest class])
    {
        fetchedImages = [NSMutableDictionary dictionary];
    }
}

-(id)initAndFetchWithURL:(NSString*)anUrl withBlock:(imageErrorBlock)block
{
    return [self initAndFetchWithURL:anUrl andCacheName:anUrl withBlock:block];
}

-(id)initAndFetchWithURL:(NSString *)anUrl andCacheName:(NSString *)cacheName withBlock:(imageErrorBlock)block
{
    if (self = [self init])
    {
        _cacheName = (cacheName ? cacheName : anUrl);
        [self setUrl:anUrl];
        [self fetchImageWithBlock:block];
    }

    return self;
}

-(void)fetchImageWithBlock:(imageErrorBlock)block
{
    [self cancelFetch];
    
    UIImage* cachedImage = [fetchedImages objectForKey:_cacheName];
    
    if (cachedImage)
    {
        if (block)
            block(cachedImage,nil);
    }
    else
    {
        _block = block;
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:_url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30.0];
        _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    }
}

-(void)cancelFetch
{
    [_connection cancel];
}

#pragma mark - NSURLConnectionDataDelegate methods
- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData
{
    if (!_data)
        _data = [[NSMutableData alloc] initWithCapacity:2024];

    [_data appendData:incrementalData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Error downloading image: %@",error);
    if (_block)
        _block(nil,error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection
{
    UIImage* image = [[UIImage alloc] initWithData:_data];

    if (image)
        [fetchedImages setObject:image forKey:_cacheName];
    else
        [fetchedImages removeObjectForKey:_cacheName];

    _data = nil;
    _connection = nil;

    if (_block)
        _block(image,nil);
}

#pragma mark - Static methods
+(void)removeCacheImageByCacheName:(NSString*)cacheName
{
    [fetchedImages removeObjectForKey:cacheName];
}

+(void)clearCache
{
    [fetchedImages removeAllObjects];
}

@end
