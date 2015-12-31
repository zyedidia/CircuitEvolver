import std.stdio;
import std.random;
import std.conv;
import std.algorithm;
import std.string;

import gate;
import circuit;
import simulator;

enum TICK_COUNT = 10; // Number of ticks before changing the inputs when testing

T[] chooseRandom(T)(T[] arr) {
    auto numValues = uniform(1, arr.length);
    T[] ans;
    for (int i = 0; i < numValues; i++) {
        auto chosen = arr[uniform(0, arr.length)];
        if (!ans.canFind(chosen)) {
            ans ~= chosen;
        } else {
            i--;
        }
    }
    return ans;
}

Circuit randomCircuit(int minGates, int maxGates, int numInputs, int numOutputs) {
    Circuit c = new Circuit();

    for (int i = 1; i <= numInputs; i++) {
        Gate g = new Gate();
        g.num = -i;
        c.inputGates ~= g;
    }

    int numGates = uniform(minGates, maxGates);
    for (int i = 1; i <= numGates; i++) {
        Gate g = new Gate();
        g.num = i;
        c.gates ~= g;
    }

    int[] possibleInputGateNums;
    foreach (Gate g; c.gates) {
        possibleInputGateNums ~= g.num;
    }
    foreach (Gate g; c.inputGates) {
        possibleInputGateNums ~= g.num;
    }

    foreach (Gate g; c.gates) {
        g.inputNums = chooseRandom(possibleInputGateNums);
        g.linkInputGates(c.inputGates, c.gates);
    }

    for (int i = 0; i < numOutputs; i++) {
        c.addOutput(uniform(1, numGates + 1));
    }

    return c;
}

void randomMutation(Circuit c) {
    bool changeOutput = uniform(0.0f, 1.0f) > 0.75;
    if (changeOutput) {
        for (int i = 0; i < c.outputNums.length; i++) {
            c.setOutput(i, uniform(1, cast(int) c.gates.length + 1));
        }
    } else {
        int[] possibleInputGateNums;
        foreach (Gate g; c.gates) {
            possibleInputGateNums ~= g.num;
        }
        foreach (Gate g; c.inputGates) {
            possibleInputGateNums ~= g.num;
        }

        Gate g = c.gates[uniform(0, c.gates.length)];
        bool largeMutation = uniform(0.0f, 1.0f) >= 0.0;
        if (largeMutation) {
            g.inputNums = chooseRandom(possibleInputGateNums);
        } else {
            /* float mutationChoice = uniform(0.0f, 1.0f); */
            /* if (mutationChoice < 0.33f && g.inputGates.length > 1) { */
            /*     // Delete an input */
            /*     g.inputNums = g.inputNums.remove(uniform(0, g.inputGates.length)); */
            /* } else if (mutationChoice < 0.66f && g.inputGates.length < (c.inputGates.length + c.gates.length)) { */
            /*     // Add an input */
            /*     g.inputNums ~= possibleInputGateNums[uniform(0, possibleInputGateNums.length)]; */
            /* } else { */
            /*     // Change an input */
            /*     g.inputNums[uniform(0, g.inputNums.length)] = possibleInputGateNums[uniform(0, possibleInputGateNums.length)]; */
            /* } */
        }
        g.linkInputGates(c.inputGates, c.gates);
    }
}

class Evolver {
    byte[][] inputs;
    byte[][] correctOutputs;

    Circuit[] population;

    int generations = 0;

    int popSize = 1000;

    Circuit bestCircuit;

    void advanceGen(bool debugPrint = false) {
        foreach (Circuit c; population) {
            calculateFitness(c);
            c.reset();
        }

        population = sort!("a.fitness > b.fitness")(population).array;

        Circuit[] newPopulation;

        bestCircuit = population[0].dup();
        for (int i = 0; i < population.length / 2; i++) {
            newPopulation ~= population[i].dup();
            randomMutation(population[i]);
            newPopulation ~= population[i].dup();
        }
        if (debugPrint) {
            writeln(generations, ": ", bestCircuit.fitness);
            bestCircuit.writeSV("Cmod");
        }
        population = newPopulation.dup();

        generations++;
    }

    // Calculate the fitness for a given circuit
    int calculateFitness(Circuit c, bool debugPrint = false) {
        int fitness = 0;

        foreach (Gate g; c.gates) {
            fitness -= g.inputGates.length;
        }

        // Loop through this evolver's inputs
        for (int i = 0; i < inputs.length; i++) {
            c.setInputs(inputs[i]);

            for (int j = 0; j < TICK_COUNT; j++) {
                c.tick();

                // Check if it got the right output
                bool pass = true;
                for (int k = 0; k < correctOutputs[i].length; k++) {
                    if (correctOutputs[i][k] != c.gates[c.outputNums[k] - 1].output) {
                        pass = false;
                    }
                }
                if (pass) { fitness += 1; }
                else { fitness -= 0; }

                if (debugPrint) {
                    writef("%2d: ", i * 10 + j);
                    foreach (Gate g; c.inputGates) {
                        write(g.output, " ");
                    }
                    foreach (Gate g; c.gates) {
                        write(g.output, " ");
                    }
                    if (pass) {
                        write("✓ ", fitness);
                    } else {
                        write("✗ ", fitness);
                    }
                    write(" ", correctOutputs[i][0], " ", c.gates[c.outputNums[0] - 1].output);
                    writeln();
                }
            }
        }
        c.fitness = fitness;
        if (debugPrint) {
            writeln(c.toStr());
            writeln(c.outputNums);
            writeln(fitness);
        }

        return fitness;
    }
}

void main(string[] args) {
    Evolver e = new Evolver();

    File file = File(args[1], "r");

    byte[][][] inputs = [[]];
    byte[][][] outputs = [[]];

    int environments = 0;
    while (!file.eof()) {
        string line = strip(file.readln());
        if (line != "") {
            if (line == "---") {
                environments++;
                inputs ~= [[]];
                outputs ~= [[]];
            } else {
                string[] lineSplit = line.split(" -> ");
                inputs[environments] ~= lineSplit[0].split(" ").map!(to!byte).array;
                outputs[environments] ~= lineSplit[1].split(" ").map!(to!byte).array;
            }
        }
    }

    Circuit c = new Circuit("14:-1 1-1:-2 1-2:4 11:2:3", 2);
    c.addOutput(4);
    e.inputs = inputs[0];
    e.correctOutputs = outputs[0];
    writeln("TARGET FITNESS ", e.calculateFitness(c));

    for (int i = 0; i < e.popSize; i++) {
        e.population ~= randomCircuit(4, 5, 2, 1);
    }

    int i = 0;
    while (true) {
        if (i % 50 == 0) {
            /* c.reset(); */
            /* for (int j = cast(int) e.population.length / 2; j < e.population.length; j++) { */
            /*     e.population[j] = randomCircuit(4, 5, 2, 1); */
            /* } */
            /* e.inputs = inputs[(i/50) % inputs.length]; */
            /* e.correctOutputs = outputs[(i/50) % outputs.length]; */
            /* writeln("TARGET FITNESS ", e.calculateFitness(c)); */
        }
        e.advanceGen(i % 10 == 0);
        if (i % 100 == 0) {
            e.bestCircuit.writeSV("Cmod");
        }
        i++;
    }
}
