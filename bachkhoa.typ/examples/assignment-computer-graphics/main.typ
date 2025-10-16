#import "/bachkhoa.typ/template.typ": *

#show: doc.with(
	department: [Computer Science Department]
)

#cover(
	[Assignments — Computer Graphics],
	instructor: [Dr. Gia-Bao NGUYEN],
	version: "v1.0",
	department: [Department of Computer
	Science],
	date: datetime.today()
)

== Version History

== Introduction

This assignment set is designed to help
students gain practical experience in
modern computer graphics programming.
Across both assignments, students will
learn how to create and render
geometric scenes using OpenGL or
equivalent libraries across different
platforms. The emphasis is on
understanding and using programmable
graphics pipelines with custom shaders
written in GLSL (OpenGL Shading
Language), rather than relying on
outdated fixed-function techniques.

Depending on their preferred
programming language or development
environment, students may choose from a
variety of rendering APIs:

- #[*OpenGL (C++)*: The standard
cross-platform graphics API. Students
are expected to use shader-based
rendering with libraries such as
`GLFW`, `GLEW`, or `GLM`.]
- #[*PyOpenGL (Python)*: A Python
binding for OpenGL that supports modern
graphics programming. Often used with
`GLFW`, `PyGLM`, or `ModernGL`.]
- #[*WebGL (JavaScript)*: A web-based
version of OpenGL ES 2.0 with shader
support. Common frameworks include
`Three.js` and `Babylon.js`.]

By completing the two assignments, students will explore various core topics in computer graphics, including transformation matrices, 3D geometry rendering, lighting, and syntehtic data generation for downstream computer vision tasks.
