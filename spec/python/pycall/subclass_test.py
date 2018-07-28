class SuperClass(object):
    def __init__(self, *args):
        self.init_args = args

    def dbl(self, x):
        return 2 * x

def call_dbl(obj, x):
    return obj.dbl(x)
