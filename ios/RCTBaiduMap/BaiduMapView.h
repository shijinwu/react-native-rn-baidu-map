//
//  RCTBaiduMap.h
//  RCTBaiduMap
//
//  Created by lovebing on 4/17/2016.
//  Copyright © 2016 lovebing.org. All rights reserved.
//

#ifndef BaiduMapView_h
#define BaiduMapView_h


#import <React/RCTViewManager.h>
#import <React/RCTConvert+CoreLocation.h>
#import <BaiduMapAPI_Map/BMKMapView.h>
#import <BaiduMapAPI_Map/BMKPinAnnotationView.h>
#import <BaiduMapAPI_Map/BMKPointAnnotation.h>

#import <UIKit/UIKit.h>
#import "OverlayUtils.h"
#import "OverlayPolyline.h"
#import "OverlayMarker.h"
#import "ClusterAnnotation.h"


@interface BaiduMapView : BMKMapView <BMKMapViewDelegate>

@property(nonatomic) BOOL clusterEnabled;
@property(nonatomic) int childrenCount;
@property (nonatomic) BMKUserLocation *userLocation;
@property (nonatomic, copy) RCTBubblingEventBlock onChange;
@property (nonatomic) BOOL isMaxLevel;
@property (nonatomic,copy)NSArray * outArray;
@property (nonatomic) BOOL findHouse;
- (void)setZoom:(float)zoom;
- (void)setCenterLatLng:(NSDictionary *)LatLngObj;

- (void)setScrollGesturesEnabled:(BOOL)scrollGesturesEnabled;
- (void)setZoomGesturesEnabled:(BOOL)zoomGesturesEnabled;

- (OverlayView *)findOverlayView:(id<BMKOverlay>)overlay;

@end


@interface TriangleView : UIView
@property(nonatomic,strong)UIColor * color;

- (instancetype)initWithColor:(UIColor *)color;



@end


@interface OldAnnotation : BMKPointAnnotation
@property(nonatomic) BOOL selected;

@end

@interface NewAnnotation : BMKPointAnnotation
@property(nonatomic) BOOL selected;
@property(nonatomic,copy)NSString * code;
@property(nonatomic,copy)NSArray * textArray;
@end



@interface NewAnnotationView : BMKAnnotationView
-(void)setInfo:(BOOL)info;
@end


@interface SubAnnotationView : BMKAnnotationView
@property (nonatomic,strong)UIView * topView;
@property (nonatomic,strong)UILabel * leftLabel;
@property (nonatomic,strong)UIView * rightView;
@property (nonatomic,strong)TriangleView * bottomView;
-(void)setContentWithAnnotation:(NewAnnotation *)annotation;
@end



#endif
