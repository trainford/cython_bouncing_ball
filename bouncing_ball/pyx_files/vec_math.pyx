import numpy as np
cimport numpy as np
from libc.math cimport sqrt
import timeit

cpdef np.ndarray[np.float64_t, ndim=1] add(double[:] v1, double[:] v2):
    cdef list array = [v1[0] + v2[0], v1[1] + v2[1], v1[2] + v2[2]]
    return np.array(array, dtype=np.float64)
    
cpdef np.ndarray[np.float64_t, ndim=1] sub(double[:] v1, double[:] v2):
    cdef list array = [v1[0] - v2[0], v1[1] - v2[1], v1[2] - v2[2]]
    return np.array(array, dtype=np.float64)

cpdef np.ndarray[np.float64_t, ndim=1] multi(double[:] v, double s):
    cdef list array = [v[0] * s, v[1] * s, v[2] * s]
    return np.array(array, dtype=np.float64)

cpdef np.ndarray[np.float64_t, ndim=1] add22(double[:] v1, double[:] v2):
    cdef list array = [v1[0] + v2[0], v1[1] + v2[1]]
    return np.array(array, dtype=np.float64)

cpdef np.ndarray[np.float64_t, ndim=1] sub22(double[:] v1, double[:] v2):
    cdef list array = [v1[0] - v2[0], v1[1] - v2[1]]
    return np.array(array, dtype=np.float64)

cpdef np.ndarray[np.float64_t, ndim=1] multi2(double[:] v, double s):
    cdef list array = [v[0] * s, v[1] * s]
    return np.array(array, dtype=np.float64)

cpdef double dot(double[:] v1, double[:] v2):
    return v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2]

cpdef double mag(double[:] v):
    return sqrt((v[0] ** 2) + (v[1] ** 2) + (v[2] ** 2))

cpdef double deter22(double[:, :] M):
    return (M[0, 0] * M[1, 1]) - (M[1, 0] * M[0, 1])
