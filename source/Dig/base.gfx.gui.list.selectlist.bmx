Rem
	====================================================================
	GUI Select List
	====================================================================

	Code contains:
	- TGUISelectList: list allowing to select a specific item
	- TGUISelectListItem: selectable list item


	====================================================================
	LICENCE

	Copyright (C) 2002-2019 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.
	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.
	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
End Rem
SuperStrict
Import "base.gfx.gui.list.base.bmx"



Type TGUISelectList Extends TGUIListBase
	Field selectedEntry:TGUIobject = Null


	Method GetClassName:String()
		Return "tguiselectlist"
	End Method


    Method Create:TGUISelectList(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
		Super.Create(position, dimension, limitState)

		'register listeners in a central location
		RegisterListeners()

		Return Self
	End Method


	Method Remove:Int()
		Super.Remove()
		If selectedEntry
			selectedEntry.Remove()
			selectedEntry = Null
		EndIf
	End Method


	'overrideable
	Method RegisterListeners:Int()
		'we want to know about clicks
		AddEventListener(EventManager.registerListenerMethod("GUIListItem.onClick",	Self, "onClickOnEntry"))
	End Method


	Method onClickOnEntry:Int(triggerEvent:TEventBase)
		Local entry:TGUIListItem = TGUIListItem( triggerEvent.getSender() )
		If Not entry Then Return False

		'ignore entries of other lists
		If entry._parent <> Self.guiEntriesPanel Then Return False

		'default to left button if nothing was sent
		Local button:Int = triggerEvent.GetData().GetInt("button", 1)
		If button = 1
			SelectEntry(entry)
		EndIf
		
		Return True
	End Method


	Method SelectEntry:Int(entry:TGUIListItem)
		'only mark selected if we are owner of that entry
		If Self.HasItem(entry)
			'remove old entry
			Self.deselectEntry()
			Self.selectedEntry = entry
			Self.selectedEntry.SetSelected(True)

			'inform others: we successfully selected an item
			EventManager.triggerEvent( TEventSimple.Create( "GUISelectList.onSelectEntry", New TData.Add("entry", entry) , Self ) )
		EndIf
	End Method


	Method DeselectEntry:Int()
		If TGUIListItem(selectedEntry)
			TGUIListItem(selectedEntry).SetSelected(False)
			selectedEntry = Null
		EndIf
	End Method


	Method GetSelectedEntry:TGUIobject()
		Return selectedEntry
	End Method
End Type




Type TGUISelectListItem Extends TGUIListItem


	Method GetClassName:String()
		Return "tguiselectlistitem"
	End Method


    Method Create:TGUISelectListItem(position:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		If Not dimension Then dimension = New TVec2D.Init(80,20)

		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(position, dimension, "")

		SetValue(value)

		GUIManager.add(Self)

		Return Self
	End Method


	Method DrawBackground()
		Local oldCol:TColor = New TColor.Get()

		'available width is parentsDimension minus startingpoint
		'Local maxWidth:Int = GetParent().getContentScreenWidth() - rect.getX()
		Local maxWidth:Int = GetScreenRect().GetW()
		If isHovered()
			SetColor 250,210,100
			DrawRect(GetScreenRect().GetX(), GetScreenRect().GetY(), maxWidth, GetScreenRect().GetH())
			SetColor 255,255,255
		ElseIf isSelected()
			SetAlpha GetAlpha()*0.5
			SetColor 250,210,100
			DrawRect(GetScreenRect().GetX(), GetScreenRect().GetY(), maxWidth, GetScreenRect().GetH())
			SetColor 255,255,255
			SetAlpha GetAlpha()*2.0
		EndIf

		oldCol.SetRGBA()
	End Method


	Method DrawContent()
		DrawValue()
	End Method


	Method Draw()
		If Not isDragged()
			'this allows to use a list in a modal dialogue
			Local upperParent:TGUIObject = TGUIListBase.FindGUIListBaseParent(Self)
			If upperParent Then upperParent.RestrictViewPort()

			Super.Draw()

			If upperParent Then upperParent.ResetViewPort()
		Else
			Super.Draw()
		EndIf
	End Method


	Method UpdateLayout()
	End Method
End Type