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

using namespace cv;
using namespace std;

namespace pw {

    MDStarbustNeo::MDStarbustNeo( const string& name ):
            IPupilAlgorithm(name),
            threshold(25),
            rayNumber(15),
            degreeOffset(25),
            primer(1 * precision),
            _oldLeftRadius(0.0f),
            _oldRightRadius(0.0f){

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
        window->addTrackbar("threshold", &threshold, 255 );
        window->addTrackbar("primer", &primer, precision*100);
    }

    PWPupilSize MDStarbustNeo::process(const PupilMeta &pupilMeta)
    {
//        float leftPupilRadius = max(findPupilSize(colorLeftEye, pupilMeta.getLeftEyeCenter(), "left eye"), _oldLeftRadius);
//        float rightPupilRadius = max(findPupilSize(colorRightEye, pupilMeta.getRightEyeCenter(), "right eye"), _oldRightRadius);


        Mat debugLeftEye = pupilMeta.getLeftEyeImage().clone();
        float leftPupilRadius = findPupilSize(  pupilMeta.getLeftEyeImage()
                , pupilMeta.getLeftEyeCenter()
                , debugLeftEye );

//        float leftPupilRadius = 0.0f;


        Mat debugRightEye = pupilMeta.getRightEyeImage().clone();
        float rightPupilRadius = findPupilSize(  pupilMeta.getRightEyeImage()
                , pupilMeta.getRightEyeCenter()
                , debugRightEye );

        //! Store data for next frame used.
        _oldLeftRadius = leftPupilRadius;
        _oldRightRadius = rightPupilRadius;

        Mat debugImg;
        hconcat(debugLeftEye, debugRightEye, debugImg);
        window->update(debugImg);
        
        this->debugImg = debugImg;
        
        return PWPupilSize(  leftPupilRadius / pupilMeta.getEyeDistancePx()
                             ,rightPupilRadius/ pupilMeta.getEyeDistancePx()  );

    }

    vector<float> elps;
    vector<float> cirs;
    vector<float> areas;

    float MDStarbustNeo::findPupilSize(const Mat &colorEyeFrame,
                                    cv::Point eyeCenter,
                                    Mat &debugImg) const {

        vector<Mat> rgbChannels(3);
        split(colorEyeFrame, rgbChannels);

        // Only use a red channel.
        Mat grayEye = rgbChannels[2];


        vector<Point2f>rays;
        createRays(rays);

        vector<Point2f>edgePoints;
        findEdgePoints(grayEye, eyeCenter, rays, edgePoints, debugImg);


        if(edgePoints.size() > MIN_NUM_RAYS)
        {
            const float MAX_ERROR_FROM_EDGE_OF_THE_CIRCLE = 2;
            vector<Point2f> inliers;
//
//            //TODO: Parameterized RANSAC class. Can be done after clean up RANSAC class.
            Ransac r;
            r.ransac_circle_fitting(edgePoints,
                                    static_cast<int>(edgePoints.size()),
                                    edgePoints.size()*0.9f, // not use it
                                    0.2f ,// not use it
                                    MAX_ERROR_FROM_EDGE_OF_THE_CIRCLE,
                                    edgePoints.size()*0.8f,
                                    inliers);


            //---------------------------------------------------------------------------------
            //! Just assigned the best model to PupilMeta object.
            //---------------------------------------------------------------------------------
            if (inliers.size() > MIM_NUM_INLIER_POINTS)
            {
                RotatedRect myEllipse = fitEllipse( edgePoints );

                float eyeRadius = 0.0f;

                float elp = 0.0f;
                float cir = 0.0f;
                float area = 0.0f;

                if(isValidEllipse(myEllipse))
                {
                    //TODO: Use RANSAC Circle radius? How about Ellipse wight?

                    elp = (myEllipse.size.width + myEllipse.size.height) * 0.25f;
                    cir = r.bestModel.GetRadius();
                    area = (myEllipse.size.width * myEllipse.size.height) * 0.02f;

                    eyeRadius = elp;

                }
                else
                {
                    //TODO: Make it not ZERO. Use the old frame maybe?
                    eyeRadius = 0.0f;
                }

                //---------------------------------------------------------------------------------
                //! Draw debug image
                //---------------------------------------------------------------------------------
                ellipse( debugImg, myEllipse, Scalar(0,50,255) );


                circle( debugImg,
                            *r.bestModel.GetCenter(),
                            r.bestModel.GetRadius(),
                            Scalar(50,255,255) );

                elps.push_back(elp);
                cirs.push_back(cir);
                areas.push_back(area);

                vector<float> elpsSmooth;
                vector<float> cirsSmooth;
                vector<float> areasSmooth;

                cw::fastMedfilt(elps, elpsSmooth, 61);
                cw::fastMedfilt(cirs, cirsSmooth, 61);
                cw::fastMedfilt(areas, areasSmooth, 61);

                auto pg = std::make_shared<PWGraph>("Elps(red), Cir(blue)");
//                pg->drawGraph("elps", elps, Scalar(255,0,0), 7, 18, 0, 600);
//                pg->drawGraph("cirs", cirs, Scalar(0,0,255), 7, 18, 0, 600);
//                pg->drawGraph("areas", areas, Scalar(255,0,255), 7, 18, 0, 600);

                pg->drawGraph("elps", elpsSmooth, Scalar(255,0,0),0,0, 0, 600);
                pg->drawGraph("cirs", cirsSmooth, Scalar(0,0,255),0,0, 0, 600);
                pg->drawGraph("areas", areasSmooth, Scalar(255,0,255), 0,0, 0, 600);

                pg->show();



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

        int th = cw::calDynamicThreshold(blur, 0.01);

        Mat walkMat = grayEye;
        cv::threshold(grayEye, walkMat, th, 255, CV_THRESH_TRUNC);

        {
//            int ksize = grayEye.cols * 0.07;
//            float sigma = ksize * 0.20;
//            Mat kernelX = getGaussianKernel(ksize, sigma);
//            Mat kernelY = getGaussianKernel(ksize, sigma);
//            Mat kernelXY = kernelX * kernelY.t();
//
//            double min;
//            double max;
//            cv::minMaxIdx(kernelXY, &min, &max);
//            cv::Mat adjMap2d;
//            cv::convertScaleAbs(kernelXY, adjMap2d, 255 / max);
//
//            cv::Rect r;
//            r.width = kernelXY.cols;
//            r.height = kernelXY.rows;
//            r.x = startingPoint.x - r.width/2;
//            r.y = startingPoint.y - r.height/2;
//
//            walkMat(r) = walkMat(r) - ((adjMap2d/255.0f)*th);


        }


        cw::showImage("thth", walkMat, 1);

        Point seedPoint = startingPoint;

        std::vector<cv::Point> edgePointThisRound;

        for( int iter = 0; iter < STARBURST_ITERATION; iter++ )
        {
            edgePointThisRound.clear();
            uchar *seed_intensity = walkMat.ptr<uchar>(seedPoint.y, seedPoint.x);

            for(auto r = rays.begin(); r != rays.end(); r++)
            {
                Point walking_point = seedPoint;
                int walking_intensity = 0;

                for( int i=0; i < MAX_WALKING_STEPS; i++ )
                {
                    Point nextPoint;
                    nextPoint.y = seedPoint.y+(i* r->y);
                    nextPoint.x = seedPoint.x+(r->x * i);

                    // Make sure next point is out of bound.
                    nextPoint.x = min(max(nextPoint.x,0),walkMat.cols - 1);
                    nextPoint.y = min(max(nextPoint.y,0),walkMat.rows - 1);

                    uchar nextPointIntensity = *walkMat.ptr<uchar>(nextPoint.y, nextPoint.x);

                    walking_intensity = nextPointIntensity;
                    walking_point = nextPoint;

//                    const int cost = getCost(i, grayEye.cols, th);

                    if((walking_intensity ) >= th )
                    {
                        outEdgePoints.push_back(nextPoint);
                        edgePointThisRound.push_back(nextPoint);
                        break;
                    }
                }

            }

            // Prepare for next iteration
            if( edgePointThisRound.size() > 0)
            {
                // Draw points to the debug image.
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

        // Draw points to the debug image.
//        for( int i=0; i<edgePointThisRound.size(); i++ )
//        {
//            *debugColorEye.ptr<Vec3b>(edgePointThisRound[i].y, edgePointThisRound[i].x) = Vec3b(255,0,0);
//        }

//        outEdgePoints.assign(edgePointThisRound.begin(), edgePointThisRound.end());
    }

    float MDStarbustNeo::getCost(int step, int eyeWidth, int thresholdValue ) const {

        int ksize = eyeWidth * 0.07;
        float sigma = ksize * 0.20;

        cv::Mat gaussianKernel = cv::getGaussianKernel(ksize, sigma);


        double min;
        double max;
        cv::minMaxIdx(gaussianKernel, &min, &max);
        cv::Mat adjMap;
        cv::convertScaleAbs(gaussianKernel, adjMap, 255 / max);
        cv::imshow("Gaussian Kernel", adjMap);


        const double scale = (thresholdValue * 0.5 ) / max;

        // Start at the middle of the gaussian kernel, and walk outward.
        const int startingPoint = ksize/2;

        return *gaussianKernel.ptr<double>(startingPoint + step) * scale;
    }


    void MDStarbustNeo::createRays(vector<Point2f> &rays) const {

        // TODO: It does not have to create ray every frame.

        float radiansOffset = (degreeOffset * M_PI / 180.0f);

        const float step = (2*M_PI - (radiansOffset*2))/float(rayNumber);

        // The circle walk counter clock wise, because OpenCV is 'y' top->down.
        // The beginning of rays are at the top of circle,
        // and moves aways to the left and right with the number of offset
        const float startLoc = -M_PI_2 + radiansOffset;
        const float endLoc = M_PI + M_PI_2 - radiansOffset;

        for(float i=startLoc; i < (endLoc); i+= step )
        {
            rays.push_back( Point2f( cos(i), sin(i)) );
        }
    }



    void MDStarbustNeo::increaseContrast(const Mat &grayEye, const Point &eyeCenter) const {
        Rect pupil_area = Rect(max(eyeCenter.x - 20, 0),
                               max(eyeCenter.y - 20,0),
                               min( grayEye.cols - eyeCenter.x ,40),
                               min( grayEye.rows - eyeCenter.y ,40));

        medianBlur(grayEye, grayEye, 3);

    }


    void MDStarbustNeo::exit()
    {
        // Clean up code here.
    }
    
    const cv::Mat& MDStarbustNeo::getDebugImage() const{
        return debugImg;
    }
    
}