//
//  mdStarbust.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 5/25/16.
//  Copyright © 2016 Chatchai Wangwiwattana. All rights reserved.
//

#ifndef MDSTARBURSTNEO_HPP
#define MDSTARBURSTNEO_HPP

#include "IPupilAlgorithm.hpp"

namespace pw {

    class MDStarbustNeo : public IPupilAlgorithm {

    public:
        MDStarbustNeo( const std::string& name );
        MDStarbustNeo( const MDStarbustNeo& other)=default;
        MDStarbustNeo( MDStarbustNeo&& other)=default;
        MDStarbustNeo& operator=( const MDStarbustNeo& other)=default;
        MDStarbustNeo& operator=( MDStarbustNeo&& other)=default;
        virtual ~MDStarbustNeo();

        virtual void init() override ;

        virtual PWPupilSize process( const cv::Mat& src, const PWFaceMeta &meta ) override;

        virtual void exit() override ;
        
        const cv::Mat& getDebugImage() const;

        
        /* Setter and Getter */
        void setThreshold( float value );
        void setRayNumber( int value );
        void setDegreeOffset( int value );
        void setPrior( float value );
        void setSigma( float sigma );
        
    protected:


        // Maximum iteration of processing starbust algorithm
        const unsigned int STARBURST_ITERATION = 5;


        // Minimum number of rays before doing RANSAC circle fit algorithm
        const unsigned int MIN_NUM_RAYS = 5;


        // Minimum number of points before doing Ellipse fit algorithm
        const unsigned int MIM_NUM_INLIER_POINTS = 5;
        

        // It is used in dynamic thresholding
        float threshold;


        // Number of rays casting around a center point.
        int rayNumber;


        // Degree from the top of circle
        // it is designed for avoid eyelash shadow
        int degreeOffset;


        // Gassian Mask
        // It's used to improve a reflection problem in pupils.
        float prior;
        float sigma;

        // Just a window name for debuging
        std::shared_ptr<CVWindow> window;
        
        // Debug Image
        cv::Mat debugImage;


        // Create rays that walk from center of the eyes
        void createRays(std::vector<cv::Point2f> &rays) const;


        // Find edge points
        void findEdgePoints(cv::Mat grayEye,
                            const cv::Point &startingPoint,
                            const std::vector<cv::Point2f> &rays,
                            std::vector<cv::Point2f> &outEdgePoints,
                            cv::Mat debugColorEye) const;



        bool isValidEllipse(const cv::RotatedRect &theEllipse) const;



        // Cost function to predict if the pixel an edge or reflection
        virtual float getCost(int step, int eyeWidth, int thresholdValue) const;



        float findPupilSize(const cv::Mat &colorEyeFrame,
                            cv::Point eyeCenter,
                            cv::Mat &debugImg) const;
    };
}

#endif /* MDSTARBURSTNEO_HPP */
