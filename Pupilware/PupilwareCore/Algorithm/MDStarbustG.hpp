//
// Created by Chatchai Wangwiwattana on 6/6/16.
//

#ifndef PUPILWARE_MDSTARBUSTG_HPP
#define PUPILWARE_MDSTARBUSTG_HPP

#include "MDStarbust.hpp"

namespace pw{

class MDStarbustG: public MDStarbust {

public:
    MDStarbustG( const std::string& name );
    MDStarbustG( const MDStarbustG& other);
    virtual ~MDStarbustG();

    virtual void init() override ;

protected:
    virtual float getCost(int step) const override ;

private:
    int sigma;

};


}


#endif //PUPILWARE_MDSTARBUSTG_HPP
