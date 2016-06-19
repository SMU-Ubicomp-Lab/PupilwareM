//
//  PWPupilProcessor.m
//  Pupilware
//
//

#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/imgproc/imgproc.hpp>

#include "opencv2/opencv.hpp"
#include "constants.h"
#include "findEyeCenter.h"
#include "findEyeCorner.h"
#include "Ransac.h"

#include <iostream>
#include <queue>
#include <stdio.h>

#define _USE_MATH_DEFINES
#include <math.h>

#include <vector>
#include <string>
#include <fstream>
#include <numeric>


#include "PWPupilProcessor.hpp"
#include "PWViewController.h"
#include "PWUtilities.h"

using namespace cv;
using namespace std;
// cv::String face_cascade_name = "@/Users/srafiqi/haarcascade_frontalface_alt.xml";


// cv::CascadeClassifier face_cascade;
std::string main_window_name = "Capture - Face detection";
std::string face_window_name = "Capture - Face";
cv::RNG rng(12345);
cv::Mat debugImage;
cv::Mat skinCrCbHist = cv::Mat::zeros(cv::Size(256, 256), CV_8UC1);

int signal_counter = 0;

float eyeDistanceInMM = 64.15f;

float g_pupilSizeleft_wc;
float g_pupilSizeRight_wc ;
float g_distanceBetweenEyesP1_wc;
float g_distanceBetweenEyesP2_wc;


float g_pupilSizeleft_w_sb;
float g_pupilSizeRight_w_sb;
float g_pupilSizeleft_h_sb;
float g_pupilSizeRight_h_sb;
float g_distanceBetweenEyesP2_sb;
float g_pupilSize;
std::vector <cv::Point> g_leftPupilCenterVector;
std::vector <cv::Point> g_rightPupilCenterVector;


cv::Point g_leftPupilCenter;
cv::Point g_rightPupilCenter;
cv::Rect g_leftEyeRect;
cv::Rect g_rightEyeRect;

NSString *videoFile;

const cv::Size kRecordFrameSize(80,80);
const int kRecordFPS = 25;
int firstIteration = 0;


const unsigned int k_signal_buffer_size = 15*3;
Mat g_signal = Mat(1, k_signal_buffer_size, CV_32F);
Mat g_signal1 = Mat(1, k_signal_buffer_size, CV_32F);
Mat g_left_w_sb = Mat(1, k_signal_buffer_size, CV_32F);
Mat g_right_w_sb = Mat(1, k_signal_buffer_size, CV_32F);
Mat g_avg_eye = Mat(1, k_signal_buffer_size, CV_32F);
Mat g_eye_dist = Mat(1, k_signal_buffer_size, CV_32F);
Mat g_pupil_mm = Mat(1, k_signal_buffer_size, CV_32F);


namespace pw
{
    ///////////////////////////////////////////////////////////////////////////////
    // Utility Functions Implementation
    ///////////////////////////////////////////////////////////////////////////////
    
    
    template <typename T>
    void printv(std::vector<T> v)
    {
        for (int i=0; i<v.size(); i++) {
            std::cout << (float)v[i] << ",";
        }
        
        std::cout << std::endl;
        std::cout << std::endl;
        std::cout << std::endl;
    }
    
    Mat getNanMark(Mat v)
    {
        Mat mark = Mat(v == v);
        return mark;
    }
    

    
    Mat PWPupilProcessor::equalizeIntensity(const Mat& inputImage)
    {
        if(inputImage.channels() >= 3)
        {
            Mat ycrcb;
            
            cvtColor(inputImage,ycrcb,CV_BGR2YCrCb);
            
            vector<Mat> channels;
            split(ycrcb,channels);
            
            equalizeHist(channels[0], channels[0]);
            
            Mat result;
            merge(channels,ycrcb);
            
            cvtColor(ycrcb,result,CV_YCrCb2BGR);
            
            return result;
        }
        return Mat();
    }
    
    ///////////////////////////////////////////////////////////////////////////////
    // Class Implementation
    ///////////////////////////////////////////////////////////////////////////////
    
    PWPupilProcessor::PWPupilProcessor(const std::string& leftOutputFileName,
                                       const std::string& rightOutputFileName)
    {
        
        
//        std::cout << "Opening Left output file name " <<  leftOutputFileName << std::endl;
//        std::cout << "Opening Right output file name " <<  rightOutputFileName << std::endl;
        
        
        // Open the output files to save the videos for left and right eye.
        leftOutvideo.open(leftOutputFileName, 0, kRecordFPS, kRecordFrameSize);
        rightOutvideo.open(rightOutputFileName, 0, kRecordFPS, kRecordFrameSize);

        if (leftOutvideo.isOpened() and rightOutvideo.isOpened())
            NSLog(@"Succsssfully opened files to write");
        else
            NSLog(@"File did not  open");
        
        
        frameNumber                 = 0;
        isShouldWriteVideo          = false;
        isDrawFPS                   = true;
        isShouldDetectFace          = true;
        isGetBaselineFromVideo      = false;
        
        eyeDistance_ud       = 60.0f;
        windowSize_ud        = 11;
        mbWindowSize_ud      = 11;
        baselineStart_ud     = 0;
        baselineEnd_ud       = 20;
        threshold_ud         = 20;
        markCost             = 2;
        baseline             = 0.0;
        cogHigh              = 0.017;

    }
    
    PWPupilProcessor::~PWPupilProcessor()
    {
        // Close all the open files
        if(leftEyeCapture.isOpened())
        {
            leftEyeCapture.release();
        }
        if(rightEyeCapture.isOpened())
        {
            rightEyeCapture.release();
        }

    }
    
    cv::VideoCapture PWPupilProcessor::getVideoDevice(const std::string& eye_type)
    {
        if (eye_type == "leftEye")
        {
            return leftEyeCapture;
        }
        else
        {
            return rightEyeCapture;
        }
    }
    
    void PWPupilProcessor::setVideoDevice(const std::string& eye_type, cv::VideoCapture& capture)
    {
        if (eye_type == "leftEye")
        {
            leftEyeCapture = capture;

        }
        else
        {
            rightEyeCapture = capture;
        }
    }
    
    string type2str(int type) {
        string r;
        
        uchar depth = type & CV_MAT_DEPTH_MASK;
        uchar chans = 1 + (type >> CV_CN_SHIFT);
        
        switch ( depth ) {
            case CV_8U:  r = "8U"; break;
            case CV_8S:  r = "8S"; break;
            case CV_16U: r = "16U"; break;
            case CV_16S: r = "16S"; break;
            case CV_32S: r = "32S"; break;
            case CV_32F: r = "32F"; break;
            case CV_64F: r = "64F"; break;
            default:     r = "User"; break;
        }
        
        r += "C";
        r += (chans+'0');
        
        return r;
    }

    
    float PWPupilProcessor::getPupilSize() const
    {
        return pupilSize;
    }
    
    size_t PWPupilProcessor::getTotalFrames() const
    {
        return left_eye_w_sb.size();
    }

    float PWPupilProcessor::getLeftEyeW(int idx) const
    {
        return left_eye_w_sb.at(idx);
    }
    
    float PWPupilProcessor::getRightEyeW(int idx) const
    {
        return right_eye_w_sb.at(idx);
    }
    
    float PWPupilProcessor::getEyeDistSB(int idx) const
    {
        return eye_dist_sb.at(idx);
    }

    std::vector<float>  PWPupilProcessor::getResultGraph() const
    {
        return resultGraph;
    }
    
    const std::vector<float>& PWPupilProcessor::getPupilMM() const
    {
        return pupil_mm;
    }
    
    const std::vector<float>& PWPupilProcessor::getPupilPixel() const
    {
        return right_eye_w_sb;
    }
    
    const std::vector<float>& PWPupilProcessor::getEyeDist() const
    {
        return eye_dist_sb;
    }
    
    const std::vector<cv::Point>& PWPupilProcessor::getLeftEyeCenter() const
    {
        return left_eye_center;
    }

    const std::vector<cv::Point>& PWPupilProcessor::getRightEyeCenter() const
    {
        return right_eye_center;
    }
    
    float PWPupilProcessor::getResultPeak() const
    {
        int offset = resultGraph.size() * 0.20;
        return *std::max_element(resultGraph.begin()+offset, resultGraph.end()-offset);
    }
    
//    cv::Mat PWPupilProcessor::getLeftFrame() const
//    {
//        return leftOutputMatVideoVector[0];
//    }
    
    // This opens a video file for processing. File name is passed, which is either for the left
    // eye or the right eye.
    
    bool PWPupilProcessor::loadVideo( const std::string& videoFileName, cv::VideoCapture& capture )
    {
        // NSLog(@"Loading the video");
        if (videoFileName != "")
        {
            if (capture.isOpened())
            {
                capture.release();
            }
            
            capture = cv::VideoCapture(videoFileName);
            
            if (!capture.isOpened())
            {
                std::cout << "[WARNING] Video file not found/open?" << std::endl;
                return false;
            }
            return true;
        }
        else
        {
            std::cout << "[WARNING] Video file is NULL, it may be in video mode?" << std::endl;;
            return false;
        }
    }

    
    float PWPupilProcessor::calBaselineFromCurrentSignal()
    {
        // NSLog(@"Inside calBaseline from current signal");
        
        //assert(pupil_mm.size() > 0);
        
        
        if (pupil_mm.size() <= 0)
        {
            std::cout << "[Warning] pupil is empty. It is not enough to calculate baseline.\n" << std::endl;
            // NSLog(@"Returning calbasline from current signal with 0.0");
            return 0.0f;
        }
        
        int endFrame = min((int)pupil_mm.size(), baselineEnd_ud);
        
        int startFrame = baselineStart_ud;
        if( pupil_mm.size() < startFrame)
        {
            startFrame = 0;
        }
        
        
        std::vector<float> baselineList;
        
        baselineList.assign(pupil_mm.begin()+startFrame,
                            pupil_mm.begin()+endFrame);
        
        float medianOfbaseline = median(baselineList);
        // NSLog(@"Returning median of basline");
        
        return medianOfbaseline;
    }
    
    
    float PWPupilProcessor::getCognitiveLevel() const
    {
        return calCogMax(resultGraph);
    }
    
    float PWPupilProcessor::getCurrentCognitiveLoad()
    {
        std::vector<float>pupilMMV(g_pupil_mm);
        std::vector<float>smooth;
        //medfilt(pupilMMV, smooth, 21);
        
        std::vector<float>verySmooth;
        movingAverage(pupilMMV, verySmooth);
        
        float medianOfbaseline = getBaseline();
        
        Mat pChange;
        cv::subtract(verySmooth,
                     Mat::ones(1, (int)verySmooth.size(), CV_32F) * medianOfbaseline,
                     pChange);
        
        cv::divide(pChange, Mat::ones(1, (int)verySmooth.size(), CV_32F)*medianOfbaseline, pChange);
        
        
        Mat mark = getNanMark(pChange);
        
        std::vector<float>pChangeNoNan;
        pChange.copyTo(pChangeNoNan, mark);
        
        return calCogMax(pChangeNoNan);
        
    }
    
    float PWPupilProcessor::calCogMax( std::vector<float>signal) const
    {
        assert(signal.size() > 0);
        
        if(signal.size() <= 0)
        {
            std::cout<<"pupil mm is empty.";
            return 0.0f;
        }
        
        // trim signal 20%.
        int trimBegin = signal.size() * 0.1;
        int trimEnd = trimBegin;
        
        float pupilSizeAtHighCog = cogHigh;
        
        float max = *std::max_element(signal.begin()+trimBegin, signal.end()-trimEnd);
        //float maxProcess = (max*2) - 0.05;
        
        std::cout << "max value = " << max << std::endl;
        //std::cout << "max value process = " << maxProcess << std::endl;
        
        return fmax(fmin(max/pupilSizeAtHighCog , 1.0f),0.0f);
    }
    
    float PWPupilProcessor::getBaseline( )
    {
        return baseline;
    }
    
    
    void PWPupilProcessor::process_signal()
    {
         // NSLog(@"Inside process signal window size %d mb window size %d", windowSize_ud, mbWindowSize_ud);
        
        // Do nothing if the data point less than median filter window size.
        if (left_eye_w_sb.size() < mbWindowSize_ud)
            return;
        

        std::vector<float> sumEye;
        cv::add(right_eye_w_sb, right_eye_w_sb, sumEye);

        std::vector<float> smoothEye;
        medfilt(sumEye, smoothEye, mbWindowSize_ud);

        std::vector<float>smoothDist;
        medfilt(eye_dist_sb, smoothDist, mbWindowSize_ud);

        std::vector<float> avgEye;
        for (size_t i=0; i<smoothEye.size(); i++) {
            float avgEye =(float)smoothEye[i] / 2.0f;
            pupil_mm.push_back(convert_pixel_to_mm(avgEye,
                                                   (float)smoothDist[i],
                                                   eyeDistance_ud));
        }
        
        if( !isGetBaselineFromVideo )
        {
            if( baseline == 0 )
            {
                NSLog(@"[Warning] There is no baseline. Please calibrate.");
                baseline = calBaselineFromCurrentSignal();
            }
        }
        else
        {
            // NSLog(@"calling baseline from current signal ");
            baseline = calBaselineFromCurrentSignal();
        }
        
        float medianOfbaseline = getBaseline();
        
        Mat pChange;
        cv::subtract(pupil_mm,
                     Mat::ones(1, (int)pupil_mm.size(), CV_32F) * medianOfbaseline,
                     pChange);

        cv::divide(pChange, Mat::ones(1, (int)pupil_mm.size(), CV_32F)*medianOfbaseline, pChange);
        
        cv::GaussianBlur(pChange, pChange, cv::Size(windowSize_ud,windowSize_ud), 15);
        
        Mat mark = getNanMark(pChange);
        
        std::vector<float>pChangeNoNan;
        pChange.copyTo(pChangeNoNan, mark);
        
        // NSLog(@"printing pchange vector");
        
        // printv(pChangeNoNan);
        
        resultGraph = pChangeNoNan;
        
    }
    
    
    // Signal Processing
    void PWPupilProcessor::clearData()
    {
        left_eye_w_sb.clear();
        right_eye_w_sb.clear();
        eye_dist_sb.clear();
        right_eye_center.clear();
        
        pupil_mm.clear();
        resultGraph.clear();
        
    }
    
    // Signal Processing
    void PWPupilProcessor::store_signal()
    {        
        // diameter of the left eye in pixels
        // NSLog(@"Store signal left eye sb %f, eye Distance %f", g_pupilSizeleft_w_sb, g_distanceBetweenEyesP2_sb);
        left_eye_w_sb.push_back(g_pupilSizeleft_w_sb);
        
        // diameter of the right eye in pixels
        right_eye_w_sb.push_back(g_pupilSizeRight_w_sb);
        
        // Euclidean distance between the center of left and right eyes
        eye_dist_sb.push_back(g_distanceBetweenEyesP2_sb);
        
        
        /*!WORNNING use only right eye for now */
#pragma warning -- use only right eye for now.
        
        // Pupil size in mm
        g_pupilSize = convert_pixel_to_mm((g_pupilSizeRight_w_sb),
                                            g_distanceBetweenEyesP2_sb, eyeDistance_ud);

        // Center point of the right and left eyes
        right_eye_center.push_back(g_rightPupilCenter);
        
        left_eye_center.push_back(g_rightPupilCenter);

        
        
//        *g_left_w_sb.ptr<float>(0, signal_counter) = g_pupilSizeleft_w_sb;
//        *g_right_w_sb.ptr<float>(0, signal_counter) = g_pupilSizeRight_w_sb;
//        *g_eye_dist.ptr<float>(0, signal_counter) = g_distanceBetweenEyesP2_sb;
        *g_pupil_mm.ptr<float>(0, signal_counter) =g_pupilSize;
        
        signal_counter++;
        signal_counter = signal_counter%k_signal_buffer_size;
        
    }
    
    
    /**  @function Erosion  */
    void Erosion( Mat src, Mat& dst )
    {
        int erosion_type = MORPH_ELLIPSE;
        
        int erosion_size = 2;
        
        Mat element = getStructuringElement( erosion_type,
                                            cv::Size( 2*erosion_size + 1, 2*erosion_size+1 ),
                                            cv::Point( erosion_size, erosion_size ) );
        
        /// Apply the erosion operation
        cv::morphologyEx( src, dst, 0, element );
        
        
    }
    
     
    // This is the new function that basically does exactly the same thing except it uses eyeMat as an input to find eye center.
    
    cv::Point findEyeCenterUsingMat(Mat eyeMAT, const std::string& name )
    {
              
        Mat eq;
        
//        string ty =  type2str( eyeMAT.type() );
//        // printf("Find Eyes Using Mat Matrix: %s %dx%d \n", ty.c_str(), eyeMAT.cols, eyeMAT.rows );
        
        Mat grayEyeMat;
        
        if (eyeMAT.channels() > 1)
            cvtColor(eyeMAT, grayEyeMat, CV_BGR2GRAY);
        
//        ty =  type2str( eyeMAT.type() );
//        printf("Matrix: %s %dx%d \n", ty.c_str(), eyeMAT.cols, eyeMAT.rows );
                
        cv::equalizeHist(grayEyeMat, eq);
        
        Mat binary;
       // cv::threshold(eq, binary, 10, 255, CV_THRESH_BINARY_INV);
        cv::adaptiveThreshold(eq, binary, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY_INV, 3, 0);
        
        Erosion(binary, binary);
        
        
        Mat difference = binary;
        
        float sumx=0, sumy=0;
        float num_pixel = 0;
        for(int x=0; x<difference.cols; x++) {
            for(int y=0; y<difference.rows; y++) {
                int val = *difference.ptr<uchar>(y,x);
                if( val >= 50) {
                    sumx += x;
                    sumy += y;
                    num_pixel++;
                }
            }
        }
        
        if(sumx < 3 && sumy < 3) return cv::Point(0,0);
        
        cv::Point p(sumx/num_pixel, sumy/num_pixel);
        
        
        Moments m = moments(difference, false);
        cv::Point p1(m.m10/m.m00, m.m01/m.m00);

        return p;
    }
    
    void PWPupilProcessor::searchDarkestSpotWithInRange( int range, Mat& grayImage, cv::Point& inOutPoint )
    {
        assert( range % 2 > 0 ); //Accept only odd number.
        assert( !grayImage.empty() );
        
        cv::Point initialPoint = inOutPoint;
        unsigned char darkestValue = *grayImage.ptr<unsigned char>(initialPoint.y, initialPoint.x);
        int haftRange = range/2;
        
        int left   = max(0,initialPoint.x- haftRange);
        int top    = max(0,initialPoint.y);
        int right  = min( initialPoint.x + haftRange, grayImage.cols-1);
        int bottom = min( initialPoint.y + range, grayImage.rows-1 );
        
        
        // Optimization Notice : use pointer iteration for better performance.
        for( int i=top; i<=bottom; i++ )
        {
            for( int j=left; j<=right; j++ )
            {
                unsigned char thisPixVal = *grayImage.ptr<unsigned char>(i, j);
                
                if( darkestValue > thisPixVal )
                {
                    
                    darkestValue = thisPixVal;
                    inOutPoint.y = i;
                    inOutPoint.x = j;
                }
            }
        }
        
    }

    float oldsize = 0;
    
    // STARBURST
    
    bool PWPupilProcessor::applyStarbust( const Mat& eyeROI, const cv::Point& eyeCenter, float& outWidth, float& outHeight, cv::Point& outCenterPoint, const std::string& eye_type, Mat& outDisplayImage )
    {
        
        Mat gxyMatOfEye;

        // NSLog(@"Inside the apply Starbust threshold %d and mark cost %d and intensity threshold %d", threshold_ud, markCost, intensityThreshold_ud);
        
        // NSLog(@"Numbe of channels in apply starbust %d",eyeROI.channels());

        if (eyeROI.channels() == 1)
            gxyMatOfEye = eyeROI;
        else
            cvtColor(eyeROI,gxyMatOfEye,COLOR_BGR2GRAY);
    
        
        cv::Rect pupil_area = cv::Rect(max(eyeCenter.x-20,0),
                                       max(eyeCenter.y-20,0),
                                       min( gxyMatOfEye.cols - eyeCenter.x ,40),
                                       min( gxyMatOfEye.rows - eyeCenter.y ,40));
        
        // NSLog(@"Calling median blur");

        medianBlur(gxyMatOfEye, gxyMatOfEye, 3);
        
        equalizeHist(gxyMatOfEye(pupil_area),
                     gxyMatOfEye(pupil_area));
        
        // Just for displaying.
        
        vector<int> ray_distant;
        
        vector<Point2f>rays;
        vector<Point2f>ray_points;
        
        // Construct rays
        const int number_of_point = 15;
        const float step = M_PI/float(number_of_point);
        float degreeOffset = threshold_ud;
        float offset_radians = ( degreeOffset * M_PI / 180.0f);
        
        for(float i=-offset_radians; i < M_PI+offset_radians; i+= step )
        {
            rays.push_back( Point2f( cos(i), sin(i)) );
        }
        
        Mat gxyMatOfEye_display = eyeROI.clone();
        
        cv::Point seedPoint = cv::Point(eyeCenter.x, eyeCenter.y);
        
        float d_cost = markCost; //
        
        for( int iter = 0; iter < 5; iter++ )
        {
            
            uchar *seed_intensity = gxyMatOfEye.ptr<uchar>(seedPoint.y, seedPoint.x);
            
            for(auto r = rays.begin(); r != rays.end(); r++)
            {
                cv::Point walking_point = seedPoint;
                int walking_intensity = 0;
                int increment = 1;
                // Following hardcoded statement was originally used.
                // int th = 25; // Threshold of the next pixel.. using to find the edge of the pupil
                
                // Replacing the above statement with configurable intensity threhsold.
                
                int th = intensityThreshold_ud;
                for( int i=0; ( (walking_intensity - *seed_intensity - (d_cost*(20-i))) <= th ) && i < 20; i+= increment )
                {
                    cv::Point nextPoint;
                    nextPoint.y = seedPoint.y+(i* r->y);
                    nextPoint.x = seedPoint.x+(r->x * i);
                    
                    nextPoint.x = min(max(nextPoint.x,0),eyeROI.cols - 1);
                    nextPoint.y = min(max(nextPoint.y,0),eyeROI.rows - 1);
                    
                    uchar *p_intensity = gxyMatOfEye.ptr<uchar>(nextPoint.y,nextPoint.x);
                    
                    
                    walking_intensity = *p_intensity;
                    walking_point = nextPoint;
                    
                    if( (walking_intensity - *seed_intensity - (d_cost*(20-i)) ) > th)
                    {
                        ray_points.push_back(nextPoint);
                    }
                 }
                
            }
            
            
            
            if( ray_points.size() > 0)
            {
                int sum_x = 0;
                int sum_y = 0;
                for( int i=0; i<ray_points.size(); i++ )
                {
                    sum_x += ray_points[i].x;
                    sum_y += ray_points[i].y;
                    *gxyMatOfEye_display.ptr<Vec3b>(ray_points[i].y, ray_points[i].x) = Vec3b(0,255,0); // green
                }
                
                
                int mean_point_x = sum_x / ray_points.size();
                int mean_point_y = sum_y / ray_points.size();
                
                circle( gxyMatOfEye_display, cv::Point(mean_point_x, mean_point_y), 1, Scalar(0,0,255));
                
//                int r_x = (rand()%5)-2; // random -1 to 1
//                int r_y = (rand()%3)-4;
                
                int r_x = 0;
                int r_y = -4;
                
                seedPoint.x = mean_point_x+r_x;
                seedPoint.y = mean_point_y+r_y;
                seedPoint.x = min(max(seedPoint.x,0),eyeROI.cols - 1);
                seedPoint.y = min(max(seedPoint.y,0),eyeROI.rows - 1);
                
            }
        }
        
        // Ransac Circle Outlier Detection
        if( ray_points.size() > 5)
        {
            float distance = 1;
            std::vector<cv::Point> iniliner;
            
            pd::Ransac r;
            r.ransac_circle_fitting(ray_points,
                                    static_cast<int>(ray_points.size()),
                                    ray_points.size()*0.2f,
                                    0.0f ,
                                    distance,
                                    ray_points.size()*0.99f,
                                    iniliner);
            
            //RotatedRect my_ellipse = fitEllipse( ray_points );
            
            if (iniliner.size()>5)
            {
                RotatedRect my_ellipse_2 = fitEllipse( iniliner );
                
                ellipse( gxyMatOfEye_display, my_ellipse_2, Scalar(0,50,255) );
                cv::circle( gxyMatOfEye_display, *r.bestModel.GetCenter(), r.bestModel.GetRadius(), Scalar(255,50,255) );
                
                //check for round ness;
                if( max(my_ellipse_2.size.width, my_ellipse_2.size.height) / min(my_ellipse_2.size.width, my_ellipse_2.size.height) < 1.5 )
                {
                
                    oldsize = r.bestModel.GetRadius()*2.0f;
                    outWidth = r.bestModel.GetRadius()*2.0f;
                    outHeight = r.bestModel.GetRadius()*2.0f;
                    outCenterPoint = my_ellipse_2.center;
                }
                else
                {
                    
                    outWidth = oldsize;
                    outHeight = oldsize;
                    outCenterPoint = my_ellipse_2.center;
                }
                outDisplayImage = gxyMatOfEye_display;
                
                return true;
            }
            
        }
        
        return false;
    }
    
    // END STARBURST
    
    Mat leftOutput;
    Mat rightOutput;
  
    void PWPupilProcessor::extractFeatures(Mat& leftEyeROIMat, Mat& rightEyeROIMat, cv::Point leftCenter, cv::Point rightCenter)
    {
        cv::Point leftPupilCenterInFaceCoor;
        cv::Point rightPupilCenterInFaceCoor;
        
        //! Starbust Algorithm on both eyes
        
        float pupilSizeLeftWidthSB = 0.0f;
        float pupilSizeRightWidthSB = 0.0f;
        float pupilSizeLeftHeightSB = 0.0f;
        float pupilSizeRightHeightSB = 0.0f;
        cv::Point leftEyeCenterSB;
        cv::Point rightEyeCenterSB;
        
        applyStarbust( leftEyeROIMat, leftCenter, pupilSizeLeftWidthSB, pupilSizeLeftHeightSB,leftEyeCenterSB, "left", leftOutput);
        applyStarbust( rightEyeROIMat, rightCenter, pupilSizeRightWidthSB, pupilSizeRightHeightSB,rightEyeCenterSB, "right", rightOutput);
        
        
        rightPupilCenterInFaceCoor.x = rightEyeCenterSB.x + g_rightEyeRect.x;
        rightPupilCenterInFaceCoor.y = rightEyeCenterSB.y + g_rightEyeRect.y;
        leftPupilCenterInFaceCoor.x = leftEyeCenterSB.x + g_leftEyeRect.x;
        leftPupilCenterInFaceCoor.y = leftEyeCenterSB.y + g_leftEyeRect.y;
        
        cv::Point diffSB = leftPupilCenterInFaceCoor - rightPupilCenterInFaceCoor;
        float distBetweenEyesSB = sqrt( float( (diffSB.x * diffSB.x) + (diffSB.y * diffSB.y) ) );

        g_pupilSizeleft_w_sb = pupilSizeLeftWidthSB;
        g_pupilSizeRight_w_sb = pupilSizeRightWidthSB;
        g_pupilSizeleft_h_sb = pupilSizeLeftHeightSB;
        g_pupilSizeRight_h_sb = pupilSizeRightHeightSB;
        g_distanceBetweenEyesP2_sb = distBetweenEyesSB;
        
    }
    
    
    void PWPupilProcessor::combindImages( cv::Size canvasSize, Mat face, Mat leftEye, Mat rightEye, Mat& out )
    {
        //assert(face.cols >= face.rows);
        // NSLog(@"inside combind images");
        out = face;
        if(leftEye.rows==0) return;
        if(rightEye.rows==0) return;
        
         Mat canvas = Mat::zeros(canvasSize, CV_8UC4);
        
        // Scale face image to fit the canvas size, and reserver aspect ratio.
        cv::Size FaceScaledSize(canvasSize.width, canvasSize.height );
        
        Mat scale_face;
        cv::resize( face, scale_face, FaceScaledSize ); // please reserver respect ratio
  
        // Scale eyes image to fit the canvas size, and reserver aspect ratio.
        // float eyeRatio = (canvasSize.width/2) / static_cast<float>(leftEye.rows);
       cv::Size EyeScaledSize(canvasSize.width/3, canvasSize.height/2);
        
        Mat scaledLeftEye;
        cv::resize( leftEye, scaledLeftEye, EyeScaledSize);
        
        Mat scaledRightEye;
        cv::resize( rightEye, scaledRightEye, EyeScaledSize);
        
        scale_face.copyTo( canvas(cv::Rect(0,0,FaceScaledSize.width, FaceScaledSize.height)) );
        
        scaledLeftEye.copyTo( canvas(cv::Rect(EyeScaledSize.width*1.5,(canvasSize.height-EyeScaledSize.height),EyeScaledSize.width, EyeScaledSize.height)) );

        
        scaledRightEye.copyTo( canvas(cv::Rect(EyeScaledSize.width*1.5,0,EyeScaledSize.width, EyeScaledSize.height)) );

         cv::cvtColor(canvas, out, CV_BGRA2RGB);
        
        // NSLog(@"Setting out to canvas");
         out = canvas;
    }
    
#ifdef __cplusplus
    
    int getFPS()
    {
        static double lstFrameTime = 0.0;
        
        double currentTime = CACurrentMediaTime();
        double elpseTime = currentTime - lstFrameTime;
        lstFrameTime = currentTime;
        int fps = 1.0/elpseTime;
        
        return fps;
    }
    
    bool PWPupilProcessor::closeCapture()
    {
        // NSLog(@"Inside close capture");
        if(leftOutvideo.isOpened())
        {
            // NSLog(@"Closing left eye file");
            leftOutvideo.release();
        }
        if(rightOutvideo.isOpened())
        {
            // NSLog(@"Closing right eye file");
            rightOutvideo.release();
        }
        return true;
    }
    
 
    // NEW FUNCTION
    
    bool PWPupilProcessor::faceAndEyeFeatureExtraction(cv::Mat srcImage, cv::Mat leftEyeMat, cv::Mat rightEyeMat, cv::Mat leftEyeMatColor, cv::Mat rightEyeMatColor, cv::Rect leftEyeRect, cv::Rect rightEyeRect, bool isFinished, cv::Mat& resultImage)
    {
        
//        string ty =  type2str( leftEyeMat.type() );
//        printf("FACE AND EYE ... Matrix: %s %dx%d \n", ty.c_str(), leftEyeMat.cols, leftEyeMat.rows );

        
        cv::Mat frame_gray;
        cv::Rect faceROI;
        
        cv::Mat faceGrayMat;
        faceGrayMat = srcImage;
        cv::Mat faceColorMat;
        
        if (isFinished)
        {
            resultImage = srcImage;
            return true;
        }
        // NSLog(@"Inside feature and eye extraction");
        
        
        cvtColor(srcImage, faceColorMat, CV_GRAY2BGRA);

        Mat gray_clone = faceGrayMat.clone();
        
        g_leftEyeRect = leftEyeRect;
        g_rightEyeRect = rightEyeRect;

        
        cv::Point leftPupilUsingMat = findEyeCenterUsingMat(leftEyeMat,"Left Eye");
        cv::Point rightPupilUsingMat = findEyeCenterUsingMat(rightEyeMat,"Right Eye");
        
      //  NSLog(@"FaceFeature Center point left pupil x %d left pupil y %d", leftPupilUsingMat.x, leftPupilUsingMat.y);
        
       // NSLog(@"FaceFeature Center point right pupil x %d right pupil y %d ", rightPupilUsingMat.x, rightPupilUsingMat.y);

        
        // Set global variables. These global variables are later used in extract feature function.
        g_leftPupilCenter = leftPupilUsingMat;
        g_rightPupilCenter = rightPupilUsingMat;
        

        Mat leftEyeROIMat = leftEyeMatColor;
        Mat rightEyeROIMat = rightEyeMatColor;
        
        Mat tmp_leftEyeRect;
        Mat tmp_rightEyeRect;
        
        
        cvtColor(leftEyeMat, tmp_leftEyeRect, CV_BGR2GRAY);
        cvtColor(rightEyeMat, tmp_rightEyeRect, CV_BGR2GRAY);

        
        searchDarkestSpotWithInRange(11,tmp_leftEyeRect, g_leftPupilCenter);
        searchDarkestSpotWithInRange(11,tmp_rightEyeRect, g_rightPupilCenter);
        
        
        
       // NSLog(@"FaceFeature Center after search darkest left pupil x %d left pupil y %d", g_leftPupilCenter.x, g_leftPupilCenter.y);
        
      //  NSLog(@"FaceFeature Center after search darkest right pupil x %d right pupil y %d ", g_rightPupilCenter.x, g_rightPupilCenter.y);

        extractFeatures(leftEyeROIMat,
                        rightEyeROIMat,
                        g_leftPupilCenter,
                        g_rightPupilCenter);
        
        store_signal();
        
        // Create output image.
        
        Mat cmb;
        
        combindImages(cv::Size(200, 300), faceColorMat, leftOutput, rightOutput, cmb);
        
        // NSLog(@"Returning combined image");
        resultImage = cmb;
        
        
        // PupilSize from Starburst algorithm
        
        pupilSize = g_pupilSize;
        
        if( isShouldWriteVideo )
        {
            Mat outputFrameToFileMat;
            
           // cvtColor(leftEyeMat, leftEyeMat, CV_GRAY2BGR); // May need to add BGRA back

            cv::resize(leftEyeMat, leftEyeMat, kRecordFrameSize);
            
         //   cvtColor(rightEyeMat, rightEyeMat, CV_GRAY2BGR);
            
            cv::resize(rightEyeMat, rightEyeMat, kRecordFrameSize);
            
            // NSLog(@"Number of channels %d", rightEyeMat.channels());

            leftOutvideo << leftEyeMat;
            rightOutvideo << rightEyeMat;
            leftOutputMatVideoVector.push_back(leftEyeMat);
            rightOutputMatVideoVector.push_back(rightEyeMat);

        }
        return true;
    }
    // END NEW FUNCTION TO PROCESS EYES AND COMBINE FACE TOGETHER
    
    
    // Adding eyeFeature Extraction
    
    bool PWPupilProcessor::eyeFeatureExtraction(cv::Mat leftEyeMat, cv::Mat rightEyeMat)
    {
        // Save the pupil center in the first iteration so that we don't have to repeat the same process again
        // Pupil center values are being saved in the left and right pupil center vector.
        
        
        if (firstIteration == 0)
        {
            firstIteration = 1;
            // NSLog(@"Inside the first iteration Loop");
            cv::Point leftPupilUsingMat = findEyeCenterUsingMat(leftEyeMat,"Left Eye");
            cv::Point rightPupilUsingMat = findEyeCenterUsingMat(rightEyeMat,"Right Eye");

            // Set global variables. These global variables are later used in extract feature function.
            g_leftPupilCenter = leftPupilUsingMat;
            g_rightPupilCenter = rightPupilUsingMat;
            
            
            Mat tmp_leftEyeRect = leftEyeMat;
            Mat tmp_rightEyeRect = rightEyeMat;
            
            searchDarkestSpotWithInRange(11,tmp_leftEyeRect, g_leftPupilCenter);
            
            searchDarkestSpotWithInRange(11,tmp_rightEyeRect, g_rightPupilCenter);
            
           // std::cout << "Adding to the pupil center vector" << endl;
            
            g_leftPupilCenterVector.push_back(g_leftPupilCenter); // This is where to store the center values
            g_rightPupilCenterVector.push_back(g_rightPupilCenter); // This is where to store the center values

        }
        else
        {
            // All iterations after the first one we take the center values off of the vector and use them.
            // This save processing time for finding the pupil center.
//            std::cout << "Inside subsequent iterations " << iteration << "Frame Number " << frameNumber << endl;
//            std::cout << "Total frames in the pupil center vectro " << g_leftPupilCenterVector.size() << endl;
            g_leftPupilCenter = g_leftPupilCenterVector[frameNumber];
            g_rightPupilCenter = g_rightPupilCenterVector[frameNumber];
            
            frameNumber++;
        }
        
        if (!leftEyeMat.dims || !rightEyeMat.dims) {
            return true;
        }
        
        extractFeatures(leftEyeMat,
                        rightEyeMat,
                        g_leftPupilCenter,
                        g_rightPupilCenter);
        
        store_signal();
        
        
        // PupilSize from Starburst algorithm
        
        pupilSize = g_pupilSize;
        
        // NSLog(@"Pupil size %f", pupilSize);
        
        return true;
    }
    

    
    // End eye Feature Extraction


}






#endif