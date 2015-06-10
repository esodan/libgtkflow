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

public class GFlowTest.Source : GFlow.SimpleSource
{
  public void update ()
  {
    if (_val.get_boolean ()) _val.set_boolean (false);
    else _val.set_boolean (true);
  }
  public Source () {
    Value v = false;
    base (v);
  }
}

public class GFlowTest.SourceTest
{
  public static void add_tests ()
  {
    Test.add_func ("/gflow/source", 
    () => {
      Value initial = Value(typeof(int));
      initial.set_int (1);
      var src = new GFlow.SimpleSource (initial);
      assert (src.initial != null);
      assert (src.val != null);
      assert (src.val.holds (typeof (int)));
      assert (src.val.get_int () == 1);
      assert (!src.is_connected ());
      src.val.set_int (10);
      assert (src.val.get_int () == 10);
      src.val = 0.10;
      assert (src.val.get_int () == 10);
    });
    Test.add_func ("/gflow/source/derived", 
    () => {
      var src = new GFlowTest.Source ();
      assert (src.initial != null);
      assert (src.val != null);
      assert (src.val.holds (typeof (bool)));
      assert (!src.val.get_boolean ());
      src.update ();
      assert (src.val.get_boolean ());
      assert (!src.is_connected ());
    });
  }
}
