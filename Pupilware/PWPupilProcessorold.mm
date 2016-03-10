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




#include "PWPupilProcessor.h"
#include "PWViewController.h"

using namespace cv;
cv::String face_cascade_name = "@/Users/srafiqi/haarcascade_frontalface_alt.xml";
NSString *fileName = @"haarcascade_frontalface_alt";
NSFileHandle *fileHandle;
NSString *featureFile;



cv::CascadeClassifier face_cascade;
std::string main_window_name = "Capture - Face detection";
std::string face_window_name = "Capture - Face";
cv::RNG rng(12345);
cv::Mat debugImage;
cv::Mat skinCrCbHist = cv::Mat::zeros(cv::Size(256, 256), CV_8UC1);

int frameNumber = 0;
int signal_counter = 0;
//const int MAX_SIGNAL = 10;

// const int FPS = 9;



std::ofstream eyeDistanceMMLogFile;
std::ofstream eyeDistancePixelLogFile;
std::ofstream leftEyePixelLogFile;
std::ofstream leftEyeMMLogFile;
std::ofstream rightEyePixelLogFile;
std::ofstream rightEyeMMLogFile;
std::ofstream featuresSetFile;


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

cv::Point g_leftPupilCenter;
cv::Point g_rightPupilCenter;
cv::Rect g_leftEyeRect;
cv::Rect g_rightEyeRect;

NSString *videoFile;


cv::Vec4f g_line;

const unsigned int k_signal_buffer_size = 10;
Mat g_signal = Mat(1, k_signal_buffer_size, CV_32F);
Mat g_signal1 = Mat(1, k_signal_buffer_size, CV_32F);
Mat g_left_w_sb = Mat(1, k_signal_buffer_size, CV_32F);
Mat g_right_w_sb = Mat(1, k_signal_buffer_size, CV_32F);
Mat g_avg_eye = Mat(1, k_signal_buffer_size, CV_32F);
Mat g_eye_dist = Mat(1, k_signal_buffer_size, CV_32F);
Mat g_pupil_mm = Mat(1, k_signal_buffer_size, CV_32F);

//----- Example of dynamic memory allocation
std::vector<float> buffer;
std::vector<float> left_eye_w_sb;
std::vector<float> right_eye_w_sb;
std::vector<float> avg_eye_sb;
std::vector<float> eye_dist_sb;
std::vector<float> pupil_mm;

/// NOT SURE IF ANY OF THE FOLLOWING ARE REALLY USED

float sumFaceSizeX = 0;
float sumFaceSizeY = 0;
float eyeSizeX=0.0f;
float eyeSizeY=0.0f;
int faceCount = 0;



//! You can process the data as the same way as using cv::Mat;
//cv::medianBlur(buffer, out_buffer, 31);

//! However, if you want to do vector operation
//! you may need to use CV functions
//! EX. if you want to add to vectors, do like this.
//cv::add(buffer, buffer1, result_buffer);


namespace pw
{
    PWPupilProcessor::PWPupilProcessor(NSString *videoFileName)
    {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"xml"];
        if (!face_cascade.load([filePath UTF8String])) {
            std::cout << "Cannot load file " << std::endl;
        }
        else
            std::cout << "Loaded file successfully " << std::endl;
        
        if (videoFileName != NULL)
        {
            videoFile = [[NSBundle mainBundle]
                     pathForResource:videoFileName ofType:@"mp4"];
        

            NSLog(@"Opening the video file %s" , [videoFile UTF8String]);
        
            string fileToOpen = [videoFile UTF8String];
            capture = cv::VideoCapture(fileToOpen);
        }
        else
            NSLog(@"Video file is NULL");
        
        // NEW CODE TO WRITE FILE
        NSString *docDir = NSSearchPathForDirectoriesInDomains(
                                                               NSDocumentDirectory,
                                                               NSUserDomainMask, YES
                                                               )[0];
        featureFile = [docDir
                                stringByAppendingPathComponent:
                                @"featureResults.csv"];
        
        if  (![[NSFileManager defaultManager] fileExistsAtPath:featureFile]) {
            [[NSFileManager defaultManager]
             createFileAtPath:featureFile contents:nil attributes:nil];
        }
        
        fileHandle = [NSFileHandle
                                    fileHandleForUpdatingAtPath:featureFile];

        
        NSLog(@"Video file inside the constructor %s\n", [videoFileName UTF8String]);
        
        // END NEW CODE TO WRITE FILE
        
        // Read from nsuserdefaults
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        eyeDistance_ud       = [defaults floatForKey:kEyeDistance];
        windowSize_ud        = [defaults integerForKey:kWindowSize];
        mbWindowSize_ud      = [defaults integerForKey:kMbWindowSize];
        baselineStart_ud     = [defaults integerForKey:kBaselineStart];
        baselineEnd_ud       = [defaults integerForKey:kBaselineEnd];
        threshold_ud         = [defaults integerForKey:kThreshold];
    }
    
    
    PWPupilProcessor::~PWPupilProcessor()
    {
        [fileHandle closeFile];

    }
    
    // Write File
    void PWPupilProcessor::write_file()
    {
        //float tmp_pupil_mm=0;
        for( int i=0; i<left_eye_w_sb.size(); i++ )
        {
            
            // NEW CODE TO WRITE FILE
            fileHandle = [NSFileHandle
                          fileHandleForUpdatingAtPath:featureFile];
            
            [fileHandle seekToEndOfFile];
            
            NSString *testCsvLine=[NSString stringWithFormat:@"%f,%f,%f\n",
                                   left_eye_w_sb.at(i),
                                   right_eye_w_sb.at(i),
                                   eye_dist_sb.at(i)];

            [fileHandle writeData:[testCsvLine
                                   dataUsingEncoding:NSUTF8StringEncoding]];
          }    
    }

    // End Write File
    
    float PWPupilProcessor::convert_pixel_to_mm(float pupilSizeInPixel, float eyeDistanceInPixel)
    {
//        Mat tmp = Mat(1, k_signal_buffer_size, CV_32F);
//
//        cv::divide(eyeDistance_ud, g_eye_dist, tmp);
//        
//        cv::multiply(g_avg_eye, tmp, g_pupil_mm);
        
        return (eyeDistance_ud/eyeDistanceInPixel) * pupilSizeInPixel;
        
        
    }
    
    void PWPupilProcessor::process_signal()
    {
        
        // Average Eye
        g_avg_eye = (g_left_w_sb + g_right_w_sb )/2;
        
        // Median Filter
        cv::medianBlur(g_avg_eye, g_avg_eye, (int)mbWindowSize_ud);
        
        //Smooth eye average -- Moving Average
        cv::blur(g_avg_eye, g_avg_eye, cv::Size((int)windowSize_ud,(int)windowSize_ud));
        
        // Median Filter the eye distance
        cv::medianBlur(g_eye_dist, g_eye_dist, (int)mbWindowSize_ud);

        // Convert pixels to mm
        //convert_pixel_to_mm();

    }
    
    // Signal Processing
    void PWPupilProcessor::store_signal(float left_w_sb, float right_w_sb, float eye_distance )
    {
            *g_left_w_sb.ptr<float>(0, signal_counter) = g_pupilSizeleft_w_sb;
            *g_right_w_sb.ptr<float>(0, signal_counter) = g_pupilSizeRight_w_sb;
            *g_eye_dist.ptr<float>(0, signal_counter) = g_distanceBetweenEyesP2_sb;
            signal_counter++;
            left_eye_w_sb.push_back(g_pupilSizeleft_w_sb);
            right_eye_w_sb.push_back(g_pupilSizeRight_w_sb);
            eye_dist_sb.push_back(g_distanceBetweenEyesP2_sb);
        
            // Real-time pupil size in pixel
            g_pupilSize = convert_pixel_to_mm((g_pupilSizeleft_w_sb + g_pupilSizeRight_w_sb)/2, g_distanceBetweenEyesP2_sb);
    }
    
    // Signal Processing
    
  //  void PWPupilProcessor::cleanImageWithMorphology( Mat src, Mat& dst );
    
    
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
    
    void PWPupilProcessor::findEyes(cv::Mat frame_gray, cv::Rect face)
    {
       
        cv::Mat faceROI = frame_gray(face);
        cv::Mat debugFace = faceROI;
        
        if (kSmoothFaceImage) {
            double sigma = kSmoothFaceFactor * face.width;
            GaussianBlur( faceROI, faceROI, cv::Size( 0, 0 ), sigma);
        }
        //-- Find eye regions and draw them
        int eye_region_width = face.width * (kEyePercentWidth/100.0);
        int eye_region_height = face.width * (kEyePercentHeight/100.0);
        int eye_region_top = face.height * (kEyePercentTop/100.0);
        cv::Rect leftEyeRegion(face.width*(kEyePercentSide/100.0),
                               eye_region_top,eye_region_width,eye_region_height);
        cv::Rect rightEyeRegion(face.width - eye_region_width - face.width*(kEyePercentSide/100.0),
                                eye_region_top,eye_region_width,eye_region_height);
        
        eyeSizeX += eye_region_width;
        eyeSizeY += eye_region_height;
        
  
        //-- Find Eye Centers
        
       cv::Point leftPupil = findEyeCenter(faceROI,leftEyeRegion,"Left Eye");
       cv::Point rightPupil = findEyeCenter(faceROI,rightEyeRegion,"Right Eye");
        
        // get corner regions
        cv::Rect leftRightCornerRegion(leftEyeRegion);
        leftRightCornerRegion.width -= leftPupil.x;
        leftRightCornerRegion.x += leftPupil.x;
        leftRightCornerRegion.height /= 2;
        leftRightCornerRegion.y += leftRightCornerRegion.height / 2;
        cv::Rect leftLeftCornerRegion(leftEyeRegion);
        leftLeftCornerRegion.width = leftPupil.x;
        leftLeftCornerRegion.height /= 2;
        leftLeftCornerRegion.y += leftLeftCornerRegion.height / 2;
        cv::Rect rightLeftCornerRegion(rightEyeRegion);
        rightLeftCornerRegion.width = rightPupil.x;
        rightLeftCornerRegion.height /= 2;
        rightLeftCornerRegion.y += rightLeftCornerRegion.height / 2;
        cv::Rect rightRightCornerRegion(rightEyeRegion);
        rightRightCornerRegion.width -= rightPupil.x;
        rightRightCornerRegion.x += rightPupil.x;
        rightRightCornerRegion.height /= 2;
        rightRightCornerRegion.y += rightRightCornerRegion.height / 2;
        rectangle(debugFace,leftRightCornerRegion,200);
        rectangle(debugFace,leftLeftCornerRegion,200);
        rectangle(debugFace,rightLeftCornerRegion,200);
        rectangle(debugFace,rightRightCornerRegion,200);
        
        // Mark Added
        g_leftPupilCenter = leftPupil;
        g_rightPupilCenter = rightPupil;
        g_leftEyeRect = leftEyeRegion;
        g_rightEyeRect = rightEyeRegion;
        // End mark added
        
        // change eye centers to face coordinates
        rightPupil.x += rightEyeRegion.x;
        rightPupil.y += rightEyeRegion.y;
        leftPupil.x += leftEyeRegion.x;
        leftPupil.y += leftEyeRegion.y;
        
        // draw eye centers
        
        circle(debugFace, rightPupil, 3, 1234);
        circle(debugFace, leftPupil, 3, 1234);
        
    }
    
    void PWPupilProcessor::searchDarkestSpotWithInRange( int range, Mat& grayImage, cv::Point& inOutPoint )
    {
        assert( range % 2 > 0 ); //Accept only odd number.
        assert( !grayImage.empty() );
        
        cv::Point initialPoint = inOutPoint;
        unsigned char darkestValue = *grayImage.ptr<unsigned char>(initialPoint.y, initialPoint.x);
        int haftRange = range/2;
        
        int left   = max(0,initialPoint.x - haftRange);
        int top    = max(0,initialPoint.y - haftRange);
        int right  = min( initialPoint.x + haftRange, grayImage.cols-1);
        int bottom = min( initialPoint.y + haftRange, grayImage.rows-1 );
        
        
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

    
    // STARBURST
    
    bool PWPupilProcessor::applyStarbust( const Mat& eyeROI, const cv::Point& eyeCenter, float& outWidth, float& outHeight, cv::Point& outCenterPoint, const std::string& eye_type, Mat& outDisplayImage )
    {
        
        
        Mat gxyMatOfEye;
        cvtColor(eyeROI,gxyMatOfEye,COLOR_BGR2GRAY);
    
        
        cv::Rect pupil_area = cv::Rect( max(eyeCenter.x-20,0),max(eyeCenter.y-20,0), min( gxyMatOfEye.cols - eyeCenter.x - 2 ,40), min( gxyMatOfEye.rows - eyeCenter.y - 2 ,40));
        
        medianBlur(gxyMatOfEye, gxyMatOfEye, 3);
        
        equalizeHist(gxyMatOfEye(pupil_area),gxyMatOfEye(pupil_area));
        
        // Just for displaying.
        
        vector<int> ray_distant;
        
        vector<Point2f>rays;
        vector<Point2f>ray_points;
        
        // Construct rays
        const int number_of_point = 15;
        const float step = M_PI/float(number_of_point);
        float d = 35;
        float offset_radians = ( d * M_PI / 180.0f);
        
        for(float i=-offset_radians; i < M_PI+offset_radians; i+= step )
        {
            rays.push_back( Point2f( cos(i), sin(i)) );
        }
        
        Mat gxyMatOfEye_display = eyeROI.clone();
        
        cv::Point seedPoint = cv::Point(eyeCenter.x, eyeCenter.y);
        
        float d_cost = 0;
        
        for( int iter = 0; iter < 5; iter++ )
        {
            
            uchar *seed_intensity = gxyMatOfEye.ptr<uchar>(seedPoint.y, seedPoint.x);
            
            for(auto r = rays.begin(); r != rays.end(); r++)
            {
                cv::Point walking_point = seedPoint;
                int walking_intensity = 0;
                int increment = 1;
                int th =25;
                
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
                
                int r_x = (rand()%5)-2; // random -1 to 1
                int r_y = (rand()%3)-4;
                seedPoint.x = mean_point_x+r_x;
                seedPoint.y = mean_point_y+r_y;
                seedPoint.x = min(max(seedPoint.x,0),eyeROI.cols - 1);
                seedPoint.y = min(max(seedPoint.y,0),eyeROI.rows - 1);
                
            }
            
            
            
        }
        if( ray_points.size() > 5)
        {
            float distance = 1;
            std::vector<cv::Point> iniliner;
            pd::Ransac r;
            r.ransac_circle_fitting(ray_points, ray_points.size(), ray_points.size()*0.2, 0. , distance, ray_points.size()*0.9, iniliner);
            //RotatedRect my_ellipse = fitEllipse( ray_points );
            
            if (iniliner.size()>5)
            {
                RotatedRect my_ellipse_2 = fitEllipse( iniliner );
                
                ellipse( gxyMatOfEye_display, my_ellipse_2, Scalar(0,50,255) );
                
                
                outWidth = my_ellipse_2.size.width;
                outHeight = my_ellipse_2.size.height;
                outCenterPoint = my_ellipse_2.center;
                
                outDisplayImage = gxyMatOfEye_display;
                
                return true;
            }
            
            
        }
        else
        {
            // cout << "ray point less than 5" << std::endl;
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
        
        // In the first pass the leftCenter and rightCenter was returned from findEyes function, so it was calculated using gradient method.
        rightPupilCenterInFaceCoor.x = rightCenter.x + g_rightEyeRect.x;
        rightPupilCenterInFaceCoor.y = rightCenter.y + g_rightEyeRect.y;
        leftPupilCenterInFaceCoor.x = leftCenter.x + g_leftEyeRect.x;
        leftPupilCenterInFaceCoor.y = leftCenter.y + g_leftEyeRect.y;

        cv::Point diff = leftPupilCenterInFaceCoor - rightPupilCenterInFaceCoor;
        
        float distanceBetweenEye = sqrt( (diff.x * diff.x) + (diff.y * diff.y) );
        
        // Pass 1
        
        cv::Point2f leftFitCircleCenter;
        cv::Point2f rightFitCircleCenter;
        
        
        // Pass 2 -- Do this again with the different center point to see if it makes a difference == Pass 2
        rightPupilCenterInFaceCoor.x = rightFitCircleCenter.x + g_rightEyeRect.x;
        rightPupilCenterInFaceCoor.y = rightFitCircleCenter.y + g_rightEyeRect.y;
        leftPupilCenterInFaceCoor.x = leftFitCircleCenter.x + g_leftEyeRect.x;
        leftPupilCenterInFaceCoor.y = leftFitCircleCenter.y + g_leftEyeRect.y;
        
        cv::Point diffP2 = leftPupilCenterInFaceCoor - rightPupilCenterInFaceCoor;
        
        float distanceBetweenEyeP2 = sqrt( float((diffP2.x * diffP2.x) + (diffP2.y * diffP2.y)) );
        
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
        
        g_distanceBetweenEyesP1_wc = distanceBetweenEye;
        g_distanceBetweenEyesP2_wc = distanceBetweenEyeP2;
        g_pupilSizeleft_w_sb = pupilSizeLeftWidthSB;
        g_pupilSizeRight_w_sb = pupilSizeRightWidthSB;
        g_pupilSizeleft_h_sb = pupilSizeLeftHeightSB;
        g_pupilSizeRight_h_sb = pupilSizeRightHeightSB;
        g_distanceBetweenEyesP2_sb = distBetweenEyesSB;
        
    }
    
    void PWPupilProcessor::combindImages( cv::Size canvasSize, Mat face, Mat leftEye, Mat rightEye, Mat& out )
    {
        assert(face.cols >= face.rows);
        
        Mat canvas = Mat::zeros(canvasSize, CV_8UC3);
        
        // Scale face image to fit the canvas size, and reserver aspect ratio.
        float ratio =  static_cast<float>(canvasSize.width) / static_cast<float>(face.rows);
        cv::Size FaceScaledSize(canvasSize.width, face.rows * ratio );
        
        Mat scale_face;
        cv::resize( face, scale_face, FaceScaledSize ); // please reserver respect ratio
        
        // Scale eyes image to fit the canvas size, and reserver aspect ratio.
        float eyeRatio = (canvasSize.width/2) / static_cast<float>(leftEye.rows);
        cv::Size EyeScaledSize(canvasSize.width/2, leftEye.rows * eyeRatio);
        
        Mat scaledLeftEye;
        cv::resize( leftEye, scaledLeftEye, EyeScaledSize);
        
        Mat scaledRightEye;
        cv::resize( rightEye, scaledRightEye, EyeScaledSize);
        
        // Draw to the canvas
        scale_face.copyTo( canvas(cv::Rect(0,0,FaceScaledSize.width, FaceScaledSize.height)) );
        scaledLeftEye.copyTo( canvas(cv::Rect(0,canvasSize.height-EyeScaledSize.height,EyeScaledSize.width, EyeScaledSize.height)) );
        scaledRightEye.copyTo( canvas(cv::Rect(EyeScaledSize.width,canvasSize.height-EyeScaledSize.height,EyeScaledSize.width, EyeScaledSize.height)) );
        
        cv::cvtColor(canvas, out, CV_BGR2RGB);
    }
    
#ifdef __cplusplus
    

    
    void PWPupilProcessor::processImage(cv::Mat srcImage, cv::Mat& resultImage)
    {

        std::vector<cv::Rect> faces;
        cv::Mat frame_gray;
        // cv::Mat frame;
        
        flip(srcImage, srcImage, 1);
        std::vector<cv::Mat> rgbChannels(3);
        cv::split(srcImage, rgbChannels);
        frame_gray = rgbChannels[2];

        //-- Detect faces
        face_cascade.detectMultiScale( frame_gray, faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE|CV_HAAR_FIND_BIGGEST_OBJECT, cv::Size(150, 150) );
        
        
        for( int i = 0; i < faces.size(); i++ )
        {
            rectangle(frame_gray, faces[i], 1234, 4);
        }
        cv::Rect faceROI;

        //-- Show what you got
        if (faces.size() > 0)
        {
            /*--------- This section is just for get data to the paper. */
            faceCount ++;
            sumFaceSizeX += faces[0].width;
            sumFaceSizeY += faces[0].height;
            faceROI = faces[0];
            Mat gray_clone = frame_gray.clone();
            
            findEyes(gray_clone, faceROI);
            
            Mat faceColorMat = srcImage( faceROI );
            Mat faceGrayMat = frame_gray( faceROI );
            
            Mat leftEyeROIMat = faceColorMat( g_leftEyeRect );
            Mat rightEyeROIMat = faceColorMat( g_rightEyeRect );
            
            Mat tmp_leftEyeRect = faceGrayMat(g_leftEyeRect);
            Mat tmp_rightEyeRect = faceGrayMat(g_rightEyeRect);
            
            searchDarkestSpotWithInRange(11,tmp_leftEyeRect, g_leftPupilCenter);
            searchDarkestSpotWithInRange(11,tmp_rightEyeRect, g_rightPupilCenter);
            extractFeatures(leftEyeROIMat, rightEyeROIMat, g_leftPupilCenter, g_rightPupilCenter);
            
   
            store_signal(g_pupilSizeleft_w_sb,g_pupilSizeRight_w_sb,g_distanceBetweenEyesP2_sb);
            
            resultImage = gray_clone;
            
//            // New code to combine image
            Mat cmb;
            combindImages(cv::Size(200, 300), faceColorMat, leftOutput, rightOutput, cmb);
            resultImage = cmb;
//
            // PupilSize from Starburst algorithm
            pupilSize = g_pupilSize;
            
        }
        else
        {
            faceROI.x = 523;
            faceROI.y = 373;
            faceROI.width = 325;
            faceROI.height = 325;
        }

    }

}
#endif