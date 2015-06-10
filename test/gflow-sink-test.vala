/* -*- Mode: vala; indent-tabs-mode: nil; c-basic-offset: 2; tab-width: 2 -*-  */
/* GFlowTest
 *
 * Copyright (C) 2015 Daniel Espinosa <esodan@gmail.com>
 *
 * librescl is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * librescl is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using GFlow;

public class GFlowTest.SinkTest
{
  public static void add_tests ()
  {
    Test.add_func ("/gflow/sink", 
    () => {
      Value initial = Value(typeof(int));
      initial.set_int (1);
      var s = new GFlow.SimpleSink (initial);
      assert (s.initial != null);
      assert (s.val != null);
      assert (s.val.holds (typeof(int)));
      assert (s.val.get_int () == 1);
      assert (s.val.type () == typeof (int));
      assert (!s.valid);
      assert (!s.highlight);
      assert (!s.active);
      assert (s.node == null);
      assert (s.source == null);
      assert (!s.is_connected ());
    });
  }
}
