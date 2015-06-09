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
     * A simple implementation of {@link GtkFlow.Sink}.
     */
    public class SimpleSink : Object, Dock, Sink {
        // Dock interface
        private GLib.Value _val;
        private GLib.Value _initial;

        public string? name { get; set; }
        public bool highlight { get; set; }
        public bool active {get; set; default=false;}
        public weak Node? node { get; set; };
        public GLib.Value val { get { return _val; } };
        public GLib.Value initial { get { return _initial; } };
        public bool is_valid { get; };
        // Sink Interface
        private weak Source? _source;
        public weak Source? source {
            get{
                return this._source;
            }
        }

        public Sink(GLib.Value initial) {
            base(initial);
        }

        /**
         * Returns true if this Sink is connected to the given Source
         */
        public bool is_connected_to (Source s) {
            return this.source == s;
        }

        /**
         * Returns true if this sink is connected to a source
         */
        public bool is_connected() {
            return this.source != null;
        }

        public override void invalidate () {
            this.valid = false;
            this.changed(this.initial);
        }
        // FIXME This oeverrides Dock.changed signals and set a value but this should not be the case
        // FIXME when change_value is callled it sets its value and send this signal
/*        public virtual signal void changed (GLib.Value v) {
            this.val = v;
        }*/

    }
}
