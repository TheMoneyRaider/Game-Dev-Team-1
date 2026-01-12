extends Node
class_name RoomData
const room = preload("res://Game Elements/Rooms/room.gd")

#the root node of each room MUST BE NAMED Root
#var rooms : Array[Room] = [room.Create_Room(
#"res://Game Elements/Rooms/test_room1.tscn", 																								#Scene Location                       
#4,																																#Num Liquids
#[room.Liquid.Water,room.Liquid.Water,room.Liquid.Water,room.Liquid.Water],														#Liquid Types 
#[.75,.25,.75,.25],																												#Liquid Chances                     
#2,																																#Num Fillings              
#[0,0],																															#Terrain Set                                      
#[3,4],																															#Terrain ID                       
#[.6,1.0],																														#Threshold            
#randi(),																														#Noise Seed           
#FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
#.1,																															#Noise Frequency                        
#3,																																#Num Traps              
#[.65,.65,.65],																													#Trap Chances                                
#[room.Trap.Spike, room.Trap.Tile, room.Trap.Tile],																				#Trap Types                         
#6,																																#Num Pathways                   
#[room.Direction.Up,room.Direction.Right,room.Direction.Left,room.Direction.Down,room.Direction.Down,room.Direction.Right],		#Pathway Directions                        
#5,																																#Enemy Num Goal                               
#0,																																#NPC Spawnpoints   
#false),																															#Has Shop
										#room.Create_Room(
#"res://Game Elements/Rooms/test_room2.tscn", 																								#Scene Location                       
#2,																																#Num Liquids
#[room.Liquid.Water,room.Liquid.Water],																							#Liquid Types 
#[.5,.5],																														#Liquid Chances                     
#2,																																#Num Fillings              
#[0,0],																															#Terrain Set                                      
#[3,4],																															#Terrain ID                       
#[.6,1.0],																														#Threshold          
#randi(),																														#Noise Seed           
#FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
#.1,																																#Noise Frequency                       
#2,																																#Num Traps              
#[.75,.25],																														#Trap Chances                          
#[room.Trap.Tile, room.Trap.Spike],																				#Trap Types                                        
#5,																																#Num Pathways                   
#[room.Direction.Up,room.Direction.Up,room.Direction.Left,room.Direction.Down,room.Direction.Right],								#Pathway Directions                        
#8,																																#Enemy Num Goal                               
#0,																																#NPC Spawnpoints   
#false),room.Create_Room(
#"res://Game Elements/Rooms/test_room3.tscn", 																					#Scene Location                       
#0,																																#Num Liquids
#[],																																#Liquid Types 
#[],																																#Liquid Chances                     
#0,																																#Num Fillings              
#[0],																															#Terrain Set                                      
#[0],																															#Terrain ID                       
#[.6,1.0],																														#Threshold            
#randi(),																														#Noise Seed           
#FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
#.1,																																#Noise Frequency                        
#0,																																#Num Traps              
#[],																																#Trap Chances                                
#[],																																#Trap Types                         
#4,																																#Num Pathways                   
#[room.Direction.Up,room.Direction.Right,room.Direction.Left,room.Direction.Down],												#Pathway Directions                       
#3,																																#Enemy Num Goal                               
#0,																																#NPC Spawnpoints   
#false)]																															#Has Shop


#Dev array

var rooms : Array[Room] = [room.Create_Room(
"res://Game Elements/Rooms/test_room1.tscn", 																					#Scene Location                       
4,																																#Num Liquids
[room.Liquid.Water,room.Liquid.Water,room.Liquid.Water,room.Liquid.Water],														#Liquid Types 
[.75,.25,.75,.25],																												#Liquid Chances                     
2,																																#Num Fillings              
[0,0],																															#Terrain Set                                      
[3,4],																															#Terrain ID                       
[.6,1.0],																														#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
3,																																#Num Traps              
[.65,.65,.65],																													#Trap Chances                                
[room.Trap.Spike, room.Trap.Tile, room.Trap.Tile],																				#Trap Types                         
6,																																#Num Pathways                   
[room.Direction.Up,room.Direction.Right,room.Direction.Left,room.Direction.Down,room.Direction.Down,room.Direction.Right],		#Pathway Directions                       
5,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
false)]


var testing_room : Room = room.Create_Room(
"res://Game Elements/Rooms/testing_room.tscn", 																								#Scene Location                       
0,																																#Num Liquids
[],																																#Liquid Types 
[1.0],																															#Liquid Chances                     
2,																																#Num Fillings              
[0,0],																															#Terrain Set                                      
[3,4],																															#Terrain ID                       
[.6,1.0],																														#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
2,																																#Num Pathways                   
[room.Direction.Up,room.Direction.Down],																						#Pathway Directions                     
1,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
false)
