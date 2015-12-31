import std.conv;
import std.math: abs;

import simulator;
import circuit;

class Gate {
    int num;
    byte type = 1;

    int[] inputNums;
    Gate[] inputGates;
    byte output = 2;
    byte newOutput = 2;

    void linkInputGates(Gate[] circuitInputGates, Gate[] circuitGates) {
        this.inputGates = [];
        foreach (int inputNum; inputNums) {
            if (inputNum < 0) {
                addInput(circuitInputGates[abs(inputNum)-1]);
            } else {
                addInput(circuitGates[inputNum - 1]);
            }
        }
    }

    Gate dup() {
        Gate g = new Gate();
        g.num = num;
        g.type = type;
        g.inputNums = inputNums.dup();
        g.output = output;
        g.newOutput = newOutput;

        return g;
    }

    void reset() {
        newOutput = 2;
        output = 2;
    }

    byte tick() {
        byte[] inputs = new byte[inputGates.length];
        for (int i = 0; i < inputGates.length; i++) {
            inputs[i] = inputGates[i].output;
        }
        if (type == NAND) {
            newOutput = nand(inputs);
        } else {
            newOutput = nor(inputs);
        }
        return newOutput;
    }

    void updateOutput() {
        output = newOutput;
    }

    void addInput(Gate i) {
        inputGates ~= i;
    }
}
