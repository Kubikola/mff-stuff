using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text.RegularExpressions;
using System.Windows.Forms;
using Utilities;

namespace Modules
{
  public class ModuleGlobalHistogram : DefaultRasterModule
  {


    /// <summary>
    /// Mandatory plain constructor.
    /// </summary>
    public ModuleGlobalHistogram ()
    {
    }

    /// <summary>
    /// Author's full name.
    /// </summary>
    public override string Author => "LevyJakub";

    /// <summary>
    /// Name of the module (short enough to fit inside a list-boxes, etc.).
    /// </summary>
    public override string Name => "GlobalHistogram";

    /// <summary>
    /// Tooltip for Param (text parameters).
    /// </summary>
    /// circle n, square n definuje type selekce mysi
    /// 
    public override string Tooltip => "{red[-alt] | green[-alt] | blue[-alt] | gray[-alt]} [circle n|square n] [sort] ";

    /// <summary>
    /// Default mode - gray.
    /// </summary>
    protected string param = "gray blue red-alt square 50 sort";

    /// <summary>
    /// Current 'Param' string is stored in the module.
    /// Set reasonable initial value.
    /// </summary>
    public override string Param
    {
      get => param;
      set
      {
        if (value != param)
        {
          param = value;
          dirty = true;     // to recompute histogram table

          recompute();
        }
      }
    }

    /// <summary>
    /// Usually read-only, optionally writable (client is defining number of inputs).
    /// </summary>
    public override int InputSlots => 1;

    /// <summary>
    /// Usually read-only, optionally writable (client is defining number of outputs).
    /// </summary>
    public override int OutputSlots => 0;

    /// <summary>
    /// Input raster image.
    /// </summary>
    protected Bitmap inImage = null;

    protected Bitmap inImageLocal = null;

    /// <summary>
    /// True if the histogram needs recomputation.
    /// </summary>
    protected bool dirty = true;

    /// <summary>
    /// Active histogram view window.
    /// </summary>
    protected HistogramForm hForm = null;

    /// <summary>
    /// Interior (visualization) of the hForm.
    /// </summary>
    protected Bitmap hImage = null;

    protected void recompute ()
    {
      if (hForm   != null &&
          inImage != null)
      {
        Bitmap workingImg = LocalImage() && inImageLocal != null ? inImageLocal : inImage;


        hImage = new Bitmap(hForm.ClientSize.Width, hForm.ClientSize.Height, PixelFormat.Format24bppRgb);
        if (dirty)
        {
          ImageHistogram.ComputeHistogram(workingImg, Param);
          dirty = false;
        }
        ImageHistogram.DrawHistogram(hImage);
        hForm.SetResult(hImage);
      }
    }

    /// <summary>
    /// Returns true if there is an active GUI window associted with this module.
    /// Open/close GUI window using the setter.
    /// </summary>
    public override bool GuiWindow
    {
      get => hForm != null;
      set
      {
        if (value)
        {
          // Show GUI window.
          if (hForm == null)
          {
            hForm = new HistogramForm(this);
            hForm.Show();
          }

          recompute();
        }
        else
        {
          hForm?.Hide();
          hForm = null;
        }
      }
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
      dirty   = inImage != inputImage;     // to recompute histogram table
      inImage = DeepClone(inputImage);

      recompute();
    }

    public static T DeepClone<T> (T obj)
    {
      using (var ms = new MemoryStream())
      {
        var formatter = new BinaryFormatter();
        formatter.Serialize(ms, obj);
        ms.Position = 0;

        return (T)formatter.Deserialize(ms);
      }
    }

    /// <summary>
    /// Recompute the output image[s] according to input image[s].
    /// Blocking (synchronous) function.
    /// #GetOutput() functions can be called after that.
    /// </summary>
    public override void Update ()
    {
      recompute();
    }

    /// <summary>
    /// PixelUpdate() is called after every user interaction.
    /// </summary>
    public override bool HasPixelUpdate => true;


    public static string[] RemoveBlanks (string[] arr)
    {
      List<string> output = new List<string>();
      for (int i = 0; i < arr.Length; ++i)
      {
        if (arr[i].Trim() != "")
        {
          output.Add(arr[i]);
        }
      }

      return output.ToArray();
    }

    private bool LocalImage ()
    {
      string[] spl = RemoveBlanks(Regex.Split(param.ToLower(),".*(circle|square)[ ]*([0-9]+).*"));
      return spl.Length == 2;
    }

    private (string, int) ParseLocalImageInfo ()
    {
      string[] spl = RemoveBlanks(Regex.Split(param.ToLower(),".*(circle|square)[ ]*([0-9]+).*"));
      return (spl[0], int.Parse(spl[1]));
    }

    public Bitmap CropCircle (Bitmap original, Point center, int radius)
    {
      Point upperLeft = new Point(center.X - radius, center.Y - radius);
      if (upperLeft.X < 0)
      {
        upperLeft = new Point(0, upperLeft.Y);
        
      }
      if (upperLeft.Y < 0)
      {
        upperLeft = new Point(upperLeft.X, 0);
      }

      int diameter = radius * 2;
      Rectangle cropRectangle = new Rectangle(upperLeft, new Size(diameter, diameter));

      if (cropRectangle.X + cropRectangle.Width > original.Width)
      {
        cropRectangle = new Rectangle(cropRectangle.X, cropRectangle.Y, original.Width - cropRectangle.X, cropRectangle.Height);
      }

      if (cropRectangle.Y + cropRectangle.Height > original.Height)
      {
        cropRectangle = new Rectangle(cropRectangle.X, cropRectangle.Y, cropRectangle.Width, original.Height - cropRectangle.Y);
      }

      diameter = Math.Min(cropRectangle.Width, cropRectangle.Height);

      using (Image croppedImage = original.Clone(cropRectangle, original.PixelFormat))
      {
        using (TextureBrush tb = new TextureBrush(croppedImage))
        {
          Bitmap finalImage = new Bitmap(diameter, diameter, PixelFormat.Format32bppArgb);
          using (Graphics g = Graphics.FromImage(finalImage))
          {
            g.FillEllipse(tb, 0, 0, diameter, diameter);
            return finalImage;
          }
        }
      }
    }

    public static Bitmap CropSquare (Bitmap original, int x, int y, int width, int height)
    { 
      if (x < 0)
      {
        x = 0;

      }
      if (y < 0)
      {
        y = 0;
      }

      Rectangle cropRectangle = new Rectangle(x, y, width, height);

      if (cropRectangle.X + cropRectangle.Width > original.Width)
      {
        cropRectangle = new Rectangle(cropRectangle.X, cropRectangle.Y, original.Width - cropRectangle.X, cropRectangle.Height);
      }

      if (cropRectangle.Y + cropRectangle.Height > original.Height)
      {
        cropRectangle = new Rectangle(cropRectangle.X, cropRectangle.Y, cropRectangle.Width, original.Height - cropRectangle.Y);
      }

      Bitmap bmp = new Bitmap(cropRectangle.Width, cropRectangle.Height);
      using (Graphics gr = Graphics.FromImage(bmp))
      {
        gr.DrawImage(original, new Rectangle(0, 0, bmp.Width, bmp.Height), cropRectangle, GraphicsUnit.Pixel);
      }
      return bmp;
    }

    private bool lts = false;

    /// <summary>
    /// Optional action performed at the given pixel.
    /// Blocking (synchronous) function.
    /// Logically equivalent to Update() but with potential local effect.
    /// </summary>
    public override void PixelUpdate (
      int x,
      int y)
    {
      if (LocalImage())
      {
        dirty = true;

        (string shape, int distance) = ParseLocalImageInfo();
        if (shape == "circle")
        {
          inImageLocal = CropCircle(inImage, new Point(x, y), distance);
        }

        if (shape == "square")
        {
          inImageLocal = CropSquare(inImage, x -distance, y -distance, distance *2, distance *2);
          //inImageLocal = CropSquare(inImage, (int) (x-distance), (int) (y-distance), (int) (distance*2), (int) (distance*2));
        }
        recompute();
      }
  //    inImageLocal?.Save("C:\\obr.png");
      
    }

    /// <summary>
    /// Notification: GUI window has been closed.
    /// </summary>
    public override void OnGuiWindowClose ()
    {
      hForm = null;
    }
  }

}

