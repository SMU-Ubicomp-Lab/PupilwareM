//
//  CWProfiler.cpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 7/15/16.
//  Copyright © 2016 Chatchai Wangwiwattana All rights reserved.
//

#include "CWProfiler.hpp"
#include "CWClock.hpp"

namespace cw{
    std::shared_ptr<CWProfiler> CWProfiler::s_instance;
    
    CWProfiler& CWProfiler::get(){
        if(!s_instance){
            s_instance = std::make_shared<CWProfiler>();
        }
        return *s_instance.get();
    }
    
    void CWProfiler::accumulateTime( const CWClock& clock ){
        CWProfiler::get()._accumulateTime(clock);
    }
    
    void CWProfiler::_accumulateTime(const cw::CWClock &clock){
        profiles[clock.getName()] += clock.getDeltaTime();
        
        print();
    }
    

    void CWProfiler::print() const{
        
        std::cout << "----- Profiles ------" << std::endl;
        for (auto it: profiles) {
            auto name = it.first;
            auto time = it.second;
            
            std::cout << "[" << name << "]" << time << std::endl;
        }
        std::cout << "--------------------" << std::endl;
    }
}