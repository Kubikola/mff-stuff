using System.Collections.Generic;
using System.Text;

namespace JakubLevy
{
  class Lsystem
  {
    public Lsystem (string axiom, Dictionary<char, string> rules = null)
    {
      Axiom = axiom;
      Sentence = axiom;
      Generation = 0;
      Rules = rules ?? new Dictionary<char, string>();
    }

    public string Axiom { get; }
    public string Sentence { get; private set; }
    public Dictionary<char, string> Rules { get; set; }
    public int Generation { get; private set; }

    /// <summary>
    ///   Generates the next generation, the user is responsible for properly defined rules
    /// </summary>
    public void NextGeneration ()
    {
      StringBuilder sb = new StringBuilder();
      for (int i = 0; i < Sentence.Length; ++i)
      {
        if (!IsNotMovingChar(Sentence[i]))
        {
          if (Rules.ContainsKey(Sentence[i]))
          {
            sb.Append(Rules[Sentence[i]]);
          }
          else
          {
            throw new KeyNotFoundException($"Missing rule for {Sentence[i]}");
          }
        }
        else
        {
          sb.Append(Sentence[i]);
        }
      }

      Sentence = sb.ToString();
      ++Generation;
    }

    public static bool IsNotMovingChar (char c)
    {
      return c == '+' || c == '-' || c == '[' || c == ']' || c == '|';
    }

    /// <summary>
    ///   Calculates the desired generation does nothing when Generation == generation
    /// </summary>
    /// <param name="generation"></param>
    public void NthGeneration (int generation)
    {
      if (generation > Generation)
      {
        for (int i = Generation; i < generation; ++i)
        {
          NextGeneration();
        }
      }
      else if (generation < Generation)
      {
        Generation = 0;
        Sentence = Axiom;
        NthGeneration(generation);
      }
    }
  }
}
