using Godot;
using System;



public partial class MainMenu : Control
{
	private VBoxContainer MainButtons;
	private Panel Options; 
	private HBoxContainer TopButtons;
	private Panel Credits;
	private Panel Logo;

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		MainButtons = GetNode<VBoxContainer>("MainButtons");
		Options = GetNode<Panel>("OptionsPanel");
		TopButtons = GetNode<HBoxContainer>("TopButtons");
		Credits = GetNode<Panel>("CreditsPanel");
		Logo = GetNode<Panel>("Logo");
		MainButtons.Visible = true;
		Options.Visible = false;
		Credits.Visible = false;

	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}

	void OnStartPressed() 
	{
		GetTree().ChangeSceneToFile("res::/Scenes/.tscn");
	}
	void OnQuitPressed()
	{
		GetTree().Quit();
	}
	void OnHowToPlayPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/HowToPlay.tscn");
	}
	void OnSettingsPressed()
	{
		MainButtons.Visible = false;
		Options.Visible = true;
		TopButtons.Visible = false;
		Logo.Visible = false;
	}
	void OnCreditsPressed()
	{
		MainButtons.Visible = false;
		Credits.Visible = true;
		TopButtons.Visible = false;
		Logo.Visible = false;
	}
	void OnCreditsBackPressed()
	{
		MainButtons.Visible = true;
		Credits.Visible = false;
		TopButtons.Visible = true;
		Logo.Visible = true;
	}
	void OnOptionsBackPressed()
	{
		MainButtons.Visible = true;
		Options.Visible = false;
		TopButtons.Visible = true;
		Logo.Visible = true;
	}
	
}	
