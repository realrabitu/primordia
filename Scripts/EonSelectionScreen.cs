using Godot;
using System;

public partial class EonSelectionScreen : Control
{
	private TextureButton HomeButton;
	private Control PanelsContainer;
	private Panel LeftPanel;
	private Panel CenterPanel;
	private Panel RightPanel;
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		HomeButton = GetNode<TextureButton>("HomeButton");
		PanelsContainer = GetNode<Control>("ScreensContainer");
		LeftPanel = PanelsContainer.GetNode<Panel>("LPanel");
		CenterPanel = PanelsContainer.GetNode<Panel>("CenterPanel");
		RightPanel = PanelsContainer.GetNode<Panel>("RPanel");
		// Set up panels side by side inside the container
		LeftPanel.Size = new Vector2(480, 1080);
		CenterPanel.Size = new Vector2(960, 1080);
		RightPanel.Size = new Vector2(480, 1080);
		LeftPanel.Position = new Vector2(0, 0);
		CenterPanel.Position = new Vector2(480, 0);
		RightPanel.Position = new Vector2(1440, 0);
		// Set PanelsContainer size to fit all panels
		PanelsContainer.Size = new Vector2(1920, 1080);
		PanelsContainer.Position = new Vector2(0, 0);
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{

	}
	// Call this method to start the transition to the Phanerozoic screen
	void SwitchToPhanerozoic()
	{
		var tween = CreateTween();
		// Animate PanelsContainer to slide left (example: 1920px for a full screen slide)
		tween.TweenProperty(LeftPanel, "position", new Vector2(-1920, 0), 0.5f)
			.SetTrans(Tween.TransitionType.Sine)
			.SetEase(Tween.EaseType.InOut);
	}
	// Call this method to start the transition back to the Precambrian screen
	void SwitchToPrecambrian()
	{
		var tween = CreateTween();
		// Animate PanelsContainer to slide right (back to start)
		tween.TweenProperty(PanelsContainer, "position", new Vector2(0, 0), 0.5f)
			.SetTrans(Tween.TransitionType.Sine)
			.SetEase(Tween.EaseType.InOut);
	}

	void OnHomeButtonPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/main_menu.tscn");
	}
	void OnPhanerozoicPlayPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/EraSelectionScreen.tscn");
	}
}
