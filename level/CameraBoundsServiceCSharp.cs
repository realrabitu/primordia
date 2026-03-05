using Godot;
using Godot.Collections;

public static class CameraBoundsService
{
	public static void UpdateCameraLimits(Node2D levelNode, Node2D generatedRoot, Rect2 generatedBounds, Array<Camera2D> cameras, float marginX, float marginTop, float marginBottom)
	{
		var worldBounds = ComputeWorldBounds(levelNode, generatedRoot, generatedBounds);
		foreach (var camera in cameras)
		{
			if (camera == null)
			{
				continue;
			}
			camera.LimitLeft = Mathf.FloorToInt(worldBounds.Position.X - marginX);
			camera.LimitTop = Mathf.FloorToInt(worldBounds.Position.Y - marginTop);
			camera.LimitRight = Mathf.CeilToInt(worldBounds.End.X + marginX);
			camera.LimitBottom = Mathf.CeilToInt(worldBounds.End.Y + marginBottom);
		}
	}

	public static Rect2 ComputeWorldBounds(Node2D levelNode, Node2D generatedRoot, Rect2 generatedBounds)
	{
		var minX = float.PositiveInfinity;
		var minY = float.PositiveInfinity;
		var maxX = float.NegativeInfinity;
		var maxY = float.NegativeInfinity;

		foreach (Node child in levelNode.GetChildren())
		{
			if (child == generatedRoot)
			{
				continue;
			}
			if (child is Node2D node2D)
			{
				var point = node2D.GlobalPosition;
				minX = Mathf.Min(minX, point.X);
				minY = Mathf.Min(minY, point.Y);
				maxX = Mathf.Max(maxX, point.X);
				maxY = Mathf.Max(maxY, point.Y);
			}
		}

		if (generatedRoot != null && generatedRoot.GetChildCount() > 0)
		{
			minX = Mathf.Min(minX, generatedBounds.Position.X);
			minY = Mathf.Min(minY, generatedBounds.Position.Y);
			maxX = Mathf.Max(maxX, generatedBounds.End.X);
			maxY = Mathf.Max(maxY, generatedBounds.End.Y);
		}

		var localTileMap = levelNode.GetNodeOrNull<TileMapLayer>("Layer0");
		if (localTileMap != null)
		{
			var used = localTileMap.GetUsedRect();
			if (used.Size != Vector2I.Zero)
			{
				var tileSize = localTileMap.TileSet.TileSize;
				var topLeft = localTileMap.ToGlobal(new Vector2(used.Position.X * tileSize.X, used.Position.Y * tileSize.Y));
				var bottomRight = localTileMap.ToGlobal(new Vector2((used.Position.X + used.Size.X) * tileSize.X, (used.Position.Y + used.Size.Y) * tileSize.Y));
				minX = Mathf.Min(minX, topLeft.X);
				minY = Mathf.Min(minY, topLeft.Y);
				maxX = Mathf.Max(maxX, bottomRight.X);
				maxY = Mathf.Max(maxY, bottomRight.Y);
			}
		}

		if (float.IsPositiveInfinity(minX))
		{
			return new Rect2(-320.0f, -220.0f, 1600.0f, 1200.0f);
		}

		return new Rect2(minX, minY, maxX - minX, maxY - minY);
	}
}
