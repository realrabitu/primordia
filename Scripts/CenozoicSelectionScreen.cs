using Godot;
using System;

public partial class CenozoicSelectionScreen : Control
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
	private void OnTertiaryPlayPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/TertiaryStage.tscn");
	}
	private void OnQuaternaryPlayPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/QuaternaryStage.tscn");
	}
}
