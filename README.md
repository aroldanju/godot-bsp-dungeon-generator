
# Godot BSP Dungeon Generator
A basic Godot addon to generate dungeons by using BSP algorithm.

## Getting started
1. Download or clone this repository.
2. Copy the folder addons/bsp_dungeon_generator to your addons path.
3. Enable the plugin.

More information about addons at [Godot - Installing Plugins](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)

## How to use
Instance a BSPDungeonGenerator object and generate the dungeon:

    var dungeon_generator := BSPDungeonGenerator.new()
    var dungeon := dungeon_generator.generate()

Optionally, you can modify the generation by creating a Parameters object.

    # Create your own custom parameters
    var parameters := BSPDungeonGenerator.Parameters.new()
    parameters.seed = 123456789
    parameters.size = Vector2i(25, 25)
    
    var dungeon := dungeon_generator.generate(parameters)
  
  Once the dungeon has been created, you can add your custom data by using `add_data` function:

    # Avoid create data touching walls.
    var data_parameters := BSPDungeonGenerator.DataParameters.new()
    data_parameters.avoid_walls = true
    
    # Generate two "objects"
    dungeon_generator.add_data(dungeon, 0, { "type": "start" }, data_parameters)
    dungeon_generator.add_data(dungeon, 1, { "type": "exit" }, data_parameters)

## Credits
Assets used in sample were made by [Kenney - 1 Bit Pack](https://www.kenney.nl/assets/1-bit-pack).

## License
Addon under [GPLv3](https://github.com/aroldanju/godot-bsp-dungeon-generator/blob/main/LICENSE) license.

