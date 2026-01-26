using Godot;
using System;

public partial class CursorManager : Node
{
    public override void _Ready()
    {
        var arrow = ResourceLoader.Load("res://Assets/Textures/Normal-Selects-Resized.png");
        Input.SetCustomMouseCursor(arrow);
    }
}
