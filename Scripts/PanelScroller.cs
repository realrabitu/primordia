using Godot;
using System;

public partial class PanelScroller : Control
{
	[Export] public float ScrollSpeed = 1800f; // Pixels per second
	[Export] public float MinX = -1920f; // Minimum X position
	[Export] public float MaxX = 0f;    // Maximum X position
	private int _direction = 0;
	private const float Threshold = 1f; // Tolerance for float comparison

	private Control PrecambrianUI;
	private Control PhanerozoicUI;

	public enum Eon
	{
		Precambrian,
		Phanerozoic
	}
	private Eon _currentEon = Eon.Precambrian;


	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		PrecambrianUI = GetNode<Control>(PrecambrianUI);
		PhanerozoicUI = GetNode<Control>(PhanerozoicUIPath);
		ShowUIForCurrentEon();

	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		if (_direction != 0)
		{
			float newX = Position.X + _direction * ScrollSpeed * (float)delta;
			newX = Mathf.Clamp(newX, MinX, MaxX);
			Position = new Vector2(newX, Position.Y);
		}
		// Check if we've reached the target position
		if ((_direction == -1 && Position.X <= MinX) || (_direction == 1 && Position.X >= MaxX))
		{
			ShowUIForCurrentEon();
			_direction = 0; // Stop scrolling
		}
		GD.Print("Scroll Position: ", Position.X);
		

	}
	void ScrollLeft()
	{
		_direction = -1;
		HideAllUI();
	}
	void ScrollRight()
	{
		_direction = 1;
		HideAllUI();
	}
	void StopScroll()
	{
		_direction = 0;
		ShowUIForCurrentEon();
	}
	void ShowUIForCurrentEon()
	{
		// Use the center of the screen to determine which eon is visible
		//float midpoint = (MinX + MaxX) / 2;
		PrecambrianUI.Visible = _currentEon == Eon.Precambrian;
		PhanerozoicUI.Visible = _currentEon == Eon.Phanerozoic;
	}
	void SwitchToPhanerozoic()
	{
		_currentEon = Eon.Phanerozoic;
		HideAllUI();
		ScrollLeft();
	}
	void SwitchToPrecambrian()
	{
		_currentEon = Eon.Precambrian;
		HideAllUI();
		ScrollRight();
	}
	void HideAllUI()
	{
		PrecambrianUI.Visible = false;
		PhanerozoicUI.Visible = false;
	}
}
