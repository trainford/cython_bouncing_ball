from OpenGL.GL import *
from OpenGL.GL.shaders import compileProgram, compileShader
from OpenGL_accelerate import *
from material_class import Material
import obj_handler as obj
import vec_math as vm
cimport numpy as np
import numpy as np
import pyrr
from timeit import default_timer as timer

class Box:

    def __init__(self, origin, s, r, t, tex):

        self.origin = origin
        self.vertices = self.init_verts()
        self.normals = self.init_normals()
        self.pts_list = self.init_points()
        self.pts_list_sim = self.pts_list
        self.d_list = self.init_dlist()
        self.hit_nrml = np.zeros(3, dtype=np.float64)

        self.scale = s
        self.rotation = r
        self.translation = t
        self.scale_M = self.scale_box(self.scale)
        self.rotation_M = self.rotate_box(self.rotation)

        self.texture = tex

        self.vbo = glGenBuffers(1)
        glBindBuffer(GL_ARRAY_BUFFER, self.vbo)
        glBufferData(GL_ARRAY_BUFFER, self.vertices.nbytes, self.vertices, GL_STATIC_DRAW)

    def init_verts(self):
        cdef np.ndarray[np.float32_t, ndim=1] verts = obj.load_mesh("obj_files/basic_cube_GEO.obj")
        return verts

    def init_normals(self):
        cdef list box_norms = [
            [ 0,  0,  1], 
            [ 0,  0, -1],
            [ 0,  1,  0],
            [ 0, -1,  0],
            [ 1,  0,  0],
            [-1,  0,  0]
        ]
        cdef np.ndarray[np.float64_t, ndim=2] box_norms_np = np.array(box_norms, dtype=np.float64)
        return box_norms_np

    def init_points(self):
        cdef list pts_list = [
            [ 1.0, -1.0, -1.0],
            [ 1.0, -1.0,  1.0],
            [ 1.0, -1.0, -1.0],
            [ 1.0,  1.0,  1.0],
            [-1.0,  1.0,  1.0],
            [ 1.0, -1.0,  1.0]
        ]
        cdef np.ndarray[np.float64_t, ndim=2] pts_list_np = np.array(pts_list, dtype=np.float64)
        return pts_list_np

    def init_dlist(self):
        cdef np.ndarray[np.float64_t, ndim=1] d_list = np.zeros(6, dtype=np.float64)
        return d_list

    def rotate_box(self, eulers):
        pass

    def translate_box(self, x, y, z):
        pass

    def scale_box(self, s):
        cdef np.ndarray[np.float64_t, ndim=1] scale_val = self.scale * s
        cdef np.ndarray[np.float64_t, ndim=2] scale_M = pyrr.matrix44.create_from_scale(scale_val, dtype=np.float64)
        self.pts_list_sim = self.pts_list * scale_val
        return scale_M

    def transform_box(self, scale):
        self.scale_M = self.scale_box(scale)
        return

    def coll_detect(self, x, new_x, h):
        cdef double[:, :] norms = self.normals
        cdef double[:, :] pts_list_mem = self.pts_list_sim
        cdef double[:] temp, temp1
        cdef int i = 0
        cdef double tol = 0.0001
        cdef double rad = 0.2
        cdef double d, d1
        cdef double timer_start = timer()
        for i in range(6):
            # curr distance
            temp = vm.sub(x, pts_list_mem[i])
            d = vm.dot(temp, norms[i]) - rad
            self.d_list[i] = d
            # see if next step will result in collision
            temp1 = vm.sub(new_x, pts_list_mem[i])
            d1 = vm.dot(temp1, norms[i]) - rad
            if d1 < tol:
                self.hit_nrml = norms[i]
                return self.coll_deter(h, d, d1)
        return 0

    def coll_deter(self, double h, double d, double d1):
        cdef double f = d / (d-d1)
        cdef double fh = f * h
        return fh

    def display(self, modelLoc):
        self.texture.use()
        cdef np.ndarray[np.float64_t, ndim=2] model = self.scale_M
        glBindBuffer(GL_ARRAY_BUFFER, self.vbo)
        glEnableVertexAttribArray(0)
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 32, ctypes.c_void_p(0))
        glEnableVertexAttribArray(1)
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 32, ctypes.c_void_p(12))
        glEnableVertexAttribArray(2)
        glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, 32, ctypes.c_void_p(20))
        glBindVertexArray(0)
        glUniformMatrix4fv(modelLoc, 1, GL_FALSE, model)
        glDrawArrays(GL_TRIANGLES, 0, len(self.vertices) / 8)
        return

    def delete_buffers(self):
        glDeleteBuffers(self.vbo)
        return

