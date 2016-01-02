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

void randomMutation(Circuit c, int minGates, int maxGates) {
    bool changeOutput = uniform(0.0f, 1.0f) > 0.75;
    if (changeOutput) {
        for (int i = 0; i < c.outputNums.length; i++) {
            c.setOutput(i, cast(int) uniform(1, c.gates.length + 1));
        }
    } else {
        int[] possibleInputGateNums;
        foreach (Gate g; c.gates) {
            possibleInputGateNums ~= g.num;
        }
        foreach (Gate g; c.inputGates) {
            possibleInputGateNums ~= g.num;
        }

        float mutationChoice = uniform(0.0f, 1.0f);
        if (mutationChoice < 0.33f && c.gates.length > minGates) {
            // Delete a gate
            Gate destroy = c.gates[uniform(0, c.gates.length)];
            c.gates = c.gates.remove(destroy.num - 1);
            for (int i = 0; i < c.gates.length; i++) {
                Gate g = c.gates[i];
                g.num = i + 1;
                int index = -1;
                for (int j = 0; j < g.inputNums.length; j++) {
                    int n = g.inputNums[j];
                    if (n > destroy.num) {
                        g.inputNums[j] = n - 1;
                    } else if (n == destroy.num) {
                        index = j;
                    }
                }
                if (index != -1) {
                    g.inputNums = g.inputNums.remove(index);
                }
                g.linkInputGates(c.inputGates, c.gates);
            }
            int index = -1;
            for (int i = 0; i < c.outputNums.length; i++) {
                if (c.outputNums[i] > destroy.num) {
                    c.outputNums[i]--;
                } else if (c.outputNums[i] == destroy.num) {
                    index = i;
                }
            }
            if (index != -1) {
                c.setOutput(index, cast(int) uniform(1, c.gates.length + 1));
            }
        } else if (mutationChoice < 0.66f && c.gates.length < maxGates) {
            // Add a gate
            Gate g = new Gate();
            g.inputNums = chooseRandom(possibleInputGateNums);
            g.linkInputGates(c.inputGates, c.gates);
            c.gates ~= g;
            g.num = cast(int) c.gates.countUntil(g);
        } else {
            // Change a gate's inputs
            Gate g = c.gates[uniform(0, c.gates.length)];
            g.inputNums = chooseRandom(possibleInputGateNums);
            g.linkInputGates(c.inputGates, c.gates);
        }

        /* Gate g = c.gates[uniform(0, c.gates.length)]; */
        /* bool largeMutation = uniform(0.0f, 1.0f) >= 0.0; */
        /* if (largeMutation) { */
        /* } else { */
        /* } */
    }
}

class Evolver {
    byte[][] inputs;
    byte[][] correctOutputs;

    Circuit[] population;
    Circuit bestCircuit;

    int generations = 0;
    int popSize = 1000;

    int minGates;
    int maxGates;

    void createPopulation(int minGates, int maxGates, int numInputs, int numOutputs) {
        this.minGates = minGates;
        this.maxGates = maxGates;
        for (int i = 0; i < popSize; i++) {
            population ~= randomCircuit(minGates, maxGates+1, numInputs, numOutputs);
        }
    }

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
            randomMutation(population[i], minGates, maxGates);
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
    e.createPopulation(4, 4, 2, 1);

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


    int i = 0;
    while (true) {
        e.advanceGen(true);
        e.bestCircuit.writeSV("Cmod");
        i++;
    }
}
