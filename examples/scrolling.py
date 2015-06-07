#!/usr/bin/python3

from gi.repository import Gtk
from gi.repository import GtkFlow

import sys

class OperationNode(GtkFlow.Node):
    def __init__(self):
        GtkFlow.Node.__init__(self)
       
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
        self.number = GtkFlow.Source.new(float(number))
        self.number.set_valid()
        self.number.set_label("output")
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
        self.number = GtkFlow.Sink.new(float(0))
        self.number.set_label("")
        self.number.connect("changed", self.do_printing)
        self.add_sink(self.number)

        self.childlabel = Gtk.Label()
        self.add(self.childlabel)
        self.show_all()

        self.set_title("Output")

        self.set_border_width(10)

    def do_printing(self, dock, val):
        try:
            n = self.number.get_value()
            print (n)
            self.childlabel.set_text(str(n))
        except:
            self.childlabel.set_text("")
        
class Calculator(object):
    def __init__(self):
        w = Gtk.Window.new(Gtk.WindowType.TOPLEVEL)
        self.nv = GtkFlow.NodeView.new()
        self.sw = Gtk.ScrolledWindow()

        hbox = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
        create_numbernode_button = Gtk.Button("Create NumberNode")
        create_numbernode_button.connect("clicked", self.do_create_numbernode)
        hbox.add(create_numbernode_button)
        create_addnode_button = Gtk.Button("Create OperationNode")
        create_addnode_button.connect("clicked", self.do_create_addnode)
        hbox.add(create_addnode_button)
        create_printnode_button = Gtk.Button("Create PrintNode")
        create_printnode_button.connect("clicked", self.do_create_printnode)
        hbox.add(create_printnode_button)

        self.sw.add(self.nv)
        vbox = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
        vbox.pack_start(hbox, False, False, 0)
        vbox.pack_start(self.sw, True, True, 0)
 
        w.add(vbox)
        w.show_all()       
        w.connect("destroy", self.do_quit)
        Gtk.main()

    def do_create_addnode(self, widget=None, data=None):
        self.nv.add(OperationNode())
    def do_create_numbernode(self, widget=None, data=None):
        self.nv.add(NumberNode())
    def do_create_printnode(self, widget=None, data=None):
        self.nv.add(PrintNode())
    def do_quit(self, widget=None, data=None):
        Gtk.main_quit()
        sys.exit(0)

if __name__ == "__main__":
    Calculator()
