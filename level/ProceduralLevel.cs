/**** End Patch
				return probeLeft;
			}
		}
		return surfaceCell;
	}

	private void ExpandGeneratedBounds(Vector2 point)
	{
		if (Mathf.IsZeroApprox(_generatedBounds.Size.X) && Mathf.IsZeroApprox(_generatedBounds.Size.Y))
		{
			_generatedBounds = new Rect2(point.X, point.Y, 1.0f, 1.0f);
			return;
		}

		var minX = Mathf.Min(_generatedBounds.Position.X, point.X);
		var minY = Mathf.Min(_generatedBounds.Position.Y, point.Y);
		var maxX = Mathf.Max(_generatedBounds.Position.X + _generatedBounds.Size.X, point.X);
		var maxY = Mathf.Max(_generatedBounds.Position.Y + _generatedBounds.Size.Y, point.Y);
		_generatedBounds = new Rect2(minX, minY, maxX - minX, maxY - minY);
	}

	private void UpdateCameraLimits()
	{
		var cameras = new Array<Camera2D>();
		foreach (var player in CollectPlayersWithCameras())
		{
			cameras.Add(player.Camera);
		}

		CameraBoundsServiceCSharp.UpdateCameraLimits(
			this,
			_generatedRoot,
			_generatedBounds,
			cameras,
			CameraMarginX,
			CameraMarginTop,
			CameraMarginBottom
		);
	}

	private readonly struct PlayerCameraPair
	{
		public PlayerCameraPair(Node2D player, Camera2D camera)
		{
			Player = player;
			Camera = camera;
		}

		public Node2D Player { get; }
		public Camera2D Camera { get; }
	}

	private List<PlayerCameraPair> CollectPlayersWithCameras()
	{
		var players = new List<PlayerCameraPair>();
		Node searchRoot = GetParent() ?? this;
		var stack = new Array<Node> { searchRoot };
		while (stack.Count > 0)
		{
			var node = stack[stack.Count - 1];
			stack.RemoveAt(stack.Count - 1);
			if (node is Node2D playerNode)
			{
				var camera = node.GetNodeOrNull<Camera2D>("Camera");
				if (camera != null)
				{
					players.Add(new PlayerCameraPair(playerNode, camera));
				}
			}
			foreach (Node child in node.GetChildren())
			{
				stack.Add(child);
			}
		}
		return players;
	}
}
*/
