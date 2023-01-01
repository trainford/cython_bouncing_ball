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

class PolyCollider:

    def __init__(self, origin, obj_filepath, tex, s):
        self.origin = origin
        self.vertices = self.init_verts(obj_filepath)
        self.num_verts = int(len(self.vertices) / 8)
        self.num_faces = int(self.num_verts / 3)
        self.prep_geo()
        self.d_list = self.init_dlist()
        self.hit_nrml = np.zeros(3, dtype=np.float64)

        self.scale = s

        self.texture = tex

        self.vbo = glGenBuffers(1)
        glBindBuffer(GL_ARRAY_BUFFER, self.vbo)
        glBufferData(GL_ARRAY_BUFFER, self.vertices.nbytes, self.vertices, GL_STATIC_DRAW)

    def init_verts(self, obj_filepath):
        cdef np.ndarray[np.float32_t, ndim=1] verts = obj.load_mesh(obj_filepath)
        return verts

    def init_dlist(self):
        cdef np.ndarray[np.float64_t, ndim=1] d_list = np.zeros(self.num_faces, dtype=np.float64)
        return d_list

    def prep_geo(self):
        cdef float[:]verts = self.vertices
        self.iso_verts, self.iso_norms = obj.prep_geo(verts)
        return

    def coll_detect(self, x, new_x, v_mem, h):
        cdef double[:, :] poly_norms = self.iso_norms
        cdef double[:, :] verts = self.iso_verts
        cdef double[:, :] poly
        cdef double[:] temp, temp1, x_hit
        cdef int n_f = self.num_faces
        cdef int n_v = self.num_verts
        cdef int i, j
        cdef double tol = 0.00001
        cdef double rad = 0.2
        cdef double d, d1, fh
        cdef double timer_start = timer()
        for i in range(n_f):
            j = i * 3
            temp = vm.sub(x, verts[j])
            d = vm.dot(temp, poly_norms[j]) - rad
            self.d_list[i] = d
            # see if next step will result in collision
            temp1 = vm.sub(new_x, verts[j])
            d1 = vm.dot(temp1, poly_norms[j]) - rad
            if abs(d - d1) < tol:
                continue
            else:
                fh = self.find_fh(h, d, d1)
            if 0.0 <= fh and fh < h:
                self.hit_nrml = poly_norms[j]
                poly = np.array([verts[j], verts[j + 1], verts[j + 2]], dtype=np.float64)
                x_hit = vm.add(x, vm.multi(v_mem, fh))
                if self.coll_deter(x_hit, poly_norms[j], poly):
                    return fh
        return 0

    def find_fh(self, double h, double d, double d1):
        cdef double f = d / (d-d1)
        cdef double fh = f * h
        return fh

    def coll_deter(self, x_hit, norm, poly):
        cdef double tol = 0.0001
        cdef double max_axis = 0.0
        cdef double abs_norm, deter
        cdef np.ndarray[np.float64_t, ndim=1] temp
        cdef np.ndarray[np.float64_t, ndim=1] temp1
        cdef np.ndarray[np.float64_t, ndim=2] matrix
        cdef np.ndarray[np.float64_t, ndim=2] proj_poly = np.array([[0.0, 0.0], [0.0, 0.0], [0.0, 0.0]], dtype=np.float64)
        cdef list edge_vectors = []
        cdef list xhit_vectors = []
        cdef list deter_list = []
        cdef int i, j, k, l, max_n_index
        for i in range(3):
            abs_norm = abs(norm[i])
            if abs_norm > max_axis:
                max_axis = abs_norm
                max_n_index = i
        if max_n_index == 0:
            proj_xhit = np.array([x_hit[1], x_hit[2]], dtype=np.float64)
            proj_poly[0] = np.array([poly[0, 1], poly[0, 2]], dtype=np.float64)
            proj_poly[1] = np.array([poly[1, 1], poly[1, 2]], dtype=np.float64)
            proj_poly[2] = np.array([poly[2, 1], poly[2, 2]], dtype=np.float64)
        elif max_n_index == 1:
            proj_xhit = np.array([x_hit[2], x_hit[0]], dtype=np.float64)
            proj_poly[0] = np.array([poly[0, 2], poly[0, 0]], dtype=np.float64)
            proj_poly[1] = np.array([poly[1, 2], poly[1, 0]], dtype=np.float64)
            proj_poly[2] = np.array([poly[2, 2], poly[2, 0]], dtype=np.float64)
        else:
            proj_xhit = np.array([x_hit[0], x_hit[1]], dtype=np.float64)
            proj_poly[0] = np.array([poly[0, 0], poly[0, 1]], dtype=np.float64)
            proj_poly[1] = np.array([poly[1, 0], poly[1, 1]], dtype=np.float64)
            proj_poly[2] = np.array([poly[2, 0], poly[2, 1]], dtype=np.float64)
        for j in range(3):
            if j == 2:
                temp = vm.sub22(proj_poly[0], proj_poly[2])
                temp1 = vm.sub22(proj_xhit, proj_poly[2])
            else:
                temp = vm.sub22(proj_poly[j + 1], proj_poly[j])
                temp1 = vm.sub22(proj_xhit, proj_poly[j])
            edge_vectors.append(temp)
            xhit_vectors.append(temp1)
        for k in range(3):
            matrix = np.array([edge_vectors[k], xhit_vectors[k]], dtype=np.float64)
            deter = vm.deter22(matrix)
            deter_list.append(deter)
        if deter_list[0] * deter_list[1] < 0.0:
            return 0
        elif deter_list[0] * deter_list[2] < 0.0:
            return 0
        return 1

    def display(self, modelLoc):
        self.texture.use()
        cdef np.ndarray[np.float64_t, ndim=2] model = pyrr.matrix44.create_identity(dtype=np.float64)
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
            
        

        


            
        




    