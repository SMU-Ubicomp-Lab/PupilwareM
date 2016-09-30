//
//  PWFaceLandmarkDetector.cpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 9/29/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

#include "PWFaceLandmarkDetector.hpp"

#include <dlib/opencv.h>

namespace pw{
    
    PWFaceLandmarkDetector::PWFaceLandmarkDetector(){
        
    }

    void PWFaceLandmarkDetector::loadLandmarkFile(const std::string& landmarkFilePath){
        
        this->landmarkFilePath = landmarkFilePath;
        dlib::deserialize(landmarkFilePath) >> sp;
        
        std::cout << "Landmark has loaded" << std::endl;
    }
    
    
    void PWFaceLandmarkDetector::searchLandMark( const cv::Mat& frameBGR,cv::Mat& out, cv::Rect faceLoc ){
        
        // Convert to dlib image
        dlib::array2d<dlib::bgr_pixel> dlibimg;
        dlib::assign_image(dlibimg, dlib::cv_image<dlib::bgr_pixel>(frameBGR));
        
        
        dlib::rectangle oneFaceRect(faceLoc.x, faceLoc.y, faceLoc.x+faceLoc.width, faceLoc.y+faceLoc.height);
        
        // detect all landmarks
        dlib::full_object_detection shape = sp(dlibimg, oneFaceRect);
        
        // and draw them into the image (samplebuffer)
        for (unsigned long k = 0; k < shape.num_parts(); k++) {
            dlib::point p = shape.part(k);
            draw_solid_circle(dlibimg, p, 3, dlib::rgb_pixel(0, 255, 255));
        }
        
        // convert back to OpenCV-Mat
        out = dlib::toMat(dlibimg).clone();

    }
}