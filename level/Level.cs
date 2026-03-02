using Godot;
using Godot.Collections;

public partial class Level : Node2D
{
	private const float CameraMarginX = 320.0f;
	private const float CameraMarginTop = 260.0f;
	private const float CameraMarginBottom = 360.0f;

	private Node2D _generatedRoot;
	private Rect2 _generatedBounds = new();

	public override void _Ready()
	{
		_generatedRoot = GetNodeOrNull<Node2D>("GeneratedTerrain");
		if (_generatedRoot == null)
		{
            _generatedRoot = new Node2D
            {
                Name = "GeneratedTerrain"
            };
            AddChild(_generatedRoot);
		}

		UpdateCameraLimits();
	}

	private void UpdateCameraLimits()
	{
		var cameras = new Array<Camera2D>();
		foreach (var player in CollectPlayers())
		{
			var camera = player.GetNodeOrNull<Camera2D>("Camera");
			if (camera != null)
			{
				cameras.Add(camera);
			}
		}

		CameraBoundsService.UpdateCameraLimits(
			this,
			_generatedRoot,
			_generatedBounds,
			cameras,
			CameraMarginX,
			CameraMarginTop,
			CameraMarginBottom
		);
	}

	private Array<Node2D> CollectPlayers()
	{
		var players = new Array<Node2D>();
		Node searchRoot = GetParent() ?? this;
		var stack = new Array<Node> { searchRoot };
		while (stack.Count > 0)
		{
			var node = stack[stack.Count - 1];
			stack.RemoveAt(stack.Count - 1);
			if (node is Node2D playerNode && node.IsClass("Player"))
			{
				players.Add(playerNode);
			}
			foreach (Node child in node.GetChildren())
			{
				stack.Add(child);
			}
		}
		return players;
	}
}
