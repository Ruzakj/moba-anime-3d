class_name HeroCatalog
extends RefCounted

const ROLES=["TANK","FIGHTER","ASSASSIN","MAGE","MARKSMAN","SUPPORT"]

static func all()->Array[Dictionary]:
	var names=["Aegis Ruun","Bront Vale","Kaida Mon","Orren Bast","Tsuba Gran","Riven Kyo","Mara Vex","Daigo Flint","Selka Rune","Torin Ash","Nyra Shade","Kaze Lynx","Veyra Noct","Ren Talon","Sumi Rift","Astra Mio","Luma Hex","Ciel Arca","Yuna Volt","Mirei Frost","Jett Sol","Arin Gale","Kira Bolt","Nami Quill","Ryo Ember","Eira Bloom","Mina Ward","Sora Bell","Tali Dawn","Nero Muse"]
	var out:Array[Dictionary]=[]
	for i in 30:
		var role_idx:int=i/5
		var types=_skill_types_for(i)
		out.append({"id":"hero_%02d"%(i+1),"name":names[i],"role":ROLES[role_idx],"hp":[1500,1250,950,900,900,1050][role_idx]+(i%5)*65,"attack":[55,75,95,80,88,58][role_idx]+(i%5)*4,"defense":[38,26,16,14,13,20][role_idx]+(i%5)*2,"move_speed":5.4+float(i%5)*0.08,"attack_range":[2.3,2.5,2.6,7.0,8.0,6.0][role_idx],"difficulty":1+(i%3),"variant":i,"skills":[_skill("%s I"%names[i],types[0],70+3*i,5.0+(i%3),6.0+(i%4),i,0),_skill("%s II"%names[i],types[1],55+4*i,7.0+(i%4),5.5+(i%5),i,1),_skill("%s III"%names[i],types[2],45+3*i,9.0+(i%5),5.0+(i%3),i,2),_skill("%s Nova"%names[i],types[3],150+6*i,28.0+(i%5)*2.0,8.0+(i%4),i,3)]})
	return out

static func get_by_id(id:String)->Dictionary:
	for h in all():
		if h.id==id:return h
	return all()[0]

static func _skill(name:String,kind:String,power:float,cooldown:float,radius:float,hero:int,slot:int)->Dictionary:
	return {"name":name,"kind":kind,"power":power,"cooldown":cooldown,"radius":radius,"duration":1.0+float((hero+slot)%4)*0.4,"speed":8.0+float(hero%5),"seed":hero*7+slot}

static func _skill_types_for(i:int)->Array[String]:
	var palettes=[["TAUNT","SHIELD","KNOCKUP","BARRIER"],["DASH","LIFESTEAL","CONE","EXECUTE"],["BLINK","MARK","CHAIN","EXECUTE"],["PROJECTILE","AREA","ROOT","AREA_DENIAL"],["MULTISHOT","DASH","ATTACK_SPEED","CHARGE"],["HEAL","SHIELD","SLOW","TEAM_BUFF"]]
	var p:Array=palettes[i/5].duplicate()
	for _n in i%5:p.push_back(p.pop_front())
	return [str(p[0]),str(p[1]),str(p[2]),str(p[3])]
