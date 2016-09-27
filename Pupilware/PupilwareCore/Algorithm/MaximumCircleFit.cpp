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
#include "../SignalProcessing/SignalProcessingHelper.hpp"

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

        // intialization of KF...
        KF.init(2, 1, 0);
        KF.transitionMatrix = (Mat_<float>(2, 2) << 1, 1, 0, 1);

        setIdentity(KF.measurementMatrix);
        setIdentity(KF.processNoiseCov, Scalar::all(1e-5));
        setIdentity(KF.measurementNoiseCov, Scalar::all(0.02));
        setIdentity(KF.errorCovPost, Scalar::all(1));
    
    }

    std::vector<float> smooth;
    std::vector<float> pupilSize;
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


//        pupilSize.push_back(leftPupilRadius);
//
//        cw::trimMeanFilt(pupilSize, smooth, 31);
//        // big
//        const float kMinValue = 4.0f;
//        const float kMaxValue = 15.0f;
//        auto g = PWGraph("smooth");
//        g.drawGraph("soom", smooth, Scalar(0,0,255), kMinValue, kMaxValue);
//        g.show();

//        float rightPupilRadius = 1;

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

        if(rgbChannels.size() <= 0 ) return 0.0f;
        // Only use a red channel.
        Mat grayEye = rgbChannels[2];

        Mat blur;
        cv::GaussianBlur(grayEye, blur,Size(15,15), 7);

/*-------- Snakucules Method ----------*/
        cv::Point cPoint = eyeCenter;
        Snakuscules sn;
        sn.fit(blur,               // src image
                cPoint,             // initial seed point
                grayEye.cols*0.1,   // radius
                2.0,                // alpha
                20                  // max iteration
                );
        eyeCenter = sn.getFitCenter();
        int irisRadius = sn.getInnerRadius();
        circle( debugImg,
                eyeCenter,
                irisRadius,
                Scalar(200,200,0) );
/*-------------------------------------*/

            int ksize = irisRadius*2;
            float sigma = 2;
            Mat kernelX = getGaussianKernel(ksize, sigma);
            Mat kernelY = getGaussianKernel(ksize, sigma);
            Mat kernelXY = kernelX * kernelY.t();

            // find min and max values in kernelXY.
            double min;
            double max;
            cv::minMaxIdx(kernelXY, &min, &max);

            // scale kernelXY to 0-255 range;
            cv::Mat maskImage;
            cv::convertScaleAbs(kernelXY, maskImage, 255 / max);

            // create a rect that have the same size as the gausian kernel,
            // locating it at the eye center.
            cv::Rect r;
            r.width = kernelXY.cols;
            r.height = kernelXY.rows;
            r.x = std::max(0,eyeCenter.x - r.width/2);
            r.y = std::max(0,eyeCenter.y - r.height/2);

        const int tx = std::fmax(eyeCenter.x - irisRadius,0);
        const int ty = std::fmax(eyeCenter.y - irisRadius,0);
        const int t_height = (irisRadius*2 + ty) >= blur.rows? blur.rows - eyeCenter.y :irisRadius*2;
        const int t_width = (irisRadius*2 + tx) >= blur.cols? blur.cols - eyeCenter.x :irisRadius*2;
        Mat iris = blur(Rect( tx, ty, t_width, t_height));
        cv::equalizeHist(iris,iris);

        blur(r) = blur(r) - (maskImage(cv::Rect(0,0,t_width, t_height))*0.5);

//        cw::showImage("open", iris);
//        cw::showImage("m", maskImage);

/*-------- Snakucules Method ----------*/
        Snakuscules sn2;
        sn2.fit(blur,               // src image
               cPoint,             // initial seed point
               irisRadius*0.3,   // radius
               1.6,                // alpha
               10                  // max iteration
        );
        Point pPoint = sn2.getFitCenter();
        int pupilRadius = sn2.getInnerRadius();
        circle( debugImg,
                eyeCenter,
                pupilRadius,
                Scalar(200,0,200) );
        circle( debugImg,
                eyeCenter,
                sn2.getOuterRadius(),
                Scalar(200,0,200) );
/*-------------------------------------*/


//        float maxE = -1000;
//        int maxR = 1;
//
//        std::cout << ">>> start " << std::endl;
//        for (int r = 1; r < irisRadius-2; ++r) {
//            size_t bigSum = 0;
//            size_t bigCount = 1; //not 0 to avoid divide by zero
//            size_t smallSum = 0;
//            size_t smallCount = 1;
//
//            calCircularEnergy(grayEye, eyeCenter, r+2, bigSum, bigCount);
//            calCircularEnergy(grayEye, eyeCenter, r, smallSum, smallCount);
//
//            float e1 = (bigSum - smallSum) / (double)(bigCount-smallCount);
//            float e2 = smallSum / smallCount;
//            float e = e1 - e2;
//
//            std::cout << e1 << " , " << e2 << ", " << e << std::endl;
//
//            if(e > maxE)
//            {
//                maxE = e;
//                maxR = r;
//            }
//
//        }
//
//        std::cout << "<<<--- end " << maxE <<  std::endl;

//        circle( debugImg,
//                eyeCenter,
//                maxR,
//                Scalar(200,200,0) );


        return sn2.getInnerRadius();
    }

    float MaximumCircleFit::calCircularEnergy(const cv::Mat& src,
                                              const cv::Point& center,
                                              int radius, size_t& outSum, size_t& outCount){

        Mat debug = src.clone();

        const float radiusSq = radius * radius;

        size_t sum = 0;
        size_t count = 0;

        for (int i = 0; i < src.rows; ++i) {
            for (int j = 0; j < src.cols; ++j) {
                if( cw::calDistanceSq( cv::Point(j,i), center  ) < radiusSq ){
                    auto intensity = src.ptr<uchar>(i,j);
                    sum += *intensity;
                    count++;

                    *debug.ptr<uchar>(i,j) = 255;
                }

            }
        }

        cw::showImage("debug", debug, 0);

        outSum = sum;
        outCount = count;

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