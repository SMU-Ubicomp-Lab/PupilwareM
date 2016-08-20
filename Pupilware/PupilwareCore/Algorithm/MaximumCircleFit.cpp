//
//  MaximumCircleFit.cpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/20/16.
//  Copyright © 2016 Chatchai Wangwiwattana. All rights reserved.
//

#include "MaximumCircleFit.hpp"
#include "../Helpers/PWGraph.hpp"
#include "../Helpers/math/Snakuscules.hpp"
#include "../Helpers/CWCVHelper.hpp"

using namespace cv;
using namespace std;

namespace pw {

    MaximumCircleFit::MaximumCircleFit( const string& name ):
            IPupilAlgorithm(name),
            threshold(0.01),
            ticks(0.0f){

    }

    MaximumCircleFit::~MaximumCircleFit()
    {

    }


    void MaximumCircleFit::init()
    {
        window = std::make_shared<CVWindow>(getName() + " Debug");
        window->resize(500, 500);
        window->moveWindow(200,300);
//        window->addTrackbar("threshold", &threshold, 255 );


        // intialization of KF...
        KF.init(2, 1, 0);
        KF.transitionMatrix = (Mat_<float>(2, 2) << 1, 1, 0, 1);

        setIdentity(KF.measurementMatrix);
        setIdentity(KF.processNoiseCov, Scalar::all(1e-5));
        setIdentity(KF.measurementNoiseCov, Scalar::all(0.02));
        setIdentity(KF.errorCovPost, Scalar::all(1));
    
    }

    PWPupilSize MaximumCircleFit::process( const cv::Mat& src, const PWFaceMeta &meta )
    {
        assert(!src.empty());
        
        cv::Point leftEyeCenterEyeCoord( meta.getLeftEyeCenter().x - meta.getLeftEyeRect().x ,
                                         meta.getLeftEyeCenter().y - meta.getLeftEyeRect().y );
        
        Mat debugLeftEye = src(meta.getLeftEyeRect()).clone();
        float leftPupilRadius = findPupilSize( src(meta.getLeftEyeRect())
                , leftEyeCenterEyeCoord
                , debugLeftEye );


        cv::Point rightEyeCenterEyeCoord( meta.getRightEyeCenter().x - meta.getRightEyeRect().x ,
                                          meta.getRightEyeCenter().y - meta.getRightEyeRect().y);
        
        Mat debugRightEye = src(meta.getRightEyeRect()).clone();
        float rightPupilRadius = findPupilSize( src(meta.getRightEyeRect())
                , rightEyeCenterEyeCoord
                , debugRightEye );


//        float pupilSize = estimatePupilSize( leftPupilRadius/meta.getEyeDistancePx(),
//                                             rightPupilRadius/meta.getEyeDistancePx() );

        // draw debug image
        Mat debugImg;
        hconcat(debugLeftEye,
                debugRightEye,
                debugImg);
        
        window->update(debugImg);
        
        this->debugImage = debugImg;

        return PWPupilSize(  leftPupilRadius/meta.getEyeDistancePx()
                           , rightPupilRadius/meta.getEyeDistancePx() );

    }

    void MaximumCircleFit::exit()
    {
        // Clean up code here.
    }

    float MaximumCircleFit::estimatePupilSize( float leftRadius, float rightRadius){

        double precTick = ticks;
        ticks = (double) cv::getTickCount();
        double dT = (ticks - precTick) / cv::getTickFrequency(); //seconds
        KF.transitionMatrix.at<float>(1) = dT;

        Mat prediction = KF.predict();

        double predictPupilSize = 0.0;
        predictPupilSize = prediction.at<float>(0);

        float errorLeft = fabs(predictPupilSize - leftRadius);
        float errorRight = fabs(predictPupilSize - rightRadius);
        float alpha = errorLeft/( errorLeft + errorRight );


        float mesPupilRadius = ((1.0-alpha) * leftRadius) + (alpha * rightRadius);

        Mat measurement = Mat::zeros(1, 1, CV_32F);

        const float maxPupuilSize = 0.08;
        const float minPupilSize = 0.03;
        if ( (mesPupilRadius <= maxPupuilSize && mesPupilRadius >= minPupilSize) ) {
            measurement.at<float>(0) = mesPupilRadius;
            predictPupilSize = KF.correct(measurement).at<float>(0);

        }
        else{
            predictPupilSize = prediction.at<float>(0);
            std::cout << "predict " << predictPupilSize << std::endl;
        }

        return predictPupilSize;
    }


    float MaximumCircleFit::findPupilSize(const Mat &colorEyeFrame,
                                       cv::Point eyeCenter,
                                       Mat &debugImg) {

        vector<Mat> rgbChannels(3);
        split(colorEyeFrame, rgbChannels);

        // Only use a red channel.
        Mat grayEye = rgbChannels[2];
        
        
        Mat blur;
        cv::GaussianBlur(grayEye, blur,Size(3,3), 3);

        
/*-------- Snakucules Method ----------*/
        cv::Point cPoint = eyeCenter;
        Snakuscules sn;
        sn.fit(blur,               // src image
                cPoint,             // initial seed point
                grayEye.cols*0.14,   // radius
                2.0,                // alpha
                40                  // max iteration
                );
        cPoint = sn.getFitCenter();
        eyeCenter = cPoint;
        int irisRadius = sn.getInnerRadius();
        circle( debugImg,
                eyeCenter,
                irisRadius,
                Scalar(200,200,0) );
/*-------------------------------------*/

        float maxE = -1000;
        int maxR = 1;

        for (int r = 1; r < irisRadius-3; ++r) {
            float e1 = calCircularEnergy(grayEye, eyeCenter, r);
            float e2 = calCircularEnergy(grayEye, eyeCenter, r+1);
            float e = e2-e1;

            if(e > maxE)
            {
                maxE = e;
                maxR = r;
            }

        }

        circle( debugImg,
                eyeCenter,
                maxR,
                Scalar(200,200,0) );


        return maxR;
    }

    float MaximumCircleFit::calCircularEnergy(const cv::Mat& src,
                                              const cv::Point& center,
                                              int radius){

        Mat debug = src.clone();

        const float radiusSq = radius * radius;

        size_t sum = 0;
        size_t count = 0;

        for (int i = 0; i < src.rows; ++i) {
            for (int j = 0; j < src.cols; ++j) {
                if( fabs(cw::calDistanceSq( cv::Point(j,i), center  ) - radiusSq) < 20 ){
                    auto intensity = src.ptr<uchar>(i,j);
                    sum += *intensity;
                    count++;

                    *debug.ptr<uchar>(i,j) = 255;
                }

            }
        }

//        cw::showImage("debug", debug, 0);

        return sum / (double)count ;
    }


    const cv::Mat& MaximumCircleFit::getDebugImage() const{
        return this->debugImage;
    }

    
    void MaximumCircleFit::setThreshold( float value ){
        threshold = fmax(value, 0);
        if (threshold > 1) {
            threshold = 1;
        }
    }
    
}