//
//  PWCSVExporter.cpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/30/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#include "PWCSVExporter.hpp"

#include "preHeader.hpp"
#include "Algorithm/PWFaceMeta.hpp"
#include "Algorithm/PWDataModel.hpp"
#include "PWParameter.hpp"

#include <chrono>

namespace pw{
    
    
    PWCSVExporter::PWCSVExporter(){}
    
    PWCSVExporter::PWCSVExporter( const std::string& filePath ):
    targetPath(filePath){
        open(filePath);
    }
    
    PWCSVExporter::~PWCSVExporter(){
        close();
    }
    
    
    bool PWCSVExporter::open( const std::string& filePath ){
    
        file.open(filePath);
        
        PROMISES(file.is_open(), "File is not open. The file name is [ " << filePath);
        
        /* Writer header */
        file << "time"
        << "," << "frameNum"
        << "," << "faceX"
        << "," << "faceY"
        << "," << "faceWidth"
        << "," << "faceHeight"
        << "," << "leftX"
        << "," << "leftY"
        << "," << "rightX"
        << "," << "rightY"
        << "\n";

        
        return file.is_open();
    }
    
    
    void PWCSVExporter::close(){
        if(file.is_open()){
            file.close();
        }
    }
    
    PWCSVExporter& PWCSVExporter::operator<<( const PWFaceMeta& meta ){
        
        REQUIRES(file.is_open(), "File has not yet open.");
        
        using namespace std::chrono;
        milliseconds ms = duration_cast< milliseconds >( system_clock::now().time_since_epoch() );
        
        file << ms.count()
        << "," << meta.getFrameNumber()
        << "," << meta.getFaceRect().x
        << "," << meta.getFaceRect().y
        << "," << meta.getFaceRect().width
        << "," << meta.getFaceRect().height
        << "," << meta.getLeftEyeCenter().x
        << "," << meta.getLeftEyeCenter().y
        << "," << meta.getRightEyeCenter().x
        << "," << meta.getRightEyeCenter().y
        << "\n";
        
        
        return *this;
    }
    
    PWCSVExporter& PWCSVExporter::operator<<( const PWDataModel& meta ){
        
        throw_assert(false, "This method has not yet implemented.");
        
        return *this;
    }
    
    
    void PWCSVExporter::toCSV( const PWDataModel& data, const std::string& fileName ){
        
        std::ofstream f(fileName);
        
        if (f.is_open()) {
            auto lpupil = data.getLeftPupilSizes();
            auto rpupil = data.getRightPupilSizes();
            
            
            f << "number,left,right" << std::endl;
            for (size_t i=0; i<lpupil.size(); ++i) {
                f << i << ",";
                f << lpupil[i] << ",";
                f << rpupil[i] << "\n";
            }
            
        }
        
        f.close();

    }

    
    void PWCSVExporter::toCSV( const PWParameter& param, const std::string& fileName ){
        
        std::ofstream f(fileName);
        
        if (f.is_open()) {
            
            f << "threshold,sigma,prior,degree_offset,ray_number" << std::endl;
            f << param.threshold <<
            "," << param.sigma <<
            "," << param.prior <<
            "," << param.degreeOffset <<
            "," << param.sbRayNumber << std::endl;
            
        }
        
        f.close();
        
    }
}