from OpenGL.GL import *
from OpenGL.GL.shaders import compileProgram, compileShader
from OpenGL_accelerate import *
from PIL import Image
cimport numpy as np
import numpy as np


class Material:

    def __init__(self, filepath):
        self.texture = glGenTextures(1)
        glBindTexture(GL_TEXTURE_2D, self.texture)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

        image = Image.open(filepath)
        image_width, image_height = image.size
        image_data = image.tobytes()
        glTexImage2D(
            GL_TEXTURE_2D, 0, GL_RGB, image_width, image_height,
            0, GL_RGB, GL_UNSIGNED_BYTE, image_data
        )
        glGenerateMipmap(GL_TEXTURE_2D)

    def use(self):
        glActiveTexture(GL_TEXTURE0)
        glBindTexture(GL_TEXTURE_2D, self.texture)
        return

    def destroy(self):
        glDeleteTextures(1, (self.texture,))
        return