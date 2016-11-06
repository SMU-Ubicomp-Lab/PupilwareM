//
// Created by Chatchai Wangwiwattana on 6/7/16.
//

#include "PWDataModel.hpp"

#include <cassert>
#include <iostream>

namespace pw{


    void PWDataModel::addPupilSize(const PWPupilSize &ps) {

        leftPupilSizes.push_back( ps.leftRadius );
        rightPupilSizes.push_back( ps.rightRadius );
        
        leftMPIs.push_back(ps.leftMPI);
        rightMPIs.push_back(ps.rightMPI);

    }


    void PWDataModel::setPupilSizeAt(size_t index, const PWPupilSize &ps) {

        assert( index >= 0 );


        if( index >= leftPupilSizes.size() ){

            assert( (index*2+1) <= MAXIMUM_BUFFER_SIZE );

            // Index + 1 because sometime index is zero.
            leftPupilSizes.resize( (index+1) * 2 );
            rightPupilSizes.resize( (index+1) * 2 );

            std::cout<< "[Warning] index is more than storage: "
                    << "We try to resize the buffer. Now the buffer size is "
                    << leftPupilSizes.size() << " elements " << std::endl;
        }

        leftPupilSizes[index] = ps.leftRadius;
        rightPupilSizes[index] = ps.rightRadius;
        
        std::cout<< "[Warning] MPI is not set here.!!" << std::endl;
    }


    PWPupilSize PWDataModel::getPupilSizeAt(size_t index) const {
        assert( index >= 0 );
        assert( index < leftPupilSizes.size() );

        return PWPupilSize(leftPupilSizes[index], rightPupilSizes[index]);

    }


    const std::vector<float>& PWDataModel::getLeftPupilSizes() const {
        return leftPupilSizes;
    }


    const std::vector<float>& PWDataModel::getRightPupilSizes() const {
        return rightPupilSizes;
    }

    const std::vector<float>& PWDataModel::getLeftMPIs() const {
        return leftMPIs;
    }
    
    
    const std::vector<float>& PWDataModel::getRightMPIs() const {
        return rightMPIs;
    }

    void PWDataModel::resize( size_t newSize ){
        leftPupilSizes.resize(newSize);
        rightPupilSizes.resize(newSize);
        
        leftMPIs.resize(newSize);
        rightMPIs.resize(newSize);
    }
    
    
    void PWDataModel::clear(){
        leftPupilSizes.clear();
        rightPupilSizes.clear();
        
        leftMPIs.clear();
        rightMPIs.clear();
        
    }

}