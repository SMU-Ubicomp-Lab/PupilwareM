//
// Created by Chatchai Wangwiwattana on 5/26/16.
//

#include "CWUIHelper.hpp"

#include "simpleGraph/GraphUtils.h"
#include "CVWindow.hpp"

namespace cw {


    void showGraph(const std::string& name,
                   const std::vector<float> &dataSrc,
                   int delayInMilliSec,
                   cv::Scalar color) {


        // No implementation on IOS version
        
    }

    int showImage(const std::string& name, const cv::Mat img, int delayInMilliSec) {
        
        
        // No implementation on IOS version
        
        return 0;
        
    }

    std::shared_ptr<pw::CVWindow> createWindow( const std::string& winName){
        return std::shared_ptr<pw::CVWindow>(new pw::CVWindow(winName));
    }

    //----------------------------------------------------------------------------
    //  Simple OpenCV Warper
    //----------------------------------------------------------------------------

    void namedWindow( const std::string& winName, int flag ){

        // No implementation on IOS version
    }


    void createTrackbar( const std::string& barName,
                         const std::string& windowName,
                         int& value, int max,
                         cv::TrackbarCallback callback ,
                         void* userData  ){

        // No implementation on IOS version
    }


    void imshow(const std::string& winName, cv::InputArray mat){

        // No implementation on IOS version
    }


    int waitKey(int delay){
        
        // No implementation on IOS version
        
        return 0;
    }

}