using Godot;
using System;

public partial class EraScroller : Control
{
	[Export] public float ScrollSpeed = 3800f;
	[Export] public float MaxX = 3840f;
	[Export] public float MidpointX = 1920f;
	[Export] public float MinX = 0f;
	private int _direction = 0;
	private float _targetX = 0f;
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
		ShowUIForCurrentEra();
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		if (_direction != 0)
		{
			float move = ScrollSpeed * (float)delta * _direction;
			float newX = Position.X + move;
			// Check if we've reached or passed the target
			if ((_direction == 1 && newX >= _targetX) || (_direction == -1 && newX <= _targetX))
			{
				newX = _targetX;
				Position = new Vector2(newX, Position.Y);
				UpdateEraByPosition();
				ShowUIForCurrentEra();
				_direction = 0;
			}
			else
			{
				Position = new Vector2(newX, Position.Y);
			}
		}
	}

	   private void UpdateEraByPosition()
	   {
		   if (Mathf.Abs(Position.X - MinX) < 1f)
			   _currentEra = Era.Paleozoic;
		   else if (Mathf.Abs(Position.X - MidpointX) < 1f)
			   _currentEra = Era.Mesozoic;
		   else if (Mathf.Abs(Position.X - MaxX) < 1f)
			   _currentEra = Era.Cenozoic;
	   }
	private void ShowUIForCurrentEra()
	{
		HideAllUI();
		switch (_currentEra)
		{
			case Era.Paleozoic:
				PaleozoicUI.Visible = true;
				break;
			case Era.Mesozoic:
				MesozoicUI.Visible = true;
				break;
			case Era.Cenozoic:
				CenozoicUI.Visible = true;
				break;
		}
	}
	private void HideAllUI()
	{
		PaleozoicUI.Visible = false;
		MesozoicUI.Visible = false;
		CenozoicUI.Visible = false;
	}
	   private void ScrollLeft()
	   {
		   if (_currentEra == Era.Mesozoic)
		   {
			   _targetX = MinX;
			   _direction = -1;
		   }
		   else if (_currentEra == Era.Cenozoic)
		   {
			   _targetX = MidpointX;
			   _direction = -1;
		   }
		   else
		   {
			   // Already at leftmost
			   return;
		   }
		   HideAllUI();
		   GD.Print("Scrolling Left to X: " + _targetX);
	   }

	   private void ScrollRight()
	   {
		   if (_currentEra == Era.Paleozoic)
		   {
			   _targetX = MidpointX;
			   _direction = 1;
		   }
		   else if (_currentEra == Era.Mesozoic)
		   {
			   _targetX = MaxX;
			   _direction = 1;
		   }
		   else
		   {
			   // Already at rightmost
			   return;
		   }
		   HideAllUI();
		   GD.Print("Scrolling Right to X: " + _targetX);
	   }
	private void StopScroll()
	{
		_direction = 0;
		ShowUIForCurrentEra();
	}
	private void OnPaleozoicPlayPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/PaleozoicSelectionScreen.tscn");
	}
	private void OnMesozoicPlayPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/MesozoicSelectionScreen.tscn");
	}
	private void OnCenozoicPlayPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/CenozoicSelectionScreen.tscn");
	}
}
