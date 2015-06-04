#!/usr/bin/python3

from gi.repository import Gtk
from gi.repository import GtkFlow

import sys

class ConcatNode(GtkFlow.Node):
    def __init__(self):
        GtkFlow.Node.__init__(self)

        self.string_a = GtkFlow.Sink.new("")
        self.string_b = GtkFlow.Sink.new("")
        self.string_a.set_label("string A")
        self.string_b.set_label("string B")
        self.add_sink(self.string_a)
        self.add_sink(self.string_b)

        self.result = GtkFlow.Source.new("")
        self.result.set_label("output")
        self.add_source(self.result)

        self.string_a.connect("changed", self.do_concatenation)
        self.string_b.connect("changed", self.do_concatenation)
        self.set_title("Concatenation")

        self.set_border_width(10)
        self.set_show_types(True)

    def do_concatenation(self, dock, val=None):
        val_a = val_b = ""
        try:
            val_a = self.string_a.get_value()
        except:
            pass
        try:
            val_b = self.string_b.get_value()
        except:
            pass
        self.result.set_value(val_a+val_b)

class ConversionNode(GtkFlow.Node):
    def __init__(self):
        GtkFlow.Node.__init__(self)

        self.sink = GtkFlow.Sink.new(float(0))
        self.sink.set_label("input")
        self.add_sink(self.sink)

        self.source = GtkFlow.Source.new("")
        self.source.set_label("output")
        self.add_source(self.source)

        self.sink.connect("changed", self.do_conversion)
        self.set_title("Number2String")
        self.set_border_width(10)
        self.set_show_types(True)

    def do_conversion(self, dock, val=None):
        try:
            v = self.sink.get_value()
            self.source.set_value(str(v))
        except:
            self.source.invalidate()

class StringNode(GtkFlow.Node):
    def __init__(self):
        GtkFlow.Node.__init__(self)
        
        self.source = GtkFlow.Source.new("")
        self.source.set_label("output")
        self.source.set_valid()
        self.add_source(self.source)

        self.entry = Gtk.Entry()
        self.add(self.entry)
        self.entry.connect("changed", self.do_changed)
        self.show_all()

        self.set_title("String")
        self.set_border_width(10)
        self.set_show_types(True)

    def do_changed(self, widget=None, data=None):
        self.source.set_value(self.entry.get_text())

class OperationNode(GtkFlow.Node):
    def __init__(self):
        GtkFlow.Node.__init__(self)
        self.set_show_types(True)
       
        self.summand_a = GtkFlow.Sink.new(float(0))
        self.summand_b = GtkFlow.Sink.new(float(0))
        self.summand_a.set_label("operand A")
        self.summand_b.set_label("operand B")
        self.add_sink(self.summand_a)
        self.add_sink(self.summand_b)    
    
        self.result = GtkFlow.Source.new(float(0))
        self.result.set_label("result")
        self.add_source(self.result)

        self.operations = Gtk.ListStore(str)
        self.operations.append(("+",))
        self.operations.append(("-",))
        self.operations.append(("*",))
        self.operations.append(("/",))

        operations = ["+", "-", "*", "/"]
        self.combobox = Gtk.ComboBoxText()
        self.combobox.connect("changed", self.do_calculations)
        self.combobox.set_entry_text_column(0)
        for op in operations:
            self.combobox.append_text(op)
        self.add(self.combobox)
        self.show_all()

        self.summand_a.connect("changed", self.do_calculations)
        self.summand_b.connect("changed", self.do_calculations)

        self.set_title("Operation")
    
        self.set_border_width(10)

    def do_calculations(self, dock, val=None):
        op = self.combobox.get_active_text() 
        
        try:
            val_a = self.summand_a.get_value()
            val_b = self.summand_b.get_value()
        except:
            self.result.invalidate()
            return
    
        if op == "+":
            self.result.set_value(val_a+val_b)
        elif op == "-":
            self.result.set_value(val_a-val_b)
        elif op == "*":
            self.result.set_value(val_a*val_b)
        elif op == "/":
            self.result.set_value(val_a/val_b)
        else:
            self.result.invalidate()

class NumberNode(GtkFlow.Node):
    def __init__(self, number=0):
        GtkFlow.Node.__init__(self)
        self.set_show_types(True)
        self.number = GtkFlow.Source.new(float(number))
        self.number.set_label("output")
        self.number.set_valid()
        self.add_source(self.number)
        
        adjustment = Gtk.Adjustment(0, 0, 100, 1, 10, 0)
        self.spinbutton = Gtk.SpinButton()
        self.spinbutton.set_adjustment(adjustment)
        self.spinbutton.set_size_request(50,20)
        self.spinbutton.connect("value_changed", self.do_value_changed)
        self.add(self.spinbutton)
        self.show_all()

        self.set_title("NumberGenerator")

        self.set_border_width(10)

    def do_value_changed(self, widget=None, data=None):
        self.number.set_value(float(self.spinbutton.get_value()))

class PrintNode(GtkFlow.Node):
    def __init__(self):
        GtkFlow.Node.__init__(self)
        self.set_show_types(True)
        self.sink = GtkFlow.Sink.new("")
        self.sink.set_label("")
        self.sink.connect("changed", self.do_printing)
        self.add_sink(self.sink)

        self.childlabel = Gtk.Label()
        self.add(self.childlabel)
        self.show_all()

        self.set_title("Output")

        self.set_border_width(10)

    def do_printing(self, dock, val):
        try:
            v = self.sink.get_value()
            self.childlabel.set_text(v)
        except:
            self.childlabel.set_text("")
        
class TypesExampleApplication(object):
    def __init__(self):
        w = Gtk.Window.new(Gtk.WindowType.TOPLEVEL)
        self.nv = GtkFlow.NodeView.new()

        hbox = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
        create_numbernode_button = Gtk.Button("Create NumberNode")
        create_numbernode_button.connect("clicked", self.do_create_numbernode)
        hbox.add(create_numbernode_button)
        create_addnode_button = Gtk.Button("Create OperationNode")
        create_addnode_button.connect("clicked", self.do_create_addnode)
        hbox.add(create_addnode_button)
        create_printnode_button = Gtk.Button("Create PrintNode")
        create_printnode_button.connect("clicked", self.do_create_printnode)
        hbox.add(create_printnode_button)
        create_concatnode_button = Gtk.Button("Create ConcatenationNode")
        create_concatnode_button.connect("clicked", self.do_create_concatnode)
        hbox.add(create_concatnode_button)
        create_stringnode_button = Gtk.Button("Create StringNode")
        create_stringnode_button.connect("clicked", self.do_create_stringnode)
        hbox.add(create_stringnode_button)
        create_conversionnode_button = Gtk.Button("Create ConversionNode")
        create_conversionnode_button.connect("clicked", self.do_create_conversionnode)
        hbox.add(create_conversionnode_button)

        vbox = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
        vbox.pack_start(hbox, False, False, 0)
        vbox.pack_start(self.nv, True, True, 0)
 
        w.add(vbox)
        w.add(self.nv)
        w.show_all()       
        w.connect("destroy", self.do_quit)
        Gtk.main()

    def do_create_addnode(self, widget=None, data=None):
        self.nv.add(OperationNode())
    def do_create_numbernode(self, widget=None, data=None):
        self.nv.add(NumberNode())
    def do_create_printnode(self, widget=None, data=None):
        self.nv.add(PrintNode())
    def do_create_concatnode(self, widget=None, data=None):
        self.nv.add(ConcatNode())
    def do_create_stringnode(self, widget=None, data=None):
        self.nv.add(StringNode())
    def do_create_conversionnode(self, widget=None, data=None):
        self.nv.add(ConversionNode())
    def do_quit(self, widget=None, data=None):
        Gtk.main_quit()
        sys.exit(0)

if __name__ == "__main__":
    TypesExampleApplication()
