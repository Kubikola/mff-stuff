using System;
using System.Collections.Generic;
using System.Drawing;

namespace JakubLevy
{
  class Turtle : IDisposable
  {
    /// <summary>
    ///   Constructor for Turtle class
    /// </summary>
    /// <param name="sentence"> drawing grammar </param>
    /// <param name="lineLength"> length of the drawing line </param>
    /// <param name="rotationAngle"> determines the rotation amount when + or - </param>
    /// <param name="startingPoint">the starting location to draw</param>
    /// <param name="directionPoint"> (1,0) means "right", (-1, 0) means left, (0,1) means down, (0,-1) means up </param>
    /// <param name="colors"> associated colors with moving letter </param>
    public Turtle (string sentence, float lineLength, float rotationAngle, PointF startingPoint,
      Point directionPoint, Dictionary<char, Color> colors)
    {
      Sentence = sentence;
      LineLength = lineLength;
      RotationAngle = rotationAngle;
      StartingPoint = startingPoint;
      DirectionPoint = directionPoint;
      Colors = colors;
      Render();
    }

    public string Sentence { get; }
    public float LineLength { get; }
    public float RotationAngle { get; }
    public PointF StartingPoint { get; }

    public Point DirectionPoint { get; }

    public Dictionary<char, Color> Colors { get; }

    public List<DrawInfo> DrawInfo { get; } = new List<DrawInfo>(); //all information needed to redraw a fractal

    private float top = int.MaxValue;
    private float bottom = int.MinValue;
    private float left  = int.MaxValue;
    private float right  = int.MinValue;

    public float Width => right - left;
    public float Height => bottom - top;

    public float Size => Math.Max(Width, Height);

    /// <summary>
    ///   Disconnects the panel from Turtle and releases memory
    /// </summary>
    public void Dispose ()
    {
      Colors.Clear();
      DrawInfo.Clear();
    }

    public void TranslateCenter (PointF center)
    {
      float shiftX = center.X - Width / 2f - left;
      float shiftY = center.Y - Height / 2f - top;
      PointF shift = new PointF(shiftX, shiftY);
      DrawInfo.ForEach(x =>
      {
        x.Start = Utils.AddVectors(x.Start, shift);
        x.End = Utils.AddVectors(x.End, shift);
      });
    }

    private void Render ()
    {
      State currentState = new State {Location = StartingPoint, CurrentAngle = 0};
      Stack<State> states = new Stack<State>();
      for (int i = 0; i < Sentence.Length; ++i)
      {
        if (Lsystem.IsNotMovingChar(Sentence[i]))
        {
          switch (Sentence[i])
          {
            case '+':
              currentState.CurrentAngle += RotationAngle;
              break;
            case '-':
              currentState.CurrentAngle -= RotationAngle;
              break;
            case '[':
              states.Push(currentState);
              break;
            case '|':
              currentState.CurrentAngle = currentState.CurrentAngle >= 180 ? currentState.CurrentAngle - 180 : currentState.CurrentAngle + 180;
              break;
            case ']':
              if (states.Count > 0)
              {
                currentState = states.Pop();
              }
              else
              {
                Utils.ShowErrorMessageBox("Bad grammar");
                return;
              }

              break;
          }
        }
        else
        {
          //moving
          PointF shift = Utils.ScaleVector(Utils.RotateVector(DirectionPoint, currentState.CurrentAngle), LineLength);
          if (char.IsLower(Sentence[i]))
          {
            currentState.Location = Utils.AddVectors(currentState.Location, shift);
          }
          else //drawing 
          {
            Color c = Color.Black;
            if (Colors.ContainsKey(Sentence[i]))
            {
              c = Colors[Sentence[i]];
            }

            PointF newLocation = Utils.AddVectors(currentState.Location, shift);
            Pen p = new Pen(c);

            DrawInfo.Add(new DrawInfo {Start = currentState.Location, End = newLocation, Pen = p});
            currentState.Location = newLocation;

            if (currentState.Location.X < left)
            {
              left = currentState.Location.X;
            }

            if (currentState.Location.X > right)
            {
              right = currentState.Location.X;
            }

            if (currentState.Location.Y < top)
            {
              top = currentState.Location.Y;
            }

            if (currentState.Location.Y > bottom)
            {
              bottom = currentState.Location.Y;
            }
          }
        }
      }
    }
  }

  //[Serializable]
  struct State
  {
    public PointF Location { get; set; }
    public float CurrentAngle { get; set; }
  }

  class DrawInfo
  {
    public PointF Start { get; set; }
    public PointF End { get; set; }
    public Pen Pen { get; set; }
  }
}
