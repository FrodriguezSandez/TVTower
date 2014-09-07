
'Interface, border, TV-antenna, audience-picture and number, watch...
'updates tv-images shown and so on
Type TInGameInterface
	Field gfx_bottomRTT:TImage
	Field CurrentProgramme:TSprite
	Field CurrentProgrammeOverlay:TSprite
	Field CurrentAudience:TImage
	Field CurrentProgrammeText:String
	Field CurrentProgrammeToolTip:TTooltip
	Field CurrentAudienceToolTip:TTooltipAudience
	Field MoneyToolTip:TTooltip
	Field BettyToolTip:TTooltip
	Field CurrentTimeToolTip:TTooltip
	Field tooltips:TList = CreateList()
	Field noiseSprite:TSprite
	Field noiseAlpha:Float	= 0.95
	Field noiseDisplace:Trectangle = new TRectangle.Init(0,0,0,0)
	Field ChangeNoiseTimer:Float= 0.0
	Field ShowChannel:Byte 	= 1
	Field BottomImgDirty:Byte = 1

	Global _instance:TInGameInterface


	Function GetInstance:TInGameInterface()
		if not _instance then _instance = new TInGameInterface.Init()
		return _instance
	End Function


	'initializes an interface
	Method Init:TInGameInterface()
		CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_none")

		CurrentProgrammeToolTip = TTooltip.Create("", "", 40, 395)
		CurrentProgrammeToolTip.minContentWidth = 220

		CurrentAudienceToolTip = TTooltipAudience.Create("", "", 490, 440)
		CurrentAudienceToolTip.minContentWidth = 200

		CurrentTimeToolTip = TTooltip.Create("", "", 490, 535)
		MoneyToolTip = TTooltip.Create("", "", 490, 408)
		BettyToolTip = TTooltip.Create("", "", 490, 485)

		'collect them in one list (to sort them correctly)
		tooltips.AddLast(CurrentProgrammeToolTip)
		tooltips.AddLast(CurrentAudienceToolTip)
		tooltips.AddLast(CurrentTimeToolTip)
		tooltips.AddLast(MoneyTooltip)
		tooltips.AddLast(BettyToolTip)


		noiseSprite = GetSpriteFromRegistry("gfx_interface_tv_noise")
		'set space "left" when subtracting the genre image
		'so we know how many pixels we can move that image to simulate animation
		noiseDisplace.Dimension.SetX(Max(0, noiseSprite.GetWidth() - CurrentProgramme.GetWidth()))
		noiseDisplace.Dimension.SetY(Max(0, noiseSprite.GetHeight() - CurrentProgramme.GetHeight()))


		'=== SETUP SPAWNPOINTS FOR TOASTMESSAGES ===
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle.Init(20,10, 380,200), new TVec2D.Init(0,0), "TOPLEFT" )
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle.Init(400,10, 380,200), new TVec2D.Init(1,0), "TOPRIGHT" )
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle.Init(20,230, 380,150), new TVec2D.Init(0,1), "BOTTOMLEFT" )
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle.Init(400,230, 380,150), new TVec2D.Init(1,1), "BOTTOMRIGHT" )
		

		Return self
	End Method


	Method Update(deltaTime:Float=1.0)
		'=== UPDATE TOASTMESSAGES ===
		GetToastMessageCollection().Update()


		local programmePlan:TPlayerProgrammePlan = GetPlayerProgrammePlanCollection().Get(ShowChannel)

		'reset current programme sprites
		CurrentProgrammeOverlay = Null
		CurrentProgramme = Null
		
		if programmePlan	'similar to "ShowChannel<>0"
			If GetWorldTime().GetDayMinute() >= 55
				Local obj:TBroadcastMaterial = programmePlan.GetAdvertisement()
			    If obj
					CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_ads")
					'real ad
					If TAdvertisement(obj)
						CurrentProgrammeToolTip.TitleBGtype = 1
						CurrentProgrammeText = getLocale("ADVERTISMENT") + ": " + obj.GetTitle()
					Else
						If(TProgramme(obj))
							CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_" + TProgramme(obj).data.GetGenre(), "gfx_interface_tv_programme_none")
						EndIf
						CurrentProgrammeOverlay = GetSpriteFromRegistry("gfx_interface_tv_programme_traileroverlay")
						CurrentProgrammeToolTip.TitleBGtype = 1
						CurrentProgrammeText = getLocale("TRAILER") + ": " + obj.GetTitle()
					EndIf
				Else
					CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_ads_none")

					CurrentProgrammeToolTip.TitleBGtype	= 2
					CurrentProgrammeText = getLocale("BROADCASTING_OUTAGE")
				EndIf
			ElseIf GetWorldTime().GetDayMinute() < 5
				CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_news")
				CurrentProgrammeToolTip.TitleBGtype	= 3
				CurrentProgrammeText = getLocale("NEWS")
			Else
				Local obj:TBroadcastMaterial = programmePlan.GetProgramme()
				If obj
					CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_none")
					CurrentProgrammeToolTip.TitleBGtype	= 0
					'real programme
					If TProgramme(obj)
						Local programme:TProgramme = TProgramme(obj)
						CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_" + programme.data.GetGenre(), "gfx_interface_tv_programme_none")
						If programme.isSeries()
							CurrentProgrammeText = programme.licence.parentLicence.GetTitle() + " ("+ (programme.GetEpisodeNumber()+1) + "/" + programme.GetEpisodeCount()+"): " + programme.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + programme.GetBlocks() + ")"
						Else
							CurrentProgrammeText = programme.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + programme.GetBlocks() + ")"
						EndIf
					ElseIf TAdvertisement(obj)
						CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_ads")
						CurrentProgrammeOverlay = GetSpriteFromRegistry("gfx_interface_tv_programme_infomercialoverlay")
						CurrentProgrammeText = GetLocale("INFOMERCIAL")+": "+obj.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
					ElseIf TNews(obj)
						CurrentProgrammeText = GetLocale("SPECIAL_NEWS_BROADCAST")+": "+obj.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
					EndIf
				Else
					CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_none")
					CurrentProgrammeToolTip.TitleBGtype	= 2
					CurrentProgrammeText = getLocale("BROADCASTING_OUTAGE")
				EndIf
			EndIf
		Else
			CurrentProgrammeToolTip.TitleBGtype = 3
			CurrentProgrammeText = getLocale("TV_OFF")
		EndIf 'no programmePlan found -> invalid player / tv off

		For local tip:TTooltip = eachin tooltips
			If tip.enabled Then tip.Update()
		Next
		tooltips.Sort() 'sort according lifetime

		'channel selection (tvscreen on interface)
		If MOUSEMANAGER.IsHit(1)
			For Local i:Int = 0 To 4
				If THelper.MouseIn( 75 + i * 33, 171 + 383, 33, 41)
					ShowChannel = i
					BottomImgDirty = True
				EndIf
			Next
		EndIf


		'skip adjusting the noise if the tv is off
		If programmePlan
			'noise on interface-tvscreen
			ChangeNoiseTimer :+ deltaTime
			If ChangeNoiseTimer >= 0.20
				noiseDisplace.position.SetXY(Rand(0, noiseDisplace.dimension.GetX()),Rand(0, noiseDisplace.dimension.GetY()))
				ChangeNoiseTimer = 0.0
				NoiseAlpha = 0.45 - (Rand(0,20)*0.01)
			EndIf
		EndIf


		If THelper.MouseIn(20,385,280,200)
			CurrentProgrammeToolTip.SetTitle(CurrentProgrammeText)
			local content:String = ""
			If programmePlan
				content	= GetLocale("AUDIENCE_RATING")+": "+programmePlan.getFormattedAudience()+ " (MA: "+MathHelper.floatToString(programmePlan.GetAudiencePercentage()*100,2)+"%)"

				'show additional information if channel is player's channel
				If ShowChannel = GetPlayerCollection().playerID
					If GetWorldTime().GetDayMinute() >= 5 And GetWorldTime().GetDayMinute() < 55
						Local obj:TBroadcastMaterial = programmePlan.GetAdvertisement()
						If TAdvertisement(obj)
							'outage before?
							If not programmePlan.GetProgramme()
								content :+ "~n ~n|b||color=200,100,100|"+getLocale("NEXT_ADBLOCK")+":|/color||/b|~n" + obj.GetTitle()+" ("+ GetLocale("INVALID_BY_BROADCAST_OUTAGE") +")"
							Else
								content :+ "~n ~n|b||color=100,150,100|"+getLocale("NEXT_ADBLOCK")+":|/color||/b|~n" + obj.GetTitle()+" ("+ GetLocale("MIN_AUDIENCE") +": "+ TFunctions.convertValue(TAdvertisement(obj).contract.getMinAudience())+")"
							EndIf
						ElseIf TProgramme(obj)
							content :+ "~n ~n|b|"+getLocale("NEXT_ADBLOCK")+":|/b|~n"+ GetLocale("TRAILER")+": " + obj.GetTitle()
						Else
							content :+ "~n ~n|b||color=200,100,100|"+getLocale("NEXT_ADBLOCK")+":|/color||/b|~n"+ GetLocale("NEXT_NOTHINGSET")
						EndIf
					ElseIf GetWorldTime().GetDayMinute()>=55 Or GetWorldTime().GetDayMinute()<5
						Local obj:TBroadcastMaterial = programmePlan.GetProgramme()
						If TProgramme(obj)
							content :+ "~n ~n|b|"+getLocale("NEXT_PROGRAMME")+":|/b|~n"
							If TProgramme(obj) And TProgramme(obj).isSeries()
								content :+ TProgramme(obj).licence.parentLicence.data.GetTitle() + ": " + obj.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
							Else
								content :+ obj.GetTitle() + " (" + getLocale("BLOCK")+" " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
							EndIf
						ElseIf TAdvertisement(obj)
							content :+ "~n ~n|b|"+getLocale("NEXT_PROGRAMME")+":|/b|~n"+ GetLocale("INFOMERCIAL")+": " + obj.GetTitle() + " (" + getLocale("BLOCK")+" " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
						Else
							content :+ "~n ~n|b||color=200,100,100|"+getLocale("NEXT_PROGRAMME")+":|/color||/b|~n"+ GetLocale("NEXT_NOTHINGSET")
						EndIf
					EndIf
				EndIf
			Else
				content = getLocale("TV_TURN_IT_ON")
			EndIf

			CurrentProgrammeToolTip.SetContent(content)
			CurrentProgrammeToolTip.enabled = 1
			CurrentProgrammeToolTip.Hover()
	    EndIf
		If THelper.MouseIn(355,468,130,30)
			local playerProgrammePlan:TPlayerProgrammePlan = GetPlayerCollection().Get().GetProgrammePlan()
			if playerProgrammePlan
				CurrentAudienceToolTip.SetTitle(GetLocale("AUDIENCE_RATING")+": "+playerProgrammePlan.getFormattedAudience()+ " (MA: "+MathHelper.floatToString(playerProgrammePlan.GetAudiencePercentage() * 100,2)+"%)")
				CurrentAudienceToolTip.SetAudienceResult(GetBroadcastManager().GetAudienceResult(playerProgrammePlan.owner))
				CurrentAudienceToolTip.enabled = 1
				CurrentAudienceToolTip.Hover()
				'force redraw
				CurrentTimeToolTip.dirtyImage = True
			endif
		EndIf
		If THelper.MouseIn(355,533,130,45)
			CurrentTimeToolTip.SetTitle(getLocale("GAME_TIME")+": ")
			CurrentTimeToolTip.SetContent(GetWorldTime().getFormattedTime()+" "+getLocale("DAY")+" "+GetWorldTime().getDayOfYear()+"/"+GetWorldTime().GetDaysPerYear()+" "+GetWorldTime().getYear())
			CurrentTimeToolTip.enabled = 1
			CurrentTimeToolTip.Hover()
		EndIf
		If THelper.MouseIn(355,415,130,30)
			MoneyToolTip.title = getLocale("MONEY")
			local content:String = ""
			content	= "|b|"+getLocale("MONEY")+":|/b| "+GetPlayerCollection().Get().GetMoney() + getLocale("CURRENCY")
			content	:+ "~n"
			content	:+ "|b|"+getLocale("DEBT")+":|/b| |color=200,100,100|"+ GetPlayerCollection().Get().GetCredit() + getLocale("CURRENCY")+"|/color|"
			MoneyTooltip.SetContent(content)
			MoneyToolTip.enabled 	= 1
			MoneyToolTip.Hover()
		EndIf
		If THelper.MouseIn(355,510,130,15)
			BettyToolTip.SetTitle(getLocale("BETTY_FEELINGS"))
			BettyToolTip.SetContent(getLocale("THERE_IS_NO_LOVE_IN_THE_AIR_YET"))
			BettyToolTip.enabled = 1
			BettyToolTip.Hover()
		EndIf
	End Method


	'returns a string list of abbreviations for the watching family
	Function GetWatchingFamily:string[]()
		'fetch feedback to see which test-family member might watch
		Local feedback:TBroadcastFeedback = GetBroadcastManager().GetCurrentBroadcast().GetFeedback(GetPlayerCollection().playerID)

		local result:String[]

		if (feedback.AudienceInterest.Children > 0)
			'maybe sent to bed ? :D
			'If GetWorldTime().GetDayHour() >= 5 and GetWorldTime().GetDayHour() < 22 then 'manuel: muss im Feedback-Code geprüft werden.
			result :+ ["girl"]
		endif

		if (feedback.AudienceInterest.Pensioners > 0) then result :+ ["grandpa"]

		if (feedback.AudienceInterest.Teenagers > 0)
			'in school monday-friday - in school from till 7 to 13 - needs no sleep :D
			'If Game.GetWeekday()>6 or (GetWorldTime().GetDayHour() < 7 or GetWorldTime().GetDayHour() >= 13) then result :+ ["teen"] 'manuel: muss im Feedback-Code geprüft werden.
			result :+ ["teen"]
		endif

		return result
	End Function


	'draws the interface
	Method Draw(tweenValue:Float=1.0)
		'=== RENDER TOASTMESSAGES ===
		'below everything else of the interface: our toastmessages
		GetToastMessageCollection().Render(0,0)
	
		SetBlend ALPHABLEND
		GetSpriteFromRegistry("gfx_interface_top").Draw(0,0)
		GetSpriteFromRegistry("gfx_interface_leftright").DrawClipped(new TRectangle.Init(0, 20, 27, 363))
		SetBlend SOLIDBLEND
		GetSpriteFromRegistry("gfx_interface_leftright").DrawClipped(new TRectangle.Init(780, 20, 20, 363), new TVec2D.Init(27,0))

		If BottomImgDirty

			SetBlend MASKBLEND
			'draw bottom, aligned "bottom"
			GetSpriteFromRegistry("gfx_interface_bottom").Draw(0, GetGraphicsManager().GetHeight(), 0, new TVec2D.Init(ALIGN_LEFT, ALIGN_BOTTOM))

			If ShowChannel <> 0 Then GetSpriteFromRegistry("gfx_interface_audience_bg").Draw(520, 419)
			SetBlend ALPHABLEND

		    'channel choosen and something aired?
		    local programmePlan:TPlayerProgrammePlan = GetPlayerProgrammePlanCollection().Get(ShowChannel)

			'CurrentProgramme can contain "outage"-image, so draw
			'even without audience
			If CurrentProgramme Then CurrentProgramme.Draw(45, 400)
			If CurrentProgrammeOverlay Then CurrentProgrammeOverlay.Draw(45, 400)

			If programmePlan and programmePlan.GetAudience() > 0

				'fetch a list of watching family members
				local members:string[] = GetWatchingFamily()
				'later: limit to amount of "places" on couch
				Local familyMembersUsed:int = members.length

				'slots if 3 members watch
				local figureSlots:int[]
				if familyMembersUsed = 3 then figureSlots = [550, 610, 670]
				if familyMembersUsed = 2 then figureSlots = [580, 640]
				if familyMembersUsed = 1 then figureSlots = [610]

				'display an empty/dark room
				if familyMembersUsed = 0
					local col:TColor = new TColor.Get()
					SetColor 50, 50, 50
					SetBlend MASKBLEND
					GetSpriteFromRegistry("gfx_interface_audience_bg").Draw(520, 419)
					col.SetRGBA()
					SetBlend ALPHABLEND
				else
					local currentSlot:int = 0
					For local member:string = eachin members
						GetSpriteFromRegistry("gfx_interface_audience_"+member).Draw(figureslots[currentslot], 419)
						currentslot:+1 'occupy a slot
					Next
				endif
			EndIf 'showchannel <>0

			GetSpriteFromRegistry("gfx_interface_antenna").Draw(111,329)

			'draw noise of tv device
			If ShowChannel <> 0
				SetAlpha NoiseAlpha
				If noiseSprite Then noiseSprite.DrawClipped(new TRectangle.Init(45, 400, 220,170), new TVec2D.Init(noiseDisplace.GetX(), noiseDisplace.GetY()) )
				SetAlpha 1.0
			EndIf
			'draw overlay to hide corners of non-round images
			GetSpriteFromRegistry("gfx_interface_tv_overlay").Draw(45,400)

		    For Local i:Int = 0 To 4
				If i = ShowChannel
					GetSpriteFromRegistry("gfx_interface_channelbuttons_on_"+i).Draw(75 + i * 33, 554)
				Else
					GetSpriteFromRegistry("gfx_interface_channelbuttons_off_"+i).Draw(75 + i * 33, 554)
				EndIf
		    Next

			'draw the small electronic parts - "the inner tv"
	     	GetSpriteFromRegistry("gfx_interface_audience_overlay").Draw(520, 419)

			GetBitmapFont("Default", 16, BOLDFONT).drawBlock(GetPlayerCollection().Get().getMoneyFormatted(), 366, 421, 112, 15, ALIGN_CENTER_CENTER, TColor.Create(200,230,200), 2, 1, 0.5)

			GetBitmapFont("Default", 16, BOLDFONT).drawBlock(GetPlayerCollection().Get().GetProgrammePlan().getFormattedAudience(), 366, 463, 112, 15, ALIGN_CENTER_CENTER, TColor.Create(200,200,230), 2, 1, 0.5)

			'=== DRAW SECONDARY INFO ===
			local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha*0.75

			'current days financial win/loss
			local profit:int = GetPlayerCollection().Get().GetFinance().GetCurrentProfit()
			if profit > 0
				GetBitmapFont("Default", 12, BOLDFONT).drawBlock("+"+TFunctions.DottedValue(profit), 366, 421+15, 112, 12, ALIGN_CENTER_CENTER, TColor.Create(170,200,170), 2, 1, 0.5)
			elseif profit = 0
				GetBitmapFont("Default", 12, BOLDFONT).drawBlock(0, 366, 421+15, 112, 12, ALIGN_CENTER_CENTER, TColor.Create(170,170,170), 2, 1, 0.5)
			else
				GetBitmapFont("Default", 12, BOLDFONT).drawBlock(TFunctions.DottedValue(profit), 366, 421+15, 112, 12, ALIGN_CENTER_CENTER, TColor.Create(200,170,170), 2, 1, 0.5)
			endif

			'market share
			GetBitmapFont("Default", 12, BOLDFONT).drawBlock("MA: "+MathHelper.floatToString(GetPlayerCollection().Get().GetProgrammePlan().GetAudiencePercentage()*100,2)+"%", 366, 463+15, 112, 12, ALIGN_CENTER_CENTER, TColor.Create(170,170,200), 2, 1, 0.5)

			'current day
		 	GetBitmapFont("Default", 12, BOLDFONT).drawBlock((GetWorldTime().GetDaysRun()+1) + ". "+GetLocale("DAY"), 366, 555, 112, 12, ALIGN_CENTER_CENTER, TColor.Create(180,180,180), 2, 1, 0.5)

			SetAlpha oldAlpha
		EndIf 'bottomimg is dirty

		SetBlend ALPHABLEND

'DrawRect(366, 542, 112, 15)
		GetBitmapFont("Default", 16, BOLDFONT).drawBlock(GetWorldTime().getFormattedTime() + " "+GetLocale("OCLOCK"), 366, 540, 112, 15, ALIGN_CENTER_CENTER, TColor.Create(220,220,220), 2, 1, 0.5)

		For local tip:TTooltip = eachin tooltips
			If tip.enabled Then tip.Render()
		Next

	    GUIManager.Draw("InGame")

		TError.DrawErrors()
	End Method
End Type


'===== CONVENIENCE ACCESSORS =====
Function GetInGameInterface:TInGameInterface()
	return TInGameInterface.GetInstance()
End Function