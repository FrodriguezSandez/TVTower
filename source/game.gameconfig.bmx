SuperStrict
Import "Dig/base.util.data.bmx"
Import "Dig/base.util.rectangle.bmx"

'generic variables shared across the whole game
Type TGameConfig {_exposeToLua}
	'which figure/entity to follow with the camera?
	Field observerMode:int = False
	Field observedObject:object = null
	Field interfaceRect:TRectangle = new TRectangle.Init(0,385, 800,215)
	Field nonInterfaceRect:TRectangle = new TRectangle.Init(0,0, 800,385)
	Field isChristmasTime:int = False
	Field devGUID:string
	Field _values:TData
	Field _modifiers:TData

	Method IsObserved:int(obj:object)
		if not observerMode then return False
		return observedObject = obj
	End Method


	Method GetObservedObject:object()
		if not observerMode then return Null

		return observedObject
	End Method


	Method SetObservedObject:int(obj:object)
		observedObject = obj

		return True
	End Method


	Method GetValues:TData()
		if not _values then _values = new TData
		return _values
	End Method


	Method GetModifier:Float(key:string, defaultValue:Float=1.0)
		if not _modifiers then return defaultValue
		return _modifiers.GetFloat(key, defaultValue)
	End Method


	Method SetModifier(key:string, value:Float)
		if not _modifiers then _modifiers = new TData
		_modifiers.AddNumber(key, value)
	End Method
End Type

Global GameConfig:TGameConfig = new TGameConfig