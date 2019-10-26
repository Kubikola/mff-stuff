using MathSupport;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Drawing.Imaging;
using System.Globalization;
using System.Threading.Tasks;
using _117raster.PelikanHSV;
using Utilities;

namespace Modules
{
  public class Param
  {
    [DisplayName("Tolerance")]
    [Description("Maximum pixel metric value for scaling hue angle with \"Hue scale coeff\"")]
    public double MetricTolerance
    {
      get => metricTolerance.FixedValue(0, 9999999999);
      set => metricTolerance = value.FixedValue(0, 9999999999);
    }

    private double metricTolerance = 8;

    private double hueMaxShiftCoeff = 1;

    [DisplayName("Hue scale coeff")]

    [Description("Coefficient to multiply hue when pixel metric == \"Tolerance\".\nFor lower metric values scaled evenly.\nThis does not affect higher metric values.")]
    public double HueMaxShiftCoeff
    {
      get => hueMaxShiftCoeff.FixedValue(0, 1);
      set => hueMaxShiftCoeff = value.FixedValue(0, 1);
    }

    [DisplayName("Hue LB")]
    [Description("Lower bound for skin hues")]
    public double HueLB { get => hueLB; set => hueLB = value; }

    private double hueLB = 342;

    [DisplayName("Hue UB")]
    [Description("Upper bound for skin hues")]
    public double HueUB
    {
      get => hueUB;
      set => hueUB = value;
    }

    private double hueUB = 22;

    [DisplayName("Saturation LB")]
    [Description("Lower bound for skin saturation")]
    public double SatLB { get => satLB.FixedValue(0, 1); set => satLB = value.FixedValue(0, 1); }
    private double satLB = 0.03921568627;

    [DisplayName("Saturation UB")]
    [Description("Upper bound for skin saturation")]
    public double SatUB
    {
      get => satUB.FixedValue(0, 1);
      set => satUB = value.FixedValue(0, 1);
    }
    private double satUB = 0.58823529411;


    [DisplayName("Value LB")]
    [Description("Lower bound for skin values")]
    public double ValLB { get => valLB.FixedValue(0, 1); set => valLB = value.FixedValue(0, 1); }
    private double valLB = 0.23529411764;


    [DisplayName("Value UB")]
    [Description("Upper bound for skin values")]
    public double ValUB { get => valUB.FixedValue(0, 1); set => valUB = value.FixedValue(0, 1); }
    private double valUB = 1;
  }

  public struct Point3D
  {
    public double X { get; set; }
    public double Y { get; set; }
    public double Z { get; set; }

    public Point3D (double x, double y, double z)
    {
      X = x;
      Y = y;
      Z = z;
    }
    public static Point3D Empty => new Point3D(0, 0, 0);

    public static bool operator == (Point3D pt1, Point3D pt2)
    {
      const double TOL = 0.001;
      return Math.Abs(pt1.X - pt2.X) < TOL && Math.Abs(pt1.Y - pt2.Y) < TOL && Math.Abs(pt1.Z - pt2.Z) < TOL;
    }
    public override bool Equals (object obj)
    {
      if (obj != null)
      {
        return GetHashCode() == obj.GetHashCode();
      }

      return false;
    }

    public bool Equals (Point3D other)
    {
      return X.Equals(other.X) && Y.Equals(other.Y) && Z.Equals(other.Z);
    }

    public override int GetHashCode ()
    {
      unchecked
      {
        int hashCode = X.GetHashCode();
        hashCode = (hashCode * 397) ^ Y.GetHashCode();
        hashCode = (hashCode * 397) ^ Z.GetHashCode();
        return hashCode;
      }
    }

    public static bool operator != (Point3D pt1, Point3D pt2)
    {
      return !(pt1 == pt2);
    }

    public double Length => Math.Sqrt(X * X + Y * Y + Z * Z);
  }
  public class OmezenePrebarveni : DefaultRasterModule
  {
    /// <summary>
    /// Mandatory plain constructor.
    /// </summary>
    public OmezenePrebarveni ()
    {
    }

    /// <summary>
    /// Author's full name.
    /// </summary>
    public override string Author => "LevyJakub";

    /// <summary>
    /// Name of the module (short enough to fit inside a list-boxes, etc.).
    /// </summary>
    public override string Name => "OmezenePrebarveni";

    /// <summary>
    /// Tooltip for Param (text parameters).
    /// </summary>
    public override string Tooltip => "[dH=<double>][,mulS=<double>][,mulV=<double>][,gamma=<double>][,slow][,par]\n... dH is absolute, mS, mV, dGamma relative";

    /// <summary>
    /// Default HSV transform parameters (have to by in sync with the default module state).
    /// </summary>
    protected string param = "mulS=1.4,par";

    /// <summary>
    /// True if 'param' has to be parsed in the next recompute() call.
    /// </summary>
    protected bool paramDirty = true;

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
          paramDirty = true;
          recompute();
        }
      }
    }

    public static Param MyParams { get; set; } = new Param();

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
    /// Absolute Hue delta in degrees.
    /// </summary>
    protected double dH = 200.0;

    /// <summary>
    /// Saturation multiplier.
    /// </summary>
    protected double mS = 1.0;

    /// <summary>
    /// Value multiplier.
    /// </summary>
    protected double mV = 1.0;

    /// <summary>
    /// Gamma-correction coefficient (visible value = inverse value).
    /// </summary>
    protected double gamma = 1.0;

    /// <summary>
    /// Do we ignore skin or not
    /// </summary>
    protected bool ignoreSkin = false;

    /// <summary>
    /// Slow computation (using GetPixel/SetPixel).
    /// </summary>
    protected bool slow = false;

    /// <summary>
    /// Parallel computation (most useful for large pictures).
    /// </summary>
    protected bool parallel = true;

    /// <summary>
    /// Active HSV form.
    /// </summary>
    protected FormHSV hsvForm = null;

    protected void updateParam ()
    {
      if (paramDirty)
      {
        paramDirty = false;

        // 'param' parsing.
        Dictionary<string, string> p = Util.ParseKeyValueList(param);
        if (p.Count > 0)
        {
          // dH=<double> [+- number in degrees]
          Util.TryParse(p, "dH", ref dH);

          // mulS=<double> [relative number .. multiplicator]
          Util.TryParse(p, "mulS", ref mS);

          // mulV=<double> [relative number .. multiplicator]
          Util.TryParse(p, "mulV", ref mV);

          // gamma=<double> [gamma correction .. exponent]
          if (Util.TryParse(p, "gamma", ref gamma))
          {
            // <= 0.0 || 1.0.. nothing
            if (gamma < 0.001)
            {
              gamma = 1.0;
            }
          }

          // par .. use Parallel.For
          parallel = p.ContainsKey("par");

          // slow .. set GetPixel/SetPixel computation
          slow = p.ContainsKey("slow");
        }
      }

      formUpdate();
    }

    public static double MathMod (double a, int b)
    {
      if (a >= 0)
      {
        return a % b;
      }
      double abs = Math.Abs(a);

      if (abs < b)
      {
        return b + a;
      }

      return Math.Ceiling(abs / b) + a;
    }



    public static double ConvertRange (double originalStart, double originalEnd, double newStart, double newEnd, double value)
    {
      double scale = (newEnd - newStart) / (originalEnd - originalStart);
      return newStart + (value - originalStart) * scale;
    }


    private Point3D SkinColor (double h, double s, double v)
    {
      double hueLB = MyParams.HueLB;
      double hueUB = MyParams.HueUB;
      double satLB = MyParams.SatLB;
      double satUB = MyParams.SatUB;
      double valLB = MyParams.ValLB;
      double valUB = MyParams.ValUB;

      bool cHue = hueLB > hueUB ? (h >= hueLB || h <= hueUB) : (h >= hueLB && h <= hueUB);
      bool isSkinColor = cHue && s >= satLB && s <= satUB && v >= valLB && v <= valUB;
      if (isSkinColor)
      {
        return Point3D.Empty;
      }


      double d1 = Math.Min(MathMod(MyParams.HueLB - h, 360), MathMod(h - MyParams.HueLB, 360));
      double d2 = Math.Min(MathMod(MyParams.HueUB - h, 360), MathMod(h - MyParams.HueUB, 360));
      double hueD = Math.Min(d1, d2);
      double satD = Math.Min(Math.Abs(s - MyParams.SatLB), Math.Abs(s - MyParams.SatUB));
      double valD = Math.Min(Math.Abs(v - MyParams.ValLB), Math.Abs(v - MyParams.ValUB));

      //max 360      max 100      max 100
      return new Point3D(hueD, satD * 100, valD * 100);
    }

    /// <summary>
    /// Recompute the image.
    /// </summary>
    protected void recompute ()
    {
      if (inImage == null)
      {
        return;
      }

      // Update module values from 'param' string.
      updateParam();

      int wid = inImage.Width;
      int hei = inImage.Height;

      // Output image must be true-color.
      outImage = new Bitmap(wid, hei, PixelFormat.Format24bppRgb);

      // Convert pixel data.
      double gam = gamma < 0.001 ? 1.0 : 1.0 / gamma;

      if (slow)
      {
        // Slow GetPixel/SetPixel code.

        for (int y = 0; y < hei; y++)
        {
          // !!! TODO: Interrupt handling.
          double R, G, B;
          double H, S, V;

          for (int x = 0; x < wid; x++)
          {

            Color ic = inImage.GetPixel(x, y);

            // Conversion to HSV.
            Arith.ColorToHSV(ic, out H, out S, out V);
            // 0 <= H <= 360, 0 <= S <= 1, 0 <= V <= 1

            // HSV transform.
            //  if (!(H >= 340 || H <= 35))

            HueTransformation(ref H, S, V);

            S = Util.Clamp(S * mS, 0.0, 1.0);
            V = Util.Clamp(V * mV, 0.0, 1.0);

            // Conversion back to RGB.
            Arith.HSVToRGB(H, S, V, out R, out G, out B);
            // [R,G,B] is from [0.0, 1.0]^3

            // Optional gamma correction.
            if (gam != 1.0)
            {
              // Gamma-correction.
              R = Math.Pow(R, gam);
              G = Math.Pow(G, gam);
              B = Math.Pow(B, gam);
            }

            Color oc = Color.FromArgb(
            Convert.ToInt32(Util.Clamp(R * 255.0, 0.0, 255.0)),
            Convert.ToInt32(Util.Clamp(G * 255.0, 0.0, 255.0)),
            Convert.ToInt32(Util.Clamp(B * 255.0, 0.0, 255.0)));

            outImage.SetPixel(x, y, oc);
          }
        }
      }
      else
      {
        // Fast memory-mapped code.
        PixelFormat iFormat = inImage.PixelFormat;
        if (!PixelFormat.Format24bppRgb.Equals(iFormat) &&
            !PixelFormat.Format32bppArgb.Equals(iFormat) &&
            !PixelFormat.Format32bppPArgb.Equals(iFormat) &&
            !PixelFormat.Format32bppRgb.Equals(iFormat))
        {
          iFormat = PixelFormat.Format24bppRgb;
        }

        BitmapData dataIn  = inImage.LockBits(new Rectangle(0, 0, wid, hei), ImageLockMode.ReadOnly, iFormat);
        BitmapData dataOut = outImage.LockBits(new Rectangle(0, 0, wid, hei), ImageLockMode.WriteOnly, PixelFormat.Format24bppRgb);
        unsafe
        {
          int dI = Image.GetPixelFormatSize(iFormat) / 8;
          int dO = Image.GetPixelFormatSize(PixelFormat.Format24bppRgb) / 8;

          Action<int> inner = y =>
          {
            // !!! TODO: Interrupt handling.
            double R, G, B;
            double H, S, V;

            byte* iptr = (byte*)dataIn.Scan0  + y * dataIn.Stride;
            byte* optr = (byte*)dataOut.Scan0 + y * dataOut.Stride;

            for (int x = 0; x < wid; x++, iptr += dI, optr += dO)
            {
              // Recompute one pixel (*iptr -> *optr).
              // iptr, optr -> [B,G,R]

              // Conversion to HSV.
              Arith.RGBtoHSV(iptr[2] / 255.0, iptr[1] / 255.0, iptr[0] / 255.0, out H, out S, out V);
              // 0 <= H <= 360, 0 <= S <= 1, 0 <= V <= 1

              // HSV transform.
              HueTransformation(ref H, S, V);

              S = Util.Clamp(S * mS, 0.0, 1.0);
              V = Util.Clamp(V * mV, 0.0, 1.0);

              // Conversion back to RGB.
              Arith.HSVToRGB(H, S, V, out R, out G, out B);
              // [R,G,B] is from [0.0, 1.0]^3

              // Optional gamma correction.
              if (Math.Abs(gam - 1.0) > 0.001)
              {
                // Gamma-correction.
                R = Math.Pow(R, gam);
                G = Math.Pow(G, gam);
                B = Math.Pow(B, gam);
              }

              optr[0] = Convert.ToByte(Util.Clamp(B * 255.0, 0.0, 255.0));
              optr[1] = Convert.ToByte(Util.Clamp(G * 255.0, 0.0, 255.0));
              optr[2] = Convert.ToByte(Util.Clamp(R * 255.0, 0.0, 255.0));
            }
          };

          if (parallel)
          {
            Parallel.For(0, hei, inner);
          }
          else
          {
            for (int y = 0; y < hei; y++)
            {
              inner(y);
            }
          }
        }

        outImage.UnlockBits(dataOut);
        inImage.UnlockBits(dataIn);
      }
    }

    private void HueTransformation (ref double H, double S, double V)
    {
      if (ignoreSkin)
      {
        H += dH;
        return;
      }

      Point3D metric = SkinColor(H, S, V);
      if (metric != Point3D.Empty)
      {
        if (metric.Length < MyParams.MetricTolerance)
        {
          double c = ConvertRange(0, MyParams.MetricTolerance, 0, MyParams.HueMaxShiftCoeff, metric.X);
          H += dH * c;
        }
        else
        {
          H = H + dH;
        }
      }
    }

    /// <summary>
    /// Send ModuleHSV values to the form elements.
    /// </summary>
    protected void formUpdate ()
    {
      if (hsvForm == null)
      {
        return;
      }

      hsvForm.numericHue.Value = Convert.ToDecimal(dH);
      hsvForm.textSaturation.Text = string.Format(CultureInfo.InvariantCulture, "{0:g5}", mS);
      hsvForm.textValue.Text = string.Format(CultureInfo.InvariantCulture, "{0:g5}", mV);
      hsvForm.textGamma.Text = string.Format(CultureInfo.InvariantCulture, "{0:g5}", gamma);
      hsvForm.checkParallel.Checked = parallel;
      hsvForm.checkSlow.Checked = slow;
      hsvForm.ignoreSkinChckBox.Checked = ignoreSkin;

      hsvForm.Invalidate();
    }

    /// <summary>
    /// Notification: GUI window changed its values (sync GUI -> module is needed).
    /// </summary>
    public override void OnGuiWindowChanged ()
    {
      if (hsvForm == null)
      {
        return;
      }

      dH = Convert.ToDouble(hsvForm.numericHue.Value);
      if (!double.TryParse(hsvForm.textSaturation.Text, NumberStyles.Number, CultureInfo.InvariantCulture, out mS))
      {
        mS = 1.0;
      }

      if (!double.TryParse(hsvForm.textValue.Text, NumberStyles.Number, CultureInfo.InvariantCulture, out mV))
      {
        mV = 1.0;
      }

      if (!double.TryParse(hsvForm.textGamma.Text, NumberStyles.Number, CultureInfo.InvariantCulture, out gamma))
      {
        gamma = 1.0;
      }

      parallel = hsvForm.checkParallel.Checked;
      slow = hsvForm.checkSlow.Checked;
      ignoreSkin = hsvForm.ignoreSkinChckBox.Checked;

      // Update 'param'.
      List<string> pars = new List<string>();

      if (dH != 0.0)
      {
        pars.Add(string.Format(CultureInfo.InvariantCulture, "dH={0:g}", dH));
      }

      if (mS != 1.0)
      {
        pars.Add(string.Format(CultureInfo.InvariantCulture, "mulS={0:g5}", mS));
      }

      if (mV != 1.0)
      {
        pars.Add(string.Format(CultureInfo.InvariantCulture, "mulV={0:g5}", mV));
      }

      if (gamma != 1.0)
      {
        pars.Add(string.Format(CultureInfo.InvariantCulture, "gamma={0:g5}", gamma));
      }

      if (parallel)
      {
        pars.Add("par");
      }

      if (slow)
      {
        pars.Add("slow");
      }

      param = string.Join(",", pars);
      paramDirty = false;

      ParamUpdated?.Invoke(this);
    }

    /// <summary>
    /// Notification: GUI window has been closed.
    /// </summary>
    public override void OnGuiWindowClose ()
    {
      hsvForm?.Hide();
      hsvForm = null;
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
    public override void Update () => recompute();

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
      get => hsvForm != null;
      set
      {
        if (value)
        {
          // Show GUI window.
          if (hsvForm == null)
          {
            hsvForm = new FormHSV(this);
            formUpdate();
            hsvForm.Show();
          }
        }
        else
        {
          hsvForm?.Hide();
          hsvForm = null;
        }
      }
    }
  }
}
