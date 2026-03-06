using Godot;
using System;



public partial class MainMenu : Control
{
	private TextureButton _startButton;
	private TextureButton _quitButton;
	private TextureButton _howToPlayButton;
	private TextureButton _settingsButton;
	private TextureButton _creditsButton;
	private HBoxContainer _topButtons;
	private Panel _options;
	private Panel _credits;
	private Panel _logo;
	private Panel _howToPlay;

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		_startButton = GetNode<TextureButton>("TextureButton");
		_quitButton = GetNode<TextureButton>("QuitButton");
		_howToPlayButton = GetNode<TextureButton>("HowToPlayButton");
		_settingsButton = GetNode<TextureButton>("TopButtons/SettingsButton");
		_creditsButton = GetNode<TextureButton>("TopButtons/CreditsButton");
		_topButtons = GetNode<HBoxContainer>("TopButtons");
		_options = GetNode<Panel>("OptionsPanel");
		_credits = GetNode<Panel>("CreditsPanel");
		_logo = GetNode<Panel>("Logo");
		_howToPlay = GetNode<Panel>("HowToPlayPanel");

		_options.Visible = false;
		_credits.Visible = false;
		_howToPlay.Visible = false;

		_startButton.Pressed += OnStartPressed;
		_quitButton.Pressed += OnQuitPressed;
		_howToPlayButton.Pressed += OnHowToPlayPressed;
		_settingsButton.Pressed += OnSettingsPressed;
		_creditsButton.Pressed += OnCreditsPressed;
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{

	}

	void OnStartPressed()
	{
		GetTree().ChangeSceneToFile("res://Scenes/Menu Scenes/EonSelectionScreen.tscn");
	}
	void OnQuitPressed()
	{
		GetTree().Quit();
	}
	private void SetMainControlsVisible(bool visible)
	{
		_startButton.Visible = visible;
		_quitButton.Visible = visible;
		_howToPlayButton.Visible = visible;
		_topButtons.Visible = visible;
		_logo.Visible = visible;
	}

	void OnHowToPlayPressed()
	{
		SetMainControlsVisible(false);
		_howToPlay.Visible = true;
	}
	void OnSettingsPressed()
	{
		SetMainControlsVisible(false);
		_options.Visible = true;
	}
	void OnCreditsPressed()
	{
		SetMainControlsVisible(false);
		_credits.Visible = true;
	}
	void OnCreditsBackPressed()
	{
		SetMainControlsVisible(true);
		_credits.Visible = false;
	}
	void OnOptionsBackPressed()
	{
		SetMainControlsVisible(true);
		_options.Visible = false;
	}
	void OnHowToPlayBackButtonPressed()
	{
		SetMainControlsVisible(true);
		_howToPlay.Visible = false;
	}

}
