import random as pyrandom

def rand(dim1):
    row = []
    for j in range(dim1):
        row = row + [float("0." + str(pyrandom.getrandbits(32)))]
    return row
            
