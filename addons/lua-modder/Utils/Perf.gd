class_name Perf extends RefCounted

static var _stack: Array = []        # [chave, início, tempo dos filhos]
static var calls := {}
static var own := {}                 # tempo próprio (exclusivo)
static var incl := {}                # tempo inclusivo

static func begin(key: String) -> void:
	_stack.push_back([key, Time.get_ticks_usec(), 0])

static func end() -> void:
	var e: Array = _stack.pop_back()
	var total := Time.get_ticks_usec() - int(e[1])
	var k: String = e[0]
	calls[k] = calls.get(k, 0) + 1
	own[k] = own.get(k, 0) + total - int(e[2])
	incl[k] = incl.get(k, 0) + total
	if not _stack.is_empty():
		_stack.back()[2] += total

static func dump() -> void:
	var keys := own.keys()
	keys.sort_custom(func(a, b): return own[a] > own[b])
	var sum := 0
	for k in keys:
		sum += own[k]
		print("[PERF] %-18s %4d x  próprio %7.2f ms  incl %7.2f ms" % [k, calls[k], own[k] / 1000.0, incl[k] / 1000.0])
	print("[PERF] soma dos tempos próprios: %.2f ms" % (sum / 1000.0))
	calls.clear(); own.clear(); incl.clear(); _stack.clear()
