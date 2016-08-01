//
//  CWClock.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 7/15/16.
//  Copyright © 2016 Chatchai Wangwiwattana All rights reserved.
//

#ifndef CWClock_hpp
#define CWClock_hpp

#include <stdio.h>
#include <chrono>

namespace cw{
    class CWClock{
    public:
        CWClock();
        CWClock( const std::string& );
        CWClock( const CWClock& )=default;
        CWClock( CWClock&& )=default;
        CWClock& operator=( const CWClock& )=default;
        CWClock& operator=( CWClock&& )=default;
        ~CWClock();
        
        void reset();
        double stop();
        double getTime() const;
        const std::string& getName() const;
        
    private:
        std::chrono::steady_clock::time_point begin;
        std::chrono::steady_clock::time_point end;
        std::string name;
    };
}

#endif /* CWClock_hpp */
