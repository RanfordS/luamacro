LMC := lua luamacro.lua

all: examples/c_result.c examples/py_result.py

examples/c_result.c: examples/c_sample.lmc
	$(LMC) examples/c_sample.lmc examples/c_result.c

examples/py_result.py: examples/py_sample.lmpy
	$(LMC) examples/py_sample.lmpy examples/py_result.py
