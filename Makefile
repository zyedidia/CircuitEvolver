.PHONY: evolver simulator verilog clean

evolver:
	dmd -O evolver.d simulator.d circuit.d gate.d

simulator:
	dmd simulator.d circuit.d gate.d
	@rm simulator.o

verilog:
	iverilog -g2012 cmod.sv cmod_tb.sv

clean:
	@rm -f *.o
	@rm -f a.out
	@rm -f simulator
	@rm -f evolver
