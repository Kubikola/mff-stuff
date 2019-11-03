using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Modules;
using Utilities;

namespace _117raster.ModuleHSV
{
  public partial class HSVForm : Form
  {
    private readonly IRasterModule module;
    protected Bitmap backBuffer;

    private double sat, val;
    private Point mousePos;
    readonly ToolTip tt = new ToolTip{ShowAlways = true};

    private PictureInfo collision;
    public PictureInfo Collision
    {
      get => collision;
      set
      {
        collision = value;
        CollisionChanged();
      }
    }

    private void CollisionChanged ()
    {
      if (Collision == null)
      {
        tt.Hide(this);
      }
      else
      {
        Focus();
        string s = $"H: {Collision.Hsv.H:F2} S: {Collision.Hsv.S:F2} V: {Collision.Hsv.V:F2}\n" +
                   $"R: {Collision.Rgb.R} G: {Collision.Rgb.G} B: {Collision.Rgb.B}\n" +
                   $"Original Loc: ({Collision.OriginalLocation.X}, {Collision.OriginalLocation.Y})";

        Point m = new Point(mousePos.X + 10, mousePos.Y- 10);
        tt.Show(s, this, m);
      }

    }

    public HSVForm (IRasterModule module)
    {
      this.module = module;
      InitializeComponent();
    }

    private void HSVForm_FormClosed (object sender, FormClosedEventArgs e)
    {
      backBuffer?.Dispose();
      tt?.Dispose();
      backBuffer = null;
    }

    private void HSVForm_Resize (object sender, EventArgs e)
    {
      if (backBuffer == null ||
          backBuffer.Width != ClientSize.Width ||
          backBuffer.Height != ClientSize.Height)
      {
        module.Update();
      }
    }

    private void HSVForm_Paint (object sender, PaintEventArgs e)
    {
      if (backBuffer == null)
      {
        e.Graphics.Clear(Color.White);
      }
      else
      {
        try
        {
          e.Graphics.DrawImageUnscaled(backBuffer, 0, 0);

        }
        catch (InvalidOperationException) { }
      }
    }

    public void SetBuffer (Bitmap bmp)
    {
      backBuffer?.Dispose();
      backBuffer = bmp;
      Invalidate();
    }



    private void HSVForm_MouseMove (object sender, MouseEventArgs e)
    {
      mousePos = e.Location;
      Text = "";

      val = -(111.111 * (0.05 * ClientSize.Width - e.X) / ClientSize.Width);
      sat = 111.111 * (0.95 * ClientSize.Height - e.Y) / ClientSize.Height;
      if (val >= 0 && val <= 100)
      {
        Text += $"V: {val:F2} ";
      }
      else
      {
        Text += "V: ERR ";
      }

      if (sat >= 0 && sat <= 100)
      {
        Text += $"S: {sat:F2}";
      }
      else
      {
        Text += "S: ERR";
      }



      float kx = ClientSize.Width * 0.9f / 100f;
      float ky = -ClientSize.Height * 0.9f / 100f;
      bool cc = false;

      //double d = !HSV.hueOff ? Math.Min(kx, Math.Abs(ky))/* : Math.Min(kx, Math.Abs(ky)) / 1.5f*/;
      double d = Math.Min(kx, Math.Abs(ky));
      foreach (PictureInfo pi in HSV.pis)
      {
        if (ExtensionMethods.Distance(pi.Location, mousePos) < d)
        {
          Collision = pi;
          cc = true;
          break;
        }
      }

      if(!cc)
      {
        Collision = null;
      }
    }
  }
}
