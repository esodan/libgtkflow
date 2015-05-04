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
