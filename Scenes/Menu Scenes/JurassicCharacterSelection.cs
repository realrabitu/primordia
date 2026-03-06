using Godot;
using System;

public partial class JurassicCharacterSelection : Control
{
	private TextureButton SelectButton;
	private AnimatedSprite2D Stegosaurus;
	private const string LoadingScenePath = "res://Scenes/Menu Scenes/loading.tscn";
	private const string GameSinglePlayerScenePath = "res://Scenes/Player Scenes/game_singleplayer.tscn";
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		Stegosaurus = GetNode<AnimatedSprite2D>("Stegosaurus");
		SelectButton = GetNode<TextureButton>("SelectButton");
		Stegosaurus.Play("idle");
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
	private void OnSelectButtonPressed()
	{
		var loadState = GetNodeOrNull<SceneLoadState>("/root/SceneLoadState");
		if (loadState == null)
		{
			GD.PushError("SceneLoadState autoload is missing.");
			return;
		}

		loadState.TargetScenePath = GameSinglePlayerScenePath;
		GetTree().ChangeSceneToFile(LoadingScenePath);
	}
}
