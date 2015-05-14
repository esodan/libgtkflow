#!/usr/bin/python3

from gi.repository import Gtk
from gi.repository import GtkFlow

import sys

class AddNode(GtkFlow.Node):
    def __init__(self):
        GtkFlow.Node.__init__(self)
        
        self.summand_a = GtkFlow.Sink.new(0)
        self.summand_b = GtkFlow.Sink.new(0)
        self.summand_a.set_label("summand A")
        self.summand_b.set_label("summand B")
        self.add_sink(self.summand_a)
        self.add_sink(self.summand_b)    
    
        self.result = GtkFlow.Source.new(0)
        self.result.set_label("result")
        self.add_source(self.result)

        self.summand_a.connect("changed", self.do_calculations)
        self.summand_b.connect("changed", self.do_calculations)
    
        self.set_border_width(10)

    def do_calculations(self, dock, val):
        print ("doing calculations")
        
        val_a = self.summand_a.val
        val_b = self.summand_b.val    
    
        self.result.set_value(val_a+val_b)

class NumberNode(GtkFlow.Node):
    def __init__(self, number=0):
        GtkFlow.Node.__init__(self)
        self.number = GtkFlow.Source.new(number)
        self.number.set_label("number %d"%number)
        self.add_source(self.number)
        self.set_border_width(10)

class PrintNode(GtkFlow.Node):
    def __init__(self):
        GtkFlow.Node.__init__(self)
        self.number = GtkFlow.Sink.new(0)
        self.number.set_label("")
        self.number.connect("changed", self.do_printing)
        self.add_sink(self.number)
        self.set_border_width(10)

    def do_printing(self, dock, val):
        self.number.set_label(str(self.number.val))
        print (self.number.val)
        
class Calculator(object):
    def __init__(self):
        w = Gtk.Window.new(Gtk.WindowType.TOPLEVEL)
        self.nv = GtkFlow.NodeView.new()

        hbox = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
        adjustment = Gtk.Adjustment(0, 0, 100, 1, 10, 0)
        self.spinbutton = Gtk.SpinButton()
        self.spinbutton.set_adjustment(adjustment)
        hbox.add(self.spinbutton)
        create_numbernode_button = Gtk.Button("Create NumberNode")
        create_numbernode_button.connect("clicked", self.do_create_numbernode)
        hbox.add(create_numbernode_button)
        create_addnode_button = Gtk.Button("Create AddNode")
        create_addnode_button.connect("clicked", self.do_create_addnode)
        hbox.add(create_addnode_button)
        create_printnode_button = Gtk.Button("Create PrintNode")
        create_printnode_button.connect("clicked", self.do_create_printnode)
        hbox.add(create_printnode_button)

        vbox = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
        vbox.pack_start(hbox, False, False, 0)
        vbox.pack_start(self.nv, True, True, 0)
 
        w.add(vbox)
        w.add(self.nv)
        w.show_all()       
        w.connect("destroy", self.do_quit)
        Gtk.main()

    def do_create_addnode(self, widget=None, data=None):
        self.nv.add_node(AddNode())
    def do_create_numbernode(self, widget=None, data=None):
        num = self.spinbutton.get_value_as_int()
        self.nv.add_node(NumberNode(num))
    def do_create_printnode(self, widget=None, data=None):
        self.nv.add_node(PrintNode())
    def do_quit(self, widget=None, data=None):
        Gtk.main_quit()
        sys.exit(0)

if __name__ == "__main__":
    Calculator()
