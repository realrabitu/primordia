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
<<<<<<< HEAD
		ResetScore();
		GetTree().ChangeSceneToFile("res://game_singleplayer.tscn");
=======
		GetTree().ChangeSceneToFile("res://JurassicCharacterSelection.tscn");
>>>>>>> 977f0e04645e63f0a3c1dd75ca35a66942ff8b3a
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
