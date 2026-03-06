using Godot;
using System;

public partial class EraSelectionScreen : Control
{
	private TextureButton BackButton;
	private Control PanelsContainer;
	private Panel LeftPanel;
	private Panel CenterPanel;
	private Panel RightPanel;
	private const string LoadingScenePath = "res://Scenes/Menu Scenes/loading.tscn";
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

	private void OnBackButtonPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/Menu Scenes/EonSelectionScreen.tscn");
	}
	private void OnPaleozoicPlayPressed()
	{
		StartLoading("res://Scenes/Menu Scenes/PaleozoicSelectionScreen.tscn");
	}
	private void OnMesozoicPlayPressed()
	{
		StartLoading("res://Scenes/Menu Scenes/MesozoicSelectionScreen.tscn");
	}
	private void OnCenozoicPlayPressed()
	{
		StartLoading("res://Scenes/Menu Scenes/CenozoicSelectionScreen.tscn");
	}

	private void StartLoading(string targetScenePath)
	{
		var loadState = GetNodeOrNull<SceneLoadState>("/root/SceneLoadState");
		if (loadState == null)
		{
			GD.PushError("SceneLoadState autoload is missing.");
			return;
		}

		loadState.TargetScenePath = targetScenePath;
		GetTree().ChangeSceneToFile(LoadingScenePath);
	}
}
