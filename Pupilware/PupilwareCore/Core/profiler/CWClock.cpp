//
//  CWClock.cpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 7/15/16.
//  Copyright © 2016 Chatchai Wangwiwattana All rights reserved.
//

#include "CWClock.hpp"
#include "CWProfiler.hpp"

namespace cw
{
    
    CWClock::CWClock():
        begin(std::chrono::steady_clock::now()){
        
    }

    CWClock::CWClock(const std::string& name):
    begin(std::chrono::steady_clock::now()),
    name(name){
        
    }
    
    void CWClock::reset(){
        begin = std::chrono::steady_clock::now();
    }
    
    
    double CWClock::getTime() const{
        return std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - begin).count();
    }
    
    const std::string& CWClock::getName() const{
        return name;
    }
    
    double CWClock::stop(){
//        CWProfiler::accumulateTime(*this);
        auto dt = getTime();
        reset();
        return dt;
    }
    
    CWClock::~CWClock(){

    }
}