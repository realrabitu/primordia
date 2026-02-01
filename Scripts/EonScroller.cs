using Godot;
using System;

public partial class EonScroller : Control
{
	[Export] public float ScrollSpeed = 3800f; // Pixels per second
	[Export] public float MinX = -1920f; // Minimum X position
	[Export] public float MaxX = 0f;    // Maximum X position
	private int _direction = 0;

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
		PrecambrianUI = GetNode<Control>("../../PrecambrianUI");
		PhanerozoicUI = GetNode<Control>("../../PhanerozoicUI");
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
			// Set the current eon based on the final position
			if (Mathf.Abs(Position.X - MinX) < 1f)
				_currentEon = Eon.Phanerozoic;
			else if (Mathf.Abs(Position.X - MaxX) < 1f)
				_currentEon = Eon.Precambrian;
			ShowUIForCurrentEon();
			_direction = 0; // Stop scrolling
		}
	}
	private void ScrollLeft()
	{
		_direction = -1;
		HideAllUI();
	}
	private void ScrollRight()
	{
		_direction = 1;
		HideAllUI();
	}
	private void StopScroll()
	{
		_direction = 0;
		ShowUIForCurrentEon();
	}
	private void ShowUIForCurrentEon()
	{
		PrecambrianUI.Visible = _currentEon == Eon.Precambrian;
		PhanerozoicUI.Visible = _currentEon == Eon.Phanerozoic;
	}
	private void SwitchToPhanerozoic()
	{
		_currentEon = Eon.Phanerozoic;
		HideAllUI();
		ScrollLeft();
	}
	private void SwitchToPrecambrian()
	{
		_currentEon = Eon.Precambrian;
		HideAllUI();
		ScrollRight();
	}
	private void HideAllUI()
	{
		PrecambrianUI.Visible = false;
		PhanerozoicUI.Visible = false;
	}
}
