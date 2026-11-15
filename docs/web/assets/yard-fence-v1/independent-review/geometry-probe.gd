extends SceneTree
var checks := 0
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures.append(message)
func edge_key(a: Vector2i, b: Vector2i) -> String:
 return '%d,%d>%d,%d' % [a.x,a.y,b.x,b.y]
func _initialize() -> void: call_deferred('run')
func run() -> void:
 var court := Courtyard.new()
 root.add_child(court)
 court.set_active(true)
 var nav := court.navigation
 var floor: Dictionary = nav._floor.duplicate()
 var expected: Dictionary = {}
 for y: int in range(nav.grid.region.end.y + 1):
  for x: int in range(nav.grid.region.end.x):
   if bool(floor.get(Vector2i(x,y-1),false)) != bool(floor.get(Vector2i(x,y),false)):
    expected[edge_key(Vector2i(x,y),Vector2i(x+1,y))] = true
 for x: int in range(nav.grid.region.end.x + 1):
  for y: int in range(nav.grid.region.end.y):
   if bool(floor.get(Vector2i(x-1,y),false)) != bool(floor.get(Vector2i(x,y),false)):
    expected[edge_key(Vector2i(x,y),Vector2i(x,y+1))] = true
 check(expected.size()==82,'Independent complete boundary contains82 edges')
 var gate_data: Dictionary = OfficeLayout._read_json(Courtyard.LAYOUT_PATH)
 check(gate_data.boundary_gates.size()==1,'Exactly one authored Studio gate')
 var gate: Dictionary = gate_data.boundary_gates[0]
 check(OfficeLayout.vector(gate['from'])==Vector2i(15,20) and OfficeLayout.vector(gate['to'])==Vector2i(17,20),'Gate has exact two-cell boundary extent')
 check(gate.interaction_id=='office-return' and nav.world(OfficeLayout.vector(gate.approach))==Courtyard.SPAWN,'Gate resolves existing return affordance')
 expected.erase(edge_key(Vector2i(15,20),Vector2i(16,20)))
 expected.erase(edge_key(Vector2i(16,20),Vector2i(17,20)))
 check(court.fence.connections.size()==81 and court.fence.edges.size()==80,'Open perimeter has81 posts and80 rails')
 check(court.fence.connections[Vector2i(15,20)]==YardFence.WEST and court.fence.connections[Vector2i(17,20)]==YardFence.EAST,'Both terminal posts retain correct one-sided connection')
 check(not court.fence.connections.has(Vector2i(16,20)),'No post blocks the middle of the gate')
 var actual: Dictionary = {}
 for edge: Dictionary in court.fence.edges:
  var key := edge_key(edge['from'],edge['to'])
  check(not actual.has(key),'Unique ground edge '+key)
  actual[key] = true
 check(actual==expected,'Fence equals independent boundary scan minus exactly declared Studio opening')
 var seen: Dictionary = {}
 var queue: Array[Vector2i] = [nav.cell_at(Courtyard.SPAWN)]
 var at := 0
 while at<queue.size():
  var c := queue[at]
  at+=1
  if seen.has(c) or not nav.walkable(c): continue
  seen[c]=true
  for d: Vector2i in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   var next := c+d
   if not nav.walkable(next): continue
   var start := Vector2i(maxi(c.x,next.x),mini(c.y,next.y)) if d.x!=0 else Vector2i(mini(c.x,next.x),maxi(c.y,next.y))
   var finish := start + (Vector2i.DOWN if d.x!=0 else Vector2i.RIGHT)
   check(not actual.has(edge_key(start,finish)),'No fence ground edge crosses reachable center-to-center path')
   if not seen.has(next): queue.append(next)
 var covered: Array[Dictionary] = []
 for c: Vector2i in seen:
  var point := nav.world(c)
  for child: Node in court.fence.get_children():
   var sprite := child as Sprite2D
   check(sprite.position==sprite.position.round() and sprite.scale==Vector2.ONE and is_zero_approx(sprite.rotation),'Native integer registration without transforms')
   if VisibleSurface.painted(sprite,point+Vector2(0.5,0.5)):
    var vertex: Vector2i = sprite.get_meta('vertex')
    var ground := Vector2(vertex*32)
    var kind := str(sprite.get_meta('kind'))
    covered.append({'cell':[c.x,c.y],'kind':kind,'ground':[ground.x,ground.y],'z':sprite.z_index})
    check(kind=='horizontal' and ground.y>point.y and ground.y-point.y<=24,'Projected fence paint at a cell center belongs only to its front perimeter')
 for x: int in [496,528]:
  for child: Node in court.fence.get_children():
   check(not VisibleSurface.painted(child as Sprite2D,Vector2(x+0.5,624.5)),'Gate front-row centers have no fence pixels')
 check(not nav.walkable(Vector2i(15,20)) and not nav.walkable(Vector2i(16,20)),'Visual opening does not create a new world traversal beyond the existing return action')
 var ground_distance := INF
 for c: Vector2i in seen:
  var p:=nav.world(c)
  for e: Dictionary in court.fence.edges:
   var a:=Vector2(e['from']*32)
   var b:=Vector2(e['to']*32)
   var dist:=p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))
   ground_distance=minf(ground_distance,dist)
 check(ground_distance>=16,'Every reachable center is at least half a tile from fence ground')
 var nav_before: Array[Vector2i] = []
 for c: Vector2i in floor:
  if nav.walkable(c):nav_before.append(c)
 var path_before:=nav.path(Courtyard.SPAWN,Vector2(144,112),'founder')
 court.fence.free()
 var nav_after: Array[Vector2i] = []
 for c: Vector2i in floor:
  if nav.walkable(c):nav_after.append(c)
 check(nav_before==nav_after and nav.path(Courtyard.SPAWN,Vector2(144,112),'founder')==path_before,'Removing visual fence changes no walkable cell or route')
 var result: Dictionary={'checks':checks,'failures':failures,'expectedEdges':expected.size(),'actualEdges':actual.size(),'reachableCells':seen.size(),'minimumCenterToGroundEdgePixels':ground_distance,'projectedPaintAtReachableCenters':covered,'note':'Fence ground never crosses reachable centers/paths. Its raised front rails may intentionally project over front-row feet; that occlusion needs in-app visual approval.'}
 FileAccess.open('/private/tmp/startup-valley-fence-independent-gated-geometry.json',FileAccess.WRITE).store_string(JSON.stringify(result,'  ')+'\n')
 court.free()
 print('Independent fence geometry: ',checks,' checks, ',failures.size(),' failures; reachable=',seen.size(),', projectedCenters=',covered.size())
 quit(0 if failures.is_empty() else 1)
