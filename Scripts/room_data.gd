extends Node
class_name RoomData
const room = preload("res://Scripts/room.gd")

#the root node of each room MUST BE NAMED Root
var rooms : Array[Room] = [room.Create_Room(
"res://Scenes/test_room1.tscn", 																								#Scene Location                       
4,																																#Num Liquids
[room.Liquid.Water,room.Liquid.Water,room.Liquid.Water,room.Liquid.Water],														#Liquid Types 
[.75,.25,.75,.25],																												#Liquid Chances                     
2,																																#Num Fillings              
[0,0],																															#Terrain Set                                      
[3,4],																															#Terrain ID                       
[.6,1.0],																														#Threshold            
Vector2i(10,10),																												#Noise Scale                              
3,																																#Num Traps              
[.65,.65,.65],																													#Trap Chances                                
6,																																#Num Pathways                   
[room.Direction.Up,room.Direction.Right,room.Direction.Left,room.Direction.Down,room.Direction.Down,room.Direction.Right],		#Pathway Directions                                       
7,																																#Enemy Spawnpoints                     
5,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
false),																															#Has Shop
										room.Create_Room(
"res://Scenes/test_room2.tscn", 																								#Scene Location                       
2,																																#Num Liquids
[room.Liquid.Water,room.Liquid.Water],																							#Liquid Types 
[.5,.5],																														#Liquid Chances                     
2,																																#Num Fillings              
[0,0],																															#Terrain Set                                      
[4,3],																															#Terrain ID                       
[.6,1.0],																														#Threshold            
Vector2i(20,20),																												#Noise Scale                              
2,																																#Num Traps              
[.75,.25],																														#Trap Chances                                
5,																																#Num Pathways                   
[room.Direction.Up,room.Direction.Up,room.Direction.Left,room.Direction.Down,room.Direction.Right],								#Pathway Directions                                       
11,																																#Enemy Spawnpoints                     
8,																																#Enemy Num Goal                               
0,																																#NPC Spawnpoints   
false)]																															#Has Shop
