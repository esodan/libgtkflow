#!/usr/bin/python3

import unittest

from gi.repository import GLib
from gi.repository import GtkFlow


class TestSinkSource(unittest.TestCase):
    """
    This test creates two docks with the same type (int) and connects them
    """
    def test_valid_connection(self):
        src = GtkFlow.Source.new(1)
        snk = GtkFlow.Sink.new(0)
        src.add_sink(snk)
        self.assertTrue(src.connected_to(snk))
        self.assertTrue(snk.connected_to(src))

    """
    This test creates two docks with different types an connects them
    """
    def test_invalid_connection(self):
        with self.assertRaises(GLib.Error) as err:
            src = GtkFlow.Source.new("string")
            snk = GtkFlow.Sink.new(0)
            src.add_sink(snk)

    def data_flow_callback(self, obj, val):
        self.assertEqual(val, 1337)

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
