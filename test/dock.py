#!/usr/bin/python3

import unittest

from gi.repository import GLib
from gi.repository import GtkFlow


class TestSinkSource(unittest.TestCase):
    """
    This test creates two docks with the same type (int) and connects them
    """
    def test_legit_connection(self):
        src = GtkFlow.Source.new(1)
        snk = GtkFlow.Sink.new(0)
        src.add_sink(snk)
        self.assertTrue(src.connected_to(snk))
        self.assertTrue(snk.connected_to(src))
        src.remove_sink(snk)
        self.assertFalse(src.connected_to(snk))
        self.assertFalse(snk.connected_to(src))

    """
    This test creates two docks with different types an connects them
    """
    def test_illegit_connection(self):
        with self.assertRaises(GLib.Error) as err:
            src = GtkFlow.Source.new("string")
            snk = GtkFlow.Sink.new(0)
            src.add_sink(snk)

    """
    Tests if a value-update gets transported from source to sink
    """
    def test_data_flow(self):
        src = GtkFlow.Source.new(1)
        snk = GtkFlow.Sink.new(0)
        src.add_sink(snk)
        self.assertTrue(src.connected_to(snk))
        self.assertTrue(snk.connected_to(src))
        snk.connect("changed", self.data_flow_callback)
        src.set_value(1337)
        self.assertEqual(snk.get_value(), 1337)

    def data_flow_callback(self, obj, val):
        self.assertEqual(val, 1337)

    """
    Tests that a source is invalid if not told otherwise
    """
    def test_invalid_source(self):
        src = GtkFlow.Source.new(1)
        snk = GtkFlow.Sink.new(0)
        src.add_sink(snk)
        with self.assertRaises(GLib.Error) as err:
            v = snk.get_value()
        src.set_value(0)
        v = snk.get_value()
        self.assertEqual(v, 0)
    
    """
    Tests that invalidating docks works
    """
    def test_invalidate_docks(self):
        src = GtkFlow.Source.new(2)
        sinks = [GtkFlow.Sink.new(0) for x in range(0,2)]
        for snk in sinks:
            src.add_sink(snk)
        src.set_value(1337)
        v = sinks[0].get_value()
        self.assertEqual(v,1337)
        src.invalidate()
        for snk in sinks:
            with self.assertRaises(GLib.Error) as err:
                v = snk.get_value()

