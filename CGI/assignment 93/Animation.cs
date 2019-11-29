using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Threading;
using JakubLevy;
using LineCanvas;
using MathSupport;
using Utilities;

namespace _093animation
{
  public class Animation
  {
    private static float? baseLineLength = null;
    private static object lck = new  object();
    private static ThreadLocal<bool> shouldNotUnlock = new ThreadLocal<bool>();

    /// <summary>
    /// Form data initialization.
    /// </summary>
    /// <param name="name">Your first-name and last-name.</param>
    /// <param name="wid">Image width in pixels.</param>
    /// <param name="hei">Image height in pixels.</param>
    /// <param name="from">Animation start in seconds.</param>
    /// <param name="to">Animation end in seconds.</param>
    /// <param name="fps">Frames-per-seconds.</param>
    /// <param name="param">Optional text to initialize the form's text-field.</param>
    /// <param name="tooltip">Optional tooltip = param help.</param>
    public static void InitParams (out string name, out int wid, out int hei, out double from, out double to, out double fps, out string param, out string tooltip)
    {
      // {{

      // Put your name here.
      name = "Jakub Levý";

      // Image size in pixels.
      wid = 1800;
      hei = 1000;

      // Animation.
      from = 0.0;
      to   = 10.0;
      fps  = 25.0;

      // Specific animation params.
      param = "bush, gen=6, lineLength=0.01, speed=0";

      // Tooltip = help.
      tooltip = "[koch|kochAnti|kochQuadratic|tree|binTree|flower|bush|fern|islandsAndLakes|map|brokenWindow|dragon|levyCCurve|sierpinski], gen=<int>, lineLength=<float>, speed=<int>, antialiasing=<bool>";

      // }}
    }

    /// <summary>
    /// Global initialization. Called before each animation batch
    /// or single-frame computation.
    /// </summary>
    /// <param name="width">Width of the future canvas in pixels.</param>
    /// <param name="height">Height of the future canvas in pixels.</param>
    /// <param name="start">Start time (t0)</param>
    /// <param name="end">End time (for animation length normalization).</param>
    /// <param name="fps">Required fps.</param>
    /// <param name="param">Optional string parameter from the form.</param>
    public static void InitAnimation (int width, int height, double start, double end, double fps, string param)
    {
      // {{ TODO: put your init code here
      baseLineLength = null;
      // }}
    }

    /// <summary>
    /// Draw single animation frame.
    /// Has to be re-entrant!
    /// </summary>
    /// <param name="c">Canvas to draw to.</param>
    /// <param name="time">Current time in seconds.</param>
    /// <param name="start">Start time (t0)</param>
    /// <param name="end">End time (for animation length normalization).</param>
    /// <param name="param">Optional string parameter from the form.</param>
    public static void DrawFrame (Canvas c, double time, double start, double end, string param)
    {
      // {{ TODO: put your drawing code here

      double timeNorm = Arith.Clamp((time - start) / (end - start), 0.0, 1.0);

      bool antialiasing = true;  // use anti-aliasing?
      bool koch = false;
      bool kochAnti = false;
      bool kochQuadratic = false;
      bool tree = false;
      bool binTree = false;
      bool flower = false;
      bool bush = false;
      bool fern = false;
      bool islandsAndLakes = false;
      bool map = false;
      bool brokenWindow = false;
      bool dragon = false;
      bool levyCCurve = false;
      bool sierpinski = false;
      bool pentaplexity = false;
      double speed = 2;
      int gen = 6;

      Dictionary<string, string> p = Util.ParseKeyValueList(param);
      if (p.Count > 0)
      {
        // anti[=<bool>]
        Util.TryParse(p, "antialiasing", ref antialiasing);
        Util.TryParse(p, "koch", ref koch);
        Util.TryParse(p, "kochAnti", ref kochAnti);
        Util.TryParse(p, "kochQuadratic", ref kochQuadratic);
        Util.TryParse(p, "tree", ref tree);
        Util.TryParse(p, "binTree", ref binTree);
        Util.TryParse(p, "flower", ref flower);
        Util.TryParse(p, "bush", ref bush);
        Util.TryParse(p, "fern", ref fern);
        Util.TryParse(p, "islandsAndLakes", ref islandsAndLakes);
        Util.TryParse(p, "map", ref map);
        Util.TryParse(p, "brokenWindow", ref brokenWindow);
        Util.TryParse(p, "dragon", ref dragon);
        Util.TryParse(p, "levyCCurve", ref levyCCurve);
        Util.TryParse(p, "sierpinski", ref sierpinski);
        Util.TryParse(p, "pentaplexity", ref pentaplexity);

        if (Util.TryParse(p, "gen", ref gen))
        {
          gen = Math.Max(0, gen);
        }

        if (Util.TryParse(p, "speed", ref speed))
        {
          speed = Math.Max(0.1f, speed);
        }

        float ll = 0f;
        if (Util.TryParse(p, "lineLength", ref ll))
        {
          baseLineLength = ll;
        }
      }

      //c.Clear(Color.Black);
    //  c.Clear(Color.FromArgb(149,89,255));
//  c.Clear(Color.FromArgb(80,14,255));
   // c.Clear(Color.FromArgb(37,0,255));

      //c.Clear(Color.FromArgb(0,0,65));
      c.Clear(Color.FromArgb(179,109,144));
      c.SetAntiAlias(antialiasing);

      if (koch)
      {
        Koch(c, gen, time,speed);
      }

      else if (kochAnti)
      {
        KochAnti(c, gen, time, speed);
      }

      else if (kochQuadratic)
      {
        KochQuadratic(c, gen, time, speed);
      }

      else if (tree)
      {
        Tree(c, gen, time, speed);
      }

      else if (binTree)
      {
        BinTree(c, gen, time, speed);
      }

      else if (flower)
      {
        Flower(c, gen, time, speed);
      }

      else if (bush)
      {
        Bush(c, gen, time, speed);
      }

      else if (fern)
      {
        Fern(c, gen, time, speed);
      }

      else if (islandsAndLakes)
      {
        IslandsAndLakes(c, gen, time, speed);
      }

      else if (map)
      {
        Map(c, gen, time, speed);
      }

      else if (brokenWindow)
      {
        BrokenWindow(c, gen, time, speed);
      }

      else if (dragon)
      {
        Dragon(c, gen, time, speed);
      }

      else if (levyCCurve)
      {
        LevyCCurve(c, gen, time, speed);
      }

      else if (sierpinski)
      {
        Sierpinski(c, gen, time, speed);
      }
      else if (pentaplexity)
      {
      //  Pentaplexity(c, gen, time, speed);
      Pentaplexity(c, gen, time,speed);
      }
    }

    private static void PerformDrawing (Canvas c, List<DrawInfo> dis)
    {
      foreach (DrawInfo di in dis)
      {
        c.SetColor(di.Pen.Color);
        c.Line(di.Start.X, di.Start.Y, di.End.X, di.End.Y);
      }
    }

    private static Turtle BinarySearch (int maxG, float currMin, float currMax, string sentence, float rotationAngle, Point dir, Dictionary<char, Color> colorMappings)
    {
      Stack<Turtle> output = new Stack<Turtle>();
      while (currMin <= currMax)
      {
        float ce = (currMin + currMax) / 2f;
        Turtle t = new Turtle(sentence, ce, rotationAngle, PointF.Empty, dir, colorMappings);
        if (Math.Abs(t.Size) < 0.01f)
        {
          output.Push(t);
          break;
        }

        if (t.Size < maxG)
        {
          currMin = ce + 0.5f;
          output.Push(t);
        }
        else if (t.Size > maxG)
        {
          currMax = ce - 0.5f;
        }
      }

      if (output.Any())
      {

        if (output.Peek().Size < 0.01f)
        {
          return output.Peek();
        }

        Turtle t = output.Pop();
        float lineL = t.LineLength;
        do
        {
          output.Push(t);
          lineL += 0.1f;
          t = new Turtle(sentence, lineL, rotationAngle, PointF.Empty, dir, colorMappings);
        } while (t.Size < maxG);

        return output.Peek();
      }

      return null;
    }

    private static Turtle RenderLsystem (Canvas c, string sentence, float rotationAngle, Point dir, Dictionary<char, Color> colorMappings)
    {
      int m = Math.Min(c.Width, c.Height);
      PointF center = new PointF(c.Width /2f, c.Height /2f);
      float min = 0.1f;
      float max = (m / 2f);
      Turtle t = BinarySearch(m, min, max, sentence, rotationAngle, dir, colorMappings);
      if (t != null)
      {
        t.TranslateCenter(center);
        return t;
      }
      t = new Turtle(sentence, 0.1f, rotationAngle, center, dir, colorMappings);
      t.TranslateCenter(center);
      return t;
    }

    private static float NewLineLength (double time, double speed)
    {
      return (float)(baseLineLength + time*time + speed);
    }

    private static void Koch (Canvas c, int gen, double time, double speed)
    {
      PointF center = new PointF(c.Width/2f, c.Height/2f);
      Lsystem lsys = new Lsystem("F++F++F", new Dictionary<char, string>{ { 'F', "F-F++F-F" }});
      lsys.NthGeneration(gen);
      Turtle t;
      if (baseLineLength == null)
      {
        t = RenderLsystem(c, lsys.Sentence, 60, new Point(1, 0), new Dictionary<char, Color>());
        baseLineLength = t.LineLength;
      }
      else
      {
        t = new Turtle(lsys.Sentence, NewLineLength(time, speed), 60, PointF.Empty, new Point(1, 0), new Dictionary<char, Color>());
        t.TranslateCenter(center);
      }
      PerformDrawing(c, t.DrawInfo);
    }

    private static void Sierpinski (Canvas c, int gen, double time, double speed)
    {
      PointF center = new PointF(c.Width/2f, c.Height/2f);
      Lsystem lsys = new Lsystem("F-G-G", new Dictionary<char, string>{ {'F', "F-G+F+G-F" }, {'G', "GG"} });
      lsys.NthGeneration(gen);
      Turtle t;
      if (baseLineLength == null)
      {
        t = RenderLsystem(c, lsys.Sentence,60, new Point(-1, 0), new Dictionary<char, Color>());
        baseLineLength = t.LineLength;
      }
      else
      {
        t = new Turtle(lsys.Sentence, NewLineLength(time, speed), 60, PointF.Empty, new Point(-1, 0), new Dictionary<char, Color>());
        t.TranslateCenter(center);
      }
      PerformDrawing(c, t.DrawInfo);
    }
    private static void Map (Canvas c, int gen, double time, double speed)
    {
      if (baseLineLength == null)
      {
        shouldNotUnlock.Value = false;
        Monitor.Enter(lck);
      }
      else
      {
        shouldNotUnlock.Value = true;
      }

      PointF center = new PointF(c.Width/2f, c.Height/2f);
      Lsystem lsys = new Lsystem("F-F-F-F", new Dictionary<char, string>{ { 'F', "F-FF--F-F" }});
      lsys.NthGeneration(gen);
      Turtle t;
      if (baseLineLength == null)
      {
        t = RenderLsystem(c, lsys.Sentence, 90, new Point(0, 1), new Dictionary<char, Color> { { 'F', Color.FromArgb(0, 128, 255) } });
        baseLineLength = t.LineLength;
      }
      else
      {
        t = new Turtle(lsys.Sentence, NewLineLength(time, speed), 90, PointF.Empty, new Point(0, 1), new Dictionary<char, Color> { { 'F', Color.FromArgb(0, 128, 255) } });
        t.TranslateCenter(center);
      }
      PerformDrawing(c, t.DrawInfo);

      if (!shouldNotUnlock.Value)
        Monitor.Exit(lck);
    }

    private static void KochAnti (Canvas c, int gen, double time, double speed)
    {
      if (baseLineLength == null)
      {
        shouldNotUnlock.Value = false;
        Monitor.Enter(lck);
      }
      else
      {
        shouldNotUnlock.Value = true;
      }

      PointF center = new PointF(c.Width/2f, c.Height/2f);
      Lsystem lsys = new Lsystem("F++F++F", new Dictionary<char, string>{ { 'F', "F+F--F+F" }});
      lsys.NthGeneration(gen);
      Turtle t;
      if (baseLineLength == null)
      {
        t = RenderLsystem(c, lsys.Sentence, 60, new Point(1, 0), new Dictionary<char, Color>());
        baseLineLength = t.LineLength;
      }
      else
      {
        t = new Turtle(lsys.Sentence, NewLineLength(time, speed), 60, PointF.Empty, new Point(1, 0), new Dictionary<char, Color>());
        t.TranslateCenter(center);
      }
      PerformDrawing(c, t.DrawInfo);

      if (!shouldNotUnlock.Value)
        Monitor.Exit(lck);
    }

    private static void Bush (Canvas c, int gen, double time, double speed)
    {
      if (baseLineLength == null)
      {
        shouldNotUnlock.Value = false;
        Monitor.Enter(lck);
      }
      else
      {
        shouldNotUnlock.Value = true;
      }

      PointF center = new PointF(c.Width/2f, c.Height/2f);
      Lsystem lsys = new Lsystem("F", new Dictionary<char, string>{ { 'F', "FF+[+F-F-F]-[-F+F+F]" } });
      lsys.NthGeneration(gen);
      Turtle t;
      if (baseLineLength == null)
      {
        t = RenderLsystem(c, lsys.Sentence, -25, new Point(0, -1), new Dictionary<char, Color> { { 'F', Color.FromArgb(0, 64, 0) } });
        baseLineLength = t.LineLength;
      }
      else
      {
        t = new Turtle(lsys.Sentence, NewLineLength(time, speed), -25, PointF.Empty, new Point(0, -1), new Dictionary<char, Color> { { 'F', Color.FromArgb(0, 64, 0) } });
        t.TranslateCenter(center);
      }
      PerformDrawing(c, t.DrawInfo);

      if(!shouldNotUnlock.Value)
        Monitor.Exit(lck);
    }
    private static void Flower (Canvas c, int gen, double time, double speed)
    {
      if (baseLineLength == null)
      {
        shouldNotUnlock.Value = false;
        Monitor.Enter(lck);
      }
      else
      {
        shouldNotUnlock.Value = true;
      }

      PointF center = new PointF(c.Width/2f, c.Height/2f);
      Lsystem lsys = new Lsystem("F", new Dictionary<char, string>{ { 'F', "F[+F]F[-F]F" } });
      lsys.NthGeneration(gen);
      Turtle t;
      if (baseLineLength == null)
      {
        t = RenderLsystem(c, lsys.Sentence, 25, new Point(0, -1), new Dictionary<char, Color> { { 'F', Color.FromArgb(128, 128, 64) } });
        baseLineLength = t.LineLength;
      }
      else
      {
        t = new Turtle(lsys.Sentence, NewLineLength(time, speed), 25, PointF.Empty, new Point(0, -1), new Dictionary<char, Color> { { 'F', Color.FromArgb(128, 128, 64) } });
        t.TranslateCenter(center);
      }
      PerformDrawing(c, t.DrawInfo);

      if (!shouldNotUnlock.Value)
        Monitor.Exit(lck);
    }
    private static void KochQuadratic(Canvas c, int gen, double time, double speed)
    {
      if (baseLineLength == null)
      {
        shouldNotUnlock.Value = false;
        Monitor.Enter(lck);
      }
      else
      {
        shouldNotUnlock.Value = true;
      }

      PointF center = new PointF(c.Width/2f, c.Height/2f);
      Lsystem lsys = new Lsystem("F-F-F-F", new Dictionary<char, string>{ { 'F', "F-F+F+FF-F-F+F" } });
      lsys.NthGeneration(gen);
      Turtle t;
      if (baseLineLength == null)
      {
        t = RenderLsystem(c, lsys.Sentence, 90, new Point(1, 0), new Dictionary<char, Color>());
        baseLineLength = t.LineLength;
      }
      else
      {
        t = new Turtle(lsys.Sentence, NewLineLength(time, speed), 90, PointF.Empty, new Point(1, 0), new Dictionary<char, Color>());
        t.TranslateCenter(center);
      }
      PerformDrawing(c, t.DrawInfo);

      if (!shouldNotUnlock.Value)
        Monitor.Exit(lck);
    }

    private static void IslandsAndLakes (Canvas c, int gen, double time, double speed)
    {
      if (baseLineLength == null)
      {
        shouldNotUnlock.Value = false;
        Monitor.Enter(lck);
      }
      else
      {
        shouldNotUnlock.Value = true;
      }

      PointF center = new PointF(c.Width/2f, c.Height/2f);
      Lsystem lsys = new Lsystem("F+F+F+F", new Dictionary<char, string>{ { 'F', "F+f-FF+F+FF+Ff+FF-f+FF-F-FF-Ff-FFF" }, { 'f', "ffffff" } });
      lsys.NthGeneration(gen);
      Turtle t;
      if (baseLineLength == null)
      {
        t = RenderLsystem(c, lsys.Sentence, 90, new Point(1, 0), new Dictionary<char, Color>());
        baseLineLength = t.LineLength;
      }
      else
      {
        t = new Turtle(lsys.Sentence, NewLineLength(time, speed), 90, PointF.Empty, new Point(1, 0), new Dictionary<char, Color>());
        t.TranslateCenter(center);
      }
      PerformDrawing(c, t.DrawInfo);

      if (!shouldNotUnlock.Value)
        Monitor.Exit(lck);
    }

    private static void Tree(Canvas c, int gen, double time, double speed)
    {
      if (baseLineLength == null)
      {
        shouldNotUnlock.Value = false;
        Monitor.Enter(lck);
      }
      else
      {
        shouldNotUnlock.Value = true;
      }

      PointF center = new PointF(c.Width/2f, c.Height/2f);
      Lsystem lsys = new Lsystem("M", new Dictionary<char, string>{ { 'M', "S[+M][-M]SM" }, {'S', "SS"} });
      lsys.NthGeneration(gen);
      Turtle t;
      if (baseLineLength == null)
      {
        t = RenderLsystem(c, lsys.Sentence, 45, new Point(0, -1), new Dictionary<char, Color> { { 'M', Color.DarkGreen }, { 'S', Color.SaddleBrown } });
        baseLineLength = t.LineLength;
      }
      else
      {
        t = new Turtle(lsys.Sentence, NewLineLength(time, speed), 45, PointF.Empty, new Point(0, -1), new Dictionary<char, Color> { { 'M', Color.DarkGreen }, { 'S', Color.SaddleBrown } });
        t.TranslateCenter(center);
      }
      PerformDrawing(c, t.DrawInfo);

      if (!shouldNotUnlock.Value)
        Monitor.Exit(lck);
    }

    private static void BinTree (Canvas c, int gen, double time, double speed)
    {
      if (baseLineLength == null)
      {
        shouldNotUnlock.Value = false;
        Monitor.Enter(lck);
      }
      else
      {
        shouldNotUnlock.Value = true;
      }

      PointF center = new PointF(c.Width/2f, c.Height/2f);
      Lsystem lsys = new Lsystem("F", new Dictionary<char, string>{ { 'F', "G[+F]-F" }, {'G', "GG"} });
      lsys.NthGeneration(gen);
      Turtle t;
      if (baseLineLength == null)
      {
        t = RenderLsystem(c, lsys.Sentence, 45, new Point(0, -1), new Dictionary<char, Color> { { 'F', Color.DarkGreen }, { 'G', Color.SaddleBrown } });
        baseLineLength = t.LineLength;
      }
      else
      {
        t = new Turtle(lsys.Sentence, NewLineLength(time, speed), 45, PointF.Empty, new Point(0, -1), new Dictionary<char, Color> { { 'F', Color.DarkGreen }, { 'G', Color.SaddleBrown } });
        t.TranslateCenter(center);
      }
      PerformDrawing(c, t.DrawInfo);

      if (!shouldNotUnlock.Value)
        Monitor.Exit(lck);
    }

    private static void Fern (Canvas c, int gen, double time, double speed)
    {
      if (baseLineLength == null)
      {
        shouldNotUnlock.Value = false;
        Monitor.Enter(lck);
      }
      else
      {
        shouldNotUnlock.Value = true;
      }

      PointF center = new PointF(c.Width/2f, c.Height/2f);
      Lsystem lsys = new Lsystem("G", new Dictionary<char, string>{ { 'G', "F+[[G]-G]-F[-FG]+G" }, { 'F', "FF" } });
      lsys.NthGeneration(gen);
      Turtle t;
      if (baseLineLength == null)
      {
        t = RenderLsystem(c, lsys.Sentence, 25, new Point(0, -1), new Dictionary<char, Color> { { 'F', Color.DarkGreen }, { 'G', Color.DarkGreen } });
        baseLineLength = t.LineLength;
      }
      else
      {
        t = new Turtle(lsys.Sentence, NewLineLength(time, speed), 25, PointF.Empty, new Point(0, -1), new Dictionary<char, Color> { { 'F', Color.DarkGreen }, { 'G', Color.DarkGreen } });
        t.TranslateCenter(center);
      }
      PerformDrawing(c, t.DrawInfo);

      if (!shouldNotUnlock.Value)
        Monitor.Exit(lck);
    }
    private static void BrokenWindow(Canvas c, int gen, double time, double speed)
    {
      PointF center = new PointF(c.Width/2f, c.Height/2f);
      Lsystem lsys = new Lsystem("F-F-F-F", new Dictionary<char, string>{ { 'F', "FF-F--F-F" } });
      lsys.NthGeneration(gen);
      Turtle t;
      if (baseLineLength == null)
      {
        t = RenderLsystem(c, lsys.Sentence, 90, new Point(0, 1), new Dictionary<char, Color> { { 'F', Color.FromArgb(0, 128, 255) } });
        baseLineLength = t.LineLength;
      }
      else
      {
        t = new Turtle(lsys.Sentence, NewLineLength(time, speed), 90, PointF.Empty, new Point(0, 1), new Dictionary<char, Color> { { 'F', Color.FromArgb(0, 128, 255) } });
        t.TranslateCenter(center);
      }
      PerformDrawing(c, t.DrawInfo);
    }
    private static void Dragon (Canvas c, int gen, double time, double speed)
    {
      PointF center = new PointF(c.Width/2f, c.Height/2f);
      Lsystem lsys = new Lsystem("L", new Dictionary<char, string>{ { 'L', "L+R+" }, {'R', "-L-R"} });
      lsys.NthGeneration(gen);
      Turtle t;
      if (baseLineLength == null)
      {
        t = RenderLsystem(c, lsys.Sentence, 90, new Point(0, 1), new Dictionary<char, Color> { { 'L', Color.DarkOrchid }, { 'R', Color.FromArgb(255, 219, 148) } });
        baseLineLength = t.LineLength;
      }
      else
      {
        t = new Turtle(lsys.Sentence, NewLineLength(time, speed), 90, PointF.Empty, new Point(0, 1), new Dictionary<char, Color> { { 'L', Color.DarkOrchid }, { 'R', Color.FromArgb(255, 219, 148) } });
        t.TranslateCenter(center);
      }
      PerformDrawing(c, t.DrawInfo);
    }
    private static void LevyCCurve (Canvas c, int gen, double time, double speed)
    {
      if (baseLineLength == null)
      {
        shouldNotUnlock.Value = false;
        Monitor.Enter(lck);
      }
      else
      {
        shouldNotUnlock.Value = true;
      }

      PointF center = new PointF(c.Width/2f, c.Height/2f);
      Lsystem lsys = new Lsystem("F", new Dictionary<char, string>{ {'F', "+F--F+"} });
      lsys.NthGeneration(gen);
      Turtle t;
      if (baseLineLength == null)
      {
        t = RenderLsystem(c, lsys.Sentence, 45, new Point(-1, 0), new Dictionary<char, Color>());
        baseLineLength = t.LineLength;
      }
      else
      {
        t = new Turtle(lsys.Sentence, NewLineLength(time, speed), 45, PointF.Empty, new Point(-1, 0), new Dictionary<char, Color>());
        t.TranslateCenter(center);
      }
      PerformDrawing(c, t.DrawInfo);

      if (!shouldNotUnlock.Value)
        Monitor.Exit(lck);
    }

    private static void Pentaplexity (Canvas c, int gen, double time, double speed)
    {
      if (baseLineLength == null)
      {
        shouldNotUnlock.Value = false;
        Monitor.Enter(lck);
      }
      else
      {
        shouldNotUnlock.Value = true;
      }

      PointF center = new PointF(c.Width/2f, c.Height/2f);
      Lsystem lsys = new Lsystem("F++F++F++F++F", new Dictionary<char, string>{ {'F', "F++F++F|F-F++F" } });
      lsys.NthGeneration(gen);
      Turtle t;
      if (baseLineLength == null)
      {
        t = RenderLsystem(c, lsys.Sentence, 36, new Point(1, 0), new Dictionary<char, Color>());
        baseLineLength = t.LineLength;
      }
      else
      {
       
        t = new Turtle(lsys.Sentence, NewLineLength(time, speed), 36, PointF.Empty, new Point(1, 0), new Dictionary<char, Color>{{'F', Color.Yellow}});
        t.TranslateCenter(center);
      }
      PerformDrawing(c, t.DrawInfo);

      if (!shouldNotUnlock.Value)
        Monitor.Exit(lck);
    }

  }


}

