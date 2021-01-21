/**
 * Copyright (c) 2016-present, lovebing.org.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

package org.lovebing.reactnative.baidumap.uimanager;

import android.graphics.Color;
import android.os.Message;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.baidu.mapapi.map.*;
import com.baidu.mapapi.model.LatLng;
import android.os.Handler;

import com.baidu.mapapi.model.LatLngBounds;
import com.baidu.mapapi.search.core.SearchResult;
import com.baidu.mapapi.search.district.DistrictResult;
import com.baidu.mapapi.search.district.DistrictSearch;
import com.baidu.mapapi.search.district.DistrictSearchOption;
import com.baidu.mapapi.search.district.OnGetDistricSearchResultListener;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;
import org.lovebing.reactnative.baidumap.R;
import org.lovebing.reactnative.baidumap.listener.MapListener;
import org.lovebing.reactnative.baidumap.model.LocationData;
import org.lovebing.reactnative.baidumap.support.ConvertUtils;
import org.lovebing.reactnative.baidumap.view.OverlayCluster;
import org.lovebing.reactnative.baidumap.view.OverlayView;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Random;

public class MapViewManager extends ViewGroupManager<MapView> {

    private static Object EMPTY_OBJ = new Object();

    private List<Object> children = new ArrayList<>(10);
    private MapListener mapListener;
    private int childrenCount = 0;

    private ThemedReactContext themedReactContext;
    private DistrictSearch mDistrictSearch;


//    @Override
//    public Map getExportedCustomBubblingEventTypeConstants() {
//        return MapBuilder.builder()
//                .put("topChange", MapBuilder.of("phasedRegistrationNames", MapBuilder.of("bubbled", "onChange")))
//                .build();
//    }

    @Override
    public String getName() {
        return "BaiduMapView";
    }

    @Override
    public void addView(MapView parent, View child, int index) {
        Log.i("MapViewManager", "addView:" + index);
        if (index == 0 && !children.isEmpty()) {
            removeOldChildViews(parent.getMap());
        }
        if (child instanceof OverlayView) {
            if (child instanceof OverlayCluster) {
                ((OverlayCluster) child).setMapListener(mapListener);
            }
            ((OverlayView) child).addTopMap(parent.getMap());
            children.add(child);
        } else {
            children.add(EMPTY_OBJ);
        }
    }

    @Override
    public void removeViewAt(MapView parent, int index) {
        Log.i("MapViewManager", "removeViewAt:" + index);
        if (index < children.size()) {
            Object child = children.get(index);
            children.remove(index);
            if (child instanceof OverlayView) {
                ((OverlayView) child).removeFromMap(parent.getMap());
            } else {
                super.removeViewAt(parent, index);
            }
        }
    }

    MapView mapView;

    @Override
    protected MapView createViewInstance(ThemedReactContext themedReactContext) {
        this.themedReactContext = themedReactContext;
        mapView =  new MapView(themedReactContext);
        BaiduMap map = mapView.getMap();
        mapListener = new MapListener(mapView, themedReactContext);
        map.setOnMapStatusChangeListener(mapListener);
        map.setOnMapLoadedCallback(mapListener);
        map.setOnMapClickListener(mapListener);
        map.setOnMapDoubleClickListener(mapListener);
        map.setOnMarkerClickListener(mapListener);

        mDistrictSearch = DistrictSearch.newInstance();
        mDistrictSearch.setOnDistrictSearchListener(new OnGetDistricSearchResultListener() {
            @Override
            public void onGetDistrictResult(DistrictResult districtResult) {
                if (null != districtResult && districtResult.error == SearchResult.ERRORNO.NO_ERROR) {
                    //获取边界坐标点，并展示
                    List<List<LatLng>> polyLines = districtResult.getPolylines();
                    if (polyLines == null) {
                        return;
                    }
                    for (List<LatLng> polyline : polyLines) {
                        OverlayOptions ooPolygon = new PolygonOptions().points(polyline)
                                .stroke(new Stroke(1, 0x3048ACF0)).fillColor(0x3048ACF0);
                        mapView.getMap().addOverlay(ooPolygon);
                    }
                }
            }
        });
        return mapView;
    }

//    @ReactProp(name = "onMarkerClickAndroid")
//    public void onMarkerClickAndroid(MapView mapView,Callback callback){
//        mapView.getMap().setOnMarkerClickListener(new BaiduMap.OnMarkerClickListener() {
//            //marker被点击时回调的方法
//            //若响应点击事件，返回true，否则返回false
//            //默认返回false
//            @Override
//            public boolean onMarkerClick(Marker marker) {
//                Log.i("androidMarkerClick-->", marker.getTitle());
//
//                WritableMap writableMap = Arguments.createMap();
//                WritableMap position = Arguments.createMap();
//                position.putDouble("latitude", marker.getPosition().latitude);
//                position.putDouble("longitude", marker.getPosition().longitude);
//                writableMap.putMap("position", position);
//                writableMap.putString("title", marker.getTitle());
//
//                themedReactContextt.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("onMarkerClickAndroid", position);
//                callback.invoke(position);
//
//                mapView.getMap().setMapStatus(MapStatusUpdateFactory.zoomTo(15));
//
//                return false;
//            }
//        });
//    }

    MarkerOptions option = new MarkerOptions();
    String parentName = "";
    String districtName = "";
    boolean searchDistrictTag = false;
    private void setMarker(HashMap map){
        LatLng point = new LatLng(Double.valueOf(map.get("y").toString()),Double.valueOf(map.get("x").toString()));
        if (point == null) {
            return;
        }

        View popupView = LinearLayout.inflate(mapView.getContext(),R.layout.layout_area,null);
        String titleStr = "";
        if(map.get("title") != null){//项目级别数据
            titleStr = map.get("title").toString();
            popupView = LinearLayout.inflate(mapView.getContext(),R.layout.layout_project,null);
            LinearLayout layout = popupView.findViewById(R.id.ll_bg);
            ImageView iv_bg = popupView.findViewById(R.id.iv_triangle);
            layout.setBackgroundResource(map.get("selected").toString()=="true"?R.drawable.bg_project_orange:R.drawable.bg_project);
            iv_bg.setImageResource(map.get("selected").toString()=="true"?R.drawable.bg_project_triangle_orange:R.drawable.bg_project_triangle_blue);
            TextView tv_name = popupView.findViewById(R.id.text1);
            TextView tv_name2 = popupView.findViewById(R.id.text2);
            tv_name.setText(titleStr);
            tv_name2.setText(map.get("detailTextStr").toString());
        } else {
            //城区级别数据
            titleStr = map.get("districtName")+"";
            LinearLayout layout = popupView.findViewById(R.id.ll_bg);
//            int bg[] = {R.drawable.bg_round_blue,R.drawable.bg_round_blue2,R.drawable.bg_round_orange};
//            layout.setBackgroundResource(bg[new Random().nextInt(bg.length)]);
            if(map.containsKey("selected") && map.get("selected").toString()=="true"){
                layout.setBackgroundResource(R.drawable.bg_round_orange);
                parentName = map.get("parentName").toString();
                districtName = titleStr;
            }else{
                layout.setBackgroundResource(R.drawable.bg_round_blue);
            }
            TextView tv_area = popupView.findViewById(R.id.text1);
            TextView tv_num = popupView.findViewById(R.id.text2);
            try {
                int num = (int) Float.parseFloat(map.get("projectNum").toString());
                tv_num.setText(num+"");
            }catch (Exception e){
                tv_num.setText(map.get("projectNum").toString());
            }

            tv_area.setText(titleStr);
        }

        if(searchDistrictTag&&parentName.length()>0&&districtName.length()>0){
            mDistrictSearch.searchDistrict(new DistrictSearchOption().cityName(parentName).districtName(districtName));
            searchDistrictTag= false;
        }
        option.position(point).icon(BitmapDescriptorFactory.fromView(popupView)).title(titleStr);
        mapView.getMap().addOverlay(option);
//        Overlay overlay = mapView.getMap().addOverlay(option);
//        overlay.remove();

    }

    Handler handler = new Handler(){
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what){
                case 1:
                    setMarker((HashMap) msg.obj);
                    break;
                case 2:
                    List<OverlayOptions> options = (List<OverlayOptions>) msg.obj;
                    mapView.getMap().addOverlays(options);
//                    List<Overlay>  overlays = mapView.getMap().addOverlays(options);
//                    overlays.get(0).remove();
                    break;
            }
        }
    };

    @ReactProp(name = "searchDistrict")
    public void searchDistrict(MapView mapView, String result){
        try {
            if(result!=null && result.length()>0){
                String data [] = result.split(",");
                parentName = data[0];
                districtName = data[1];
                mDistrictSearch.searchDistrict(new DistrictSearchOption().cityName(parentName).districtName(districtName));
//                mapView.postDelayed(new Runnable() {
//                    @Override
//                    public void run() {
//                    }
//                },500);
            }
        }catch (Error e){}
    }

    @ReactProp(name = "addOverlayy")
    public void addOverlayy(MapView mapView, ReadableArray readableArray) {
        BaiduMap baidumap = mapView.getMap();
        baidumap.setMaxAndMinZoomLevel(21, 11);
        baidumap.clear();

//        Log.i("0-------->>>",System.currentTimeMillis()+"");
        ArrayList<Object> arrayList = readableArray.toArrayList();
//        Log.i("1-------->>>",System.currentTimeMillis()+"");

        if(arrayList!=null && arrayList.size()>0){
            if(((HashMap)arrayList.get(0)).get("title") == null){//城区级别数据
                if(!arrayList.toString().contains("true")){
                    parentName = "";
                    districtName = "";
                }
            }
            for(int i = 0; i < arrayList.size();i++){
                if(i==0){
                    searchDistrictTag = true;
                }
                HashMap map = (HashMap) arrayList.get(i);
                if(map.get("y") == null || map.get("x") == null){
                    return;
                }
                new Thread(new Runnable() {
                    @Override
                    public void run() {
                        handler.sendMessage(handler.obtainMessage(1,map));
                    }
                }).start();
            }

//            new Thread(new Runnable() {
//                @Override
//                public void run() {
//                    getMarkers(arrayList);
//                }
//            }).start();
        }

//              BitmapDescriptor bitmap = BitmapDescriptorFactory.fromResource(R.drawable.popup);

//                themedReactContext.runOnUiQueueThread(new Runnable() {
//                    @Override
//                    public void run() {
//
//                    }
//                });
//            baidumap.setMapStatus(MapStatusUpdateFactory.newLatLng(marker.getPosition()));

//            baidumap.setOnMarkerClickListener(new BaiduMap.OnMarkerClickListener() {
//                //marker被点击时回调的方法
//                //若响应点击事件，返回true，否则返回false
//                //默认返回false
//                @Override
//                public boolean onMarkerClick(Marker marker) {
//                    Log.i("androidMarkerClick-->", marker.getTitle());
//                    Log.i("androidMarkerClick-zoom", baidumap.getMapStatus().zoom+"");
//                    if(baidumap.getMapStatus().zoom<14){
//                        baidumap.setMapStatus(MapStatusUpdateFactory.zoomTo(15));
////                        baidumap.setMapStatus(MapStatusUpdateFactory.newLatLngZoom(marker.getPosition(),15));
//                    }else{
////                        baidumap.setMapStatus(MapStatusUpdateFactory.newLatLng(marker.getPosition()));
//                    }
//                    baidumap.setMapStatus(MapStatusUpdateFactory.newLatLng(marker.getPosition()));
////                    baidumap.setMapStatus(MapStatusUpdateFactory.zoomTo(15));
//                    return false;
//                }
//            });

//            InfoWindow infoWindow = new InfoWindow(textView,point,-30);
//            baidumap.addOverlay(option.infoWindow(infoWindow));

//        Log.i("2-------->>>",System.currentTimeMillis()+"");
//        LocationData locationData = ConvertUtils.convert(position, LocationData.class);
//        LatLng point = ConvertUtils.convert(locationData);
//        if (point == null) {
//            return;
//        }
//        MapStatus mapStatus = new MapStatus.Builder()
//                .target(point)
//                .build();
//        MapStatusUpdate mapStatusUpdate = MapStatusUpdateFactory.newMapStatus(mapStatus);
//        mapView.getMap().setMapStatus(mapStatusUpdate);

//        BitmapDescriptor bitmap = BitmapDescriptorFactory.fromResource(R.drawable.popup);
//        //构建MarkerOption，用于在地图上添加Marker
//        OverlayOptions option = new MarkerOptions()
//                .position(point)
//                .title("百度地图测试")
//                .icon(bitmap);
//        //在地图上添加Marker，并显示
//        mapView.getMap().addOverlay(option);

        //构造CircleOptions对象
//        CircleOptions mCircleOptions = new CircleOptions().center(point)
//                .radius(100)
//                .fillColor(0xAA0000FF) //填充颜色
//                .stroke(new Stroke(5, 0xAAffffff)); //边框宽和边框颜色
//在地图上显示圆
//        Overlay mCircle = mapView.getMap().addOverlay(mCircleOptions);

        //构建TextOptions对象
//        OverlayOptions mTextOptions = new TextOptions()
//                .text("百度地图SDK") //文字内容
//                .bgColor(0xAAFFFF00) //背景色
//                .fontSize(50) //字号
//                .fontColor(0xFFFF00FF) //文字颜色
//                .position(point);
//
////在地图上显示文字覆盖物
//        Overlay mText = mapView.getMap().addOverlay(mTextOptions);
    }

    private void getMarkers(ArrayList<Object> arrayList){
        List<OverlayOptions> options = new ArrayList<>();
        for(int i = 0; i < arrayList.size();i++){
            HashMap map = (HashMap) arrayList.get(i);
            LatLng point = new LatLng(Double.valueOf(map.get("y").toString()),Double.valueOf(map.get("x").toString()));
            if (point == null) {
                return;
            }
            View popupView = LinearLayout.inflate(mapView.getContext(),R.layout.layout_area,null);
            String titleStr = "";
            if(map.get("title") != null){//项目级别数据
                titleStr = map.get("title").toString();
                popupView = LinearLayout.inflate(mapView.getContext(),R.layout.layout_project,null);
                LinearLayout layout = popupView.findViewById(R.id.ll_bg);
                ImageView iv_bg = popupView.findViewById(R.id.iv_triangle);
                layout.setBackgroundResource(map.get("selected").toString()=="true"?R.drawable.bg_project_orange:R.drawable.bg_project);
                iv_bg.setImageResource(map.get("selected").toString()=="true"?R.drawable.bg_project_triangle_orange:R.drawable.bg_project_triangle_blue);
                TextView tv_name = popupView.findViewById(R.id.text1);
                TextView tv_name2 = popupView.findViewById(R.id.text2);
                tv_name.setText(titleStr);
                tv_name2.setText(map.get("detailTextStr").toString());
            } else {
                LinearLayout layout = popupView.findViewById(R.id.ll_bg);
                if(map.containsKey("selected") && map.get("selected").toString()=="true"){
                    layout.setBackgroundResource(R.drawable.bg_round_orange);
                }else{
                    layout.setBackgroundResource(R.drawable.bg_round_blue);
                }

                TextView tv_area = popupView.findViewById(R.id.text1);
                TextView tv_num = popupView.findViewById(R.id.text2);
                //城区级别数据
                titleStr = map.get("districtName")+"";
                try {
                    int num = (int) Float.parseFloat(map.get("projectNum").toString());
                    tv_num.setText(num+"");
                }catch (Exception e){
                    tv_num.setText(map.get("projectNum").toString());
                }

                tv_area.setText(titleStr);
            }
            options.add(new MarkerOptions().position(point).icon(BitmapDescriptorFactory.fromView(popupView)).title(titleStr));
        }

        handler.sendMessage(handler.obtainMessage(2,options));
    }


    @ReactProp(name = "zoomControlsVisible")
    public void setZoomControlsVisible(MapView mapView, boolean zoomControlsVisible) {
        mapView.showZoomControls(zoomControlsVisible);
    }

    @ReactProp(name="trafficEnabled")
    public void setTrafficEnabled(MapView mapView, boolean trafficEnabled) {
        mapView.getMap().setTrafficEnabled(trafficEnabled);
    }

    @ReactProp(name="baiduHeatMapEnabled")
    public void setBaiduHeatMapEnabled(MapView mapView, boolean baiduHeatMapEnabled) {
        mapView.getMap().setBaiduHeatMapEnabled(baiduHeatMapEnabled);
    }

    @ReactProp(name = "mapType")
    public void setMapType(MapView mapView, int mapType) {
        mapView.getMap().setMapType(mapType);
    }

    @ReactProp(name="zoom")
    public void setZoom(MapView mapView, float zoom) {
        MapStatus mapStatus = new MapStatus.Builder().zoom(zoom).build();
        MapStatusUpdate mapStatusUpdate = MapStatusUpdateFactory.newMapStatus(mapStatus);
        mapView.getMap().setMapStatus(mapStatusUpdate);
    }

    @ReactProp(name = "showsUserLocation")
    public void setShowsUserLocation(MapView mapView, boolean showsUserLocation) {
        mapView.getMap().setMyLocationEnabled(showsUserLocation);
    }

    @ReactProp(name = "locationData")
    public void setLocationData(MapView mapView, ReadableMap readableMap) {
        LocationData locationData = ConvertUtils.convert(readableMap, LocationData.class);
        if (locationData == null || !locationData.isValid()) {
            return;
        }
        MyLocationData.Builder builder = new MyLocationData.Builder()
                .latitude(locationData.getLatitude())
                .longitude(locationData.getLongitude());
        if (locationData.getDirection() != null) {
            builder.direction(locationData.getDirection().floatValue());
        }
        if (locationData.getSpeed() != null) {
            builder.speed(locationData.getSpeed().floatValue());
        }
        mapView.getMap().setMyLocationData(builder.build());
    }

    @ReactProp(name="zoomGesturesEnabled")
    public void setGesturesEnabled(MapView mapView, boolean zoomGesturesEnabled) {
        UiSettings setting = mapView.getMap().getUiSettings();
        setting.setZoomGesturesEnabled(zoomGesturesEnabled);
    }

    @ReactProp(name="scrollGesturesEnabled")
    public void setScrollEnabled(MapView mapView, boolean scrollGesturesEnabled) {
        UiSettings setting = mapView.getMap().getUiSettings();
        setting.setScrollGesturesEnabled(scrollGesturesEnabled);
    }

    @ReactProp(name="center")
    public void setCenter(MapView mapView, ReadableMap position) {
        LocationData locationData = ConvertUtils.convert(position, LocationData.class);
        LatLng point = ConvertUtils.convert(locationData);
        if (point == null) {
            return;
        }
        MapStatus mapStatus = new MapStatus.Builder()
                .target(point)
                .build();
        MapStatusUpdate mapStatusUpdate = MapStatusUpdateFactory.newMapStatus(mapStatus);
        mapView.getMap().setMapStatus(mapStatusUpdate);
    }

    @ReactProp(name = "childrenCount")
    public void setChildrenCount(MapView mapView, Integer childrenCount) {
        Log.i("MapViewManager", "childrenCount:" + childrenCount);
        this.childrenCount = childrenCount;
    }

    private void removeOldChildViews(BaiduMap baiduMap) {
        for (Object child : children) {
            if (child instanceof OverlayView) {
                ((OverlayView) child).removeFromMap(baiduMap);
            }
        }
        children.clear();
    }
}
