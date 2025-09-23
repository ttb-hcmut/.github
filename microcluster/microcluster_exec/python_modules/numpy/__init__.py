from numpy.tinylinalg import LinAlgError as LinAlgError

def cross(u, v):
    """
    Return the cross product of two 2 or 3 dimensional vectors.
    """

    uDim = len(u)
    vDim = len(v)

    uxv = []

    # http://mathworld.wolfram.com/CrossProduct.html
    if uDim == vDim == 2:
        try:
            uxv = [u[0]*v[1]-u[1]*v[0]]            
        except LinAlgError as e:
            uxv = e        
    elif uDim == vDim == 3:
        try:
            for i in range(uDim):
                uxv = [u[1]*v[2]-u[2]*v[1], -(u[0]*v[2]-u[2]*v[0]),
                       u[0]*v[1]-u[1]*v[0]]
        except LinAlgError as e:
            uxv = e
    else:
        raise IndexError('Vector has invalid dimensions')
    return uxv

def add(ndarray_vec1, ndarray_vec2):
    c = []
    for a, b in zip(ndarray_vec1, ndarray_vec2):
        c.append(a+b)
    cRay = c
    return cRay
