//
//  PWCSVExporter.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/30/16.
//  Copyright © 2016 SMUUbicomp Lab All rights reserved.
//

#ifndef PWCSVExporter_hpp
#define PWCSVExporter_hpp

#include <fstream>

namespace pw {
    
    class PWFaceMeta;
    class PWDataModel;
    
    class PWCSVExporter{
        
    public:
        PWCSVExporter();
        PWCSVExporter( const std::string& filePath );
        ~PWCSVExporter();
        
        bool open( const std::string& filePath );
        void close();
        
        PWCSVExporter& operator<<( const PWFaceMeta& meta );
        PWCSVExporter& operator<<( const PWDataModel& meta );
        
    private:
        PWCSVExporter( const PWCSVExporter& other);
        PWCSVExporter& operator=( const PWCSVExporter& other);
        
        std::ofstream file;
        std::string targetPath;
        
    };
    
}

#endif /* PWCSVExporter_hpp */
