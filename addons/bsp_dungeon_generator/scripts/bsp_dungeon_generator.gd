#
# BSP Dungeon Generator - A basic BSP algorithm to generate 2D dungeons
# Copyright (C) 2024 A. Roldán
# 
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the 
# Free Software Foundation, either version 3 of the License, or 
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for 
# more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program. If not, see https://www.gnu.org/licenses/.
# 


class_name BSPDungeonGenerator
extends RefCounted


class DataParameters extends RefCounted:
	var avoid_walls: bool = true
	var avoid_data: Array = []


class Parameters extends RefCounted:
	var seed: int = 0
	var size: Vector2i = Vector2i(50, 50)
	var min_section_size: int = 4
	var max_room_size: int = 8


class Section extends RefCounted:
	var position: Vector2i
	var size: Vector2i


class Dungeon extends RefCounted:
	var size: Vector2i = Vector2i.ZERO
	var tiles: Array = []
	var rooms: Array = []
	var corridor_entries: Array = []
	
	func _init(size: Vector2i) -> void:
		self.size = size
		
		for y in range(size.y):
			self.tiles.append([])
			for x in range(size.x):
				self.tiles[y].append(Tile.new())


	func get_room(index: int) -> Dungeon.Room:
		return self.rooms[index]


	func get_tile(x: int, y: int) -> Tile:
		return self.tiles[y][x]


	func get_tilev(position: Vector2i) -> Tile:
		return self.tiles[position.y][position.x]


	func add_data(dungeon: Dungeon, position: Vector2i, data: Dictionary) -> void:
		self.tiles[position.y][position.x].add_data(data)


	class Tile extends RefCounted:
		var has_ground: bool = false
		var data: Array = []
		
		
		func has_data(type: int) -> bool:
			for data_entity in self.data:
				if data_entity.type == type:
					return true
			
			return false
		
		
		func add_data(type: int, data: Dictionary) -> void:
			self.data.append({
				"type": type,
				"data": data
			})


	class Room extends RefCounted:
		var size: Vector2i = Vector2i.ZERO
		var position: Vector2i = Vector2i.ZERO


var _parameters: Parameters = Parameters.new()
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _sections: Array = []


func generate(parameters: Parameters) -> Dungeon:
	print("[BSPDungeonGenerator::generate]: Seed = %d" % [parameters.seed])
	
	self._parameters = parameters
	self._random.seed = parameters.seed
	
	var dungeon: Dungeon = Dungeon.new(parameters.size)
	
	_generate_sections(dungeon)
	_generate_rooms(dungeon)
	_generate_corridors(dungeon)
	
	return dungeon


func _get_random_room(rooms: Array) -> Dungeon.Room:
	return rooms[self._random.randi_range(0, rooms.size() - 1)]


func _get_random_position(room: Dungeon.Room) -> Vector2i:
	return Vector2i(
		self._random.randi_range(room.position.x, room.position.x + room.size.x - 1),
		self._random.randi_range(room.position.y, room.position.y + room.size.y - 1),
	)


func _generate_sections(dungeon: Dungeon) -> void:
	var root_section: Section = Section.new()
	root_section.position = Vector2i.ZERO
	root_section.size = dungeon.size
	
	_divide_section(root_section)


func _generate_rooms(dungeon: Dungeon) -> void:
	for section in self._sections:
		var room: Dungeon.Room = _generate_room(dungeon, section)
		dungeon.rooms.append(room)


func _generate_corridors(dungeon: Dungeon) -> void:
	for i in range(1, dungeon.rooms.size()):
		var prev_room = dungeon.rooms[i - 1]
		var current_room = dungeon.rooms[i]
		
		_generate_corridor(dungeon, prev_room, current_room)
	
	_find_corridor_entries(dungeon)


func _find_corridor_entries(dungeon: Dungeon) -> void:
	for room in dungeon.rooms:
		for i in range(room.size.x):
			if room.position.y > 0:
				if dungeon.tiles[room.position.y - 1][room.position.x + i].has_ground:
					var position: Vector2i = Vector2i(room.position.x + i, room.position.y - 1)
					if dungeon.corridor_entries.find(position) == -1:
						dungeon.corridor_entries.append(position)
			if room.position.y + room.size.y < dungeon.size.y - 1:
				if dungeon.tiles[room.position.y + room.size.y][room.position.x + i].has_ground:
					var position: Vector2i = Vector2i(room.position.x + i, room.position.y + room.size.y)
					if dungeon.corridor_entries.find(position) == -1:
						dungeon.corridor_entries.append(position)
		
		for i in range(room.size.y):
			if room.position.x > 0:
				if dungeon.tiles[room.position.y + i][room.position.x - 1].has_ground:
					var position: Vector2i = Vector2i(room.position.x - 1, room.position.y + i)
					if dungeon.corridor_entries.find(position) == -1:
						dungeon.corridor_entries.append(position)

			if room.position.x + room.size.x < dungeon.size.x - 1:
				if dungeon.tiles[room.position.y + i][room.position.x + room.size.x].has_ground:
					var position: Vector2i = Vector2i(room.position.x + room.size.x, room.position.y + i)
					if dungeon.corridor_entries.find(position) == -1:
						dungeon.corridor_entries.append(position)


func _divide_section(section: Section) -> void:
	# Stop condition
	if section.size.x <= self._parameters.min_section_size * 2 or section.size.y <= self._parameters.min_section_size * 2:
		self._sections.append(section)
		return

	var horizontal_division: bool = self._random.randf() >= 0.5
	
	if horizontal_division:
		var split_point = self._random.randi_range(
			section.position.y + self._parameters.min_section_size, 
			section.position.y + section.size.y - self._parameters.min_section_size
		)
		
		var top = Section.new()
		top.position = Vector2i(section.position.x, section.position.y)
		top.size = Vector2i(section.size.x, split_point - section.position.y)

		var bottom = Section.new()
		bottom.position = Vector2i(section.position.x, split_point)
		bottom.size = Vector2i(section.size.x, section.position.y + section.size.y - split_point)
		
		_divide_section(top)
		_divide_section(bottom)
	else:
		var split_point = self._random.randi_range(
			section.position.x + self._parameters.min_section_size, 
			section.position.x + section.size.x - self._parameters.min_section_size
		)
		
		var left = Section.new()
		left.position = Vector2i(section.position.x, section.position.y)
		left.size = Vector2i(split_point - section.position.x, section.size.y)
		
		var right = Section.new()
		right.position = Vector2i(split_point, section.position.y)
		right.size = Vector2i(section.position.x + section.size.x - split_point, section.size.y)
		
		_divide_section(left)
		_divide_section(right)


func _generate_room(dungeon: Dungeon, section: Section) -> Dungeon.Room:
	var width: int = self._random.randi_range(self._parameters.min_section_size - 1, min(section.size.x - 1, self._parameters.max_room_size))
	var height: int = self._random.randi_range(self._parameters.min_section_size - 1, min(section.size.y - 1, self._parameters.max_room_size))
	var x: int = self._random.randi_range(section.position.x, section.position.x + section.size.x - width)
	var y: int = self._random.randi_range(section.position.y, section.position.y + section.size.y - height)
	
	var room: Dungeon.Room = Dungeon.Room.new()
	room.size = Vector2i(width, height)
	room.position = Vector2i(x, y)
	
	for pos_y in room.size.y:
		for pos_x in room.size.x:
			dungeon.tiles[room.position.y + pos_y][room.position.x + pos_x].has_ground = true
	
	return room


func _generate_corridor(dungeon: Dungeon, room1: Dungeon.Room, room2: Dungeon.Room) -> void:
	var center_room1 = Vector2(room1.position.x + room1.size.x / 2, room1.position.y + room1.size.y / 2)
	var center_room2 = Vector2(room2.position.x + room2.size.x / 2, room2.position.y + room2.size.y / 2)
	
	if self._random.randi_range(0, 1) == 0:
		_add_corridor(dungeon, center_room1.x, center_room2.x, center_room1.y, Vector2.AXIS_X)
		_add_corridor(dungeon, center_room1.y, center_room2.y, center_room2.x, Vector2.AXIS_Y)
	else:
		_add_corridor(dungeon, center_room1.y, center_room2.y, center_room1.x, Vector2.AXIS_Y)
		_add_corridor(dungeon, center_room1.x, center_room2.x, center_room2.y, Vector2.AXIS_X)


func _add_corridor(dungeon: Dungeon, start: int, end: int, constant: int, axis: int) -> void:
	for i in range(min(start, end), max(start, end) + 1):
		var point := Vector2.ZERO
		match axis:
			Vector2.AXIS_X: point = Vector2(i, constant)
			Vector2.AXIS_Y: point = Vector2(constant, i)
		
		dungeon.tiles[point.y][point.x].has_ground = true


func add_data(dungeon: Dungeon, type: int, data: Dictionary, data_parameters: DataParameters = DataParameters.new()) -> bool:
	var added: bool = false
	
	var rooms: Array = []
	for room in dungeon.rooms:
		rooms.append(room)
	
	while not added:
		added = true
		
		if rooms.is_empty():
			added = false
			break
		
		var room: Dungeon.Room = rooms[self._random.randi_range(0, rooms.size() - 1)]
		var rect: Rect2 = Rect2(room.position, room.size)
		
		# Avoid walls
		if data_parameters.avoid_walls:
			rect.position.x += 1
			rect.position.y += 1
			rect.size.x -= 2
			rect.size.y -= 2
		
		var positions: Array = []
		for i in range(rect.size.y):
			for j in range(rect.size.x):
				positions.append(Vector2i(rect.position.x + j, rect.position.y + i))
		
		added = false
		
		while not added:
			added = true
			
			if positions.is_empty():
				added = false
				break
			
			var position: Vector2i = positions[self._random.randi_range(0, positions.size() - 1)]
			
			if not data_parameters.avoid_data.is_empty():
				if dungeon.get_tilev(position).has_data(type):
					# Position has data to avoid
					positions.erase(position)
					added = false
			
			dungeon.get_tilev(position).add_data(type, data)
	
	return added

