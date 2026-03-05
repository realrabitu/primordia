using Godot;
using System;

public partial class PaleozoicSelectionScreen : Control
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
	private void OnCambrianPlayPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/CambrianStage.tscn");
	}
	private void OnOrdovicianPlayPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/OrdovicianStage.tscn");
	}
	// For future use, will not be implemented yet
	private void OnSilurianPlayPressed() { }
	private void OnDevonianPlayPressed() { }
	private void OnCarboniferousPlayPressed() { }
	private void OnPermianPlayPressed() { }
}
