# cython_bouncing_ball

This is a basic physics-based simulation implemented using Cython

There are quite a few libraries necessary in order to make this run. They are:
  
  1. Cython
  2. PyOpenGL and PyOpenGL accel
  3. glfw
  4. numpy (python import and cimport)
    1. setup.py already covers the numpy inclusion in c
  5. math
  6. pyrr
  7. tkinter
  8. timeit
  9. pillow
  
There are a few files that are included in the build but are not used due to bugs:

  1. poly_collider.pyx
  
    1. There are problems with any collisions that are not on the x-y plane. 
       x-z and y-z collisons occasionally work as long as the ball's vector is 
       close to perpendicular to the collision poly but it is hard to predict or 
       control so I commented it out of the loop.
  2. ui.py
  
    1. I built a UI using tkinter, hoping to run to windows concurrently 
       (a glfw window and a tkinter window). This, however, was not something that I was able 
       to get going, so the sim is controlled via keyboard commands.
       
 All textures and models were created by me and are free game to whoever want to use them.
 
 The keyboard commands are:
 
   1. Move the camera:
      WASD
      
   1. Change Gravity:
      G to add to gravity
      F to sub from gravity
      
   1. Add or subtract from wind force:
      IJKL
      
   1. Change Elasticity:
      N to add bounce
      M to sub bounce
      
   1. Change Friction:
      X to add friction
      Z to sub friction
      
Simulation is run from the run_sim.py file

I would like to return to this and revisit the bugs in the code. Until then, maybe you can take 
this code and use it in your own projects.
       
  

  
