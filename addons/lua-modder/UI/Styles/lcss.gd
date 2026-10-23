class_name LCSS extends RefCounted

const STYLE_CLASS := &"style_class"
const STATE := &"state"
const PROPERTY := &"property"
const KEYFRAMES := &"keyframes"
const COMMENT := &"comment"

const KIND := [
	STYLE_CLASS, STATE, PROPERTY, KEYFRAMES, COMMENT
]

const FROM = &"from"
const TO = &"to"

const STYLE_CLASS_OPENER := "."
#const STYLE_CLASS_SEPARATOR := "," # TODO
const STATE_OPENER := ":"
const KEYFRAMES_OPENER := "@keyframes"
const BRACKET_OPENER := "{"
const BRACKET_CLOSER := "}"
const PROPERTY_SEPARATOR := ":"
const PROPERTY_CLOSER := ";"

const SINGLE_LINE_COMMENT = "//"
const MULTI_LINE_COMMENT_OPENER = "/*"
const MULTI_LINE_COMMENT_CLOSER = "*/"

const KEYFRAMES_OFFSET_OPTIONS := {
	FROM: 0,
	TO: 1,
}

const COLORS := {
	STYLE_CLASS: "#FFFFFF",
	STATE: "#FF0000",
	PROPERTY: "#00FF00",
	KEYFRAMES: "#0000FF",
}
