from OpenGL.GL import *
from OpenGL.GL.shaders import compileProgram, compileShader
from OpenGL_accelerate import *
from box import Box
import vec_math as vm
import obj_handler as obj
from material_class import Material
cimport numpy as np
import numpy as np
import pyrr

class Ball:

    def __init__(self, obj_filepath, tex):
        self.x = np.zeros(3, dtype=np.float64)
        self.v = np.zeros(3, dtype=np.float64)
        self.new_x = np.zeros(3, dtype=np.float64)
        self.new_v = np.zeros(3, dtype=np.float64)
        self.a = np.zeros(3, dtype=np.float64)
        self.m = 1.00000

        self.vertices = self.init_verts(obj_filepath)

        self.texture = tex

        self.vbo = glGenBuffers(1)
        glBindBuffer(GL_ARRAY_BUFFER, self.vbo)
        glBufferData(GL_ARRAY_BUFFER, self.vertices.nbytes, self.vertices, GL_STATIC_DRAW)

    def init_verts(self, obj_filepath):
        cdef np.ndarray[np.float32_t, ndim=1] verts = obj.load_mesh(obj_filepath)
        return verts

    def euler(self, double h):
        self.new_x = self.x + (self.v * h)
        self.new_v = self.v + (self.a * h)
        return

    def update(self):
        self.x = self.new_x
        self.v = self.new_v
        return

    def still_moving(self, d_list, norms):
        cdef double[:] v_mem = self.v
        cdef double[:] a_mem = self.a
        cdef double[:] d_list_mem = d_list
        cdef double[:,:] norms_mem = norms
        cdef double[:] a_n, a_t
        cdef double temp
        cdef double tol = 0.01
        cdef double tol_v = 0.5
        if vm.mag(v_mem) < tol_v:
            for i in range(6):
                if d_list_mem[i] < tol:
                    if vm.dot(a_mem, norms_mem[i]) < tol:
                        temp = vm.dot(a_mem, norms_mem[i])
                        a_n = vm.multi(norms_mem[i], temp)
                        a_t = vm.sub(a_mem, a_n)
                        if vm.mag(a_t) < vm.mag(a_n):
                            return 0
                        else:
                            return 1
        else:
            return 1
        return 1

    def accelerations(self, g, w, d):
        cdef double m = self.m
        cdef np.ndarray[np.float64_t, ndim=1] v = self.v
        cdef np.ndarray[np.float64_t, ndim=1] grav = vm.multi(g, m)
        cdef np.ndarray[np.float64_t, ndim=1] wind = vm.multi(w, d)
        cdef np.ndarray[np.float64_t, ndim=1] air_r = vm.multi(v, d * -1)
        cdef np.ndarray[np.float64_t, ndim=1] a_tot = grav + wind + air_r
        self.a = a_tot
        return 

    def coll_response(self, n, cr, cf):
        cdef double[:] v = self.v
        cdef double temp
        cdef double[:] v_n, v_t, v_n_new, v_t_new
        cdef double temp_double = 1.0
        cdef np.ndarray[np.float64_t, ndim=1] v_response
        temp = vm.dot(v, n)
        v_n = vm.multi(n, temp)
        v_t = vm.sub(v, v_n)
        v_n_new = vm.multi(v_n, -cr) 
        v_t_new = self.calc_friction(v_n, v_t, cf)
        v_response = vm.add(v_n_new, v_t_new)
        self.new_x = self.x
        self.new_v = v_response
        return

    def calc_friction(self, v_n, v_t, cf):
        cdef np.ndarray[np.float64_t, ndim=1] temp
        cdef double mag_vn = vm.mag(v_n)
        cdef double mag_vt = vm.mag(v_t)
        temp = vm.multi(v_t, min((cf * mag_vn, mag_vt)))
        return vm.sub(v_t, temp)

    def display(self, modelLoc):
        self.texture.use()
        cdef np.ndarray[np.float64_t, ndim=2] model = pyrr.matrix44.create_from_translation(self.x, dtype=np.float64)
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
        glDeleteBuffers(1, self.vbo)
        return

    

    