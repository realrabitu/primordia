using Godot;
using System;
using Godot.Collections;
using Array = Godot.Collections.Array;

public partial class Loading : Node
{
	[Export] public NodePath ProgressBarPath;
	[Export] public int HoldAtFullMs = 150;

	private ProgressBar _progressBar;
	private string _targetScenePath = string.Empty;
	private bool _isSwitching;
	private PackedScene _loadedScene;
	private ulong _switchAtMs;

	public override void _Ready()
	{
		if (ProgressBarPath != null && !ProgressBarPath.IsEmpty)
		{
			_progressBar = GetNodeOrNull<ProgressBar>(ProgressBarPath);
		}

		if (_progressBar != null)
		{
			_progressBar.MinValue = 0;
			_progressBar.MaxValue = 100;
			_progressBar.Value = 0;
		}

		var loadState = GetNodeOrNull<SceneLoadState>("/root/SceneLoadState");
		if (loadState == null)
		{
			GD.PushError("Missing SceneLoadState autoload.");
			return;
		}

		_targetScenePath = loadState.TargetScenePath;
		if (string.IsNullOrWhiteSpace(_targetScenePath))
		{
			GD.PushWarning("No target scene selected.");
			return;
		}

		var requestResult = ResourceLoader.LoadThreadedRequest(_targetScenePath);
		if (requestResult != Error.Ok)
		{
			GD.PushError($"Load request failed: {requestResult}");
			return;
		}
	}

	public override void _Process(double delta)
	{
		if (_isSwitching || string.IsNullOrWhiteSpace(_targetScenePath))
		{
			return;
		}

		if (_loadedScene != null)
		{
			if (Time.GetTicksMsec() >= _switchAtMs)
			{
				_isSwitching = true;
				GetTree().ChangeSceneToPacked(_loadedScene);
			}
			return;
		}

		var progress = new Array();
		var status = ResourceLoader.LoadThreadedGetStatus(_targetScenePath, progress);

		if (_progressBar != null && progress.Count > 0)
		{
			float ratio = (float)progress[0];
			_progressBar.Value = ratio * 100.0f;
		}
	
		if (status == ResourceLoader.ThreadLoadStatus.Loaded)
		{
			if (_progressBar != null)
			{
				_progressBar.Value = 100;
			}

			var packedScene = ResourceLoader.LoadThreadedGet(_targetScenePath) as PackedScene;
			if (packedScene == null)
			{
				GD.PushError("Loaded file is not a scene.");
				return;
			}

			_loadedScene = packedScene;
			var holdMs = Math.Max(0, HoldAtFullMs);
			_switchAtMs = Time.GetTicksMsec() + (ulong)holdMs;
			return;
		}

		if (status == ResourceLoader.ThreadLoadStatus.Failed)
		{
			GD.PushError("Loading failed.");
		}
	}
}
