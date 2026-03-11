package main

import "core:bytes"
import "core:crypto/hash"
import "core:path/filepath"
import "core:strings"
import "core:encoding/cbor"
import b2 "vendor:box2d"
import ion "shared:engine"
import "core:fmt"
import "core:time"
import "core:os"

game_level :: struct 
{
	using engine : ion.engine_world,
	entities     : [dynamic]entity `cbor:"-"`,
	entity_defs  : [dynamic]entity_def,
	
	name         : string,
	
	cam          : ion.Camera,

	player       : game_player,
	player_index : i32,
}

cbor_flags : cbor.Encoder_Flags : 
{
	.Self_Described_CBOR, 
	.Deterministic_Int_Size, 
	.Deterministic_Float_Size, 
}

@(require_results)
time_to_string_hms :: proc(t: time.Time, buf: []u8) -> (res: string) #no_bounds_check {
	assert(len(buf) >= time.MIN_HMS_LEN)
	h, m, s := time.clock(t)

	buf[7] = '0' + u8(s % 10); s /= 10
	buf[6] = '0' + u8(s)
	buf[5] = '-'
	buf[4] = '0' + u8(m % 10); m /= 10
	buf[3] = '0' + u8(m)
	buf[2] = '-'
	buf[1] = '0' + u8(h % 10); h /= 10
	buf[0] = '0' + u8(h)

	return string(buf[:time.MIN_HMS_LEN])
}

level_load_from_files :: proc(game: ^game_state)
{
	
	files, err := os.read_all_directory_by_path("levels", context.allocator)
	
	for file in files 
	{
		if os.is_file(file.fullpath)
		{
			level_init_from_path(game, file.fullpath) 
		}
	}
}

level_init_from_path :: proc(game: ^game_state, path : string)
{
	
	if !os.exists(path)
	{
		fmt.println("File not exist")
		return
	}
	
	if os.is_dir(path)
	{
		fmt.println("Path is dir")
		return
	}
	
	level_name := strings.clone(filepath.stem(path))
	data , err := os.read_entire_file_from_path(path, context.allocator)
	
	if err != nil
	{
		fmt.eprintf("Failed to read file %s\n", err)
		return
	}
	
	game.levels[level_name] = {}
	
	curr_level        := &game.levels[level_name]
	curr_level.name, _ = strings.clone(level_name)
	curr_level.relations = {}
	game.curr_level    = strings.clone(level_name)
	curr_level.relations = make(map[^ion.static_index][dynamic]ion.static_index_global)
	
	if len(data) > 0
	{
		unmarshall_err := cbor.unmarshal(data, curr_level)
		
		if unmarshall_err != nil
		{
			fmt.eprintf("Failed to unmarshall level file %s", unmarshall_err)
			return
		} else
		{
			level_reload(curr_level)
			state.draw.cam = curr_level.cam
			
			for key, val in curr_level.relations_serializeable
			{
				index  := curr_level.static_indexes[key]
				entity := curr_level.entities[index]
				
				curr_level.relations[entity.index] = {}
				for v in val do append(&curr_level.relations[entity.index], v)
			}
		}
	}


	//create_player(curr_level.world_id, &curr_level.player)
	delete(data)
}


/*
	Checks hash of current level state and file's hash
	If both hash is same the exits
	
	Save the current level to backups directory
	
*/
level_save_to_file :: proc(level : ^game_level)
{
	
	level_path          := fmt.tprintf("levels/%s.cbor", level.name)
	
	level.cam = state.draw.cam
	
	//Relation serializeable
	{
		clear(&level.relations_serializeable)
		for key, val in &level.relations
		{
			if key != nil
			{
				level.relations_serializeable[key^] = {}
				for v in val do append(&level.relations_serializeable[key^], v)
			}
		}
	}
	
	binary, cbor_err    := cbor.marshal_into_bytes(level^, cbor_flags)
	
	if cbor_err != nil
	{
		fmt.eprintf("Failed to marshall level %s", cbor_err)
		return
	}
	
	
	binary_hash         := hash.hash_bytes(.SHA3_512, binary)
	file_hash, hash_err := hash.hash_file_by_name(.SHA3_512, level_path)
	
	if bytes.compare(binary_hash, file_hash) == 0
	{
		fmt.println("No changes detected")
		return
	}
	
	curr_time := time.now()
	
	buf      : [time.MIN_YYYY_DATE_LEN]u8
	time_buf : [time.MIN_HMS_LEN]u8
	
	date_str := time.to_string_yyyy_mm_dd(curr_time, buf[:])
	time_str := time_to_string_hms(curr_time, time_buf[:])
	
	if !os.exists("levels")
	{
		err := os.mkdir("levels")
		if err != nil
		{
			fmt.println("Failed to create levels directory")
			fmt.println(err)
		}
	}
	
	
	
	//If file exists then create backup
	if os.exists(level_path)
	{
		backup_dir_path  := fmt.tprintf("levels/backups/%s",date_str)
		backup_file_path := fmt.tprintf("levels/backups/%s/%s-%s", date_str, level.name, time_str)
		
		bk_err      := os.make_directory_all(backup_dir_path)
		
		if bk_err != nil
		{
			fmt.eprintf("Failed to create backup directory %s", bk_err)
		}else
		{
			bk_err  = os.copy_file(backup_file_path, level_path)
			if bk_err != nil{
				fmt.eprintf("Failed to copy file %s\n", bk_err)
			}
		}
	}
	success := os.write_entire_file_from_bytes(level_path, binary)
	if success != nil
	{
		fmt.eprintf("Failed to save level %s", success)
	}
	
}

level_reload :: proc(level: ^game_level)
{
	clear(&level.entities)
	clear(&level.static_indexes)
	
	if level.world_id != b2.nullWorldId do b2.DestroyWorld(level.world_id)
	
	{
		world_def        := b2.DefaultWorldDef()
		b2.SetLengthUnitsPerMeter(LPUM)
		world_def.gravity = { 0, -9.8 * LPUM}
		level.world_id    = b2.CreateWorld(world_def)
	}
	
	for &def, i in &level.entity_defs
	{
		new_entity := entity_create_by_type(&def, level.world_id, i32(i))
		
		append(&level.entities, new_entity)
		
		if new_entity.index != nil do level.static_indexes[new_entity.index^] = i

		if new_entity.type == .PLAYER
		{
			level.player_index = i32(i)
		}
	}

	//Initilize joints one by one
	{
		for &def in &level.distant_joint_defs
		{

			//Get entity_a and entity_b

			if def.entity_a <= 0 do continue
			if def.entity_b <= 0 do continue

			entity_a   := &level.entities[level.static_indexes[def.entity_a]]
			def.bodyIdA = entity_a.body_id

			entity_b   := &level.entities[level.static_indexes[def.entity_b]]
			def.bodyIdB = entity_b.body_id

			append(&level.joints, b2.CreateDistanceJoint(level.world_id, def.def))
		}
	}
	level.player.e = &level.entities[level.player_index]
}














