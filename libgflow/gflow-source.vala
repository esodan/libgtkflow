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
     * The Source is a special Type of Dock that provides data.
     * A Source could be used by multitude of Sinks as a source of data. // FIXME Is this correct?
     */
    public interface Source : Object, Dock {
        public signal void updated ();
        /**
        * FIXME This should be read-only (when you get it from here this could be modified by user)
        * FIXME May be the way to make sinks read-only is to return an owned copy of it to avoid writes on lists
         * Returns the sinks that this source is connected to
         */
        public abstract List<Sink> sinks { get; }

        public virtual void disconnect_all () throws GLib.Error
        {
            foreach (Sink s in this.sinks)
                this.disconnect (s);
        }
    }
}
