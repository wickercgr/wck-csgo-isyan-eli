#include <sourcemod>
#include <sdktools>
#include <warden>
#include <cstrike>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <hgr>

int g_roundStartedTime = -1, GeriSay = 0; Handle g_gerisaytimer = null, g_gelismistimer = null; bool iseliaktif = false; ConVar g_MaxTime = null, g_Hangisilah = null, g_Silahversinmi = null, g_Hookengel = null, g_MinTime = null, g_Canver = null, g_Revle = null, g_Yetkiliflag = null, g_Hucre = null, g_CTizleme = null, g_Kapi = null, g_Infotime = null, g_Slayt = null, g_Otorev = null, g_Otorevtime = null, g_Canverc = null;
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = { name = "Gelişmiş İsyan Eli", author = "wck", description = "", version = "1.5b"};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStartEnd);
	HookEvent("round_end", Event_RoundStartEnd);
	
	RegConsoleCmd("sm_iseli", Rebelround);
	RegConsoleCmd("sm_isyaneli", Rebelround);
	
	RegConsoleCmd("sm_iselidurdur", Freeround);
	RegConsoleCmd("sm_iseli0", Freeround);
	
	g_Silahversinmi = CreateConVar("sm_iseli_silahver", "0", "T takımına silah eklesin mi?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Hangisilah = CreateConVar("sm_iseli_silah", "weapon_deagle", "Hangi silah verilsin (https://developer.valvesoftware.com/wiki/List_of_Counter-Strike:_Global_Offensive_Entities)", FCVAR_NOTIFY);
	
	g_Canver = CreateConVar("sm_iseli_can_t", "100", "T Kaç canla başlasın", FCVAR_NOTIFY, true, 0.0);
	g_Canverc = CreateConVar("sm_iseli_can_ct", "400", "CT Kaç canla başlasın", FCVAR_NOTIFY, true, 0.0);
	
	g_Otorevtime = CreateConVar("sm_iseli_otorev_sure", "3490", "T Kaçta oto revi kapatılsın ( Saniye bazlı )", FCVAR_NOTIFY, true, 0.0);
	g_Otorev = CreateConVar("sm_iseli_otorev", "1", "T otomatik respawnı açılsın mı?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	g_Infotime = CreateConVar("sm_iseli_ct_info", "3490", "CT Kaçta info versin ( Saniye bazlı )", FCVAR_NOTIFY, true, 0.0);
	g_Slayt = CreateConVar("sm_iseli_t_slay", "3390", "T Kaçta slay yesin ( Saniye bazlı )", FCVAR_NOTIFY, true, 0.0);
	
	g_Hookengel = CreateConVar("sm_iseli_hgr_engel", "1", "İsyan eli başladığında hgr kapatılsın mı?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	g_MaxTime = CreateConVar("sm_iseli_max_sure", "25", "İsyan elinin başlaması için verilecek en fazla süre", FCVAR_NOTIFY, true, 0.0);
	g_MinTime = CreateConVar("sm_iseli_min_sure", "25", "İsyan elinin başlaması için verilecek en az süre", FCVAR_NOTIFY, true, 0.0);
	
	g_Revle = CreateConVar("sm_iseli_olu_revleme", "1", "İsyan eli süre verildiğinde ölü oyuncular canlandırılsın mı", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Hucre = CreateConVar("sm_iseli_hucre_isinlama", "1", "İsyan eli süre verildiğinde oyuncular hücreye ışınlansın mı", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Kapi = CreateConVar("sm_iseli_kapi_kapatma", "1", "İsyan eli süre verildiğinde kapılar kapatılsın mı", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	g_CTizleme = CreateConVar("sm_iseli_ct_izleme", "0", "İsyan eli süre verildiğinde T takımı CT oyuncularını izlebilme", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	g_Yetkiliflag = CreateConVar("sm_iseli_yetki", "b", "İsyan eli komutçu harici verebilecek kişilerin yetkisi");
	AutoExecConfig(true, "Gelismis-iseli", "WCK ");
}

public Action Event_RoundStartEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if (StrEqual(name, "round_start", true))g_roundStartedTime = GetTime();
	if (iseliaktif)
	{
		if (g_Hookengel.BoolValue) { SetCvar("sm_hgr_hook_enable", 1); SetCvar("sm_hgr_grab_enable", 1); SetCvar("sm_hgr_rope_enable", 1); }
		iseliaktif = false;
		GeriSay = 0;
		if (g_gerisaytimer != null)delete g_gerisaytimer;
		if (g_gelismistimer != null)delete g_gelismistimer;
		if (!g_CTizleme.BoolValue)SetCvar("mp_forcecamera", 0);
		SetCvar("mp_respawn_on_death_t", 0);
	}
}

public int GetTotalRoundTime() { return GameRules_GetProp("m_iRoundTime"); }

public int GetCurrentRoundTime() { Handle h_freezeTime = FindConVar("mp_freezetime"); int freezeTime = GetConVarInt(h_freezeTime); return (GetTime() - g_roundStartedTime) - freezeTime; }

public Action Rebelround(int client, int args)
{
	char YetkiliflagString[8];
	g_Yetkiliflag.GetString(YetkiliflagString, sizeof(YetkiliflagString));
	if (warden_iswarden(client) || HasFlags(client, YetkiliflagString))
	{
		if (!iseliaktif)
		{
			char arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			if (args < 1)
			{
				ReplyToCommand(client, "[SM] \x01Kullanım: sm_iseli [Saniye]");
				return Plugin_Handled;
			}
			else
			{
				if (StringToInt(arg1) > g_MaxTime.IntValue || StringToInt(arg1) < g_MinTime.IntValue)
				{
					ReplyToCommand(client, "[SM] \x01İsyan eli süresi \x04%d ve %d \x0Csaniye ve ya arasında olması gerekir!", g_MinTime.IntValue, g_MaxTime.IntValue);
					return Plugin_Handled;
				}
				else
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (g_Hucre.BoolValue && IsClientInGame(i) && !IsFakeClient(i))
						{
							if (GetClientTeam(i) == CS_TEAM_T)
							{
								SetEntityHealth(i, g_Canver.IntValue);
								CS_RespawnPlayer(i);
							}
							else if (GetClientTeam(i) == CS_TEAM_CT)
							{
								SetEntityHealth(i, g_Canverc.IntValue);
							}
						}
					}
					PrintToChatAll("[SM] \x0C%N \x01tarafından isyan eli süresi \x04%s saniye belirlemiştir.", client, arg1);
					if (!g_CTizleme.BoolValue)
						SetCvar("mp_forcecamera", 1);
					GeriSay = StringToInt(arg1);
					if (g_Kapi.BoolValue)
					{
						char classname[32];
						for (int j = MaxClients + 1; j <= 2048; j++)
						{
							if (!IsValidEntity(j))
								continue;
							GetEntityClassname(j, classname, 32);
							if (strcmp(classname, "func_door", true) || strcmp(classname, "func_movelinear", true))
								AcceptEntityInput(j, "Close");
						}
					}
					if (g_Hookengel.BoolValue)
					{
						SetCvar("sm_hgr_hook_enable", 0);
						SetCvar("sm_hgr_grab_enable", 0);
						SetCvar("sm_hgr_rope_enable", 0);
					}
					if (g_Otorev.BoolValue)
						SetCvar("mp_respawn_on_death_t", 1);
					iseliaktif = true;
					if (g_gerisaytimer != null)
						delete g_gerisaytimer;
					g_gerisaytimer = CreateTimer(1.0, GeriSayTimer, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
					return Plugin_Handled;
				}
				
			}
		}
		else
		{
			ReplyToCommand(client, "[SM] \x01İsyan eli zaten aktif \x04sm_iseli0");
			return Plugin_Handled;
		}
	}
	else if (!warden_iswarden(client) || !HasFlags(client, YetkiliflagString))
	{
		ReplyToCommand(client, "[SM] \x01Bu komuta erişiminiz yok!");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Freeround(int client, int args)
{
	char YetkiliflagString[8];
	g_Yetkiliflag.GetString(YetkiliflagString, sizeof(YetkiliflagString));
	if (warden_iswarden(client) || HasFlags(client, YetkiliflagString))
	{
		if (iseliaktif)
		{
			PrintToChatAll("[SM] \x0C%N \x01tarafından isyan eli \x04durdurulmuştur.", client);
			iseliaktif = false;
			GeriSay = 0;
			if (g_gerisaytimer != null)
				delete g_gerisaytimer;
			if (g_gelismistimer != null)
				delete g_gelismistimer;
			if (!g_CTizleme.BoolValue)
				SetCvar("mp_forcecamera", 0);
			if (g_Hookengel.BoolValue)
			{
				SetCvar("sm_hgr_hook_enable", 1);
				SetCvar("sm_hgr_grab_enable", 1);
				SetCvar("sm_hgr_rope_enable", 1);
			}
			SetCvar("mp_respawn_on_death_t", 0);
			return Plugin_Handled;
		}
		else
		{
			ReplyToCommand(client, "[SM] \x01İsyan eli zaten aktif değil. \x04sm_iseli [Saniye]");
			return Plugin_Handled;
		}
	}
	else if (!warden_iswarden(client) || !HasFlags(client, YetkiliflagString))
	{
		ReplyToCommand(client, "[SM] \x01Bu komuta erişiminiz yok!");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action GeriSayTimer(Handle timer, any data)
{
	if (GeriSay > 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
				PrintHintText(i, "<font color='#00FF00'>%d Saniye</font> sonra isyan eli başlayacak", GeriSay);
		}
		GeriSay--;
	}
	else
	{
		char classname[32];
		for (int j = MaxClients + 1; j <= 2048; j++)
		{
			if (!IsValidEntity(j))
				continue;
			GetEntityClassname(j, classname, 32);
			if (strcmp(classname, "func_door", true) || strcmp(classname, "func_movelinear", true))
				AcceptEntityInput(j, "Open");
		}
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				PrintHintText(i, "İsyan eli başladı");
				if (g_Revle.BoolValue && !IsPlayerAlive(i))
					CS_RespawnPlayer(i);
			}
		}
		if (g_gerisaytimer != null)
			delete g_gerisaytimer;
		if (g_Silahversinmi.BoolValue)
		{
			char Silahinismi[64];
			g_Hangisilah.GetString(Silahinismi, sizeof(Silahinismi));
			GivePlayerItem(GetRandomPlayer(CS_TEAM_CT, true), Silahinismi);
		}
		g_gerisaytimer = null;
		g_gelismistimer = CreateTimer(1.0, GeriSayTimer2, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
}

public Action GeriSayTimer2(Handle timer, any data)
{
	if (g_Otorev.BoolValue && GetTotalRoundTime() - GetCurrentRoundTime() == g_Otorevtime.IntValue)
		SetCvar("mp_respawn_on_death_t", 0);
	if (GetTotalRoundTime() - GetCurrentRoundTime() == g_Infotime.IntValue)
	{
		PrintToChatAll("[SM] \x0CCT takımının \x01info vakti geldi!");
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				if (IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
				{
					Handle hHudText = CreateHudSynchronizer();
					SetHudTextParams(-1.0, -0.60, 5.0, 130, 34, 33, 255, 2, 0.1, 0.1, 0.1);
					ShowSyncHudText(i, hHudText, "Info ver");
					delete hHudText;
				}
			}
		}
	}
	if (GetTotalRoundTime() - GetCurrentRoundTime() == g_Slayt.IntValue)
	{
		PrintToChatAll("[SM] \x0CT takımının \x01süresi doldu. \x02T takımı öldürüldü!");
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				if (IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
					ForcePlayerSuicide(i);
			}
		}
		if (g_gelismistimer != null)
			delete g_gelismistimer;
		g_gelismistimer = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
stock bool HasFlags(int client, const char[] flags)
{
	int iCount = 0;
	char sflagNeed[22][8], sflagFormat[64];
	bool bEntitled = false;
	Format(sflagFormat, sizeof(sflagFormat), flags);
	ReplaceString(sflagFormat, sizeof(sflagFormat), " ", "");
	iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[]));
	for (int i = 0; i < iCount; i++)
	{
		if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i])) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
		{
			bEntitled = true;
			break;
		}
	}
	return bEntitled;
}
stock int GetRandomPlayer(int team = -1, bool OnlyAlive = false)
{
	int[] clients = new int[MaxClients];
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (team == -1 || GetClientTeam(i) == team) && (!OnlyAlive || !IsPlayerAlive(i)))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)];
}
public Action HGR_OnClientHook(int client) { if (iseliaktif && g_Hookengel.BoolValue)return Plugin_Handled; return Plugin_Continue; }
public Action HGR_OnClientGrab(int client) { if (iseliaktif && g_Hookengel.BoolValue)return Plugin_Handled; return Plugin_Continue; }
public Action HGR_OnClientRope(int client) { if (iseliaktif && g_Hookengel.BoolValue)return Plugin_Handled; return Plugin_Continue; }
void SetCvar(char cvarName[64], int value) { Handle IntCvar = FindConVar(cvarName); if (IntCvar == null)return; int flags = GetConVarFlags(IntCvar); flags &= ~FCVAR_NOTIFY; SetConVarFlags(IntCvar, flags); SetConVarInt(IntCvar, value); flags |= FCVAR_NOTIFY; SetConVarFlags(IntCvar, flags); }