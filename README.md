# Gradient Domain Fusion

This project aims to explore gradient-domain processing and for seamless bledning of an object or texture from a source image into a target image. The simplest method would be to just copy and paste the pixels from one image directly into the other. Unfortunately, this will create very noticeable seams, even if the backgrounds are well-matched. Poisson blending, as explained in [this paper](http://cs.brown.edu/courses/csci1950-g/asgn/proj2/resources/PoissonImageEditing.pdf), create an image by solving for specified pixel intensities and gradients and therefore more seamless result. This project also explores mixed blending, which is very similar to poisson blending but with a twist. For more information, please visit [here](https://inst.eecs.berkeley.edu/~cs194-26/fa16/upload/files/projFinalUndergrad/cs194-26-acm/).

![Example](https://inst.eecs.berkeley.edu/~cs194-26/fa16/upload/files/projFinalUndergrad/cs194-26-acm/obamaPoisson.jpg)

# To run code

Please see comments in main.m for further definition of parameters
```
main()
``` 