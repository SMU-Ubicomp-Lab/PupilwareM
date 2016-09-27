//
// Created by Chatchai Wangwiwattana on 6/15/16.
//

#include "Snakuscules.hpp"

#include "../../preHeader.hpp"

using namespace cv;

namespace pw{
    
    /* It's used to create a radius look up table.*/
    const int MaxSqrtRadius = 300;
    std::vector<float> radiusBuffer(MaxSqrtRadius);
    

    Snakuscules::Snakuscules():
            m_center(cvPoint(0,0)),
            m_outerRadius(0.0f),
            m_innerRadius(0.0f){}


    cv::Point Snakuscules::getFitCenter() const{
        return m_center;
    }

    float Snakuscules::getOuterRadius() const{
        return m_outerRadius;
    }

    float Snakuscules::getInnerRadius() const{
        return m_innerRadius;
    }
    
    /*
     * Calculate innte radius, and create a look up table.
     * This function is called a lot! So the look up table help avoid 
     * the expensive square root operation every call.
     */
    float Snakuscules::_calInnerRadius( int radius, float alpha ){

        REQUIRES(radius < MaxSqrtRadius, "Radius must less than " << MaxSqrtRadius);

        if(radius <= 0 ){
            return 0.0f;
        }

        if(radiusBuffer[radius]<=0.0f){
            radiusBuffer[radius] = radius * (1.0/sqrt(alpha));
        }
        return radiusBuffer[radius];
    }

    
    RegionEnergy Snakuscules::_calRegionEnergy(  const cv::Mat srcGray
                                    , cv::Point center
                                    , int radius              ){

        REQUIRES( !srcGray.empty(), "The source must not be empty." );
        REQUIRES( srcGray.channels() == 1, "The source Mat must be one channel." );
        REQUIRES( radius >= 0, "the radius must be more than zero. now radius is " << radius );

        if (radius == 0) {
            return RegionEnergy(0, 0);
        }
        
        cv::Point start( center.x - radius, center.y - radius );
        cv::Point end  ( center.x + radius, center.y + radius );

        start.x = max(start.x, 0);
        start.y = max(start.y, 0);
        end.x   = min(end.x, srcGray.cols);
        end.y   = min(end.y, srcGray.rows);

        const int radiusSq = radius*radius;

        unsigned int sumIntensity = 0;
        unsigned int pixelNumber = 0;


        // Only accumulate intensity within a circle
        //
        for (int y = start.y; y < end.y; ++y) {
            for (int x = start.x; x < end.x; ++x) {

                if(   ((y - center.y) * (y - center.y))
                      +((x - center.x) * (x - center.x)) <= radiusSq  ){

                    const uchar* intensity = srcGray.ptr<uchar>(y,x);
                    sumIntensity += *intensity;
                    pixelNumber ++;

                }
            }
        }

        return RegionEnergy(sumIntensity, pixelNumber);

    }


    double Snakuscules::_calSnakeEnergy(   const cv::Mat srcGray
                            , const cv::Point center
                            , const int outerRadius
                            , const int innerRadius     ){

        REQUIRES( !srcGray.empty(), "The source must not be empty." );
        REQUIRES( srcGray.channels() == 1, "The source Mat must be one channel." );
        REQUIRES( outerRadius > 0, "the radius must be more than zero. Now radius is " << outerRadius );
        REQUIRES( innerRadius >= 0, "the inner must be more than zero. Now alpha is " << innerRadius );


        auto outerRE = _calRegionEnergy(srcGray, center, outerRadius);
        auto innerRE = _calRegionEnergy(srcGray, center, innerRadius);

        double outerEnergy = (outerRE.intensity - innerRE.intensity)
                             / static_cast<double>( outerRE.numPixel - innerRE.numPixel );

        double innerEnergy = innerRE.intensity
                             / static_cast<double>(innerRE.numPixel);

        double diff = outerEnergy - innerEnergy;

        return diff;

    }


    void Snakuscules::fit( const cv::Mat& srcGray
                    , cv::Point seedPoint
                    , int radius
                    , const float alpha
                    , const unsigned int maxIteration ){

        REQUIRES( !srcGray.empty(), "The source must not be empty." );
        REQUIRES( srcGray.channels() == 1, "The source Mat must be one channel." );
//        REQUIRES( radius > 0, "the radius must be more than zero. Now radius is " << radius );
        REQUIRES( alpha > 0, "the alpha must be more than zero. Now alpha is " << alpha );
        REQUIRES( maxIteration >= 0 && maxIteration < 1000, "Max iteration must between 0 - 1000" );

        if(radius <= 1 ){
            m_center = cv::Point(0,0);
            m_outerRadius = 1;
            m_innerRadius =  1;

            std::cout << "[Warning] Snakuscules is not support. radius is <= 1; ";

            return;
        }

        cv::Point cPoint = seedPoint;

        for (int i = 0; i < maxIteration; ++i) {

            const int innerRadius = _calInnerRadius(radius, alpha);

            std::vector<double> e(6);
            e[0]=_calSnakeEnergy(srcGray, Point(cPoint.x - 1, cPoint.y), radius, innerRadius);
            e[1]=_calSnakeEnergy(srcGray, Point(cPoint.x + 1, cPoint.y), radius, innerRadius);
            e[2]=_calSnakeEnergy(srcGray, Point(cPoint.x, cPoint.y - 1), radius, innerRadius);
            e[3]=_calSnakeEnergy(srcGray, Point(cPoint.x, cPoint.y + 1), radius, innerRadius);
            e[4]=_calSnakeEnergy(srcGray, cPoint, radius - 1, _calInnerRadius(radius-1, alpha));
            e[5]=_calSnakeEnergy(srcGray, cPoint, radius + 1, _calInnerRadius(radius+1, alpha));

            int maxIndex = static_cast<int>(std::max_element(e.begin(), e.end()) - e.begin());
            switch(maxIndex){
                case 0:
                    cPoint.x -= 1; //cout << i << " : <== " << std::endl;
                    break;
                case 1:
                    cPoint.x += 1;//cout << i << " : ==> " << std::endl;
                    break;
                case 2:
                    cPoint.y -= 1;//cout << i << " : ^ " << std::endl;
                    break;
                case 3:
                    cPoint.y += 1;//cout << i << " : v " << std::endl;
                    break;
                case 4:
                    radius -= 1;//cout << i << " : -><- " << std::endl;
                    break;
                case 5:
                    radius += 1;//cout << i << " : <--> " << std::endl;
                    break;
                default:
                    throw_assert(false, "The direction is invalided.");
            }

        }

        m_center = cPoint;
        m_outerRadius = radius;
        m_innerRadius =  _calInnerRadius(radius, alpha);

    }



    void Snakuscules::calEnergyMat(const cv::Mat& srcGray
                      , cv::Mat& dst
                      , int radius
                      , const float alpha) {

        REQUIRES(false, "this function has not yet implemented.");

//        REQUIRES( !srcGray.empty(), "The source must not be empty." );
//        REQUIRES( srcGray.channels() == 1, "The source Mat must be one channel." );
//        REQUIRES( radius > 0, "the radius must be more than zero. Now radius is " << radius );
//        REQUIRES( alpha > 0, "the alpha must be more than zero. Now alpha is " << alpha );

//        const int innerRadius = _calInnerRadius(radius, alpha);
//
//        for (int i = 0; i < srcGray.rows; ++i) {
//            for (int j = 0; j < srcGray.cols; ++j) {
//                _calSnakeEnergy(srcGray, Point(i,j), radius, innerRadius);
//            }
//        }

    }

}