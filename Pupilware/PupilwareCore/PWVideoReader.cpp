//
//  PWVideoReader.cpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/29/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

#include "PWVideoReader.hpp"
#include "preHeader.hpp"


namespace pw{
    

    PWVideoReader::PWVideoReader(){
        
    }
    
    
    PWVideoReader::PWVideoReader( const std::string& filename){
        
        open( filename );
        
    }
    
    
    PWVideoReader::PWVideoReader( const PWVideoReader& other){}
    
    
    PWVideoReader& PWVideoReader::operator=( const PWVideoReader& other){
        return *this;
    }

    
    bool PWVideoReader::open( const std::string& filename){
        
        REQUIRES( !filename.empty(), "File name must not be empty.");
        
        bool result = this->capture.open(filename);
        
        PROMISES(capture.isOpened(), "The video has not opened. Please check.");
        
        //TODO clean up this section.
        //--- Vidoe Meta Data ------------
        auto S = cv::Size((int) capture.get(CV_CAP_PROP_FRAME_WIDTH),    // Acquire input size
                          (int) capture.get(CV_CAP_PROP_FRAME_HEIGHT));
        
        auto FPS = capture.get(CV_CAP_PROP_FPS);
        auto maxVideoFrame = capture.get(CV_CAP_PROP_FRAME_COUNT);
        
//        std::string::size_type pAt = filename.find_last_of('.');                  // Find extension point
//        const std::string NAME = filename.substr(0, pAt) + argv[2][0] + ".avi";   // Form the new name with container
        int ex = static_cast<int>(capture.get(CV_CAP_PROP_FOURCC));     // Get Codec Type- Int form
        
        // Transform from int to char via Bitwise operators
        char EXT[] = {(char)(ex & 0XFF) , (char)((ex & 0XFF00) >> 8),(char)((ex & 0XFF0000) >> 16),(char)((ex & 0XFF000000) >> 24), 0};

        //----- End meta data -----------
        
        
        
        
        return result;
    }
    

    void PWVideoReader::close(){
        if(capture.isOpened())
        {
            capture.release();
        }
    }

    
    cv::Mat PWVideoReader::readFrame(){
        
        cv::Mat frame;
        
        if (capture.isOpened()) {
            capture >> frame;
        }
        
        return frame;
        
    }
    
    
    cv::Mat PWVideoReader::getFrameAt( unsigned int frameNumber ){
        throw_assert(false, "This method has not been implemeted.");
        return cv::Mat();
    }

    
    unsigned int PWVideoReader::getMaxFrame() const{
        throw_assert(false, "This method has not been implemeted.");
        return 0;
    }


}