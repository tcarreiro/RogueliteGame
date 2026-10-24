class_name ItemContainerOpResult extends RefCounted
## Result of an ItemContainer operation: real ones (add, remove...) and simulated ones (can_*).
## Invariant: moved_quantity + remained_quantity == quantity that was requested.

## New reasons go at the END of the enum (saved/logged values keep their meaning).
enum FailReason {
	NONE,
	NOT_FOUND,
	QTY_INVALID,
	FULL,
	TAG_REJECTED,
	TAG_FORBIDDEN,
	DUPLICATE,    # same unique instance added twice
	NOT_ENOUGH,   # asked to remove more than exists
	LOCKED,
}

## Did (or, for can_* methods, would) any quantity be transferred?
var ok: bool = false
var fail_reason: FailReason = FailReason.NONE
var moved_quantity: int = 0
var remained_quantity: int = 0
## Extra data: detached items on remove, previous item on swap, etc.
var payload: Variant = null


#region Constructors
static func complete(p_moved: int, p_payload: Variant = null) -> ItemContainerOpResult:
	assert(p_moved > 0, "complete() needs moved > 0")
	var op_result := ItemContainerOpResult.new()
	op_result.ok = true
	op_result.moved_quantity = p_moved
	op_result.remained_quantity = 0
	op_result.payload = p_payload
	return op_result


static func partial(p_moved: int, p_remained: int, p_payload: Variant = null) -> ItemContainerOpResult:
	assert(p_moved > 0 and p_remained > 0, "partial() needs moved > 0 and remained > 0")
	var op_result := ItemContainerOpResult.new()
	op_result.ok = true
	op_result.moved_quantity = p_moved
	op_result.remained_quantity = p_remained
	op_result.payload = p_payload
	return op_result


## p_remained = everything that could not be moved (the whole request, when nothing moved).
static func fail(p_remained: int, p_fail_reason: FailReason) -> ItemContainerOpResult:
	assert(p_fail_reason != FailReason.NONE, "fail() needs a reason")
	var op_result := ItemContainerOpResult.new()
	op_result.ok = false
	op_result.fail_reason = p_fail_reason
	op_result.moved_quantity = 0
	op_result.remained_quantity = p_remained
	return op_result
#endregion


#region Queries
func is_complete() -> bool:
	return ok and remained_quantity == 0


func is_partial() -> bool:
	return ok and remained_quantity > 0


func get_requested_quantity() -> int:
	return moved_quantity + remained_quantity


func get_fail_reason_name() -> String:
	return FailReason.keys()[fail_reason]


func _to_string() -> String:
	if ok:
		return "ItemContainerOpResult(ok moved=%d remained=%d)" % [moved_quantity, remained_quantity]
	return "ItemContainerOpResult(fail %s remained=%d)" % [get_fail_reason_name(), remained_quantity]
#endregion
