using Godot;
using System;

public partial class MesozoicSelectionScreen : Control
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		var jurassicPlayButton = GetNode<TextureButton>("TopContainer/Jurassic/JurassicPlayButton");
		jurassicPlayButton.Pressed += OnJurassicPlayPressed;
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
	private void OnTriassicPlayPressed()
	{
		ResetScore();
		GetTree().ChangeSceneToFile("res://Scenes/TriassicStage.tscn");
	}
	private void OnJurassicPlayPressed()
	{
		ResetScore();
		GetTree().ChangeSceneToFile("res://game_singleplayer.tscn");
	}
	// for future use, will not be implemented yet
	private void OnCretaceousPlayPressed() { }

	private void ResetScore()
	{
		var scoreNode = GetNodeOrNull<Node>("/root/Score");
		if (scoreNode != null)
		{
			scoreNode.Call("reset_score");
		}
	}
}
