
using Godot;
using System;

public partial class EraScroller : Control
{
	[Export] public float ScrollSpeed = 3800f;
	[Export] public float MinX = -3840f;
	[Export] public float MaxX = 0f;
	[Export] public float MidX = -1920f;
	private float targetX = 0f;
	private int _direction = 0;
	private Control PaleozoicUI;
	private Control MesozoicUI;
	private Control CenozoicUI;
	public enum Era
	{
		Paleozoic,
		Mesozoic,
		Cenozoic
	}
	private Era _currentEra = Era.Paleozoic;
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		PaleozoicUI = GetNode<Control>("../../PaleozoicUI");
		MesozoicUI = GetNode<Control>("../../MesozoicUI");
		CenozoicUI = GetNode<Control>("../../CenozoicUI");

	}

	public override void _Process(double delta)
	{
		if (_direction != 0)
		{
			// Now that we have three distinct eras, we need to adjust the scrolling logic accordingly.
			// The Mesozoic era will be positioned between the Paleozoic and Cenozoic eras.
			// Therefore, we need to modify the target positions for scrolling.
			float newX = Position.X + _direction * ScrollSpeed * (float)delta;
			newX = Mathf.Clamp(newX, MinX, MaxX);
			/*if (_currentEra == Era.Paleozoic)
				newX = Mathf.Clamp(newX, MidX, MaxX);
			else if (_currentEra == Era.Mesozoic)
				newX = Mathf.Clamp(newX, MaxX, MidX);
			else if (_currentEra == Era.Cenozoic)
				newX = Mathf.Clamp(newX, MinX, MidX);
			// newX = Mathf.Clamp(newX, MinX, MaxX); */
			Position = new Vector2(newX, Position.Y);
		}
		// Check if we've reached the target position
		/*if ((_direction == -1 && Position.X <= MidX) || (_direction == -1 && Position.X <= MinX))
		{
			// Set the current era based on the final position
			if (Mathf.Abs(Position.X - MidX) < 1f)
				_currentEra = Era.Mesozoic;
			else if (Mathf.Abs(Position.X - MaxX) < 1f)
				_currentEra = Era.Paleozoic;
			else if(Mathf.Abs(Position.X - MinX) < 1f)
				_currentEra = Era.Cenozoic;
			ShowUIForCurrentEra();
			_direction = 0; // Stop scrolling
		} */
		// Robust scroll completion logic
		float epsilon = 1.0f;
		if (_direction != 0)
		{
			if (Mathf.Abs(Position.X - MaxX) < epsilon)
			{
				_currentEra = Era.Paleozoic;
				ShowUIForCurrentEra();
				_direction = 0;
			}
			else if (Mathf.Abs(Position.X - MidX) < epsilon)
			{
				_currentEra = Era.Mesozoic;
				ShowUIForCurrentEra();
				_direction = 0;
			}
			else if (Mathf.Abs(Position.X - MinX) < epsilon)
			{
				_currentEra = Era.Cenozoic;
				ShowUIForCurrentEra();
				_direction = 0;
			}
		}
	}
	private void ScrollLeft()
	{
		_direction = -1;
		if (_currentEra == Era.Paleozoic)
			_currentEra = Era.Mesozoic;
		else if (_currentEra == Era.Mesozoic)
			_currentEra = Era.Cenozoic;
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
	}
	private void HideAllUI()
	{
		PaleozoicUI.Visible = false;
		MesozoicUI.Visible = false;
		CenozoicUI.Visible = false;
	}
	private void ShowUIForCurrentEra()
	{
		PaleozoicUI.Visible = _currentEra == Era.Paleozoic;
		MesozoicUI.Visible = _currentEra == Era.Mesozoic;
		CenozoicUI.Visible = _currentEra == Era.Cenozoic;
	}
	private void SwitchToMesozoic()
	{
		_currentEra = Era.Mesozoic;
		ShowUIForCurrentEra();
		ScrollLeft();
	}
	private void SwitchToPaleozoic()
	{
		_currentEra = Era.Paleozoic;
		ShowUIForCurrentEra();
		ScrollRight();
	}
	private void SwitchToCenozoic()
	{
		_currentEra = Era.Cenozoic;
		ShowUIForCurrentEra();
		ScrollRight();
	}

}

