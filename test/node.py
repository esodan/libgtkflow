#!/usr/bin/python3

import unittest

from gi.repository import GLib
from gi.repository import GtkFlow

class AddNode(GtkFlow.Node):
    def __init__(self):
        GtkFlow.Node.__init__(self)
        self.num_1 = GtkFlow.Sink.new(0)
        self.num_2 = GtkFlow.Sink.new(0)
        self.result = GtkFlow.Source.new(0)

        self.add_sink(self.num_1)
        self.add_sink(self.num_2)
        self.add_source(self.result)

        self.num_1.connect("changed", self.recalculate_result)
        self.num_2.connect("changed", self.recalculate_result)

    def recalculate_result(self, source, new_value):
        try:
            self.result.set_value(self.num_1.get_value() + self.num_2.get_value())
        except GLib.Error:
            print("Konnte noch keinen scheiss berechnen")

class PrintNumberNode(GtkFlow.Node):
    def __init__(self):
        GtkFlow.Node.__init__(self)
        self.input_value = GtkFlow.Sink.new(0)

        self.add_sink(self.input_value)

        self.input_value.connect("changed", self.print_input)

    def print_input(self, source, value):
        print(value)

class NumberGeneratorNode(GtkFlow.Node):
    def __init__(self, x):
        GtkFlow.Node.__init__(self)
        self.output_value = GtkFlow.Source.new(x)
        self.add_source(self.output_value)
        self.current_value = x

    def incr(self):
        self.current_value +=1
        self.output_value.set_value(self.current_value)
        
    def decr(self):
        self.current_value -=1
        self.output_value.set_value(self.current_value)

