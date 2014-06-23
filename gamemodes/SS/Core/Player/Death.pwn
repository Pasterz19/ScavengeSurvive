#include <YSI\y_hooks>


static
		death_LastDeath[MAX_PLAYERS],
Float:	death_PosX[MAX_PLAYERS],
Float:	death_PosY[MAX_PLAYERS],
Float:	death_PosZ[MAX_PLAYERS],
Float:	death_RotZ[MAX_PLAYERS],
		death_LastKilledBy[MAX_PLAYERS][MAX_PLAYER_NAME],
		death_LastKilledById[MAX_PLAYERS];


forward OnDeath(playerid, killerid, reason);


hook OnPlayerConnect(playerid)
{
	death_LastKilledBy[playerid][0] = EOS;
	death_LastKilledById[playerid] = INVALID_PLAYER_ID;

	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(GetTickCountDifference(GetTickCount(), death_LastDeath[playerid]) < 1000)
		return -1;

	death_LastDeath[playerid] = GetTickCount();

	if(killerid == INVALID_PLAYER_ID)
	{
		if(GetTickCountDifference(GetTickCount(), GetPlayerTookDamageTick(playerid)) < 1000)
		{
			killerid = GetLastHitById(playerid);

			if(!IsPlayerConnected(killerid))
				killerid = INVALID_PLAYER_ID;
		}
	}

	_OnDeath(playerid, killerid);

	return 1;
}

_OnDeath(playerid, killerid)
{
	if(!IsPlayerAlive(playerid) || IsPlayerOnAdminDuty(playerid))
	{
		return 0;
	}

	new
		deathreason = GetLastHitByWeapon(playerid),
		deathreasonstring[256];

	SetPlayerBitFlag(playerid, Dying, true);
	SetPlayerBitFlag(playerid, Spawned, false);
	SetPlayerBitFlag(playerid, Alive, false);

	GetPlayerPos(playerid, death_PosX[playerid], death_PosY[playerid], death_PosZ[playerid]);
	GetPlayerFacingAngle(playerid, death_RotZ[playerid]);

	if(IsPlayerInAnyVehicle(playerid))
		death_PosZ[playerid] += 0.1;

	HideWatch(playerid);
	DropItems(playerid, death_PosX[playerid], death_PosY[playerid], death_PosZ[playerid], death_RotZ[playerid]);
	RemovePlayerWeapon(playerid);
	SpawnPlayer(playerid);
	ToggleArmour(playerid, false);

	CallLocalFunction("OnDeath", "ddd", playerid, killerid, deathreason);

	if(IsPlayerConnected(killerid))
	{
		logf("[KILL] %p killed %p with %d at %f, %f, %f (%f)", killerid, playerid, deathreason, death_PosX[playerid], death_PosY[playerid], death_PosZ[playerid], death_RotZ[playerid]);

		GetPlayerName(killerid, death_LastKilledBy[playerid], MAX_PLAYER_NAME);
		death_LastKilledById[playerid] = killerid;

		//MsgAdminsF(1, YELLOW, " >  [KILL]: %p killed %p with %d", killerid, playerid, deathreason);

		switch(deathreason)
		{
			case 0..3, 5..7, 10..15:
				deathreasonstring = "They were beaten to death.";

			case 4:
				deathreasonstring = "They suffered small lacerations on the torso, possibly from a knife.";

			case 8:
				deathreasonstring = "Large lacerations cover the torso and head, looks like a finely sharpened sword.";

			case 9:
				deathreasonstring = "There's bits everywhere, probably suffered a chainsaw to the torso.";

			case 16, 39, 35, 36, 255:
				deathreasonstring = "They suffered massive concussion due to an explosion.";

			case 18, 37:
				deathreasonstring = "The entire body is charred and burnt.";

			case 22..34, 38:
				deathreasonstring = "They died of blood loss caused by what looks like bullets.";

			case 41, 42:
				deathreasonstring = "They were sprayed and suffocated by a high pressure liquid.";

			case 44, 45:
				deathreasonstring = "Somehow, they were killed by goggles.";

			case 43:
				deathreasonstring = "Somehow, they were killed by a camera.";

			default:
				deathreasonstring = "They died for an unknown deathreason.";
		}
	}
	else
	{
		logf("[DEATH] %p died because of %d at %f, %f, %f (%f)", playerid, deathreason, death_PosX[playerid], death_PosY[playerid], death_PosZ[playerid], death_RotZ[playerid]);

		death_LastKilledBy[playerid][0] = EOS;
		death_LastKilledById[playerid] = INVALID_PLAYER_ID;

		//MsgAdminsF(1, YELLOW, " >  [DEATH]: %p died by %d", playerid, deathreason);

		if(IsPlayerUnderDrugEffect(playerid, drug_Air))
		{
			deathreasonstring = "They died of air embolism (injecting oxygen into their bloodstream).";
		}
		else
		{
			switch(deathreason)
			{
				case 53:
					deathreasonstring = "They drowned.";

				case 54:
					deathreasonstring = "Most bones are broken, looks like they fell from a great height.";

				case 255:
					deathreasonstring = "They suffered massive concussion due to an explosion.";

				default:
					deathreasonstring = "They died for an unknown reason.";
			}
		}
	}

	CreateGravestone(playerid, deathreasonstring, death_PosX[playerid], death_PosY[playerid], death_PosZ[playerid] - FLOOR_OFFSET, death_RotZ[playerid]);

	return 1;
}

DropItems(playerid, Float:x, Float:y, Float:z, Float:r)
{
	new
		interior = GetPlayerInterior(playerid),
		backpackitem = GetPlayerBagItem(playerid),
		itemid = GetPlayerItem(playerid),
		clothes = GetPlayerClothes(playerid);

	if(IsValidItem(itemid))
	{
		CreateItemInWorld(itemid,
			x + floatsin(345.0, degrees),
			y + floatcos(345.0, degrees),
			z - FLOOR_OFFSET,
			.rz = r,
			.zoffset = ITEM_BUTTON_OFFSET,
			.interior = interior);

		RemoveCurrentItem(playerid);
	}
	else if(GetPlayerWeapon(playerid) > 0 && GetPlayerTotalAmmo(playerid) > 0)
	{
		itemid = CreateItem(ItemType:GetPlayerWeapon(playerid),
			x + floatsin(345.0, degrees),
			y + floatcos(345.0, degrees),
			z - FLOOR_OFFSET,
			.rz = r,
			.zoffset = ITEM_BUTTON_OFFSET,
			.interior = interior);

		SetItemExtraData(itemid, GetPlayerTotalAmmo(playerid));
		RemovePlayerWeapon(playerid);
	}

	itemid = GetPlayerHolsterItem(playerid);

	if(IsValidItem(itemid))
	{
		CreateItemInWorld(itemid,
			x + floatsin(15.0, degrees),
			y + floatcos(15.0, degrees),
			z - FLOOR_OFFSET,
			.rz = r,
			.zoffset = ITEM_BUTTON_OFFSET,
			.interior = interior);

		RemovePlayerHolsterItem(playerid);
	}

	for(new i; i < INV_MAX_SLOTS; i++)
	{
		itemid = GetInventorySlotItem(playerid, 0);

		if(!IsValidItem(itemid))
			break;

		RemoveItemFromInventory(playerid, 0);
		CreateItemInWorld(itemid,
			x + floatsin(45.0 + (90.0 * float(i)), degrees),
			y + floatcos(45.0 + (90.0 * float(i)), degrees),
			z - FLOOR_OFFSET,
			.rz = r,
			.zoffset = ITEM_BUTTON_OFFSET,
			.interior = interior);
	}

	if(IsValidItem(backpackitem))
	{
		RemovePlayerBag(playerid);

		SetItemPos(backpackitem, x + floatsin(180.0, degrees), y + floatcos(180.0, degrees), z - FLOOR_OFFSET, .zoffset = ITEM_BUTTON_OFFSET);
		SetItemRot(backpackitem, 0.0, 0.0, r, true);
		SetItemInterior(backpackitem, interior);
	}

	if(clothes != skin_MainM && clothes != skin_MainF)
	{
		itemid = CreateItem(item_Clothes,
			x + floatsin(90.0, degrees),
			y + floatcos(90.0, degrees),
			z - FLOOR_OFFSET,
			.rz = r,
			.zoffset = ITEM_BUTTON_OFFSET,
			.interior = interior);

		SetItemExtraData(itemid, clothes);
	}

	itemid = GetPlayerHat(playerid);

	if(IsValidItem(itemid))
	{
		CreateItem(GetItemTypeFromHat(itemid),
			x + floatsin(270.0, degrees),
			y + floatcos(270.0, degrees),
			z - FLOOR_OFFSET,
			.rz = r,
			.zoffset = ITEM_BUTTON_OFFSET,
			.interior = interior);

		RemovePlayerHat(playerid);
	}

	itemid = GetPlayerMask(playerid);

	if(IsValidItem(itemid))
	{
		CreateItem(GetItemTypeFromMask(itemid),
			x + floatsin(280.0, degrees),
			y + floatcos(280.0, degrees),
			z - FLOOR_OFFSET,
			.rz = r,
			.zoffset = ITEM_BUTTON_OFFSET,
			.interior = interior);

		RemovePlayerMask(playerid);
	}

	if(GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_CUFFED)
	{
		CreateItem(item_HandCuffs,
			x + floatsin(135.0, degrees),
			y + floatcos(135.0, degrees),
			z - FLOOR_OFFSET,
			.rz = r,
			.zoffset = ITEM_BUTTON_OFFSET,
			.interior = interior);
	}
}

hook OnPlayerSpawn(playerid)
{
	if(IsPlayerDead(playerid))
	{
		TogglePlayerSpectating(playerid, true);

		defer SetDeathCamera(playerid);

		SetPlayerCameraPos(playerid,
			death_PosX[playerid] - floatsin(-death_RotZ[playerid], degrees),
			death_PosY[playerid] - floatcos(-death_RotZ[playerid], degrees),
			death_PosZ[playerid]);

		SetPlayerCameraLookAt(playerid, death_PosX[playerid], death_PosY[playerid], death_PosZ[playerid]);

		TextDrawShowForPlayer(playerid, DeathText);
		TextDrawShowForPlayer(playerid, DeathButton);
		SelectTextDraw(playerid, 0xFFFFFF88);
		SetPlayerHP(playerid, 1.0);
		SetPlayerScreenFadeLevel(playerid, 255);
	}
}

timer SetDeathCamera[50](playerid)
{
	InterpolateCameraPos(playerid,
		death_PosX[playerid] - floatsin(-death_RotZ[playerid], degrees),
		death_PosY[playerid] - floatcos(-death_RotZ[playerid], degrees),
		death_PosZ[playerid] + 1.0,
		death_PosX[playerid] - floatsin(-death_RotZ[playerid], degrees),
		death_PosY[playerid] - floatcos(-death_RotZ[playerid], degrees),
		death_PosZ[playerid] + 20.0,
		30000, CAMERA_MOVE);

	InterpolateCameraLookAt(playerid,
		death_PosX[playerid],
		death_PosY[playerid],
		death_PosZ[playerid],
		death_PosX[playerid],
		death_PosY[playerid],
		death_PosZ[playerid] + 1.0,
		30000, CAMERA_MOVE);
}

hook OnPlayerClickTextDraw(playerid, Text:clickedid)
{
	if(clickedid == DeathButton)
	{
		SetPlayerBitFlag(playerid, Dying, false);
		TogglePlayerSpectating(playerid, false);
		CancelSelectTextDraw(playerid);
		TextDrawHideForPlayer(playerid, DeathText);
		TextDrawHideForPlayer(playerid, DeathButton);
		SpawnLoggedInPlayer(playerid);
	}

	return 1;
}


stock GetPlayerDeathPos(playerid, &Float:x, &Float:y, &Float:z)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	x = death_PosX[playerid];
	y = death_PosY[playerid];
	z = death_PosZ[playerid];

	return 1;
}

stock GetPlayerDeathRot(playerid, &Float:r)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	r = death_RotZ;

	return 1;
}

// death_LastKilledBy
stock GetLastKilledBy(playerid, name[MAX_PLAYER_NAME])
{
	if(!IsPlayerConnected(playerid))
		return 0;

	name = death_LastKilledBy[playerid];

	return 1;
}

// death_LastKilledById
stock GetLastKilledById(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	return death_LastKilledById[playerid];
}
