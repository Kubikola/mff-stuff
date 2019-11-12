using MathSupport;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using _117raster.ModuleArtSim;
using Utilities;

namespace Modules
{
  public class ModuleHSV : DefaultRasterModule
  {
    /// <summary>
    /// Mandatory plain constructor.
    /// </summary>
    public ModuleHSV ()
    {
      
    }

    /// <summary>
    /// Author's full name.
    /// </summary>
    public override string Author => "LevyJakub";

    /// <summary>
    /// Name of the module (short enough to fit inside a list-boxes, etc.).
    /// </summary>
    public override string Name => "ArtSim";

    /// <summary>
    /// Tooltip for Param (text parameters).
    /// </summary>
    public override string Tooltip => "";

    Params p = new Params();

    /// <summary>
    /// Usually read-only, optionally writable (client is defining number of inputs).
    /// </summary>
    public override int InputSlots => 1;

    /// <summary>
    /// Usually read-only, optionally writable (client is defining number of outputs).
    /// </summary>
    public override int OutputSlots => 1;

    /// <summary>
    /// Input raster image.
    /// </summary>
    protected Bitmap inImage = null;

    /// <summary>
    /// Output raster image.
    /// </summary>
    protected Bitmap outImage = null;

    /// <summary>
    /// Active HSV form.
    /// </summary>
    protected FormArtSim ArtSimForm = null;

    protected void updateParam ()
    {
      if (paramDirty)
      {
        paramDirty = false;

        // 'param' parsing.
      }

      formUpdate();
    }

    /// <summary>
    /// Send ModuleHSV values to the form elements.
    /// </summary>
    protected void formUpdate ()
    {
      if (ArtSimForm == null)
        return;



      ArtSimForm.Invalidate();
    }

    /// <summary>
    /// Notification: GUI window changed its values (sync GUI -> module is needed).
    /// </summary>
    public override void OnGuiWindowChanged ()
    {
      if (ArtSimForm == null)
        return;

      p = (Params) ArtSimForm.paramsPropertyGrid.SelectedObject;

     

      paramDirty = false;

      ParamUpdated?.Invoke(this);
    }

    /// <summary>
    /// Notification: GUI window has been closed.
    /// </summary>
    public override void OnGuiWindowClose ()
    {
      ArtSimForm?.Hide();
      ArtSimForm = null;
    }

    /// <summary>
    /// Assigns an input raster image to the given slot.
    /// Doesn't start computation (see #Update for this).
    /// </summary>
    /// <param name="inputImage">Input raster image (can be null).</param>
    /// <param name="slot">Slot number from 0 to InputSlots-1.</param>
    public override void SetInput (
      Bitmap inputImage,
      int slot = 0)
    {
      inImage = inputImage;
    }

    /// <summary>
    /// Recompute the output image[s] according to input image[s].
    /// Blocking (synchronous) function.
    /// #GetOutput() functions can be called after that.
    /// </summary>
    public override void Update ()
    {
      if (inImage == null)
        return;

      // Update module values from 'param' string.
      updateParam();

      int wid = inImage.Width;
      int hei = inImage.Height;
      PixelFormat iFormat = inImage.PixelFormat;

      // Output image must be true-color.
      outImage = new Bitmap(wid, hei, PixelFormat.Format24bppRgb);

      //for k-means
      Dictionary<Color, List<Color>> clusters;
      HashSet<Color> colors = new HashSet<Color>();

      //TODO: calculate image
      int xi, yi;
      int xo, yo;
      BitmapData dataIn = inImage.LockBits(new Rectangle(0, 0, wid, hei), ImageLockMode.ReadOnly, iFormat);
      BitmapData dataOut =
        outImage.LockBits(new Rectangle(0, 0, wid, hei), ImageLockMode.WriteOnly, outImage.PixelFormat);
      unsafe
      {
        byte* iptr, optr;
        int dI = Image.GetPixelFormatSize(iFormat) / 8; // pixel size in bytes
        int dO = Image.GetPixelFormatSize(outImage.PixelFormat) / 8; // pixel size in bytes

        //harvest all colors from image
        yi = 0;
        for (yo = 0; yo < hei; yo++)
        {
          iptr = (byte*)dataIn.Scan0 + yi * dataIn.Stride;
          optr = (byte*)dataOut.Scan0 + yo * dataOut.Stride;

          xi = 0;
          for (xo = 0; xo < wid; xo++)
          {
            colors.Add(Color.FromArgb(iptr[2], iptr[1], iptr[0]));
            iptr += dI;
            optr += dO;
            ++xi;
          }
          ++yi;
        }

      }
      clusters = Utils.KMeans(p.K, colors.ToList(), p.Iterations);
      List<Color> usableColors = clusters.Keys.ToList();
     // List<Color> usableColors = Utils.ExtractColors(clusters, p.ColorFromClusterCount);

      unsafe
      {
        byte* iptr, optr;
        int dI = Image.GetPixelFormatSize(iFormat) / 8; // pixel size in bytes
        int dO = Image.GetPixelFormatSize(outImage.PixelFormat) / 8; // pixel size in bytes

        yi = 0;
        for (yo = 0; yo < hei; yo++)
        {
          iptr = (byte*)dataIn.Scan0 + yi * dataIn.Stride;
          optr = (byte*)dataOut.Scan0 + yo * dataOut.Stride;

          xi = 0;
          for (xo = 0; xo < wid; xo++)
          {
            Color c = Color.FromArgb(iptr[2], iptr[1], iptr[0]);

            List<double> sm = Utils.Softmin(c, usableColors);
            int idx = Utils.GenRandom(sm);
            Color p = usableColors[idx];
            optr[2] = p.R;
            optr[1] = p.G;
            optr[0] = p.B;

            iptr += dI;
            optr += dO;
            ++xi;
          }
          ++yi;
        }
        inImage.UnlockBits(dataIn);
        outImage.UnlockBits(dataOut);
      }


      //using (Graphics g = Graphics.FromImage(outImage))
        //{
        //  int x = 10;
        //  foreach (var cluster in clusters)
        //  {
        //    g.DrawLine(new Pen(cluster.Key), 50, x, 150, x);
        //    x += 30;
        //  }

        //}

      }

    /// <summary>
    /// Returns an output raster image.
    /// Can return null.
    /// </summary>
    /// <param name="slot">Slot number from 0 to OutputSlots-1.</param>
    public override Bitmap GetOutput (
      int slot = 0) => outImage;

    /// <summary>
    /// Returns true if there is an active GUI window associted with this module.
    /// You can open/close GUI window using the setter.
    /// </summary>
    public override bool GuiWindow
    {
      get => ArtSimForm != null;
      set
      {
        if (value)
        {
          // Show GUI window.
          if (ArtSimForm == null)
          {
            ArtSimForm = new FormArtSim(this);
            formUpdate();
            ArtSimForm.Show();
          }
        }
        else
        {
          ArtSimForm?.Hide();
          ArtSimForm = null;
        }
      }
    }
  }
}
