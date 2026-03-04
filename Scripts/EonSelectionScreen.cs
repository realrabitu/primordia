using Godot;
using System;

public partial class EonSelectionScreen : Control
{
	private TextureButton HomeButton;
	private Control EonScroller;

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		// Get the PanelScroller node inside ScreensContainer
		EonScroller = GetNode<Control>("ScreensContainer/EonScroller");
		HomeButton = GetNode<TextureButton>("HomeButton");
		// Sliding is now handled by EonPanelScroller.cs via signals from the arrow buttons. 
	}


	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{

	}
	private void OnHomeButtonPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/Menu Scenes/MainMenu.tscn");
	}
	private void OnPhanerozoicPlayPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/Menu Scenes/EraSelectionScreen.tscn");
	}
	private void OnPrecambrianPlayPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/PrecambrianSelectionScreen.tscn");
	}
}
