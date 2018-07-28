class InitializeTest(object):
    def __init__(self, x):
        if not hasattr(self, 'values'):
            self.values = []
        self.values.append(x)

class NewOverrideTest(InitializeTest):
    def __new__(cls, x):
        obj = super().__new__(cls)
        obj.__init__(x)
        return obj
