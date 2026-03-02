using Godot;
using System;

public partial class DisplayControl : Node
{
	[Export] public bool StartInFullscreen = false;
	[Export] public StringName FullscreenToggleAction = "toggle_fullscreen";

	public override void _Ready()
	{
		if (StartInFullscreen)
		{
			SetFullscreen(true);
		}
	}

	public void SetFullscreen(bool enabled)
	{
		DisplayServer.WindowSetMode(
			enabled
				? DisplayServer.WindowMode.Fullscreen
				: DisplayServer.WindowMode.Windowed
		);
	}

	public void ToggleFullscreen()
	{
		SetFullscreen(!IsFullscreen());
	}

	public bool IsFullscreen()
	{
		DisplayServer.WindowMode currentMode = DisplayServer.WindowGetMode();
		return currentMode == DisplayServer.WindowMode.Fullscreen
			|| currentMode == DisplayServer.WindowMode.ExclusiveFullscreen;
	}

	public void OnFullscreenToggled(bool buttonPressed)
	{
		SetFullscreen(buttonPressed);
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event.IsActionPressed(FullscreenToggleAction))
		{
			ToggleFullscreen();
			GetViewport().SetInputAsHandled();
		}
	}
}
