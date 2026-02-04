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

	// This enumerated type defines the two eons available in the scroller.
	public enum Eon
	{
		Precambrian,
		Phanerozoic
	}
	// This variable keeps track of the currently selected eon.
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
		/* There might be a better way to implement this, but this is what works for now. */
		// Direction is dictated by the button presses.
		// -1 for left, 1 for right, 0 for no movement.
		if (_direction != 0)
		{
			// Example: 0 + -1 * 3800 * delta = newX
			float newX = Position.X + _direction * ScrollSpeed * (float)delta;
			// This clamps the value to the minimum and maximum ranges of X.
			newX = Mathf.Clamp(newX, MinX, MaxX);
			/* The position of the node in which the script is attached to, in this case the EonScroller, is updated based on the value of newX. The Y value stays the same. */
			Position = new Vector2(newX, Position.Y);
			/* The EonScroller node spans a width of 3840 pixels. Since it is anchored to (0, 0), moving it towards -1920 on the X axis reveals the Phanerozoic UI on the viewport as it is its child node. */
		}
		/* This block handles the UI visibility and stops scrolling when the target position is reached. The above block moves the scroller and the checks are done here. */
		if ((_direction == -1 && Position.X <= MinX) || (_direction == 1 && Position.X >= MaxX))
		{
			// Set the appropriate eon UI based on the final position
			// This if-else block shall run first before showing the UI.
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
