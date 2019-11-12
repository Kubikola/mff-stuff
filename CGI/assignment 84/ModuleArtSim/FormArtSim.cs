using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using _117raster.ModuleArtSim;

namespace Modules
{
  public partial class FormArtSim : Form
  {
    /// <summary>
    /// Associated raster module (to be notified under various conditions).
    /// </summary>
    protected IRasterModule module;

    /// <summary>
    /// If true, any of the values was changed and needs to by send to the module.
    /// </summary>
    protected bool dirty = true;

    private Params config = new Params {K = 20, ColorFromClusterCount = 3, Iterations = 35};

    public FormArtSim (IRasterModule hModule)
    {
      module = hModule;
      InitializeComponent();

      paramsPropertyGrid.SelectedObject = config;
    }

    private void buttonRecompute_Click (object sender, EventArgs e)
    {
      if (module == null)
        return;

      if (dirty)
      {
        module.OnGuiWindowChanged();
        dirty = false;
      }

      module.UpdateRequest?.Invoke(module);
    }

    private void buttonReset_Click (object sender, EventArgs e)
    {
      //TODO: reset values

      paramsPropertyGrid.SelectedObject = new Params {K = 20, ColorFromClusterCount = 3, Iterations = 35};

      module?.OnGuiWindowChanged();
      dirty = false;
    }

    private void buttonDeactivate_Click (object sender, EventArgs e)
    {
      if (module != null)
      {
        if (dirty)
          module.OnGuiWindowChanged();

        module.DeactivateRequest?.Invoke(module);
      }
    }

    private void FormHSV_FormClosed (object sender, FormClosedEventArgs e)
    {
      if (module != null)
      {
        if (dirty)
          module.OnGuiWindowChanged();

        module.OnGuiWindowClose();
      }
    }
  }
}
