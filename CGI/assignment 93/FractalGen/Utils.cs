using System;
using System.Drawing;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using System.Windows.Forms;

namespace JakubLevy
{
  public static class Utils
  {
    public static void ShowErrorMessageBox (string message)
    {
      MessageBox.Show(message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
    }

    public static PointF ScaleVector (PointF p, double n)
    {
      return new PointF((float)(p.X * n), (float)(p.Y * n));
    }

    public static PointF AddVectors (PointF p1, PointF p2)
    {
      return new PointF(p1.X + p2.X, p1.Y + p2.Y);
    }

    public static PointF RotateVector (Point direction, double rotationAngleD)
    {
      double rotationAngleRad = rotationAngleD * Math.PI / 180.0;
      PointF rotatedDirection =
        new PointF((float)(direction.X * Math.Cos(rotationAngleRad) + direction.Y * Math.Sin(rotationAngleRad)),
          (float)(-direction.X * Math.Sin(rotationAngleRad) + direction.Y * Math.Cos(rotationAngleRad)));
      return rotatedDirection;
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
  }
}
