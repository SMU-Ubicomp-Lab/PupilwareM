//
//  PWVideoWriter.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/29/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#ifndef PWVideoWriter_hpp
#define PWVideoWriter_hpp

#include <fstream>

namespace pw{
    
    class PWVideoWriter{
        
    public:
        
        PWVideoWriter();
        PWVideoWriter( const std::string& filename);
        ~PWVideoWriter();
        
        bool open( const std::string& filename, int FPS=30, cv::Size frameSize=cv::Size(100,100));
        
        void close();
        
        void writeFrame( const cv::Mat& frame );
        PWVideoWriter& operator<<( const cv::Mat& frame );
    
    
    private:
        PWVideoWriter( const PWVideoWriter& other)              = default;
        PWVideoWriter( PWVideoWriter&& other)                   = default;
        PWVideoWriter& operator=( const PWVideoWriter& other)   = default;
        PWVideoWriter& operator=( PWVideoWriter&& other )       = default;
        
        std::vector<cv::Mat> frameBuffer;
        
        cv::VideoWriter    capture;
        std::ofstream       file;
        
    };
}

#endif /* PWVideoWriter_hpp */
