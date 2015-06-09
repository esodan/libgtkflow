/********************************************************************
# Copyright 2014 Daniel 'grindhold' Brendle, 2015 Daniel Espinosa <esodan@gmail.com>
#
# This file is part of libgtkflow.
#
# libgtkflow is free software: you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later
# version.
#
# libgtkflow is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with libgtkflow.
# If not, see http://www.gnu.org/licenses/.
*********************************************************************/

namespace GFlow {
    /**
     * A simple implementation of {@link GtkFlow.Source}.
     */
    public class SimpleSource : Object, Dock, Source {
        // Dock interface
        private GLib.Value _val;
        private GLib.Value _initial;
        private bool _valid = false;

        public string? name { get; set; }
        public bool highlight { get; set; }
        public bool active {get; set; default=false;}
        public weak Node? node { get; set; }
        public GLib.Value? val {
          get { return _val; }
          set {
            _val = value;
            changed ();
          }
        }
        public GLib.Value? initial { get { return _initial; } }
        public bool valid { get { return _valid; } }
        // Source interface
        private List<Sink> _sinks = new List<Sink> ();
        public List<Sink> sinks { get { return _sinks; } }
        // FIXME This should not be set by users is a mutter of test to know if source should work
        public new void set_valid() {
            this._valid = true;
        }
        /**
         * Returns true if this Source is connected to the given Sink
         */
        public bool is_connected_to (Dock dock) {
            if (!(dock is Sink)) return false;
            return this.sinks.index((Sink) dock) != -1;
        }

        /**
         * Returns true if this Source is connected to one or more Sinks
         */
        public bool is_connected() {
            return this.sinks.length() > 0;
        }
        // FIXME: Added to implement the one on Dock - Review
        public void invalidate () { _valid = false; }
    }
}
