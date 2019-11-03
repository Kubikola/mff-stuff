using System.Drawing;
using MathSupport;
using Raster;
using System;
using System.Collections.Generic;
using System.Drawing.Drawing2D;
using System.Linq;
using System.Net;
using System.Runtime.CompilerServices;
using System.Text.RegularExpressions;
using Modules;

namespace Utilities
{
  public class DrawingInfo
  {
    public string Color { get; set; } = "gray";
    public Dictionary<int, int> Hist = new Dictionary<int, int>();
    public bool Alt = false;
    public Dictionary<RectangleF, int> DrawingPrimitive { get; set; } = new Dictionary<RectangleF, int>();
  }

  public class ImageHistogram
  { 
    public static List<DrawingInfo> DrawingInfo { get; set; } = new List<DrawingInfo>();

    private static bool sort = false;
    private static bool sortReverse = false;

    /// <summary>
    /// Draws the current histogram to the given raster image.
    /// </summary>
    /// <param name="graph">Result image (already scaled to the desired size).</param>
    public static void DrawHistogram (
      Bitmap graph)
    {
      if (DrawingInfo.Count == 0)
      {
        return;
      }

      float max = DrawingInfo.SelectMany(x => x.Hist.Values).ToArray().Max();


      using (Graphics gfx = Graphics.FromImage(graph))
      {
        // Graph scaling:
        float x0 = graph.Width * 0.05f;
        float y0 = graph.Height * 0.95f;
        float kx = graph.Width * 0.9f / 256f;
        float ky = -graph.Height * 0.9f / max;

        Pen axisPen = new Pen(Color.Black);
        Font smallest = new Font(FontFamily.GenericSansSerif, 10);
        Font smallestB = new Font(FontFamily.GenericSansSerif, 10, FontStyle.Bold);
        StringFormat sfCenter = new StringFormat {Alignment = StringAlignment.Center};

        gfx.Clear(Color.White);

        foreach (DrawingInfo di in DrawingInfo)
        {
          DataRecomputation(di, graph.Width, graph.Height);

          

          // Pens:
          Color c = di.Color == "red" ? Color.Red : (di.Color == "green" ? Color.DarkGreen : (di.Color == "blue" ? Color.Blue : Color.Gray));
          Brush graphBrush = new SolidBrush(c);

          // Histogram:
          gfx.FillRectangles(graphBrush, di.DrawingPrimitive.Keys.ToArray());
          gfx.DrawRectangles(Pens.Black, di.DrawingPrimitive.Keys.ToArray());



        }
        RectangleF lastBox = RectangleF.Empty;
        RectangleF currTextPos = RectangleF.Empty;
        RectangleF lastBox2 = RectangleF.Empty;


        if (!sort)
        {
          lastBox = RectangleF.Empty;
          currTextPos = RectangleF.Empty;
          lastBox2 = new RectangleF(new PointF((x0 + 255f * kx + (x0 + 255f * kx + kx)) / 2f, y0), gfx.MeasureString("255", smallest));
          gfx.DrawString("255", smallestB, Brushes.Black, lastBox2.X, lastBox2.Y, sfCenter);

          for (int x = 0; x < 256; x++)
          {
            currTextPos = new RectangleF(new PointF((x0 + x * kx + (x0 + x * kx + kx)) / 2f, y0),
              gfx.MeasureString(x.ToString(), smallest));

            if (RectangleF.Intersect(currTextPos, lastBox) == RectangleF.Empty &&
                RectangleF.Intersect(currTextPos, lastBox2) == RectangleF.Empty)
            {
              gfx.DrawString(x.ToString(), smallest, Brushes.Black, currTextPos.X, currTextPos.Y, sfCenter);
              lastBox = currTextPos;
            }

          }
        }


        if (sort && DrawingInfo.Count == 1)
        {
          List<KeyValuePair<int, int>> myList = DrawingInfo[0].Hist.ToList();
          if (sortReverse)
          {
            myList.Sort((pair1, pair2) => pair1.Value.CompareTo(pair2.Value));
          }
          else
          {
            myList.Sort((pair1, pair2) => pair2.Value.CompareTo(pair1.Value));
          }

          lastBox = RectangleF.Empty;
          currTextPos = RectangleF.Empty;
          lastBox2 = new RectangleF(new PointF((x0 + 255f * kx + (x0 + 255f * kx + kx)) / 2f, y0), gfx.MeasureString(myList.Last().Key.ToString(), smallest));
          gfx.DrawString(myList.Last().Key.ToString(), smallestB, Brushes.Black, lastBox2.X, lastBox2.Y, sfCenter);

          int x = 0;
          foreach (KeyValuePair<int, int> kv in myList)
          {

            int val = kv.Key;
            currTextPos = new RectangleF(new PointF((x0 + x * kx + (x0 + x * kx + kx)) / 2f, y0),
              gfx.MeasureString(val.ToString(), smallest));

            if (RectangleF.Intersect(currTextPos, lastBox) == RectangleF.Empty &&
                RectangleF.Intersect(currTextPos, lastBox2) == RectangleF.Empty)
            {
              gfx.DrawString(val.ToString(), smallest, Brushes.Black, currTextPos.X, currTextPos.Y, sfCenter);
              lastBox = currTextPos;
            }
            ++x;
          }
        }


        SizeF velikost = gfx.MeasureString(max.ToString(), smallest);
        lastBox = new RectangleF(new PointF(x0, y0), gfx.MeasureString("0", smallest));
        lastBox2 = new RectangleF(new PointF(x0, y0 + max * ky), velikost);
        gfx.DrawString(max.ToString(), smallestB, Brushes.Black, lastBox2.X, lastBox2.Y - velikost.Height/2f,
          new StringFormat { Alignment = StringAlignment.Far });

        for (int cetnost = 0; cetnost <= max; ++cetnost)
        {
          velikost = gfx.MeasureString(cetnost.ToString(), smallest);
          currTextPos = new RectangleF(new PointF(x0, y0 + cetnost * ky), velikost);
          if (RectangleF.Intersect(currTextPos, lastBox) == RectangleF.Empty &&
              RectangleF.Intersect(currTextPos, lastBox2) == RectangleF.Empty)
          {
            gfx.DrawString(cetnost.ToString(), smallest, Brushes.Black, currTextPos.X, currTextPos.Y - velikost.Height/2f, new StringFormat { Alignment = StringAlignment.Far });
            lastBox = currTextPos;
          }
        }


        // Axes:
        gfx.DrawLine(axisPen, x0, y0, x0 +256f * kx, y0);
        gfx.DrawLine(axisPen, x0, y0, x0, y0 + max * ky);

        gfx.DrawString("Kód", smallest, Brushes.Black, x0 + 256f * kx + 15f, y0 - 15f, sfCenter);
        gfx.DrawString("Výskyt", smallest, Brushes.Black, x0, y0 + max * ky - 23f, sfCenter);


      }
    }

    protected static void ParseParams (string param)
    {
      DrawingInfo.Clear();
      string[] p = ModuleGlobalHistogram.RemoveBlanks(Regex.Split(param, "(red|green|blue|gray)\\-?(alt)?"));
      for (int i = 0; i < p.Length; ++i)
      {
        if(p[i] != "red" && p[i] != "green" && p[i] != "blue" && p[i] != "gray")
        {
          continue;
        }

        DrawingInfo di = new DrawingInfo {Color = p[i]};
        if (i + 1 < p.Length && p[i + 1] == "alt")
        {
          ++i;
          di.Alt = true;
        }
        DrawingInfo.Add(di);
      }
    }

    /// <summary>
    /// Recomputes image histogram and draws the result in the given raster image.
    /// </summary>
    /// <param name="input">Input image.</param>
    /// <param name="param">Textual parameter.</param>
    public static void ComputeHistogram (
      Bitmap input,
      string param)
    {
      // Text parameters:
      param = param.ToLower().Trim();

      if (param == "")
      {
        return;
      }

      ParseParams(param);


      // Sorted histogram:
      sort = param.IndexOf("sort") >= 0;
      sortReverse = param.IndexOf("sort-reverse") >= 0;

      int x, y;

      foreach (DrawingInfo di in DrawingInfo)
      {
        // 1. Histogram recomputation.

        for (int xx = 0; xx < 256; ++xx)
        {
          di.Hist.Add(xx, 0);
        }

        int width = input.Width;
        int height = input.Height;
        for (y = 0; y < height; y++)
        {
          for (x = 0; x < width; x++)
          {
            Color col = input.GetPixel( x, y );
            if (col.A == 0)
            {
              continue;
            }
            int Y = Draw.RgbToGray( col.R, col.G, col.B );

            //double H, S, V;
            //Arith.ColorToHSV( col, out H, out S, out V );

            int key = di.Color == "red" ? col.R : di.Color == "green" ? col.G : di.Color == "blue" ? col.B : Y;
            di.Hist[key]++;
          }
        }

        DataRecomputation(di, input.Width, input.Height);
      }
    }

    static void DataRecomputation (DrawingInfo di, int width, int height)
    {
      di.DrawingPrimitive.Clear();


      float max = DrawingInfo.SelectMany(xx => xx.Hist.Values).ToArray().Max();

      float x0 = width * 0.05f;
      float y0 = height * 0.95f;
      float kx = width * 0.9f / 256f;
      float ky = -height * 0.9f / max;

      //compute histogram
      if (!sort)
      {
        for (int xx = 0; xx < 256; xx++)
        {
          float yHeight = -di.Hist[xx] * ky;
          if (di.Alt && yHeight > 3.0)
          {
            yHeight = 3.0f;
          }

          di.DrawingPrimitive.Add(new RectangleF(x0 + xx * kx, y0 + di.Hist[xx] * ky, kx, yHeight), xx);
        }
      }
      else
      {
        List<KeyValuePair<int, int>> myList = di.Hist.ToList();
        if (sortReverse)
        {
          myList.Sort((pair1, pair2) => pair1.Value.CompareTo(pair2.Value));
        }
        else
        {
          myList.Sort((pair1, pair2) => pair2.Value.CompareTo(pair1.Value));
        }

        for (int xx = 0; xx < 256; xx++)
        {
          float yHeight = -myList[xx].Value * ky;
          if (di.Alt && yHeight > 3.0)
          {
            yHeight = 3.0f;
          }

          di.DrawingPrimitive.Add(new RectangleF(x0 + xx * kx, y0 + myList[xx].Value * ky, kx, yHeight), myList[xx].Key);
        }
      }
    }
  }
}
