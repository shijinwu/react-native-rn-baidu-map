//
//  RCTBaiduMap.m
//  RCTBaiduMap
//
//  Created by lovebing on 4/17/2016.
//  Copyright © 2016 lovebing.org. All rights reserved.
//

#import "BaiduMapView.h"
#import <BaiduMapAPI_Search/BMKDistrictSearch.h>
#import <BMKLocationkit/BMKLocationComponent.h>

@interface BaiduMapView()<BMKDistrictSearchDelegate>
@property(nonatomic,strong) BMKDistrictSearch *districtSearch;
@end


@implementation BaiduMapView {
    BMKMapView* _mapView;
    BMKPointAnnotation* _annotation;
    NSMutableArray* _annotations;
}

- (void)setZoom:(float)zoom {
    self.zoomLevel = zoom;
}

- (void)setZoomGesturesEnabled:(BOOL)zoomGesturesEnabled{
    NSLog(@"setZoomGesturesEnabled: %d", zoomGesturesEnabled);
    self.gesturesEnabled = zoomGesturesEnabled;
}

- (void)setScrollGesturesEnabled:(BOOL)scrollGesturesEnabled{
    NSLog(@"setScrollGesturesEnabled: %d", scrollGesturesEnabled);
    self.scrollEnabled = scrollGesturesEnabled;
}

- (void)setCenterLatLng:(NSDictionary *)LatLngObj {
    double lat = [RCTConvert double:LatLngObj[@"lat"]];
    double lng = [RCTConvert double:LatLngObj[@"lng"]];
    CLLocationCoordinate2D point = CLLocationCoordinate2DMake(lat, lng);
    self.centerCoordinate = point;
}

- (void)setLocationData:(NSDictionary *)locationData {
    NSLog(@"setLocationData");
    if (_userLocation == nil) {
        _userLocation = [[BMKUserLocation alloc] init];
    }
    CLLocationCoordinate2D coord = [OverlayUtils getCoorFromOption:locationData];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    _userLocation.location = location;
    [self updateLocationData:_userLocation];
}

- (void)insertReactSubview:(id <RCTComponent>)subview atIndex:(NSInteger)atIndex {
    NSLog(@"childrenCount:%d", _childrenCount);
    if ([subview isKindOfClass:[OverlayView class]]) {
        OverlayView *overlayView = (OverlayView *) subview;
        [overlayView addToMap:self];
        [super insertReactSubview:subview atIndex:atIndex];
    }
}

- (void)removeReactSubview:(id <RCTComponent>)subview {
    NSLog(@"removeReactSubview");
    if ([subview isKindOfClass:[OverlayView class]]) {
        OverlayView *overlayView = (OverlayView *) subview;
        [overlayView removeFromMap:self];
        NSLog(@"overlayView atIndex: %d", overlayView.atIndex);
    }
    [super removeReactSubview:subview];
}

- (void)didSetProps:(NSArray<NSString *> *) props {
    NSLog(@"didSetProps: %d", _childrenCount);
    [super didSetProps:props];
}

- (void)didUpdateReactSubviews {
    for (int i = 0; i < [self.reactSubviews count]; i++) {
        UIView * view = [self.reactSubviews objectAtIndex:i];
        if ([view isKindOfClass:[OverlayView class]]) {
            OverlayView *overlayView = (OverlayView *) view;
            [overlayView update];
        }
    }
    NSLog(@"didUpdateReactSubviews:%d", [self.reactSubviews count]);
}

- (OverlayView *)findOverlayView:(id<BMKOverlay>)overlay {
    for (int i = 0; i < [self.reactSubviews count]; i++) {
        UIView * view = [self.reactSubviews objectAtIndex:i];
        if ([view isKindOfClass:[OverlayView class]]) {
            OverlayView *overlayView = (OverlayView *) view;
            if ([overlayView ownOverlay:overlay]) {
                return overlayView;
            }
        }
    }
    return nil;
}

-(void)setMarkers:(NSArray *)markers{
    self.findHouse = YES;
    NSArray * array = [NSArray arrayWithArray:markers];
    self.outArray = [NSArray arrayWithArray:markers];
    [self removeAnnotations:self.annotations];
    NSMutableArray * annotations = [NSMutableArray array];
    for(int i = 0;i < array.count; i++){
        
        if(array[i][@"title"]){
            if(![array[i][@"x"] isEqual:[NSNull null]]){
            
            NewAnnotation * annotation = [NewAnnotation new];
            annotation.title = array[i][@"title"];
            annotation.subtitle = @"sub";
            annotation.selected = [array[i][@"selected"] boolValue];
            annotation.textArray = array[i][@"detailTextArray"];
            // annotation.code = array[i][@"projectCode"];
            [annotation setCoordinate: CLLocationCoordinate2DMake([array[i][@"y"] floatValue],[array[i][@"x"] floatValue])];
                [annotations addObject:annotation];
                 }
                    
        }
        else{
        
            if(![array[i][@"x"] isEqual:[NSNull null]]){
                
                NSDictionary * dic = array[i];
                OldAnnotation * annotation = [OldAnnotation new];
                annotation.title = [NSString stringWithFormat:@"%@",array[i][@"districtName"]];
                annotation.subtitle =[NSString stringWithFormat:@" %@", array[i][@"projectNum"]];
                [annotation setCoordinate: CLLocationCoordinate2DMake([array[i][@"y"] floatValue],[array[i][@"x"] floatValue])];
                
                annotation.selected = false;
                if([[dic allKeys] containsObject:@"selected"]){
                    annotation.selected = [[dic valueForKey:@"selected"] boolValue];
                }
            
                [annotations addObject:annotation];
            }
                    
        }
     }
    [self addAnnotations:annotations];
    
}

// 最大缩放级别
-(void)setMaxZoom:(float)zoom{
    self.maxZoomLevel = zoom;
}

// 最小缩放级别
-(void)setMinZoom:(float)zoom{
     self.minZoomLevel = zoom;
}

-(void)setClearView:(BOOL)clear{
    [self removeOverlays:self.overlays];
}

// 设置围栏
-(void)setSearchDistrict:(NSString *)string{
    if(string.length == 0){
        return;
    }
     NSArray  *array = [string componentsSeparatedByString:@","];
    if(array.count > 0){
        [self setupDefaultData:array];
    }
}

#pragma mark - Search Data
- (void)setupDefaultData:(NSArray *)array {
      [[BMKLocationAuth sharedInstance] checkPermisionWithKey:@"GdVlRlK7g24O5QgGQcB35VE4cYG5ih5j" authDelegate:nil];
    BMKDistrictSearchOption *districtOption = [[BMKDistrictSearchOption alloc] init];
    districtOption.city = array[0];
    districtOption.district = array[1];
    [self searchData:districtOption];
}

- (void)searchData:(BMKDistrictSearchOption *)option {
    [self removeOverlays:self.overlays];
    //初始化BMKDistrictSearch实例
    self.districtSearch = [[BMKDistrictSearch alloc] init];
    //设置行政区域检索的代理
    self.districtSearch.delegate = self;
    //初始化请求参数类BMKDistrictSearchOption的实例
    BMKDistrictSearchOption *districtOption = [[BMKDistrictSearchOption alloc] init];
    //城市名，必选
    districtOption.city = option.city;
    //区县名字，可选
    districtOption.district = option.district;
    /**
     行政区域检索：异步方法，返回结果在BMKDistrictSearchDelegate的
     onGetDistrictResult里
     
     districtOption 公交线路检索信息类
     return 成功返回YES，否则返回NO
     
     */
    BOOL flag = [self.districtSearch districtSearch:districtOption];
    if (flag) {
        NSLog(@"行政区域检索发送成功");
    } else {
        NSLog(@"行政区域检索发送失败");
    }
}

#pragma mark - BMKDistrictSearchDelegate
/**
 行政区域检索结果回调
 
 @param searcher 检索对象
 @param result 行政区域检索结果
 @param error 错误码，@see BMKCloudErrorCode
 */
- (void)onGetDistrictResult:(BMKDistrictSearch *)searcher result:(BMKDistrictResult *)result errorCode:(BMKSearchErrorCode)error {
    [self removeOverlays:_mapView.overlays];
    //BMKSearchErrorCode错误码，BMK_SEARCH_NO_ERROR：检索结果正常返回
    if (error == BMK_SEARCH_NO_ERROR) {
        for (NSString *path in result.paths) {
            BMKPolygon *polygon = [self transferPathStringToPolygon:path];
            /**
             向地图View添加Overlay，需要实现BMKMapViewDelegate的-mapView:viewForOverlay:方法
             来生成标注对应的View
             
             @param overlay 要添加的overlay
             */
            [self addOverlay:polygon];
        }
       // self.centerCoordinate = result.center;
     
    }
}

- (BMKPolygon *)transferPathStringToPolygon:(NSString *)path {
    NSUInteger pathCount = [path componentsSeparatedByString:@";"].count;
    if (pathCount > 0) {
        BMKMapPoint points[pathCount];
        NSArray *pointsArray = [path componentsSeparatedByString:@";"];
        for (NSUInteger i = 0; i < pathCount; i ++) {
            if ([pointsArray[i] rangeOfString:@","].location != NSNotFound) {
                NSArray *coordinates = [pointsArray[i] componentsSeparatedByString:@","];
                points[i] = BMKMapPointMake([coordinates.firstObject doubleValue], [coordinates .lastObject doubleValue]);
            }
        }
        /**
         根据多个点生成多边形
         
         points 直角坐标点数组，这些点将被拷贝到生成的多边形对象中
         count 点的个数
         新生成的多边形对象
         */
        BMKPolygon *polygon = [BMKPolygon polygonWithPoints:points count:pathCount];
        return polygon;
    }
    return nil;
}




@end


@implementation TriangleView

-(instancetype)initWithColor:(UIColor *)color{
    if([super init]) {
        self.backgroundColor = [UIColor clearColor];
        self.color = color;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [self drawTrianglePath:rect];
}

#pragma mark - 画三角形
-(void)drawTrianglePath:(CGRect)rect {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(rect.size.width, 0)];
    [path addLineToPoint:CGPointMake(rect.size.width / 2, rect.size.height)];
    
    /*
     闭合线可以通过下面的两种方式实现
     [path closePath];
     [path addLineToPoint:CGPointMake(20, 20)];
     */
    [path closePath];
    
    path.lineWidth = 1.5;//设置线宽
    
    UIColor *fillColor = self.color;
    [fillColor set];//使设置的颜色生效
    [path fill];//填充整个三角区颜色
    
    /*
     设置边线颜色
     */
    UIColor *strokeColor = fillColor;
    [strokeColor set];//使设置的颜色生效
    
    [path stroke];//连线
    
}

@end

@implementation OldAnnotation

@end



@implementation NewAnnotation

@end

@implementation NewAnnotationView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (id)initWithAnnotation:(id<BMKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        self.frame = CGRectMake(0, 0, 80, 80);
        
   
        UIColor * twoColor = [UIColor colorWithRed:139/255.0 green:202/255.0 blue:249/255.0 alpha:1.0];
//        UIColor * threeColor = [UIColor colorWithRed:241/255.0 green:145/255.0 blue:74/255.0 alpha:1.0];
//        
//        NSArray * array = @[oneColor,twoColor,threeColor];
        
        self.layer.cornerRadius = 40;
        self.layer. masksToBounds = YES; // 部分UIView需要设置这个属性
    }
    return self;
}

-(void)setInfo:(BOOL)info{
    UIColor * oneColor = [UIColor colorWithRed:97/255.0 green:172/255.0 blue:234/255.0 alpha:1.0];
         UIColor * twoColor = [UIColor colorWithRed:139/255.0 green:202/255.0 blue:249/255.0 alpha:1.0];
         UIColor * threeColor = [UIColor colorWithRed:241/255.0 green:145/255.0 blue:74/255.0 alpha:1.0];
    if(info){
        self.backgroundColor = threeColor;
    }else{
        self.backgroundColor = oneColor;
    }
}

-(id)randomArrayObject:(NSArray *)array{
    if ([array isKindOfClass:[NSArray class]] && [array count] > 0) {
        return array[arc4random_uniform((int)array.count)];
    }
    return nil;
}

@end


@implementation SubAnnotationView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (id)initWithAnnotation:(id<BMKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
//        self.frame = CGRectMake(0, 0, 160, 60);
//        NewAnnotation * anno = (NewAnnotation *)annotation;
//        self.backgroundColor = anno.selected ? [UIColor blueColor] : [UIColor redColor];
    }
    return self;
}

-(void)setContentWithAnnotation:(NewAnnotation *)annotation{
    
    CGFloat height = annotation.textArray.count * 14 + 20 + 12;
    
    CGSize textSize = [annotation.title boundingRectWithSize:CGSizeMake(MAXFLOAT, 12) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]} context:nil].size;
    CGFloat leftWidth = 70.0>textSize.width?70.0:textSize.width;
    self.leftLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, annotation.textArray.count == 1 ? 10: ((annotation.textArray.count*14-14)/2 + 10), leftWidth, 14)];
    [self.leftLabel setFont:[UIFont systemFontOfSize:12]];
    self.leftLabel.text = annotation.title;
    self.leftLabel.textAlignment =NSTextAlignmentCenter;
    self.leftLabel.textColor = [UIColor whiteColor];
    [self addSubview:self.leftLabel];
    
    
    self.rightView = [[UIView alloc]initWithFrame:CGRectMake(leftWidth + 30, 10, 180, annotation.textArray.count * 14)];
    CGFloat rightWidth = 100;
    for (int i = 0; i < annotation.textArray.count; i++) {
        NSString * text = annotation.textArray[i];
        CGSize textSize = [text boundingRectWithSize:CGSizeMake(MAXFLOAT, 12) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]} context:nil].size;
        rightWidth = rightWidth > textSize.width ? rightWidth : textSize.width;
        UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, i*14, rightWidth, 14)];
        [label setFont:[UIFont systemFontOfSize:12]];
        label.text = text;
        label.textColor = [UIColor whiteColor];
        [self.rightView addSubview:label];
    }
        
 
    CGFloat width = leftWidth+30+rightWidth+15;
    self.frame = CGRectMake(0, 0,width, height);
    
    UIColor * oneColor = [UIColor colorWithRed:97/255.0 green:172/255.0 blue:234/255.0 alpha:1.0];
      
    UIColor * threeColor = [UIColor colorWithRed:241/255.0 green:145/255.0 blue:74/255.0 alpha:1.0];
    
    self.backgroundColor = [UIColor clearColor];
    
    self.topView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, leftWidth+30+rightWidth+15, annotation.textArray.count * 14 + 20)];
    self.topView.backgroundColor = annotation.selected ? threeColor : oneColor;
    

    self.bottomView = [[TriangleView alloc]initWithColor: annotation.selected ? threeColor : oneColor];
    self.bottomView.frame = CGRectMake((leftWidth+30+rightWidth+15)/2.0 - 6 , annotation.textArray.count * 14 + 20, 12, 12);


    self.topView.layer.cornerRadius = 8;
    self.topView.layer. masksToBounds = YES;
    
    [self.topView addSubview:self.leftLabel];
    [self.topView addSubview:self.rightView];
    [self addSubview:self.topView];
    [self addSubview:self.bottomView];
    
    self.centerOffset =  CGPointMake(0, -height/2);
    
}

-(void)prepareForReuse{
  [self.topView removeFromSuperview];
  [self.rightView removeFromSuperview];
  [self.leftLabel removeFromSuperview];
  [self.bottomView removeFromSuperview];
}

@end





