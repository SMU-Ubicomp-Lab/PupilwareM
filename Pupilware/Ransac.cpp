#include "Ransac.h"

namespace pd
{
    int Ransac::num_samples_circle( int nsample, int ngood, double p )
    {
        if(nsample == ngood) return 1;
        return ((int)(ceil(log(p)/log(1.-pow((double)ngood/nsample,3)))));
    }
    
    void Ransac::getThreeRandomPoints( int max_num, int* out_random_nums )
    {
        int index = 0;
        while (index < 3)
        {
            bool newone = true;
            int      r = (int)((double)(rand())/RAND_MAX * max_num);
            for (int i = 0; i<index; ++i)
            {
                if (r == out_random_nums[i])
                {
                    newone = false;
                    break;
                }
            }
            if (newone)
            {
                out_random_nums[index] = r;
                ++index;
            }
        }
    }
    
    
    float Ransac::distance_sq( cv::Point * pt1, cv::Point * pt2)
    {
        return sqrtf(((pt1->x - pt2->x)*(pt1->x - pt2->x))+((pt1->y - pt2->y)*(pt1->y - pt2->y)));
    }
    
    
    bool Ransac::ransac_circle_fitting(std::vector<cv::Point2f>P, int N,
                                       int ngood_pts,               //num of good input(estimation);
                                       double p_fail,                //prior prb. algorithm exit without having a good fits;
                                       
                                       double distance_th,       //fitting distance threshold;
                                       int    samples_th,           //minimum num of final fitting data.
                                       std::vector<cv::Point>& out_inliner )
    {
        int max_count = 0;
        bool res=false;
        std::vector<cv::Point> Q;     //collection of inliers;
        Q.reserve(N);
        //int max_iter=num_samples_circle(N, ngood_pts, p_fail) ;
        int max_iter = 30;
        int iter=0;
        int max_inliner = 0;
        while(iter<max_iter)
        {
            int index[3]; cv::Point pts[3];
            
            this->getThreeRandomPoints(N-1,index);
            
            for(int k=0; k<3; ++k)
            {
                pts[k]=P[index[k]];
            }
            
            Circle temp_circle;
            temp_circle.CalcCircle(&pts[0], &pts[1], &pts[2]);
            
            if( temp_circle.GetRadius() < 0 || temp_circle.GetCenter()->x<0 || temp_circle.GetCenter()->y<0)
            {
                max_count++;
                if (max_count > 30) return false;
                continue; // reject degenerate case;
            }
            
            int inliers=0;
            for(int k=0; k<N; ++k)
            {
                cv::Point tmp = P[k];
                float dist = distance_sq(&tmp, temp_circle.GetCenter());
                float diff = fabs(dist - temp_circle.GetRadius());
                if( diff <= distance_th ) 
                {  
                    Q.push_back(P[k]);
                }
            }
            
            
            if(Q.size()>=samples_th) 
            {                                     //if sufficient maybe_inliers collected;
                //refine circle==>center, radius;                      //refine model parameters;
                //re_test distance_th and samples_th;              //collect inliers;
                //if(TEST_OK) { res=TRUE; break;}
                bestModel = temp_circle;
                out_inliner.clear();
                out_inliner.assign(Q.begin(), Q.end());
                res = true;
                break;
            }
            
            if(Q.size()>=max_inliner)
            {
                out_inliner.clear();
                out_inliner.assign(Q.begin(), Q.end());
                max_inliner = Q.size();
                bestModel = temp_circle;
            }
            
            Q.clear();
            
            ++iter;
        }
        
        return res;
    }
}
