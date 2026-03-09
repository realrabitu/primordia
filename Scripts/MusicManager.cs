using Godot;

public partial class MusicManager : AudioStreamPlayer
{
    private AudioStream _menuStream;
    private AudioStream _gameStream;
    private Node _lastScene;

    public override void _Ready()
    {
        _menuStream = GD.Load<AudioStream>("res://Assets/Sounds/MAIN_SOUNDTRACK.mp3");
        _gameStream = GD.Load<AudioStream>("res://music.ogg");

        UpdateMusic();
    }

    public override void _Process(double delta)
    {
        var currentScene = GetTree().CurrentScene;
        if (currentScene != _lastScene)
        {
            _lastScene = currentScene;
            UpdateMusic();
        }
    }

    private void UpdateMusic()
    {
        var scene = GetTree().CurrentScene;
        if (scene == null)
        {
            Stop();
            return;
        }

        // Play game music only when the player is in the singleplayer game scene.
        // Otherwise, play the menu soundtrack.
        bool isGameScene = scene.Name == "Game";

        var targetStream = isGameScene ? _gameStream : _menuStream;
        if (Stream != targetStream)
        {
            Stop();
            Stream = targetStream;
        }

        if (!Playing)
        {
            Play();
        }
    }
}
