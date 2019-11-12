using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Windows.Forms.Design;

namespace _117raster.ModuleArtSim
{
  class Utils
  {
    public static double ColorDistance (Color c1, Color c2)
    {
      return Math.Sqrt((c2.R - c1.R) * 0.3 * ((c2.R - c1.R) * 0.3) + ((c2.G - c1.G) * 0.59) * ((c2.G - c1.G) * 0.59) + ((c2.B - c1.B) * 0.11) * ((c2.B - c1.B) * 0.11));
      //double l1 = Math.Sqrt(c1.R * c1.R + c1.G * c1.G + c1.B * c1.B);
      //double l2 = Math.Sqrt(c2.R * c2.R + c2.G * c2.G + c2.B * c2.B);
      //return Math.Abs(l1 - l2);
    }

    public static Color RandomColor ()
    {
      Random rnd =new Random();
      return Color.FromArgb(rnd.Next(0, 256), rnd.Next(0, 256), rnd.Next(0, 256));
    }

                  //key                                 x_j                                    
    private static Color NearestCentroid (Color c, Dictionary<Color, List<Color>> clusters)
    {
      Color nearestCentroid = clusters.Keys.First();
      double nearestDistance = ColorDistance(c, nearestCentroid);
      foreach (var cluster in clusters)
      {
        Color centroid = cluster.Key;
        double newDistance = ColorDistance(c, centroid);
        if (newDistance < nearestDistance)
        {
          nearestCentroid = centroid;
          nearestDistance = newDistance;
        }
      }

      return nearestCentroid;
    }

    public static Dictionary<Color, List<Color>> KMeans (int k, List<Color> colors, int iterations)
    {
      Dictionary<Color, List<Color>> clusters = new Dictionary<Color, List<Color>>();
      for (int i = 0; i < k; ++i)
      {
        Color centroid = RandomColor();
        while (clusters.ContainsKey(centroid))
        {
          centroid = RandomColor();
        }

        clusters.Add(RandomColor(), new List<Color>());

        
      }


      for (int i = 0; i < iterations; ++i)
      {
        for (int j = 0; j < colors.Count; ++j)
        {
          Color nearestCentroid = NearestCentroid(colors[j], clusters);
          clusters[nearestCentroid].Add(colors[j]);
        }

        if (i + 1 == iterations)
        {
          return clusters;

        }

        Dictionary<Color, List<Color>> newClusters = new Dictionary<Color, List<Color>>();
        foreach (var cluster in clusters)
        {
          List<Color> xjs = cluster.Value;
          Color newCentroid = xjs.Any() ? AverageColor(xjs) : RandomColor();
          while (newClusters.ContainsKey(newCentroid))
          {
            newCentroid = RandomColor();
          }
          newClusters[newCentroid] = new List<Color>();
          //newClusters[newCentroid] = xjs;
        }

        clusters = newClusters;
      }

      return clusters;
    }

    private static Color AverageColor (List<Color> xjs)
    {
      double r = 0, g = 0, b = 0;
      for (int i = 0; i < xjs.Count; ++i)
      {
        r += xjs[i].R;
        g += xjs[i].G;
        b += xjs[i].B;
      }
      return Color.FromArgb((int)(r / xjs.Count), (int)(g / xjs.Count), (int)(b / xjs.Count));
    }

    public static List<Color> ExtractColors (Dictionary<Color, List<Color>> clusters, int colorFromClusterCount)
    {
      List<Color> output = new List<Color>();
      foreach (var cluster in clusters)
      {
        output.Add(cluster.Key);
        if (colorFromClusterCount >= cluster.Value.Count)
        {
          output.AddRange(cluster.Value);
        }
        else
        {
          HashSet<int> addedIdxs = new HashSet<int>();
          Random rnd = new Random();
          while (addedIdxs.Count < colorFromClusterCount)
          {
            int idx = rnd.Next(0, cluster.Value.Count);
            while (addedIdxs.Contains(idx))
            {
              idx = rnd.Next(0, cluster.Value.Count);
            }

            addedIdxs.Add(idx);
            output.Add(clusters[cluster.Key][idx]);
          }
        }
      }

      return output;
    }

    public static List<double> Softmin (Color original, List<Color> usableColors)
    {
      List<double> distances = new List<double>();
      for (int i = 0; i < usableColors.Count; ++i)
      {
        distances.Add(-ColorDistance(original, usableColors[i]));
      }
      List<double> exponents = new List<double>();
      double sum = 0;
      for (int i = 0; i < distances.Count; ++i)
      {
        exponents.Add(Math.Pow(Math.E, distances[i]));
        sum += exponents.Last();
      }
      List<double> ret = new List<double>();
      for(int i =0; i < distances.Count; ++i)
      {
        ret.Add(exponents[i] / sum);
      }

      for (int i = 0; i < distances.Count; ++i)
      {
        

        //}
        //else if (ret[i] > 0.5)
        //{
        //  Inc(0.1, ret);
        //  ret[i] -= 0.05;
        //}
      }

      return ret;
    }

    private static void Inc (double v, List<double> vals)
    {
      for (int i = 0; i < vals.Count; ++i)
      {
        vals[i] += v;
      }
    }

    public static int GenRandom (List<double> distribution)
    {
      Random rnd = new Random();
      double rndN = rnd.NextDouble();

      double acc = 0;
      for (int i = 0; i < distribution.Count; ++i)
      {
        if (rndN >= acc && rndN <= acc + distribution[i])
        {
          return i;
        }
        acc += distribution[i];
      }

      return distribution.Count - 1;
    }
  }
  class Params
  {
    [Description("k-means k parameter")]
    public int K { get; set; }

    [DisplayName("# colors from cluster")]
    [Description("Number of colors to take from a single cluster")]
    public int ColorFromClusterCount { get; set; }


    [DisplayName("# K-means iter")]
    [Description("Number of K-means iterations to run")]
    public int Iterations { get; set; }

    [DisplayName("# pixels grouped")]
    [Description("Number of pixels that should be grouped together")]
    public int PixelSize { get; set; }
  }
}
