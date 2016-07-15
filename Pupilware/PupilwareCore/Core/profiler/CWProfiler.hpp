//
//  CWProfiler.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 7/15/16.
//  Copyright © 2016 Chatchai Wangwiwattana All rights reserved.
//

#ifndef CWProfiler_hpp
#define CWProfiler_hpp

#include <unordered_map>


namespace cw{
    
    class CWClock;
    
    
    class CWProfiler{
    public:
        
        void _accumulateTime( const CWClock& clock );
        void print() const;
        
        static CWProfiler& get();
        static void accumulateTime( const CWClock& clock );
        
    private:
        static std::shared_ptr<CWProfiler> s_instance;
        
        
        std::unordered_map<std::string, size_t> profiles;
    };
}

#endif /* CWProfiler_hpp */
