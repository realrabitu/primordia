using Godot;
using System;

public partial class EraSelectionScreen : Control
{
	private TextureButton HomeButton;
	private Control PanelsContainer;
	private Panel LeftPanel;
	private Panel CenterPanel;
	private Panel RightPanel;
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{

		PanelsContainer = GetNode<Control>("ScreensContainer");
		LeftPanel = PanelsContainer.GetNode<Panel>("LPanel");
		CenterPanel = PanelsContainer.GetNode<Panel>("CenterPanel");
		RightPanel = PanelsContainer.GetNode<Panel>("RPanel");


	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}

	private void OnHomeButtonPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/Menu Scenes/MainMenu.tscn");
	}
	private void OnPaleozoicPlayPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/Menu Scenes/PaleozoicSelectionScreen.tscn");
	}
	private void OnMesozoicPlayPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/Menu Scenes/MesozoicSelectionScreen.tscn");
	}
	private void OnCenozoicPlayPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/Menu Scenes/CenozoicSelectionScreen.tscn");
	}
}
