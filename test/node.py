#!/usr/bin/python3

import unittest

from gi.repository import GLib
from gi.repository import GtkFlow

"""
Contains tests that can only be done with nodes in the game
"""
class TestNode(unittest.TestCase):
    """
    Test Recursion
    """
    def test_recursion(self):
        node1 = GtkFlow.Node.new()
        node1_src = GtkFlow.Source.new(0)
        node1_snk = GtkFlow.Sink.new(0)
        node2 = GtkFlow.Node.new()
        node2_src = GtkFlow.Source.new(0)
        node2_snk = GtkFlow.Sink.new(0)
        node1_src.add_sink(node2_snk)
        self.assertTrue(node1_src.connected_to(node2_snk))
        with self.assertRaises(GLib.Error) as err:
            node2_src.add_sink(node1_snk)
        self.assertFalse(node2_src.connected_to(node1_snk))

        node1_src.remove_sink(node2_snk)
        self.assertFalse(node1_src.connected_to(node2_snk))
        node2_src.add_sink(node1_snk)
        self.assertTrue(node2_src.connected_to(node1_snk))
        


