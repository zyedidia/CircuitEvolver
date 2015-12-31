import std.stdio;
import std.conv;
import std.string: split, toLower;
import std.array: array;
import std.algorithm: canFind, countUntil, map;

import gate;

class Circuit {
    Gate[] gates;
    Gate[] inputGates;

    int[] outputNums;
    int fitness = 0;

    this() { }

    this(string definition, int numInputs) {
        string[] gatesStr = definition.split(" ");

        for (int i = 1; i <= numInputs; i++) {
            Gate g = new Gate();
            g.num = -i;
            inputGates ~= g;
        }

        for (int i = 0; i < gatesStr.length; i++) {
            string gateStr = gatesStr[i];
            Gate g = new Gate();
            g.num = i + 1;
            g.type = cast(bool) to!int(gateStr[0]);
            gateStr = gateStr[1..$];
            g.inputNums = gateStr.split(":").map!(to!int).array;

            gates ~= g;
        }

        foreach (Gate g; gates) {
            g.linkInputGates(inputGates, gates);
        }
    }

    void reset() {
        foreach (Gate g; inputGates) {
            g.reset();
        }
        foreach (Gate g; gates) {
            g.reset();
        }
    }

    Circuit dup() {
        Circuit c = new Circuit();
        c.outputNums = outputNums.dup();
        c.gates = new Gate[gates.length];
        c.inputGates = new Gate[inputGates.length];
        c.fitness = fitness;

        for (int i = 0; i < gates.length; i++) {
            c.gates[i] = gates[i].dup();
        }
        for (int i = 0; i < inputGates.length; i++) {
            c.inputGates[i] = inputGates[i].dup();
        }
        foreach (Gate g; c.gates) {
            g.linkInputGates(c.inputGates, c.gates);
        }
        return c;
    }

    void tick() {
        if (outputNums.length == 0) {
            writeln("Warning: no outputs");
        }
        foreach (Gate g; gates) {
            g.tick();
        }
        foreach (Gate g; gates) {
            g.updateOutput();
        }
        foreach (Gate g; inputGates) {
            g.updateOutput();
        }
    }

    void setInputs(byte[] inputs) {
        for (int i = 0; i < inputs.length; i++) {
            inputGates[i].newOutput = inputs[i];
        }
    }

    void setOutputs(int[] nums) {
        this.outputNums = nums;
    }

    void  addOutput(int num) {
        this.outputNums ~= num;
    }

    void setOutput(int index, int num) {
        this.outputNums[index] = num;
    }

    void writeSV(string circuitName) {
        string output = "";
        output ~= "module " ~ circuitName ~ "(\n";
        output ~= "Fitness: " ~ to!string(fitness);

        string outputGatesStr = "";
        for (int i = 1; i <= outputNums.length; i++) {
            outputGatesStr ~= "o" ~ to!string(i);
            if (i != outputNums.length) {
                outputGatesStr ~= ", ";
            }
        }

        output ~= "output logic " ~ outputGatesStr ~ ",\n";

        string inputGatesStr = "";
        for (int i = 1; i <= inputGates.length; i++) {
            inputGatesStr ~= "i" ~ to!string(i);
            if (i != inputGates.length) {
                inputGatesStr ~= ", ";
            }
        }

        output ~= "input logic " ~ inputGatesStr ~ "\n";
        output ~= ");\n";

        output ~= "parameter DELAY = 1;\n";
        output ~= "nand #DELAY ";

        for (int i = 0; i < gates.length; i++) {
            string gout = "f" ~ to!string(gates[i].num);
            if (outputNums.canFind(gates[i].num)) {
                gout = "o" ~ to!string(outputNums.countUntil(gates[i].num) + 1);
            }
            string inputs = "";
            for (int j = 0; j < gates[i].inputGates.length; j++) {
                Gate inputGate = gates[i].inputGates[j];
                if (inputGate.num < 0) {
                    inputs ~= "i" ~ to!string(abs(inputGate.num));
                } else if (outputNums.canFind(inputGate.num)) {
                    inputs ~= "o" ~ to!string(outputNums.countUntil(inputGate.num) + 1);
                } else {
                    inputs ~= "f" ~ to!string(inputGate.num);
                }
                if (j != gates[i].inputGates.length - 1) {
                    inputs ~= ", ";
                }
            }

            output ~= "g" ~ to!string(gates[i].num) ~ "(" ~ gout ~ ", " ~ inputs ~ ")";

            if (i == gates.length - 1) {
                output ~= ";\n";
            } else {
                output ~= ",\n";
            }
        }

        output ~= "endmodule: " ~ circuitName ~ "\n";

        File file = File(circuitName.toLower() ~ ".sv", "w");
        file.writeln(output);
        file.close();
    }

    string toStr() {
        string output = "";
        foreach (Gate g; gates) {
            output ~= to!string(g.type);
            for (int i = 0; i < g.inputGates.length; i++) {
                Gate input = g.inputGates[i];
                output ~= to!string(input.num);
                if (i != g.inputGates.length - 1) {
                    output ~= ":";
                }
            }
            output ~= " ";
        }
        return output;
    }
}
