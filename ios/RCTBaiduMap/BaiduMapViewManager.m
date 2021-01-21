//
//  RCTBaiduMapViewManager.m
//  RCTBaiduMap
//
//  Created by lovebing on Aug 6, 2016.
//  Copyright © 2016 lovebing.org. All rights reserved.
//

#import "BaiduMapViewManager.h"


@implementation BaiduMapViewManager;

static NSString *markerIdentifier = @"markerIdentifier";
static NSString *clusterIdentifier = @"clusterIdentifier";

RCT_EXPORT_MODULE(BaiduMapView)

RCT_EXPORT_VIEW_PROPERTY(mapType, int)
RCT_EXPORT_VIEW_PROPERTY(zoom, float)
RCT_EXPORT_VIEW_PROPERTY(maxZoom, float)
RCT_EXPORT_VIEW_PROPERTY(minZoom, float)
RCT_EXPORT_VIEW_PROPERTY(showsUserLocation, BOOL);
RCT_EXPORT_VIEW_PROPERTY(scrollGesturesEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(zoomGesturesEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(trafficEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(baiduHeatMapEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(clusterEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(markers, NSArray*)
RCT_EXPORT_VIEW_PROPERTY(locationData, NSDictionary*)
RCT_EXPORT_VIEW_PROPERTY(onChange, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(searchDistrict, NSString *)
RCT_EXPORT_VIEW_PROPERTY(clearView, BOOL)

RCT_CUSTOM_VIEW_PROPERTY(center, CLLocationCoordinate2D, BaiduMapView) {
    [view setCenterCoordinate:json ? [RCTConvert CLLocationCoordinate2D:json] : defaultView.centerCoordinate];
}

+ (void)initSDK:(NSString*)key {
    BMKMapManager* _mapManager = [[BMKMapManager alloc]init];

    // 初始化定位SDK
    [[BMKLocationAuth sharedInstance] checkPermisionWithKey:key authDelegate:nil];
    BOOL ret = [_mapManager start:key  generalDelegate:nil];
    if (!ret) {
        NSLog(@"manager start failed!");
    }
}

- (UIView *)view {
    BaiduMapView* mapView = [[BaiduMapView alloc] init];
    mapView.delegate = self;
    return mapView;
}

- (void)mapview:(BMKMapView *)mapView onDoubleClick:(CLLocationCoordinate2D)coordinate {
    NSLog(@"onDoubleClick");
    NSDictionary* event = @{
                            @"type": @"onMapDoubleClick",
                            @"params": @{
                                    @"latitude": @(coordinate.latitude),
                                    @"longitude": @(coordinate.longitude)
                                    }
                            };
    [self sendEvent:mapView params:event];
}

- (void)mapView:(BMKMapView *)mapView onClickedMapBlank:(CLLocationCoordinate2D)coordinate {
    NSLog(@"onClickedMapBlank");
    NSDictionary* event = @{
                            @"type": @"onMapClick",
                            @"params": @{
                                    @"latitude": @(coordinate.latitude),
                                    @"longitude": @(coordinate.longitude)
                                    }
                            };
    [self sendEvent:mapView params:event];
}

- (void)mapViewDidFinishLoading:(BMKMapView *)mapView {
    NSDictionary* event = @{
                            @"type": @"onMapLoaded",
                            @"params": @{}
                            };
    [self sendEvent:mapView params:event];
}

- (void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view {
    
    
    if([view.annotation  isKindOfClass:[NewAnnotation class]]){
        
        NewAnnotation * anno = (NewAnnotation *)view.annotation;
                  NSDictionary* event = @{
                                          @"type": @"onMapMarkerClick",
                                          @"params": @{
                                                  @"title":anno.title,
                                                  }
                                          };
        [self sendEvent:mapView params:event];
        
        
    }
    
    
    if([view isKindOfClass:[NewAnnotationView class]]){
        OldAnnotation * annotation = view.annotation;
//        [mapView setCenterCoordinate:annotation.coordinate];
//        [mapView setZoomLevel:14.1];
                
        CLLocationCoordinate2D targetGeoPt = [mapView getMapStatus].targetGeoPt;
               NSDictionary* event = @{
                                       @"type": @"onMapBigMarkerClick",
                                       @"params": @{
                                               @"latitude": @(annotation.coordinate.latitude),
                                               @"longitude":@(annotation.coordinate.longitude),
                                               @"title": annotation.title,
                                               }
                                       };
     [self sendEvent:mapView params:event];
        
       
//        [mapView setZoomLevel:14];
//        [self showSubMarkersWithMapView:(BaiduMapView *)mapView];

        return;
    }
    
    NSDictionary* event = @{
                            @"type": @"onMarkerClick",
                            @"params": @{
                                    @"title": [[view annotation] title],
                                    @"position": @{
                                            @"latitude": @([[view annotation] coordinate].latitude),
                                            @"longitude": @([[view annotation] coordinate].longitude)
                                            }
                                    }
                            };
    [self sendEvent:mapView params:event];
}

- (void)mapView:(BMKMapView *)mapView onClickedMapPoi:(BMKMapPoi *)mapPoi {
    NSLog(@"onClickedMapPoi");
    NSDictionary* event = @{
                            @"type": @"onMapPoiClick",
                            @"params": @{
                                    @"name": mapPoi.text,
                                    @"uid": mapPoi.uid,
                                    @"latitude": @(mapPoi.pt.latitude),
                                    @"longitude": @(mapPoi.pt.longitude)
                                    }
                            };
    [self sendEvent:mapView params:event];
}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation {
    NSLog(@"viewForAnnotation");
    
    if ([annotation isKindOfClass:[ClusterAnnotation class]]) {
        ClusterAnnotation *cluster = (ClusterAnnotation*)annotation;
        BMKPinAnnotationView *annotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:clusterIdentifier];
        UILabel *annotationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
        annotationLabel.textColor = [UIColor whiteColor];
        annotationLabel.font = [UIFont systemFontOfSize:11];
        annotationLabel.textAlignment = NSTextAlignmentCenter;
        annotationLabel.hidden = NO;
        annotationLabel.text = [NSString stringWithFormat:@"%ld", cluster.size];
        annotationLabel.backgroundColor = [UIColor greenColor];
        annotationView.alpha = 0.8;
        [annotationView addSubview:annotationLabel];
        
        if (cluster.size == 1) {
            annotationLabel.hidden = YES;
            annotationView.pinColor = BMKPinAnnotationColorRed;
        }
        if (cluster.size > 20) {
            annotationLabel.backgroundColor = [UIColor redColor];
        } else if (cluster.size > 10) {
            annotationLabel.backgroundColor = [UIColor purpleColor];
        } else if (cluster.size > 5) {
            annotationLabel.backgroundColor = [UIColor blueColor];
        } else {
            annotationLabel.backgroundColor = [UIColor greenColor];
        }
        [annotationView setBounds:CGRectMake(0, 0, 22, 22)];
        annotationView.draggable = YES;
        annotationView.annotation = annotation;
        return annotationView;
    } else if ([annotation isKindOfClass:[BMKPointAnnotation class]]) {
        
        if(![annotation.subtitle isEqualToString:@"sub"]){
            NewAnnotationView * annotationView = [[NewAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"countAnnotation"];
                           UILabel *annotationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 19, 80, 22)];
                                  annotationLabel.textColor = [UIColor whiteColor];
                                  annotationLabel.font = [UIFont systemFontOfSize:11];
                                  annotationLabel.textAlignment = NSTextAlignmentCenter;
                                  annotationLabel.hidden = NO;
                                  annotationLabel.text = annotation.title;
                                  [annotationView addSubview:annotationLabel];
            
            UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 39, 80, 22)];
                    bottomLabel.textColor = [UIColor whiteColor];
                    bottomLabel.font = [UIFont systemFontOfSize:11];
                    bottomLabel.textAlignment = NSTextAlignmentCenter;
                    bottomLabel.hidden = NO;
                    bottomLabel.text =[NSString stringWithFormat:@"%@",annotation.subtitle];
                    [annotationView addSubview:bottomLabel];
                        
                    annotationView.canShowCallout = NO;
                    OldAnnotation * anno =(OldAnnotation *)annotation;
                    [annotationView setInfo:anno.selected];
                    return annotationView;
        }
        else if([annotation.subtitle isEqualToString:@"sub"]){
            SubAnnotationView * annotationView = [[SubAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"subAnnotation"];
                                 
                                          //  [annotationView setBounds:CGRectMake(0, 0, 22, 22)];
            [annotationView setContentWithAnnotation:annotation];
            annotationView.canShowCallout = NO;
            return annotationView;
        }
        
        
        BMKPinAnnotationView *newAnnotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:markerIdentifier];
        newAnnotationView.pinColor = BMKPinAnnotationColorPurple;
        newAnnotationView.animatesDrop = YES;
        return newAnnotationView;
    }
    return nil;
}

- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay {
    NSLog(@"viewForOverlay");
    BaiduMapView *baidumMapView = (BaiduMapView *) mapView;
    
    if(baidumMapView.findHouse){        
        if ([overlay isKindOfClass:[BMKPolygon class]]) {
               //初始化一个overlay并返回相应的BMKPolygonView的实例
               BMKPolygonView *polygonView = [[BMKPolygonView alloc] initWithOverlay:overlay];
               //设置polygonView的画笔（边框）颜色
               // 0x3048ACF0
               polygonView.strokeColor = [UIColor colorWithRed:48/255.0 green:72/255.0 blue:118/255.0 alpha:.2];
               //设置polygonView的填充色
               polygonView.fillColor = [UIColor colorWithRed:48/255.0 green:72/255.0 blue:118/255.0 alpha:.1];
               //设置polygonView的线宽度
               polygonView.lineWidth = 1;
               polygonView.lineDashType = kBMKLineDashTypeSquare;
               return polygonView;
           }
    }
    
    OverlayView *overlayView = [baidumMapView findOverlayView:overlay];
    if (overlayView == nil) {
        return nil;
    }
    if ([overlay isKindOfClass:[BMKArcline class]]) {
        BMKArclineView *arclineView = [[BMKArclineView alloc] initWithArcline:overlay];
        arclineView.strokeColor = [UIColor blueColor];
       // arclineView.lineDash = YES;
        arclineView.lineWidth = 6.0;
        return arclineView;
    } else if([overlay isKindOfClass:[BMKCircle class]]) {
        BMKCircleView *circleView = [[BMKCircleView alloc] initWithCircle:overlay];
        return circleView;
    } else if([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView *polylineView = [[BMKPolylineView alloc] initWithPolyline:overlay];
        polylineView.strokeColor = [OverlayUtils getColor:overlayView.strokeColor];
        polylineView.lineWidth = overlayView.lineWidth;
        return polylineView;
    }
    return nil;
}

- (void)mapView:(BMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated reason:(BMKRegionChangeReason)reason{
    RCTLog(@"mapView---zoom == %f",mapView.zoomLevel);
    
    BaiduMapView * baiduMapView = (BaiduMapView *)mapView;
    if(baiduMapView.findHouse){
        
        CLLocationCoordinate2D targetGeoPt = [mapView getMapStatus].targetGeoPt;
          NSDictionary* event = @{
                                  @"type": @"onMapStatusChange",
                                  @"params": @{
                                          @"target": @{
                                                  @"latitude": @(targetGeoPt.latitude),
                                                  @"longitude": @(targetGeoPt.longitude)
                                                  },
                                          @"zoom": @(mapView.zoomLevel),
                                          @"overlook": @""
                                          }
                                  };
          [self sendEvent:mapView params:event];
        
        return;
        
    }
    
}

- (void)mapStatusDidChanged: (BMKMapView *)mapView {
    
    RCTLog(@"mapView---zoom == %f",mapView.zoomLevel);

    BaiduMapView * baiduMapView = (BaiduMapView *)mapView;
    if(baiduMapView.findHouse){
        return;
    }
 
    
    CLLocationCoordinate2D targetGeoPt = [mapView getMapStatus].targetGeoPt;
    NSDictionary* event = @{
                            @"type": @"onMapStatusChange",
                            @"params": @{
                                    @"target": @{
                                            @"latitude": @(targetGeoPt.latitude),
                                            @"longitude": @(targetGeoPt.longitude)
                                            },
                                    @"zoom": @"",
                                    @"overlook": @""
                                    }
                            };
    [self sendEvent:mapView params:event];
}

- (void)sendEvent:(BaiduMapView *)mapView params:(NSDictionary *)params {
    if (!mapView.onChange) {
        return;
    }
    mapView.onChange(params);
}

-(void)showSubMarkersWithMapView:(BaiduMapView *)mapView
{
    [mapView removeAnnotations:mapView.annotations];
          
          NSMutableArray * array = [NSMutableArray array];
          for (NSDictionary * dic in mapView.outArray) {
              NSArray * subArray = dic[@"projectNewVos"];
              NSString * text = subArray[0][@"projectName"];
              NSMutableString * str = [NSMutableString stringWithString:text];
              for (int i = 0; i < subArray.count; i++) {
                  NSDictionary *subDict = subArray[i];
                  if([subDict[@"projectName"] isEqualToString:text]){
                      [str appendString:subDict[@"propertyType"]];
                  }else{
                      NSMutableDictionary * muDict = [NSMutableDictionary dictionaryWithDictionary:subArray[i-1]];
                               [muDict setObject:str forKey:@"title"];
                      [array addObject:muDict];
                      text = subDict[@"projectName"];
                      str = [NSMutableString stringWithFormat:@"%@ %@",text,subDict[@"propertyType"]];
                  }
              }
              
              NSMutableDictionary * lastDict = [NSMutableDictionary dictionaryWithDictionary:subArray.lastObject];
              [lastDict setObject:str forKey:@"title"];

              [array addObject:lastDict];
          }
          
             NSMutableArray * annotations = [NSMutableArray array];
             for(int i = 0;i < array.count; i++){
                 BMKPointAnnotation * annotation = [BMKPointAnnotation new];
                 annotation.title = array[i][@"title"];
                 annotation.subtitle = @"sub";
                 [annotation setCoordinate: CLLocationCoordinate2DMake([array[i][@"y"] floatValue],[array[i][@"x"] floatValue])];
                 [annotations addObject:annotation];
              }
             [mapView addAnnotations:annotations];
    

}






@end
