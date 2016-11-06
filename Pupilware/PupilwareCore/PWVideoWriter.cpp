//
//  PWVideoWriter.cpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/29/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#include "PWVideoWriter.hpp"
#include "preHeader.hpp"


namespace pw{
    

    PWVideoWriter::PWVideoWriter(){}
    
    
    PWVideoWriter::PWVideoWriter( const std::string& filename){
        
        open( filename );
        
    }
    
    
    PWVideoWriter::~PWVideoWriter(){
        close();
    }
    
    
    bool PWVideoWriter::open( const std::string& filename, int FPS, cv::Size frameSize ){
        
        REQUIRES( !filename.empty(), "File name must not be empty.");
    
        
        // TODO: assigned codex type, and replace 0 with it.
        //        int ex = static_cast<int>(inputVideo.get(CV_CAP_PROP_FOURCC));     // Get Codec Type- Int form
        //        char EXT[] = {(char)(ex & 0XFF) , (char)((ex & 0XFF00) >> 8),(char)((ex & 0XFF0000) >> 16),(char)((ex & 0XFF000000) >> 24), 0};
        
        capture.open(filename,
                     0,             // Codex
                     FPS,           // FPS
                     frameSize,     // Frame Size
                     true);         // isColor
        
        file.open(filename + ".csv");
        
        PROMISES(capture.isOpened(), "Video is not open, something has gone wrong.");
        PROMISES(file.is_open(), "File is not open. The file name is [ " << filename);
        
        return true;
        
    }

    void PWVideoWriter::close(){
        if (capture.isOpened()) {
            capture.release();
        }
        
        if(file.is_open()){
            file.close();
        }
    }

    
    PWVideoWriter& PWVideoWriter::operator<<( const cv::Mat& frame ){
        
        writeFrame( frame );
        
        return *this;
    }
    
    
    void PWVideoWriter::writeFrame( const cv::Mat& frame){

        
        if (capture.isOpened()) {
            
            capture << frame;
            
            using namespace std::chrono;
            milliseconds ms = duration_cast< milliseconds >( system_clock::now().time_since_epoch() );
            
            file << ms.count() << "\n";
        }
        
        
    }
    

}