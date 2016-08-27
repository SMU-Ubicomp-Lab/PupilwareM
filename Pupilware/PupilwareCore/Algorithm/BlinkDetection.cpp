//
//  mdStarbust.cpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 5/25/16.
//  Copyright © 2016 Chatchai Wangwiwattana. All rights reserved.
//

#include "BlinkDetection.hpp"

namespace pw {

    BlinkDetection::BlinkDetection(const std::string& name):IPupilAlgorithm(name){
//        window = std::make_shared<CVWindow>(getName() + " Debug");
//        window->resize(500, 500);
//        window->moveWindow(200,300);
    }

    BlinkDetection::~BlinkDetection()
    {
        
    }

    
    void BlinkDetection::init()
    {
        // Init code here
        std::cout << "Init My Algorithm." << std::endl;
    }


    PWPupilSize BlinkDetection::process( const cv::Mat& src, const PWFaceMeta &meta )
    {
        cv::Mat leftEye = src(meta.getLeftEyeRect());
        cv::Mat rightEye = src(meta.getRightEyeRect());

        std::vector<cv::Mat> bgr_planes;
        cv::split(leftEye, bgr_planes);

        cv::Mat leftEyeGray = bgr_planes[2]; //green channel;
//        cv::cvtColor(leftEye, leftEyeGray, CV_BGR2GRAY);
        const float th = 0.04;

        int threshold = cw::calDynamicThreshold( leftEyeGray, th);

        cv::Mat binaryMat, binaryMatRed;
        cv::threshold(leftEyeGray, binaryMat, threshold, 255, CV_THRESH_BINARY );
        cw::closeOperation(binaryMat, binaryMat, 2);

        std::vector<std::vector<cv::Point>> contours;
        std::vector<cv::Vec4i> hierarchy;
        findContours( binaryMat, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );


        int maxSize = -999;
        int bigBlobIndex = 0;
        for( int i=0; i < contours.size(); ++i ){

            if( maxSize < (int)contours[i].size() )
            {
                maxSize = contours[i].size();
                bigBlobIndex = i;
            }
        }

        cv::Rect boundRect = cv::boundingRect( cv::Mat( contours[bigBlobIndex] ) );

        cv::Mat debug = leftEye.clone();
        cv::drawContours(debug, contours, bigBlobIndex, cv::Scalar(0,0,255),1);



        size_t count = 0;
        for(int row=0; row<binaryMat.rows; ++row){
            for (int col = 0; col < binaryMat.cols; ++col) {
                if(*binaryMat.ptr<unsigned char>(row,col) == 0){
                    count ++;
                }
            }
        }

        float blink = 0.0f;
        if ((boundRect.height / (float)boundRect.width) < 0.7f ){
            blink = 0.05f;
            rectangle( debug, boundRect.tl(), boundRect.br(), cv::Scalar(0,255,255), 1, 8, 0 );
        }
        else
        {
            rectangle( debug, boundRect.tl(), boundRect.br(), cv::Scalar(255,0,255), 1, 8, 0 );
        }

//
//        cw::showImage("th", binaryMat);
//        cw::showImage("blink",debug);

//        cw::showHist("hist", leftEyeGray);
//        cw::showHistRGB("histRGB", leftEye);
//        cw::showHistRGB("histRGBRight", rightEye);

        
        this->debugImage = std::move(debug);
        
        return PWPupilSize( blink, 0.0f);
    }


    void BlinkDetection::exit()
    {
        std::cout << " Close my algorithm " << std::endl;
    }
    
    const cv::Mat& BlinkDetection::getDebugImage() const{
        return this->debugImage;
    }
}