from kea import *

class Test(KeaTest):
    @precondition(lambda _: False)
    @rule()
    def fake():
        pass