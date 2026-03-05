
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
		targetX = Position.X;
		ShowUIForCurrentEra();
	}

	public override void _Process(double delta)
	{
		if (_direction != 0)
		{
			float step = ScrollSpeed * (float)delta;
			float newX = Mathf.MoveToward(Position.X, targetX, step);
			Position = new Vector2(newX, Position.Y);
		}

		float epsilon = 1.0f;
		if (_direction != 0 && Mathf.Abs(Position.X - targetX) <= epsilon)
		{
			Position = new Vector2(targetX, Position.Y);
			_direction = 0;
			ShowUIForCurrentEra();
		}
	}
	private void ScrollLeft()
	{
		if (_currentEra == Era.Paleozoic)
		{
			_currentEra = Era.Mesozoic;
			targetX = MidX;
			_direction = -1;
		}
		else if (_currentEra == Era.Mesozoic)
		{
			_currentEra = Era.Cenozoic;
			targetX = MinX;
			_direction = -1;
		}
		else
		{
			return;
		}
		HideAllUI();
	}
	private void ScrollRight()
	{
		if (_currentEra == Era.Cenozoic)
		{
			_currentEra = Era.Mesozoic;
			targetX = MidX;
			_direction = 1;
		}
		else if (_currentEra == Era.Mesozoic)
		{
			_currentEra = Era.Paleozoic;
			targetX = MaxX;
			_direction = 1;
		}
		else
		{
			return;
		}
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
		targetX = MidX;
		_direction = targetX < Position.X ? -1 : (targetX > Position.X ? 1 : 0);
		if (_direction == 0)
			ShowUIForCurrentEra();
		else
			HideAllUI();
	}
	private void SwitchToPaleozoic()
	{
		_currentEra = Era.Paleozoic;
		targetX = MaxX;
		_direction = targetX < Position.X ? -1 : (targetX > Position.X ? 1 : 0);
		if (_direction == 0)
			ShowUIForCurrentEra();
		else
			HideAllUI();
	}
	private void SwitchToCenozoic()
	{
		_currentEra = Era.Cenozoic;
		targetX = MinX;
		_direction = targetX < Position.X ? -1 : (targetX > Position.X ? 1 : 0);
		if (_direction == 0)
			ShowUIForCurrentEra();
		else
			HideAllUI();
	}

}

