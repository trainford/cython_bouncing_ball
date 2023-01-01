import numpy as np
cimport numpy as np
import pyrr

cpdef np.ndarray[np.float64_t, ndim=1] load_mesh(str filepath):
    cdef str v_tag = "v"
    cdef str vt_tag = "vt"
    cdef str vn_tag = "vn"
    cdef str f_tag = "f"
    cdef str flag, vertex
    cdef int firstSpace
    cdef int i
    cdef int pos, tex, norm
    cdef int tris_in_face

    # init lists
    cdef list v = []
    cdef list vt = []
    cdef list vn = []
    cdef list verts = []
    cdef list faceVerts = []
    cdef list faceTex = []
    cdef list faceNorms = []
    cdef list vert_order = []

    with open(filepath, 'r') as f:
        line = f.readline()
        while line:
            firstSpace = line.find(" ")
            flag = line[0:firstSpace]
            if flag == v_tag:
                line = line.replace("v ", "")
                # [x, y, z]
                line = line.split(" ")
                l = [float(x) for x in line]
                v.append(l)
            elif flag == vt_tag:
                line = line.replace("vt ", "")
                # [s, t]
                line = line.split(" ")
                l = [float(x) for x in line]
                vt.append(l)
            elif flag == vn_tag:
                line = line.replace("vn ", "")
                # [nx, ny, nz]
                line = line.split(" ")
                l = [float(x) for x in line]
                vn.append(l)
            elif flag == f_tag:
                line = line.replace("f ", "")
                line = line.replace("\n", "")
                # [../../.., ../../.., ../../..]
                line = line.split(" ")
                faceVerts = []
                faceTex = []
                faceNorms = []
                for vertex in line:
                    # vertex = v/vt/vn
                    # [v, vt, vn]
                    l = vertex.split("/")
                    pos = int(l[0]) - 1
                    faceVerts.append(v[pos])
                    tex = int(l[1]) - 1
                    faceTex.append(vt[tex])
                    norm = int(l[2]) - 1
                    faceNorms.append(vn[norm])
                tris_in_face = len(line) - 2
                vert_order = []
                for i in range(tris_in_face):
                    vert_order.append(0)
                    vert_order.append(i + 1)
                    vert_order.append(i + 2)
                for i in vert_order:
                    for x in faceVerts[i]:
                        verts.append(x)
                    for x in faceTex[i]:
                        verts.append(x)
                    for x in faceNorms[i]:
                        verts.append(x)
            line = f.readline()
    verts_np = np.array(verts, dtype=np.float32)
    return verts_np

cpdef prep_geo(verts):
    cdef double[:, :]iso_v_mem
    cdef double[:, :]iso_n_mem
    cdef list iso_v = []
    cdef list iso_n = []
    cdef list temp_v = []
    cdef list temp_n = []
    cdef int i, j
    cdef int num_verts = len(verts) / 8
    for i in range(num_verts):
        j = i * 8
        temp_v = [verts[j], verts[j + 1], verts[j+ 2]]
        temp_n = [verts[j + 5], verts[j + 6], verts[j + 7]]
        iso_v.append(temp_v)
        iso_n.append(temp_n)
    iso_v_mem = np.array(iso_v, dtype=np.float64)
    iso_n_mem = np.array(iso_n, dtype=np.float64)
    return iso_v_mem, iso_n_mem