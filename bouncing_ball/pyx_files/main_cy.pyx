from OpenGL.GL import *
from OpenGL.GL.shaders import compileProgram, compileShader
from OpenGL_accelerate import *
from ball import Ball
from box import Box
from material_class import Material
from poly_collider import PolyCollider
from ui import UI
import glfw
import numpy as np 
cimport numpy as np
import math
import pyrr
from tkinter import *
from tkinter import ttk
from timeit import default_timer as timer

# camera setup
cdef int scr_width = 640
cdef int scr_height = 640

cdef float cam_rad = 5.0
cdef float cam_spd = 0.5
cdef float theta = 0
cdef float phi = 0

cdef float cam_x = 0
cdef float cam_y = cam_rad
cdef float cam_z = 0

# basic physics
grav = np.array([0, 0, -10], dtype=np.float64)
wind = np.array([0, 0, 0], dtype=np.float64)
cdef double d = 0.1
cdef double cr = 1.0
cdef double cf = 0.5

# box controls
origin = np.zeros(3, dtype=np.float64)
scale = np.array([1.0, 1.0, 1.0], dtype=np.float64)
rotation = np.zeros(3, dtype=np.float64)
translation = np.zeros(3, dtype=np.float64)

# sim setup
cdef double t_max = (1.0000/60.0000)
cdef double h = t_max / 6.0000

# collider setup
cdef list collider_setup = [[[0, 0, 0], 1]]

cdef void frame_resize(window, int width, int height):
    glViewport(0, 0, width, height)
    return

cdef void process_input(window):
    global theta, phi
    global cam_x, cam_y, cam_z
    global cam_rad, cam_spd
    global grav, wind, air_resist
    global scale, rotation, translation
    global cr, cf
    cdef double limit = 100
    cdef double val = 0.01
    cdef np.ndarray[np.float64_t, ndim=1] x_var = np.array([1.0, 0.0, 0.0], dtype=np.float64)
    cdef np.ndarray[np.float64_t, ndim=1] y_var = np.array([0.0, 1.0, 0.0], dtype=np.float64)
    cdef np.ndarray[np.float64_t, ndim=1] z_var = np.array([0.0, 0.0, 1.0], dtype=np.float64)
    cdef np.ndarray[np.float64_t, ndim=1] scale_val = np.array([0.1, 0.1, 0.1], dtype=np.float64)
    # escape
    if glfw.get_key(window, glfw.KEY_ESCAPE) == glfw.PRESS:
        glfw.set_window_should_close(window, True)
        return
    # a to move left
    if glfw.get_key(window, glfw.KEY_A) == glfw.PRESS:
        theta -= cam_spd
        if theta < 0.0:
            theta += 360
        cam_x = cam_rad * math.cos(math.radians(phi)) * math.cos(math.radians(theta))
        cam_y = cam_rad * math.cos(math.radians(phi)) * math.sin(math.radians(theta))
        cam_z = cam_rad * math.sin(math.radians(phi))
    # d to move right
    if glfw.get_key(window, glfw.KEY_D) == glfw.PRESS:
        theta += cam_spd
        if theta >= 0.0:
            theta -= 360.0
        cam_x = cam_rad * math.cos(math.radians(phi)) * math.cos(math.radians(theta))
        cam_y = cam_rad * math.cos(math.radians(phi)) * math.sin(math.radians(theta))
        cam_z = cam_rad * math.sin(math.radians(phi))
    # w to move up
    if glfw.get_key(window, glfw.KEY_W) == glfw.PRESS:
        if phi < (90.0 - cam_spd):
            phi += cam_spd
        cam_x = cam_rad * math.cos(math.radians(phi)) * math.cos(math.radians(theta))
        cam_y = cam_rad * math.cos(math.radians(phi)) * math.sin(math.radians(theta))
        cam_z = cam_rad * math.sin(math.radians(phi))
    # s to move down
    if glfw.get_key(window, glfw.KEY_S) == glfw.PRESS:
        if phi > (-90.0 + cam_spd):
            phi -= cam_spd
        cam_x = cam_rad * math.cos(math.radians(phi)) * math.cos(math.radians(theta))
        cam_y = cam_rad * math.cos(math.radians(phi)) * math.sin(math.radians(theta))
        cam_z = cam_rad * math.sin(math.radians(phi))
    # g to sub from gravity
    if glfw.get_key(window, glfw.KEY_G) == glfw.PRESS:
        if grav[2] <= -limit:
            grav = grav
        else:
            grav = grav - z_var
    # f to add to gravity
    if glfw.get_key(window, glfw.KEY_F) == glfw.PRESS:
        if grav[2] >= limit:
            grav = grav
        else:
            grav = grav + z_var
    # j to move wind in -x direction
    if glfw.get_key(window, glfw.KEY_J) == glfw.PRESS:
        if wind[0] <= -limit:
            wind = wind
        else:
            wind = wind - x_var
    # l to move wind in x direction
    if glfw.get_key(window, glfw.KEY_L) == glfw.PRESS:
        if wind[0] >= limit:
            wind = wind
        else:
            wind = wind + x_var
    # i to move wind in -y direction
    if glfw.get_key(window, glfw.KEY_I) == glfw.PRESS:
        if wind[1] <= -limit:
            wind = wind
        else:
            wind = wind - y_var
    # k to move wind in y direction
    if glfw.get_key(window, glfw.KEY_K) == glfw.PRESS:
        if wind[1] >= limit:
            wind = wind
        else:
            wind = wind + y_var
    # n to raise cr
    if glfw.get_key(window, glfw.KEY_M) == glfw.PRESS:
        if cr >= 1.0:
            cr = cr
        else:
            cr += val
    # m to lower cr
    if glfw.get_key(window, glfw.KEY_N) == glfw.PRESS:
        if cr <= 0.0:
            cr = cr
        else:
            cr -= val
    # z to lower cf
    if glfw.get_key(window, glfw.Z) == glfw.PRESS:
        if cf <= 0.0:
            cf = cr
        else:
            cf -= val
    # x to raise cf
    if glfw.get_key(window, glfw.X) == glfw.PRESS:
        if cf <= 0.0:
            cf = cr
        else:
            cf += val
        
def createShader(vertexFilepath, fragmentFilepath):
    with open(vertexFilepath, 'r') as f:
        vertex_src = f.readlines()
    with open(fragmentFilepath, 'r') as f:
        fragment_src = f.readlines()
    shader = compileProgram(
        compileShader(vertex_src, GL_VERTEX_SHADER),
        compileShader(fragment_src, GL_FRAGMENT_SHADER)
    )
    return shader

cpdef int force_frame(double t_max, double wall_t_start):
    cdef double time = timer() - wall_t_start
    if time >= t_max:
        return 1
    else:
        return 0

cpdef int output_frame(double t_max, double wall_t_start):
    cdef double time = timer() - wall_t_start
    if time >= t_max:
        return 1
    else:
        while timer() - wall_t_start < t_max:
            continue
        return 1

def simloop(ball, box, collider_list, modelLoc):
    global grav, wind
    cdef double t = 0.0
    cdef double n = 0.0
    cdef double tol = 0.001
    cdef double t_remaining, box_fh, poly_fh, timestep
    cdef double[:] x_mem, new_x_mem, v_mem, grav_pntr, wind_pntr
    cdef double wall_t_start = timer()
    cdef double inner_loop_time
    while t < t_max:
        t_remaining = h
        timestep = t_remaining
        while t_remaining > tol:
            grav_pntr = grav
            wind_pntr = wind
            inner_loop_time = timer()
            ball.accelerations(grav_pntr, wind_pntr, d)
            ball.euler(timestep)
            x_mem = ball.x
            new_x_mem = ball.new_x
            v_mem = ball.v
            box_fh = box.coll_detect(x_mem, new_x_mem, timestep)
            if box_fh:
                timestep = box_fh * timestep
                ball.euler(timestep)
                ball.coll_response(box.hit_nrml, cr, cf)
            #for collider in collider_list:
            #    poly_fh = collider_list[0].coll_detect(x_mem, new_x_mem, v_mem, timestep)
            #    if poly_fh:
            #        timestep = poly_fh * timestep
            #        ball.euler(timestep)
            #        ball.coll_response(collider_list[0].hit_nrml, cr, cf)
            if timestep < tol:
                t_remaining = 0.0
            else:
                t_remaining = t_remaining - timestep
            if ball.still_moving(box.d_list, box.normals):
                ball.update()
            else:
                continue
        if force_frame(t_max, wall_t_start):
            ball.display(modelLoc)
            return
        n += 1.0
        t = n * h
    if output_frame(t_max, wall_t_start):
        ball.display(modelLoc)
        pass
    return

cpdef void main_loop():

    cdef list collider_list = []

    glfw.init()

    window = glfw.create_window(scr_width, scr_height, "Bouncing Ball", None, None)

    if window == None:
        print("Failed to create window")
        glfw.terminate()
        return

    glfw.make_context_current(window)

    glViewport(0, 0, scr_height, scr_width)

    glfw.set_framebuffer_size_callback(window, frame_resize)

    #ui = Tk()
    #UI(ui)
    #ui.mainloop()

    #ui_window = Toplevel(ui)

    glEnable(GL_DEPTH_TEST)
    glEnable(GL_CULL_FACE)
    glCullFace(GL_BACK)

    # init vert arrays
    vao = glGenVertexArrays(1)
    glBindVertexArray(vao)

    # init shader and uniform locations
    shader = createShader("openglShaders/vertex_phong.txt", "openglShaders/fragment_phong.txt")
    glUseProgram(shader)
    modelLoc = glGetUniformLocation(shader, "model")
    viewLoc = glGetUniformLocation(shader, "view")
    projLoc = glGetUniformLocation(shader, "projection")

    # set projection matrix
    projM = pyrr.matrix44.create_perspective_projection(
        fovy = 35.0, aspect = (scr_width/scr_height),
        near = 0.1, far = 100, dtype = np.float32
    )
    glUniformMatrix4fv(projLoc, 1, GL_FALSE, projM)

    ball_TEX = Material("textures/toad_head_TEX_invert.png")
    box_TEX = Material("textures/mario_cube_TEX_invert.png")
    floor_TEX = Material("textures/floor_cube_TEX_invert.png")
    #question_TEX = Material("")

    # init ball obj
    ball = Ball("obj_files/toad_head_GEO.obj", ball_TEX)
    box = Box(origin, scale, rotation, translation, box_TEX)
    floor = PolyCollider(
        [0, 0, 0], "obj_files/floor_cube_GEO.obj", floor_TEX, 1
    )
    q_block_1 = PolyCollider(
        [0, 0, 0], "obj_files/question_cube_GEO1.obj", floor_TEX, 1
    )
    q_block_2 = PolyCollider(
        [0, 0, 0], "obj_files/question_cube_GEO3.obj", floor_TEX, 1
    )

    collider_list = [] #[floor, q_block_1, q_block_2]

    while glfw.window_should_close(window) == False:

        # loop reset
        process_input(window)
        glClearColor(0.5, 0.85, 0.6, 1.0)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

        # set view matrix
        viewM = pyrr.matrix44.create_look_at(
            np.array([cam_x, cam_y, cam_z]),
            np.array([0.0, 0.0, 0.0]),
            np.array([0.0, 0.0, 1.0]),
            dtype=np.float32
        )
        glUniformMatrix4fv(viewLoc, 1, GL_FALSE, viewM)

        box.transform_box(scale)
        box.display(modelLoc)
        #floor.display(modelLoc)
        #q_block_1.display(modelLoc)
        #q_block_2.display(modelLoc)
        simloop(ball, box, collider_list, modelLoc)
        
        glfw.swap_buffers(window)
        glfw.poll_events()

    glDeleteVertexArrays(1, vao)
    ball.delete_buffers()
    box.delete_buffers()
    floor.delete_buffers()
    q_block_1.delete_buffers()
    q_block_2.delete_buffers()
    box_TEX.destroy()
    ball_TEX.destroy()
    floor_TEX.destroy()
    glDeleteProgram(shader)
    glfw.terminate()
    return





