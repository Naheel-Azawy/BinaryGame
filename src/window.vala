/* window.vala
 *
 * Copyright (C) 2018 Naheel-Azawy
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Binarygame {

	const string TITLE = "Binary Game";
	const string APPID = "com.naheel.BinaryGame";

	const string HELP_MSG =
"""Keyboard shortcuts:
1, 2, 3, and 4: First right bits
0, 9, 8, and 7: First left bits
C: Down
B: Up""";

	const string BLUE	= "#3465a4";
	const string WHITE	= "#ffffff";
	const string GRAY	= "#d3d7cf";
	const string DARK	= "#2e3436";
	const string GREEN	= "#8AE234";

	static string fileName;
	static string fileDir;
	static bool is_light;

	public class Window : BaseWindow {

		public Window (Gtk.Application app) {
			Object (application: app);
			fileDir = Environment.get_home_dir () + "/.config/bingame";
			fileName = fileDir + "/bigame_data";
			read_file ();
			Gtk.Settings.get_default().gtk_application_prefer_dark_theme = is_light;

			destroy.connect (() => { GLib.Process.exit (0); });

			var hb = new Gtk.HeaderBar ();
			hb.title = TITLE;
			hb.subtitle = "New Game with";
			hb.show_close_button = true;
			var hb_help = new Gtk.Button.with_label ("Help");
			hb_help.clicked.connect (() => {
				var msg = new Gtk.MessageDialog (
					this,
					Gtk.DialogFlags.MODAL,
					Gtk.MessageType.INFO,
					Gtk.ButtonsType.OK,
					HELP_MSG
				);
				msg.response.connect ((response_id) => { msg.destroy(); });
				msg.show ();
			});
			hb.pack_start (hb_help);
			set_titlebar (hb);

			var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
			box.add (gamebtn (4));
			box.add (gamebtn (5));
			box.add (gamebtn (6));
			box.add (gamebtn (7));
			box.add (gamebtn (8));
			box.add (new Gtk.Separator (Gtk.Orientation.VERTICAL));

			var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
			box.add (hbox);

			var hs = new Gtk.Button.with_label ("High scores");
			hs.clicked.connect (() => {
				read_file ();
				string s = "High scores:\n";
				for (int i=4; i<=8; i++) s += @"$(i)x$(i) bits: $(get_score_str(i))\n";
				var msg = new Gtk.MessageDialog (
					this,
					Gtk.DialogFlags.MODAL,
					Gtk.MessageType.INFO,
					Gtk.ButtonsType.OK,
					s
				);
				msg.response.connect ((response_id) => { msg.destroy(); });
				msg.show ();
			});

			var st = new Gtk.Button.with_label ("Switch theme");
			st.clicked.connect (() => {
				Gtk.Settings.get_default().gtk_application_prefer_dark_theme = is_light = !is_light;
				save_file ();
			});

			hbox.add (hs);
			hbox.add (st);

			add (box);

			box.margin_start = box.margin_end = 50;
			box.margin_top = box.margin_bottom = box.spacing = hbox.spacing = 10;
			show_all ();

		}

		Gtk.Button gamebtn (int i) {
			var b = new Gtk.Button.with_label (@"$(i)x$(i) bits");
			b.clicked.connect (() => {
				var g = new GameWindow (i);
				g.attached_to = this;
			});
			return b;
		}
	}

	class GameWindow : BaseWindow {

		public int bits;
		public BtnBit[,] btns;
		public LinePtr[] ptrs;
		public Deci[] decs;
		public int ck = 0;
		Gtk.Label ck_lbl;
		Gtk.Label dn_lbl;
		Gtk.HeaderBar hb;
		Gtk.Box vbox;
		Gtk.Grid grid;

		uint timeout_id = 0;
		bool _countdown;
		bool countdown {
			get { return _countdown; }
			set {
				_countdown = value;
				if (ck_lbl != null)
					if (countdown) {
						grid.hide ();
						dn_lbl.show ();
					} else {
						ck = 0;
						dn_lbl.hide ();
						grid.show ();
					}
			}
		}

		public GameWindow (int bits) {
			this.bits = bits;

			modal = true;
			destroy.connect (() => {
				stop_clock ();
			});

			hb = new Gtk.HeaderBar ();
			ck_lbl = new Gtk.Label ("");
			set_font (ck_lbl, "monospace");
			hb.custom_title = ck_lbl;
			hb.show_close_button = true;
			set_titlebar (hb);

			vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);

			int kb_x = 1, kb_y = bits;
			this.key_press_event.connect ((e) => {
				switch (e.keyval) {
					case Gdk.Key.@1: kb_x = 1; kb_click (kb_x, kb_y); break;
					case Gdk.Key.@2: kb_x = 2; kb_click (kb_x, kb_y); break;
					case Gdk.Key.@3: kb_x = 3; kb_click (kb_x, kb_y); break;
					case Gdk.Key.@4: kb_x = 4; kb_click (kb_x, kb_y); break;
					case Gdk.Key.@7: kb_x = 5; kb_click (kb_x, kb_y); break;
					case Gdk.Key.@8: kb_x = 6; kb_click (kb_x, kb_y); break;
					case Gdk.Key.@9: kb_x = 7; kb_click (kb_x, kb_y); break;
					case Gdk.Key.@0: kb_x = 8; kb_click (kb_x, kb_y); break;
					case Gdk.Key.b: case Gdk.Key.Up: if (kb_y <= bits-1) { kb_y++; kb_line (kb_y); } break;
					case Gdk.Key.c: case Gdk.Key.Down: if (kb_y > 1) { kb_y--; kb_line (kb_y); } break;
				}
				return false;
			});

			grid = new Gtk.Grid ();
			grid.row_spacing = 10;
			grid.column_spacing = 10;

			ptrs = new LinePtr[bits];
			for (int i = 0; i<bits; i++) {
				ptrs[i] = new LinePtr(false);
				grid.attach (ptrs[i], 0, i, 1, 1);
			}

			btns = new BtnBit[bits, bits];
			for (int i = 0; i<bits; i++) {
				for (int j = 0; j<bits; j++) {
					btns[i, j] = new BtnBit (this, i, j);
					grid.attach (btns[i, j], i+1, j, 1, 1);
				}
			}

			int max = (int)Math.pow (2, bits)-1;
			decs = new Deci[bits];
			for (int i = 0; i<bits; i++) {
				decs[i] = new Deci (this, Random.int_range (1, max));
				grid.attach (decs[i], bits +1, i, 1, 1);
			}

			vbox.add (grid);


			dn_lbl = new Gtk.Label ("");
			set_font_size (dn_lbl, 90);
			vbox.add (dn_lbl);

			add (vbox);
			show_all ();

			dn_lbl.set_size_request(grid.get_allocated_width (), grid.get_allocated_height ());

			resizable = false;

			countdown = true;

			window_position = Gtk.WindowPosition.CENTER_ON_PARENT;

			run_clock ();
		}

		private void kb_click (int x, int y) {
			if (x>=1 && y>=1 && y<=bits) {
				if (y == bits && !ptrs[0].on) ptrs[0].on = true;
				if (x > 4) switch (bits) {
					case 5: if (x == 8) x-=3; else return; break; // 5 -> 8
					case 6: if (x == 8 || x == 7) x-=2; else return; break; // 5 -> 7, 6 -> 8
					case 7: if (x == 8 || x == 7 || x == 6) x-=1; else return; break; // 5 -> 6, 6 -> 7, 7 -> 8
				}
				//print (@"x = $x, y = $y\n");
				if (x<=bits) btns[x-1, bits-y].click ();
			}
		}

		private void kb_line (int y) {
			if (y>=1 && y<=bits) {
				foreach (LinePtr p in ptrs) p.on = false;
				ptrs[bits-y].on = true;
			}
		}

		public void run_clock () {
			if (timeout_id != 0) Source.remove (timeout_id);
			timeout_id = Timeout.add (100, () => {
				ck++;
				if (countdown) {
					int[] a = parse_clock_arr (ck);
					if (4-a[1] == 0) countdown = false;
					dn_lbl.label = (3-a[1]).to_string ();
				} else {
					ck_lbl.label = parse_clock (ck);
				}
				return true;
			});
		}

		public void stop_clock () {
			if (timeout_id != 0) {
				Source.remove (timeout_id);
				timeout_id = 0;
			}
		}

		public string parsed_clock () {
			return parse_clock (ck);
		}

		public void done () {
			this.stop_clock ();
			read_file ();
			bool b = ck < get_score(bits) || get_score(bits) == 0;
			if (b) { set_score (bits, ck); save_file (); }
			var msg = new Gtk.MessageDialog (
				this,
				Gtk.DialogFlags.MODAL,
				Gtk.MessageType.INFO,
				Gtk.ButtonsType.OK,
				@"$(b?"New high score!":"Time:")\n$(parsed_clock ())"
			);
			msg.response.connect ((response_id) => {
				msg.destroy();
				this.close ();
			});
			msg.show ();
		}

	}

	public class BaseWindow : Gtk.ApplicationWindow  {
		public BaseWindow () {
			title = TITLE;
			border_width = 10;
			window_position = Gtk.WindowPosition.CENTER;
			resizable = false;
		}
	}

	class LinePtr : Gtk.Label {
		private bool _on = false;
		public LinePtr[] ptrs;
		public bool on {
			get { return _on; }
			set {
				_on = value;
				if (ptrs != null) foreach (LinePtr p in ptrs)
					p.on = false;
				this.label = _on ? "->" : "  ";
			}
		}
		public LinePtr (bool on) {
			this.on = on;
			set_font (this, "monospace");
		}
	}

	class BtnBit : Gtk.Button {
		GameWindow w;
		public int i;
		public int j;
		private bool _bit;
		public bool bit {
			get { return _bit; }
			set {
				_bit = value;
				if (_bit) {
					label = "1";
					set_bg_color (this, BLUE);
					set_color (this, WHITE);
				} else {
					label = "0";
					set_bg_color (this, GRAY);
					set_color (this, DARK);
				}
			}
		}

		public int get_value () {
			return bit ? (int) Math.pow (2, w.bits-i-1) : 0;
		}

		public void click () {
			bit = !bit;
			int v = 0;
			for (int a = 0; a<w.bits; a++) v += w.btns[a, j].get_value ();
			w.decs[j].check_num (v);
		}

		public BtnBit(GameWindow w, int i, int j) {
			this.w = w;
			this.i = i; this.j = j;
			bit = false;
			this.clicked.connect (click);
		}
	}

	class Deci : Gtk.Button {
		GameWindow w;
		int num;
		public bool ok = false;
		public void check_num (int n) {
			if (n == num) {
				set_bg_color (this, GREEN);
				set_color (this, DARK);
				ok = true;
			} else {
				set_bg_color (this, DARK);
				set_color (this, WHITE);
				ok = false;
			}
			if (w.decs[0] != null) {
				bool allok = true;
				foreach (var d in w.decs) if (!d.ok) { allok = false; break; }
				if (allok) w.done ();
			}
		}
		public Deci (GameWindow w, int num) {
			this.w = w;
			this.num = num;
			check_num (0);
			label = num.to_string ();
		}
	}

	void set_font (Gtk.Widget w, string font) {
		var css = @"* { font-family: $font; }";
		var p = new Gtk.CssProvider ();
		try {
			p.load_from_data (css, css.length);
			w.get_style_context ().add_provider (p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
		} catch (Error err) {
			stderr.printf ("Could not set font: %s\n", err.message);
		}
	}

	void set_font_size (Gtk.Widget w, int sz) {
		var css = @"* { font-size: $(sz)px; }";
		var p = new Gtk.CssProvider ();
		try {
			p.load_from_data (css, css.length);
			w.get_style_context ().add_provider (p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
		} catch (Error err) {
			stderr.printf ("Could not set font size: %s\n", err.message);
		}
	}

	void set_color (Gtk.Widget w, string color) {
		var css = @"* { color: $color; text-shadow: none; }";
		var p = new Gtk.CssProvider ();
		try {
			p.load_from_data (css, css.length);
			w.get_style_context ().add_provider (p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
		} catch (Error err) {
			stderr.printf ("Could not set color: %s\n", err.message);
		}
	}

	void set_bg_color (Gtk.Widget w, string color) {
		var css = @"* { background: $color; }";
		var p = new Gtk.CssProvider ();
		try {
			p.load_from_data (css, css.length);
			w.get_style_context ().add_provider (p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
		} catch (Error err) {
			stderr.printf ("Could not set background: %s\n", err.message);
		}
	}

	static int[] parse_clock_arr (int ck) {
		int ms = ck % 10;
		ck /= 10;
		int s = ck % 60;
		int m = ck / 60;
		return new int[] { m, s, ms };
	}

	static string parse_clock (int ck) {
		int ms = ck % 10;
		ck /= 10;
		int s = ck % 60;
		int m = ck / 60;
		return @"$(m<=0?"":@"$m:")$(s<=0?"":@"$s:")$(ms)";
	}

	const int SCORES_LENGTH = 5;
	static int[] scores;
	static void set_score (int b, int s) { scores[b-4] = s; }
	static int get_score (int b) { return scores[b-4]; }
	static string get_score_str (int b) { return parse_clock (scores[b-4]); }

	static void read_file () {
		if (scores == null) scores = new int[SCORES_LENGTH];

		var file = File.new_for_path (fileName);
		if (!file.query_exists ()) {
			save_file ();
		}

		try {
		var dis = new DataInputStream (file.read ());
		string line;
		for (int i=0; (line = dis.read_line (null)) != null && i<SCORES_LENGTH+1; i++) {
		    if (i == SCORES_LENGTH)
		        is_light = bool.parse(line);
		    else
			    scores[i] = int.parse(line);
		}
		} catch (Error e) {
			error ("Error read_file: %s", e.message);
		}
	}

	static void save_file () {
		if (scores == null) scores = new int[SCORES_LENGTH];
		string s = "";
		foreach (var i in scores) s += @"$i\n";
		s += is_light.to_string ();
		try {
			try {
				File.new_for_path (fileDir).make_directory_with_parents ();
			} catch (Error ignored) {}
			File f = File.new_for_path (fileName);
			if (!f.query_exists ())
				f.create (FileCreateFlags.PRIVATE);
			FileUtils.set_contents (fileName, s);
		} catch (Error e) {
			error ("Error save_file: %s", e.message);
		}
	}
}
