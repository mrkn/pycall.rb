class SimpleClass:
    class NestedClass:
        pass

    def __init__(self, x=0):
        self.x = x

    def initialize(self, x):
        self.x = x
        return 'initialized'

class SimpleSubClass(SimpleClass):
    pass
