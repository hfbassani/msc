# -*- coding=UTF-8 -*-

"""

File name : lhs.py

Creation date : 06-02-2016

Last modified :

Created by :

Purpose :

    Implements Latin Hypercube Sampling.

Usage :

    lhs(10, param_list)

    where 10 is the number of draws, param_list is a list of ml.Parameter
    instances. Returns a matrix with drawn values for each parameter

    eg.: 
    
    matrix = lhs(10, [a, b, c])

    where a, b and c are Parameter instances.


Observations :

    Must sample at least 10 values, i.e., n >= 10

"""

import numpy as np
#import Parameter

def lhs(n, param_list):

    # Array with all the draws
    draws = np.zeros((len(param_list), n))

    # All arguments in *argv are Parameters
    i = 0
    for arg in param_list:
        #assert(isinstance(arg,Parameter.Parameter) == True), 'Argument is not a \
        #Parameter instance'

        draws[i] = arg.sample(n)
        i += 1

    return draws
