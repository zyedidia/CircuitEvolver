import std.stdio;
import std.algorithm: canFind;

import circuit;
import gate;

enum NAND = 1;
enum NOR = 0;

byte nand(byte[] inputs) {
    if (inputs.canFind(2) && !inputs.canFind(0)) {
        return 2;
    }
    byte result = inputs[0];

    foreach (byte input; inputs) {
        result = result && input;
    }

    return !result;
}

byte nor(byte[] inputs) {
    if (inputs.canFind(2) && !inputs.canFind(1)) {
        return 2;
    }
    byte result = inputs[0];

    foreach (byte input; inputs) {
        result = result || input;
    }

    return !result;
}

/* void main() { */
/*     Circuit c = new Circuit("14:-1 1-1:-2 1-2:4 11:2:3", 2); */
/*     c.setOutput(4); */
/*  */
/*     c.setInputs([1, 1]); */
/*     for (int i = 0; i <= 60; i++) { */
/*         if (i == 10) { c.setInputs([0, 1]); } */
/*         if (i == 20) { c.setInputs([1, 0]); } */
/*         if (i == 30) { c.setInputs([0, 0]); } */
/*         if (i == 40) { c.setInputs([1, 0]); } */
/*         if (i == 50) { c.setInputs([0, 1]); } */
/*         writef("%2d: ", i); */
/*         c.tick(); */
/*         foreach (Gate g; c.inputGates) { */
/*             write(g.output, " "); */
/*         } */
/*         foreach (Gate g; c.gates) { */
/*             write(g.output, " "); */
/*         } */
/*         writeln(); */
/*     } */
/*  */
/*     c.writeSV("Cmod"); */
/* } */
