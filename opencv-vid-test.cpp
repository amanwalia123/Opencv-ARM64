#include "opencv2/opencv.hpp"
#include <iostream>
#include <string>

#define FRAME "frame_"
#define EXT ".png" 
 
int main(){

  std::cout<<"Hello"<<std::endl;  
 
  // Create a VideoCapture object and open the input file
  // If the input is the web camera, pass 0 instead of the video file name
  cv::VideoCapture cap("test.mp4"); 
    
  // Check if camera opened successfully
  if(!cap.isOpened()){
    std::cout << "Error opening video stream or file" <<std::endl;
    return -1;
  }

  int i = 1;

  while(1){
 
    cv::Mat frame;
    // Capture frame-by-frame
    cap >> frame;
  
    // If the frame is empty, break immediately
    if (frame.empty())
      break;
 
    // Display the resulting frame
    cv::imshow( "Frame", frame );

    if(i %300 == 0){
        std::cout<<"Read frame"<<i<<std::endl;
        cv::imwrite(FRAME+std::to_string(i)+EXT,frame);
    }
 
    i++;

  }
  
  // When everything done, release the video capture object
  cap.release();
 
     
  return 0;
}