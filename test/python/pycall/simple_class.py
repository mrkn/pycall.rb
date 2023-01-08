class SimpleClass(object):
    class NestedClass:
        pass

    def __init__(self, x=0):
        self.x = x

    def initialize(self, x):
        self.x = x
        return 'initialized'

    def __neg__(self):
        return "-{}".format(self.x)

    def __pos__(self):
        return "+{}".format(self.x)

    def __invert__(self):
        return "~{}".format(self.x)

class SimpleSubClass(SimpleClass):
    pass
