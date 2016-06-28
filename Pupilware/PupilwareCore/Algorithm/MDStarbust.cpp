//
//  mdStarbust.cpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 5/25/16.
//  Copyright © 2016 Chatchai Wangwiwattana. All rights reserved.
//

#include "MDStarbust.hpp"
#include "../Helpers/math/Ransac.h"

using namespace cv;
using namespace std;

namespace pw {

    MDStarbust::MDStarbust( const string& name ):
    IPupilAlgorithm(name),
    threshold(25),
    rayNumber(15),
    degreeOffset(25),
    primer(1 * precision),
    _oldLeftRadius(0.0f),
    _oldRightRadius(0.0f){

    }

    MDStarbust::~MDStarbust()
    {

    }

    void MDStarbust::init()
    {
        window = std::make_shared<CVWindow>(getName() + " Debug");
        window->addTrackbar("degree offset", &degreeOffset, 180);
        window->addTrackbar("ray number",&rayNumber, 200);
        window->addTrackbar("threshold", &threshold, 255 );
        window->addTrackbar("primer", &primer, precision*100);
    }

    PWPupilSize MDStarbust::process( const cv::Mat src, const PWFaceMeta &meta )
    {
//        float leftPupilRadius = max(findPupilSize(colorLeftEye, pupilMeta.getLeftEyeCenter(), "left eye"), _oldLeftRadius);
//        float rightPupilRadius = max(findPupilSize(colorRightEye, pupilMeta.getRightEyeCenter(), "right eye"), _oldRightRadius);

        Mat debugLeftEye = src.clone();
        float leftPupilRadius = findPupilSize(  src
                                              , meta.getLeftEyeCenter()
                                              , debugLeftEye );


        Mat debugRightEye = src.clone();
        float rightPupilRadius = findPupilSize(  src
                                               , meta.getRightEyeCenter()
                                               , debugRightEye );

        //! Store data for next frame used.
        _oldLeftRadius = leftPupilRadius;
        _oldRightRadius = rightPupilRadius;

        Mat debugImg;
        hconcat(debugLeftEye(meta.getLeftEyeRect()),
                debugRightEye(meta.getRightEyeRect()),
                debugImg);
        window->update(debugImg);

        return PWPupilSize(  leftPupilRadius
                           , rightPupilRadius );

    }

    float MDStarbust::findPupilSize(const Mat &src,
                                    cv::Point eyeCenter,
                                    Mat &debugImg) const {

        vector<Mat> rgbChannels(3);
        split(src, rgbChannels);

        // Only use a red channel.
        Mat srcGray = rgbChannels[2];

        increaseContrast(srcGray, eyeCenter);

        vector<Point2f>rays;
        createRays(rays);

        vector<Point2f>edgePoints;
        findEdgePoints(srcGray, eyeCenter, rays, edgePoints, debugImg);

        if(edgePoints.size() > MIN_NUM_RAYS)
        {
            const float MAX_ERROR_FROM_EDGE_OF_THE_CIRCLE = 1;
            vector<Point2f> inliers;

            //TODO: Parameterized RANSAC class. Can be done after clean up RANSAC class.
            Ransac r;
            r.ransac_circle_fitting(edgePoints,
                                    static_cast<int>(edgePoints.size()),
                                    edgePoints.size()*0.2f,
                                    0.0f ,
                                    MAX_ERROR_FROM_EDGE_OF_THE_CIRCLE,
                                    edgePoints.size()*0.99f,
                                    inliers);


            //---------------------------------------------------------------------------------
            //! Just assigned the best model to PupilMeta object.
            //---------------------------------------------------------------------------------
            if (inliers.size() > MIM_NUM_INLIER_POINTS)
            {
                RotatedRect myEllipse = fitEllipse( inliers );

                float eyeRadius = 0.0f;

                if(isValidEllipse(myEllipse))
                {
                    //TODO: Use RANSAC Circle radius? How about Ellipse wight?
                    eyeRadius = r.bestModel.GetRadius();
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
                            Scalar(255,50,255) );


                return eyeRadius;
            }

        }

        return 0.0f;
    }


    bool MDStarbust::isValidEllipse(const RotatedRect &theEllipse) const {
        return max(theEllipse.size.width, theEllipse.size.height) /
                       min(theEllipse.size.width, theEllipse.size.height) < 1.5;
    }


    void MDStarbust::findEdgePoints(Mat srcGray,
                                    const Point &startingPoint,
                                    const vector<Point2f> &rays,
                                    vector<Point2f> &outEdgePoints, Mat debugColorEye) const {


        Point seedPoint = Point(startingPoint.x, startingPoint.y);

        for( int iter = 0; iter < STARBURST_ITERATION; iter++ )
        {

            uchar *seed_intensity = srcGray.ptr<uchar>(startingPoint.y, startingPoint.x);

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
                    nextPoint.x = min(max(nextPoint.x,0),srcGray.cols - 1);
                    nextPoint.y = min(max(nextPoint.y,0),srcGray.rows - 1);

                    uchar nextPointIntensity = *srcGray.ptr<uchar>(nextPoint.y, nextPoint.x);

                    walking_intensity = nextPointIntensity;
                    walking_point = nextPoint;

                    if((walking_intensity - *seed_intensity - getCost(i)) > threshold)
                    {
                        outEdgePoints.push_back(nextPoint);
                        break;
                    }
                }

            }

            // Prepare for next iteration
            if( outEdgePoints.size() > 0)
            {
                // Draw points to the debug image.
                for( int i=0; i<outEdgePoints.size(); i++ )
                {
                    *debugColorEye.ptr<Vec3b>(outEdgePoints[i].y, outEdgePoints[i].x) = Vec3b(0,255,0); // green
                }

                /*!
                 * Traditional Starbust algorithm, a new seed point will be
                 * the mean of all points from previous iteration.
                 *
                 * Uncomment it if you want to use this one. ;)
                 **/

                /*
                int sum_x = 0;
                int sum_y = 0;
                for( int i=0; i<outEdgePoints.size(); i++ )
                {
                    sum_x += outEdgePoints[i].x;
                    sum_y += outEdgePoints[i].y;
                }

                int mean_point_x = sum_x / outEdgePoints.size();
                int mean_point_y = sum_y / outEdgePoints.size();

                int r_x = cw::randomRange(0,1);
                int r_y = cw::randomRange(-4,0);

                seedPoint.x = mean_point_x;
                seedPoint.y = mean_point_y;

                seedPoint.x = min(max(mean_point_x, 0),grayEye.cols - 1);
                seedPoint.y = min(max(mean_point_y, 0),grayEye.rows - 1);

                circle( debugColorEye, Point(mean_point_x, mean_point_y), 1, Scalar(0,0,255));
                */


            }
        }

    }

    float MDStarbust::getCost(int step) const {
        return ((primer/precision) * (MAX_WALKING_STEPS - step));
    }


    void MDStarbust::createRays(vector<Point2f> &rays) const {

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


    void MDStarbust::increaseContrast(const Mat &grayEye, const Point &eyeCenter) const {
        Rect pupil_area = Rect(max(eyeCenter.x - 20, 0),
                               max(eyeCenter.y-20,0),
                               min( grayEye.cols - eyeCenter.x ,40),
                               min( grayEye.rows - eyeCenter.y ,40));

        medianBlur(grayEye, grayEye, 3);

        equalizeHist(grayEye(pupil_area),
                     grayEye(pupil_area));
    }


    void MDStarbust::exit()
    {
        // Clean up code here.
    }
}