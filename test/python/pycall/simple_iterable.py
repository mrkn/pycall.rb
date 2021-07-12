class IntGenerator(object):
    def __init__(self, start, stop):
        self.start = start
        self.stop = stop
        self.current = None

    def __iter__(self):
        self.current = self.start
        return self

    def __next__(self):
        if self.current == self.stop:
            raise StopIteration()
        value = self.current
        self.current += 1
        return value

if __name__ == "__main__":
    print(list(IntGenerator(105, 115)))
