from setuptools import Extension, setup
from Cython.Build import cythonize
import numpy

setup(ext_modules = cythonize("pyx_files/main_cy.pyx"), include_dirs=[numpy.get_include()])
setup(ext_modules = cythonize("pyx_files/ball.pyx"), include_dirs=[numpy.get_include()])
setup(ext_modules = cythonize("pyx_files/vec_math.pyx"), include_dirs=[numpy.get_include()])
setup(ext_modules = cythonize("pyx_files/box.pyx"), include_dirs=[numpy.get_include()])
setup(ext_modules = cythonize("pyx_files/obj_handler.pyx"), include_dirs=[numpy.get_include()])
setup(ext_modules = cythonize("pyx_files/material_class.pyx"), include_dirs=[numpy.get_include()])
setup(ext_modules = cythonize("pyx_files/poly_collider.pyx"), include_dirs=[numpy.get_include()])

