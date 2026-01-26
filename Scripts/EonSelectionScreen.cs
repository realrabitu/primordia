using Godot;
using System;

public partial class EonSelectionScreen : Panel
{
	private TextureButton HomeButton;
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		HomeButton = GetNode<TextureButton>("HomeButton");
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		// ...existing code...
	}
	
	void OnHomeButtonPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/main_menu.tscn");
	}
}
