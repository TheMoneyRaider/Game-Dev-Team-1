extends Node
class_name RoomData
const room = preload("res://Game Elements/Rooms/room.gd")


###Z ORDERS
#0-9 background enviornmental elements(flooring,etc)
#10-19 background dynamic elements(grass, floor attacks)
#20-29 Player area(player is 20, most enemies are 20)
#30-39 Filling and portals
#40-49 UI Elements
####



#the root node of each room MUST BE NAMED Root
#var rooms : Array[Room] = [room.Create_Room(
#"res://Game Elements/Rooms/test_room1.tscn", 																								#Scene Location                       
#4,																																#Num Liquids
#[Globals.Liquid.Water,Globals.Liquid.Water,Globals.Liquid.Water,Globals.Liquid.Water],														#Liquid Types 
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
#[Globals.Trap.Spike, Globals.Trap.Tile, Globals.Trap.Tile],																				#Trap Types                         
#6,																																#Num Pathways                   
#[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down,Globals.Direction.Down,Globals.Direction.Right],		#Pathway Directions                        
#5,																																#Enemy Num Goal                               
#0,																																#NPC Spawnpoints   
#false),																															#Has Shop
										#room.Create_Room(
#"res://Game Elements/Rooms/test_room2.tscn", 																								#Scene Location                       
#2,																																#Num Liquids
#[Globals.Liquid.Water,Globals.Liquid.Water],																							#Liquid Types 
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
#[Globals.Trap.Tile, Globals.Trap.Spike],																				#Trap Types                                        
#5,																																#Num Pathways                   
#[Globals.Direction.Up,Globals.Direction.Up,Globals.Direction.Left,Globals.Direction.Down,Globals.Direction.Right],								#Pathway Directions                        
#8,																																#Enemy Num Goal                               
#0,																																#NPC Spawnpoints   
#false),room.Create_Room(
#"res://Game Elements/Rooms/test_room3.tscn", 																					#Scene Location                       
#0,																																#Num Liquids
#[],																															#Liquid Types 
#[],																															#Liquid Chances                     
#0,																																#Num Fillings              
#[0],																															#Terrain Set                                      
#[0],																															#Terrain ID                       
#[.6,1.0],																														#Threshold            
#randi(),																														#Noise Seed           
#FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
#.1,																															#Noise Frequency                        
#0,																																#Num Traps              
#[],																															#Trap Chances                                
#[],																															#Trap Types                         
#4,																																#Num Pathways                   
#[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down],									#Pathway Directions                       
#3,																																#Enemy Num Goal                               
#0,																																#NPC Spawnpoints   
#false)]																														#Has Shop


#Dev array
#
#var rooms : Array[Room] = [room.Create_Room(
#"res://Game Elements/Rooms/test_room1.tscn", 																								#Scene Location                       
#4,																																#Num Liquids
#[Globals.Liquid.Water,Globals.Liquid.Water,Globals.Liquid.Water,Globals.Liquid.Water],														#Liquid Types 
#[.75,.25,.75,.25],																												#Liquid Chances                     
#2,																																#Num Fillings              
#[0,0],																															#Terrain Set                                      
#[3,4],																															#Terrain ID                       
#[.6,1.0],																														#Threshold            
#randi(),																														#Noise Seed           
#FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
#.1,																																#Noise Frequency                        
#2,																																#Num Traps              
#[.65,.65],																														#Trap Chances                                
#[Globals.Trap.Spike, Globals.Trap.Tile],																						#Trap Types                         
#6,																																#Num Pathways                   
#[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down,Globals.Direction.Down,Globals.Direction.Right],		#Pathway Directions                        
#5,																																#Enemy Num Goal                               
#0,																																#NPC Spawnpoints   
#false,																															#Is a shop room?
#["res://Game Elements/Characters/laser_enemy.tscn","res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
#[.25,.75],																															#Weights for those enemies to spawn
#0)]


var rooms : Array[Room] = [room.Create_Room(
"res://Game Elements/Rooms/sci_fi/cyberspace1.tscn", 																			#Scene Location                       
0,																																#Num Liquids
[],																																#Liquid Types 
[],																																#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down],									#Pathway Directions                       
10,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
false,																															#Is a shop room?
["res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
.25),																															#Chance for waves to be segmented
room.Create_Room(			
"res://Game Elements/Rooms/sci_fi/cyberspace2.tscn", 																			#Scene Location                       
0,																																#Num Liquids
[],																																#Liquid Types 
[],																																#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down],									#Pathway Directions                       
18,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
false,																															#Is a shop room?
["res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
.25),																															#Chance for waves to be segmented
room.Create_Room(
"res://Game Elements/Rooms/sci_fi/cyberspace3.tscn", 																			#Scene Location                       
0,																																#Num Liquids
[],																																#Liquid Types 
[],																																#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down],									#Pathway Directions                       
12,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
false,																															#Is a shop room?
["res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
.25),																															#Chance for waves to be segmented
room.Create_Room(
"res://Game Elements/Rooms/sci_fi/cyberspace4.tscn", 																			#Scene Location                       
0,																																#Num Liquids
[],																																#Liquid Types 
[],																																#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down],									#Pathway Directions                       
14,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
false,																															#Is a shop room?
["res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
.25),																															#Chance for waves to be segmented
room.Create_Room(
"res://Game Elements/Rooms/sci_fi/cyberspace5.tscn", 																			#Scene Location                       
0,																																#Num Liquids
[],																																#Liquid Types 
[],																																#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
6,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down,Globals.Direction.Down,Globals.Direction.Down],		#Pathway Directions                       
16,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
false,																															#Is a shop room?
["res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
.25),																															#Chance for waves to be segmented
room.Create_Room(
"res://Game Elements/Rooms/sci_fi/cyberspace6.tscn", 																			#Scene Location                       
0,																																#Num Liquids
[],																																#Liquid Types 
[],																																#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down],									#Pathway Directions                       
8,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
false,																															#Is a shop room?
["res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
.25),																															#Chance for waves to be segmented
room.Create_Room(
"res://Game Elements/Rooms/medieval_shop.tscn", 																				#Scene Location                       
0,																																#Num Liquids
[],																																#Liquid Types 
[],																																#Liquid Chances                     
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
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Right,Globals.Direction.Left,Globals.Direction.Down],									#Pathway Directions                       
0,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
true,																															#Is a shop room?
[],																																#Enemies That can spawn in this room
[],																															#Weights for those enemies to spawn
0),
room.Create_Room(
"res://Game Elements/Rooms/medieval/outside1.tscn", 																		#Scene Location                       
0,																																#Num Liquids
[],																										#Liquid Types 
[],																										#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Down,Globals.Direction.Left,Globals.Direction.Right],									#Pathway Directions                     
10,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
false,																															#Is a shop room?
["res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
0),
room.Create_Room(
"res://Game Elements/Rooms/medieval/outside2.tscn", 																		#Scene Location                       
0,																																#Num Liquids
[Globals.Liquid.Water,Globals.Liquid.Water,Globals.Liquid.Water,Globals.Liquid.Water,Globals.Liquid.Water],																										#Liquid Types 
[.9,.9,.9,1,1],																										#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
4,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Down,Globals.Direction.Left,Globals.Direction.Right],									#Pathway Directions                     
12,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
false,																															#Is a shop room?
["res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
0)]																															#Chance for waves to be segmented



var testing_room : Room = room.Create_Room(
"res://Game Elements/Rooms/medieval/outside3.tscn", 																		#Scene Location                       
0,																																#Num Liquids
[],																										#Liquid Types 
[],																										#Liquid Chances                     
0,																																#Num Fillings              
[],																																#Terrain Set                                      
[],																																#Terrain ID                       
[],																																#Threshold            
randi(),																														#Noise Seed           
FastNoiseLite.TYPE_SIMPLEX_SMOOTH,																								#Noise Type       
.1,																																#Noise Frequency                        
0,																																#Num Traps              
[],																																#Trap Chances                                
[],																																#Trap Types                         
5,																																#Num Pathways                   
[Globals.Direction.Up,Globals.Direction.Up,Globals.Direction.Down,Globals.Direction.Left,Globals.Direction.Right],									#Pathway Directions                     
12,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
false,																															#Is a shop room?
["res://Game Elements/Characters/dynamEnemy.tscn"],																				#Enemies That can spawn in this room
[1.0],																															#Weights for those enemies to spawn
0)																															#Chance for waves to be segmented
