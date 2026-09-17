class_name Datashard extends RefCounted

signal obtained(datashard:Datashard)
signal equipped(datashard:Datashard)

var id: StringName
var tier: int = 1
var nature_id: StringName
var effects: Array[RunEffect] = []
