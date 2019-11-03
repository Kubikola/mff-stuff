using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Linq;
using System.Windows.Forms;
using Utilities;

namespace Modules
{
  public class Collision : IEquatable<Collision>
  {
    public string Color { get; set; }
    public int Code { get; set; }
    public int Vyskyt { get; set; }
    public RectangleF Im { get; set; }

    public bool Equals(Collision other)
    {
      if (ReferenceEquals(null, other))
      {
        return false;
      }

      if (ReferenceEquals(this, other))
      {
        return true;
      }

      return Color == other.Color && Code == other.Code && Vyskyt == other.Vyskyt && Im.Equals(other.Im);
    }

    public override bool Equals(object obj)
    {
      if (ReferenceEquals(null, obj))
      {
        return false;
      }

      if (ReferenceEquals(this, obj))
      {
        return true;
      }

      if (obj.GetType() != GetType())
      {
        return false;
      }

      return Equals((Collision) obj);
    }

    public override int GetHashCode()
    {
      unchecked
      {
        int hashCode = Color != null ? Color.GetHashCode() : 0;
        hashCode = (hashCode * 397) ^ Code;
        hashCode = (hashCode * 397) ^ Vyskyt;
        hashCode = (hashCode * 397) ^ Im.GetHashCode();
        return hashCode;
      }
    }
  }
  public partial class HistogramForm : Form
  {
    private readonly ToolTip tt = new ToolTip{ShowAlways = true};

    /// <summary>
    /// Back-buffer. Resized to current client-size of the form.
    /// </summary>
    protected Bitmap backBuffer = null;

    private bool mouseLeftDown = false;
    private bool mouseRightDown = false;
    private Point mousePos;

    private float x0;

    private Collision collision = null;

    public Collision Collision
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
        if(ImageHistogram.DrawingInfo.Count == 1)
        {
          tt.Show($"Kód: {collision.Code}\nVýskyt: {collision.Vyskyt}x", this, mousePos);
        }
        else
        {
          Point m = new Point(mousePos.X + 15, mousePos.Y);
          tt.Show($"Kód: {collision.Code}\nVýskyt: {collision.Vyskyt}x\nBarva: {collision.Color}", this, m);
        }
      }
    }

    /// <summary>
    /// Associated raster module (to be notified in case of form close).
    /// </summary>
    protected IRasterModule module;

    public void SetResult (Bitmap result)
    {
      backBuffer?.Dispose();
      backBuffer = result;
      Invalidate();

    }

    public HistogramForm (IRasterModule hModule)
    {
      module = hModule;
      InitializeComponent();
      x0 = ClientSize.Width * 0.05f;
    }

    private void HistogramForm_FormClosed (object sender, FormClosedEventArgs e)
    {
      backBuffer?.Dispose();
      backBuffer = null;

      module?.OnGuiWindowClose();
    }

    private void HistogramForm_Paint (object sender, PaintEventArgs e)
    {
      e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;

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
        catch(InvalidOperationException) { }
      }


      if (mouseRightDown)
      {
        e.Graphics.DrawLine(Pens.Black, x0, mousePos.Y, ClientSize.Width, mousePos.Y);
      }

      if (mouseLeftDown && Collision != null)
      {
        e.Graphics.DrawLine(Pens.Black, x0, Collision.Im.Y, Collision.Im.Right, Collision.Im.Y);
      }

      if (Collision != null)
      {
        e.Graphics.DrawRectangle(Pens.Yellow, Collision.Im.X, Collision.Im.Y, Collision.Im.Width, Collision.Im.Height);
      }
    }

    private void HistogramForm_Resize (object sender, System.EventArgs e)
    {
      x0 = ClientSize.Width * 0.05f;

      if (backBuffer == null ||
          backBuffer.Width  != ClientSize.Width ||
          backBuffer.Height != ClientSize.Height)
      {
        module.Update();
      }
    }

    private void HistogramForm_MouseMove (object sender, MouseEventArgs e)
    {
      mousePos = e.Location;

      for (int i = ImageHistogram.DrawingInfo.Count - 1; i >= 0; --i)
      {
        DrawingInfo di = ImageHistogram.DrawingInfo[i];
        RectangleF a = di.DrawingPrimitive.Select(x => x.Key).FirstOrDefault(f => IsInside(e.Location, f));
        if (a != default)
        {
          int kod = di.DrawingPrimitive[a];
          int cetnost = di.Hist[kod];
          Collision c = new Collision {Code = kod, Color = di.Color, Im = a, Vyskyt = cetnost};

          if (!c.Equals(Collision))
          {
            Collision = c;
          }
          break;
        }

        if (i == 0)
        {
          Collision = null;
        }
      }

      Refresh();
      CollisionChanged();
    }

    private bool IsInside (Point mPos, RectangleF f)
    {
      return mPos.X >= f.X && mPos.X <= f.Right && mPos.Y >= f.Y && mPos.Y <= f.Bottom;
    }

    private void HistogramForm_MouseDown (object sender, MouseEventArgs e)
    {
      if(e.Button == MouseButtons.Left)
      {
        mouseLeftDown = true;
      }

      if (e.Button == MouseButtons.Right)
      {
        mouseRightDown = true;
      }

      Invalidate();
    }

    private void HistogramForm_MouseUp (object sender, MouseEventArgs e)
    {
      if(e.Button == MouseButtons.Left)
      {
        mouseLeftDown = false;
      }

      if (e.Button == MouseButtons.Right)
      {
        mouseRightDown = false;
      }

      Invalidate();
    }
  }
}
