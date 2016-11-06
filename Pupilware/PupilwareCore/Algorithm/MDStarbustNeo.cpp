//
//  mdStarbust.cpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 5/25/16.
//  Copyright © 2016 Chatchai Wangwiwattana. All rights reserved.
//

#include "MDStarbustNeo.hpp"
#include "../Helpers/math/Ransac.h"
#include "../Helpers/PWGraph.hpp"
#include "../SignalProcessing/SignalProcessingHelper.hpp"
#include "../Helpers/math/Snakuscules.hpp"

using namespace cv;
using namespace std;

namespace pw {

    MDStarbustNeo::MDStarbustNeo( const string& name ):
            IPupilAlgorithm(name),
            threshold(0.014),
            rayNumber(17),
            degreeOffset(0),
            prior(0.5f),
            sigma(0.2f){

    }

    MDStarbustNeo::~MDStarbustNeo()
    {

    }
    

    void MDStarbustNeo::init()
    {
        window = std::make_shared<CVWindow>(getName() + " Debug");
        window->resize(500, 500);
        window->moveWindow(200,300);
        window->addTrackbar("degree offset", &degreeOffset, 180);
        window->addTrackbar("ray number",&rayNumber, 200);
//        window->addTrackbar("threshold", &threshold, 255 );
//        window->addTrackbar("primer", &prior, precision*100);
        
        
        createRays(rays);
    
    }

    // TODO: Bad practice, please refactor it.
    float buff_mpi = 0.0f;
    
    PWPupilSize MDStarbustNeo::process( const cv::Mat& src, const PWFaceMeta &meta )
    {
        assert(!src.empty());
        
        cv::Point leftEyeCenterEyeCoord( meta.getLeftEyeCenter().x - meta.getLeftEyeRect().x ,
                                         meta.getLeftEyeCenter().y - meta.getLeftEyeRect().y );
        
        Mat debugLeftEye = src(meta.getLeftEyeRect()).clone();
        float leftPupilRadius = findPupilSize( src(meta.getLeftEyeRect())
                , leftEyeCenterEyeCoord
                , debugLeftEye );

        float leftMPI = buff_mpi;

        cv::Point rightEyeCenterEyeCoord( meta.getRightEyeCenter().x - meta.getRightEyeRect().x ,
                                          meta.getRightEyeCenter().y - meta.getRightEyeRect().y);
        
        Mat debugRightEye = src(meta.getRightEyeRect()).clone();
        float rightPupilRadius = findPupilSize( src(meta.getRightEyeRect())
                , rightEyeCenterEyeCoord
                , debugRightEye );

        float rightMPI = buff_mpi;
        
        Mat debugImg;
        hconcat(debugLeftEye,
                debugRightEye,
                debugImg);
        
        window->update(debugImg);
        
        this->debugImage = debugImg;

        return PWPupilSize( leftPupilRadius / meta.getEyeDistancePx()
                            ,rightPupilRadius / meta.getEyeDistancePx()
                            ,leftMPI
                            ,rightMPI);

    }


    float MDStarbustNeo::findPupilSize(const Mat &colorEyeFrame,
                                       cv::Point eyeCenter,
                                       Mat &debugImg) const {

        vector<Mat> rgbChannels(3);
        split(colorEyeFrame, rgbChannels);

        if(rgbChannels.size() <= 0 ) return 0.0f;

        // Only use a red channel.
        Mat grayEye = rgbChannels[2];
        
        
        Mat blur;
        cv::GaussianBlur(grayEye, blur,Size(5,5), 7);

        
/*-------- Snakucules Method ----------*/
        cv::Point cPoint = eyeCenter;
        Snakuscules sn;
        sn.fit(blur,               // src image
               cPoint,             // initial seed point
               grayEye.cols*0.1,   // radius
               2.0,                // alpha
               20                  // max iteration
        );
        cPoint = sn.getFitCenter();
        eyeCenter = cPoint;
        int innerRadius = max(1, (int)sn.getInnerRadius()-3);
        
        buff_mpi = calMPI(blur, innerRadius, cPoint);

        
        circle( debugImg,
                eyeCenter,
                innerRadius,
                Scalar(200,200,0) );
/*-------------------------------------*/

        vector<Point2f>edgePoints;
        findEdgePoints(grayEye, eyeCenter, rays, edgePoints, debugImg);


        if(edgePoints.size() > MIN_NUM_RAYS)
        {


            //---------------------------------------------------------------------------------
            //! Just assigned the best model to PupilMeta object.
            //---------------------------------------------------------------------------------
            if (edgePoints.size() > MIM_NUM_INLIER_POINTS)
            {
                RotatedRect myEllipse = fitEllipse( edgePoints );

                float eyeRadius = 0.0f;
                float area = 0.0f;
                float voting = 0.0f;

                float sum = 0.0f;
                for (int i = 0; i < edgePoints.size(); ++i) {
                    sum += cw::calDistanceSq(edgePoints[i], eyeCenter);

                }


                voting = sqrtf(sum/(float)edgePoints.size());
                area = (myEllipse.size.width * myEllipse.size.height);

                eyeRadius = area;
   

                //---------------------------------------------------------------------------------
                //! Draw debug image
                //---------------------------------------------------------------------------------
                ellipse( debugImg, myEllipse, Scalar(255,50,0) );

                circle( debugImg,
                        eyeCenter,
                        voting,
                        Scalar(50,200,0) );


                return eyeRadius;
            }

        }

        return 0.0f;
    }


    bool MDStarbustNeo::isValidEllipse(const RotatedRect &theEllipse) const {
        return max(theEllipse.size.width, theEllipse.size.height) /
               min(theEllipse.size.width, theEllipse.size.height) < 1.5;
    }


    void MDStarbustNeo::findEdgePoints(Mat grayEye,
                                    const Point &startingPoint,
                                    const vector<Point2f> &rays,
                                    vector<Point2f> &outEdgePoints,
                                    Mat debugColorEye) const {

        const unsigned int MAX_WALKING_STEPS = grayEye.cols * 0.1f;

        Mat debugGray = Mat::zeros(grayEye.rows, grayEye.cols, CV_8UC1);

        const int blurKernalSize = 1;

        Mat blur;
        cv::GaussianBlur(grayEye, blur, Size(blurKernalSize*2+1,blurKernalSize*2+1), 3);

        int th = cw::calDynamicThreshold(blur, threshold);

        Mat walkMat = grayEye;
        cv::threshold(grayEye, walkMat, th, 255, CV_THRESH_TRUNC);

//        {
//            int ksize = grayEye.cols * 0.07; // can I make it bigger? let test it.
//            float sigma = ksize * this->sigma;
//            Mat kernelX = getGaussianKernel(ksize, sigma);
//            Mat kernelY = getGaussianKernel(ksize, sigma);
//            Mat kernelXY = kernelX * kernelY.t();
//
//            // find min and max values in kernelXY.
//            double min;
//            double max;
//            cv::minMaxIdx(kernelXY, &min, &max);
//            
//            // scale kernelXY to 0-255 range;
//            cv::Mat maskImage;
//            cv::convertScaleAbs(kernelXY, maskImage, 255 / max);
//
//            // create a rect that have the same size as the gausian kernel,
//            // locating it at the eye center.
//            const float haftKernalSize = kernelXY.cols/2;
//            cv::Rect r;
//
//            r.x = std::fmax(0,startingPoint.x - haftKernalSize);
//            r.y = std::fmax(0,startingPoint.y - haftKernalSize);
//            r.width = std::min(kernelXY.cols, walkMat.cols-r.x);
//            r.height = std::min(kernelXY.rows, walkMat.rows-r.y);
//            
//            //
//            walkMat(r) = walkMat(r) - (maskImage(cv::Rect(0,0,r.width,r.height))*this->prior);
//            
//        }

        Point seedPoint = startingPoint;

        std::vector<cv::Point> edgePointThisRound;

        for( int iter = 0; iter < STARBURST_ITERATION; iter++ )
        {
            edgePointThisRound.clear();
//            uchar *seed_intensity = walkMat.ptr<uchar>(seedPoint.y, seedPoint.x);

            for(auto r = rays.begin(); r != rays.end(); r++)
            {
                Point walking_point = seedPoint;
                int walking_intensity = 0;

                for( int i=0; i < MAX_WALKING_STEPS; i++ )
                {
                    Point nextPoint;
                    nextPoint.y = seedPoint.y+(i* r->y);
                    nextPoint.x = seedPoint.x+(r->x * i);

                    /* Make sure next point is out of bound. */
                    nextPoint.x = min(max(nextPoint.x,0),walkMat.cols - 1);
                    nextPoint.y = min(max(nextPoint.y,0),walkMat.rows - 1);

                    uchar nextPointIntensity = *walkMat.ptr<uchar>(nextPoint.y, nextPoint.x);

                    walking_intensity = nextPointIntensity;
                    walking_point = nextPoint;
                    

                    if((walking_intensity ) >= th )
                    {
                        outEdgePoints.push_back(nextPoint);
                        edgePointThisRound.push_back(nextPoint);
                        break;
                    }
                }

            }

            /* Prepare for next iteration */
            if( edgePointThisRound.size() > 0)
            {
                /* Draw points to the debug image. */
                for( int i=0; i<edgePointThisRound.size(); i++ )
                {
                    *debugColorEye.ptr<Vec3b>(edgePointThisRound[i].y, edgePointThisRound[i].x) = Vec3b(0,255,0);
                }


                int sum_x = 0;
                int sum_y = 0;
                for( int i=0; i<edgePointThisRound.size(); i++ )
                {
                    sum_x += edgePointThisRound[i].x;
                    sum_y += edgePointThisRound[i].y;
                }

                int mean_point_x = sum_x / edgePointThisRound.size();
                int mean_point_y = sum_y / edgePointThisRound.size();

                seedPoint.x = mean_point_x;
                seedPoint.y = mean_point_y;

                seedPoint.x = min(max(mean_point_x, 0),grayEye.cols - 1);
                seedPoint.y = min(max(mean_point_y, 0),grayEye.rows - 1);

                circle( debugColorEye, Point(mean_point_x, mean_point_y), 2, Scalar(0,255,255));


            }


        }

        /* Draw points to the debug image. */
//        for( int i=0; i<edgePointThisRound.size(); i++ )
//        {
//            *debugColorEye.ptr<Vec3b>(edgePointThisRound[i].y, edgePointThisRound[i].x) = Vec3b(255,0,0);
//        }

//        outEdgePoints.assign(edgePointThisRound.begin(), edgePointThisRound.end());
    }
    
    float MDStarbustNeo::calMPI( const cv::Mat& grayEye, int irisRadius, cv::Point eyeCenter) const{
        
        if(irisRadius<=0) return 0.0f;
        if(grayEye.empty()) return 0.0f;
        
        float mpi = 0.0f;
        
        cv::Rect irisRect(eyeCenter.x-irisRadius,
                          eyeCenter.y-irisRadius,
                          min(irisRadius*2, grayEye.cols - eyeCenter.x-irisRadius-1),
                          min(irisRadius*2, grayEye.rows - eyeCenter.y-irisRadius-1));
        
        if(irisRect.width < 1 ) return 0.0f;
        if(irisRect.height < 1 ) return 0.0f;
        
        mpi = cv::mean(grayEye(irisRect)).val[0];
        
        return mpi;
    }


    void MDStarbustNeo::createRays(vector<Point2f> &rays) const {

        float radiansOffset = (degreeOffset * M_PI / 180.0f);

        const float step = (2*M_PI - (radiansOffset*2))/float(rayNumber);
        
        std::cout << "creating rays : " << rayNumber << "rays, " << " with degree " << degreeOffset << std::endl;

        /* The circle walk counter clock wise, because OpenCV is 'y' top->down.
         * The beginning of rays are at the top of circle,
         * and moves aways to the left and right with the number of offset
         */
        const float startLoc = -M_PI_2 + radiansOffset;
        const float endLoc = M_PI + M_PI_2 - radiansOffset;

        for(float i=startLoc; i < (endLoc); i+= step )
        {
            rays.push_back( Point2f( cos(i), sin(i)) );
        }
    }
    

    const cv::Mat& MDStarbustNeo::getDebugImage() const{
        return this->debugImage;
    }
    

    void MDStarbustNeo::exit()
    {
        // Clean up code here.
    }
    
    
    void MDStarbustNeo::setThreshold( float value ){
        threshold = fmax(value, 0);
        if (threshold > 1) {
            threshold = 1;
        }
    }
    
    void MDStarbustNeo::setRayNumber( int value ){
        rayNumber = max(value, 0);
    }
    
    void MDStarbustNeo::setDegreeOffset( int value ){
        degreeOffset = min(max(value, 0), 355);
    }
    
    void MDStarbustNeo::setPrior( float value ){
        prior = fmax(value, 0);
    }
    
    void MDStarbustNeo::setSigma( float value ){
        sigma = fmax(value, 0);
    }
    
}
