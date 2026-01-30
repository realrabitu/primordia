using Godot;
using System;

public partial class AudioControl : HSlider
{
	// Export bus 
	[Export] public string BusName;
	public int AudioBusID;
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		AudioBusID = AudioServer.GetBusIndex(BusName);

	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		OnAudioControlValueChanged(Value);
	}
	
	// Method that handles the volume change
	private void OnAudioControlValueChanged(double value)
	{
		// Handle the value change, e.g., adjust volume
		float DB = Mathf.LinearToDb((float)value);
		AudioServer.SetBusVolumeDb(AudioBusID, DB);
		
	}
}
