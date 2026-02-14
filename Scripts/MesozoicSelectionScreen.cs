using Godot;
using System;

public partial class MesozoicSelectionScreen : Control
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
	private void OnTriassicPlayPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/TriassicStage.tscn");
	}
	// for future use, will not be implemented yet
	private void OnJurassicPlayPressed() { }
	private void OnCretaceousPlayPressed() { }
}
