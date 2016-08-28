//
//  PWCSVExporter.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/30/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#ifndef PWCSVExporter_hpp
#define PWCSVExporter_hpp

#include <fstream>

namespace pw {
    
    class PWFaceMeta;
    class PWDataModel;
    class PWParameter;
    
    class PWCSVExporter{
        
    public:
        PWCSVExporter();
        PWCSVExporter( const std::string& filePath );
        ~PWCSVExporter();
        
        bool open( const std::string& filePath );
        void close();
        
        PWCSVExporter& operator<<( const PWFaceMeta& meta );
        PWCSVExporter& operator<<( const PWDataModel& meta );
        
        
        static void toCSV( const PWDataModel& data, const std::string& fileName );
        static void toCSV( const PWParameter& param, const std::string& fileName );
        
    private:
        PWCSVExporter( const PWCSVExporter& other)=default;
        PWCSVExporter( PWCSVExporter&& other)=default;
        PWCSVExporter& operator=( const PWCSVExporter& other)=default;
        PWCSVExporter& operator=( PWCSVExporter&& other )=default;
        
        std::ofstream file;
        std::string targetPath;
        
    };
    
}

#endif /* PWCSVExporter_hpp */
