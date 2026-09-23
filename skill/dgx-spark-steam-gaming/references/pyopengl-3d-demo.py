#!/usr/bin/env python3
"""DGX Spark GPU rendering validation — rotating colored cube (PyOpenGL)
Used to validate the full GPU -> Sunshine -> Moonlight pipeline, no Steam needed.
Dependencies: pygame, PyOpenGL (preinstalled on the DGX Spark)
Launch: DISPLAY=:0 python3 3d_test_game.py &
Press ESC to quit
"""
import pygame
from pygame.locals import *
from OpenGL.GL import *
from OpenGL.GLU import *

pygame.init()
pygame.display.set_mode((1280, 720), DOUBLEBUF | OPENGL)
pygame.display.set_caption('DGX Spark Game Test - 3D')

gluPerspective(45, 1280/720, 0.1, 50)
glTranslatef(0, 0, -5)
glEnable(GL_DEPTH_TEST)

clock = pygame.time.Clock()
running = True

while running:
    for e in pygame.event.get():
        if e.type == QUIT or (e.type == KEYDOWN and e.key == K_ESCAPE):
            running = False

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glRotatef(1, 1, 1, 0.5)  # rotate around the diagonal

    # 6-face colored cube
    glBegin(GL_QUADS)
    colors = [(1,0,0), (0,1,0), (0,0,1), (1,1,0), (1,0,1), (0,1,1)]
    vertices = [
        [( 1, 1,-1), ( 1,-1,-1), (-1,-1,-1), (-1, 1,-1)],  # front
        [( 1, 1, 1), (-1, 1, 1), (-1,-1, 1), ( 1,-1, 1)],  # back
        [( 1, 1, 1), ( 1, 1,-1), ( 1,-1,-1), ( 1,-1, 1)],  # right
        [(-1, 1,-1), (-1, 1, 1), (-1,-1, 1), (-1,-1,-1)],  # left
        [( 1, 1, 1), (-1, 1, 1), (-1, 1,-1), ( 1, 1,-1)],  # top
        [( 1,-1,-1), (-1,-1,-1), (-1,-1, 1), ( 1,-1, 1)],  # bottom
    ]
    for i, face in enumerate(vertices):
        glColor3f(*colors[i])
        for v in face:
            glVertex3f(*v)
    glEnd()

    pygame.display.flip()
    clock.tick(60)

pygame.quit()
