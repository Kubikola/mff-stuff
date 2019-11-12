namespace Modules
{
  partial class FormArtSim
  {
    /// <summary>
    /// Required designer variable.
    /// </summary>
    private System.ComponentModel.IContainer components = null;

    /// <summary>
    /// Clean up any resources being used.
    /// </summary>
    /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
    protected override void Dispose (bool disposing)
    {
      if (disposing && (components != null))
      {
        components.Dispose();
      }
      base.Dispose(disposing);
    }

    #region Windows Form Designer generated code

    /// <summary>
    /// Required method for Designer support - do not modify
    /// the contents of this method with the code editor.
    /// </summary>
    private void InitializeComponent ()
    {
            this.buttonRecompute = new System.Windows.Forms.Button();
            this.buttonDeactivate = new System.Windows.Forms.Button();
            this.buttonReset = new System.Windows.Forms.Button();
            this.paramsPropertyGrid = new System.Windows.Forms.PropertyGrid();
            this.SuspendLayout();
            // 
            // buttonRecompute
            // 
            this.buttonRecompute.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.buttonRecompute.Location = new System.Drawing.Point(12, 178);
            this.buttonRecompute.Name = "buttonRecompute";
            this.buttonRecompute.Size = new System.Drawing.Size(147, 23);
            this.buttonRecompute.TabIndex = 11;
            this.buttonRecompute.Text = "Recompute";
            this.buttonRecompute.UseVisualStyleBackColor = true;
            this.buttonRecompute.Click += new System.EventHandler(this.buttonRecompute_Click);
            // 
            // buttonDeactivate
            // 
            this.buttonDeactivate.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.buttonDeactivate.Location = new System.Drawing.Point(165, 178);
            this.buttonDeactivate.Name = "buttonDeactivate";
            this.buttonDeactivate.Size = new System.Drawing.Size(109, 23);
            this.buttonDeactivate.TabIndex = 12;
            this.buttonDeactivate.Text = "Deactivate module";
            this.buttonDeactivate.UseVisualStyleBackColor = true;
            this.buttonDeactivate.Click += new System.EventHandler(this.buttonDeactivate_Click);
            // 
            // buttonReset
            // 
            this.buttonReset.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.buttonReset.Location = new System.Drawing.Point(291, 178);
            this.buttonReset.Name = "buttonReset";
            this.buttonReset.Size = new System.Drawing.Size(87, 23);
            this.buttonReset.TabIndex = 2;
            this.buttonReset.Text = "Reset values";
            this.buttonReset.UseVisualStyleBackColor = true;
            this.buttonReset.Click += new System.EventHandler(this.buttonReset_Click);
            // 
            // paramsPropertyGrid
            // 
            this.paramsPropertyGrid.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.paramsPropertyGrid.Location = new System.Drawing.Point(12, 17);
            this.paramsPropertyGrid.Name = "paramsPropertyGrid";
            this.paramsPropertyGrid.PropertySort = System.Windows.Forms.PropertySort.NoSort;
            this.paramsPropertyGrid.Size = new System.Drawing.Size(366, 155);
            this.paramsPropertyGrid.TabIndex = 13;
            // 
            // FormArtSim
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(390, 212);
            this.Controls.Add(this.paramsPropertyGrid);
            this.Controls.Add(this.buttonReset);
            this.Controls.Add(this.buttonDeactivate);
            this.Controls.Add(this.buttonRecompute);
            this.MinimizeBox = false;
            this.Name = "FormArtSim";
            this.Text = "Module HSV";
            this.FormClosed += new System.Windows.Forms.FormClosedEventHandler(this.FormHSV_FormClosed);
            this.ResumeLayout(false);

    }

    #endregion

    private System.Windows.Forms.Button buttonRecompute;
    private System.Windows.Forms.Button buttonDeactivate;
    private System.Windows.Forms.Button buttonReset;
    public System.Windows.Forms.PropertyGrid paramsPropertyGrid;
  }
}
