#include <sdktools>
#include <sdkhooks>
#include <geoip>

new bool:isPlayerConnected[MAXPLAYERS+1]={false,...};
public OnPluginStart() 
{
	for(new i=1; i <= MaxClients; i++) 
	{
		if(IsClientConnected(i)) 
		{
			isPlayerConnected[i] = true;
		}
	}
	RegServerCmd("is_SendClient",callback_check,"");
}
public OnMapStart() 
{
	new playerresource = -1;
	playerresource = FindEntityByClassname(playerresource, "tf_player_manager");
	if (playerresource != INVALID_ENT_REFERENCE) 
	{
		SDKHook(playerresource, SDKHook_ThinkPost, Hook_OnThinkPost);
	}
}
public OnClientPutInServer(client)
{
	isPlayerConnected[client]=true;
}
public Action:callback_check(args)
{
	new String:arg1[10];
	GetCmdArg(1,arg1,10);
	new client=StringToInt(arg1);
	ServerCommand("is_PlayerConnected %d", isPlayerConnected[client]);
	isPlayerConnected[client]=false;
}
public Action:OnClientSayCommand(client, const String:command[], const String:args[])
{
	if(StrContains(args,"fakeleave",false)>=0)
	{
		if (GetAdminFlag(GetUserAdmin(client), Admin_Ban,Access_Effective))
		{
			if(isPlayerConnected[client]==false)
			{
				PrintToChat(client,"FakeLeave: You are already hidden. Type /rejoin to come back");
			}
			else fakeLeave(client);
		}
		return Plugin_Handled;
	}
	else if(StrContains(args,"rejoin",false)>=0)
	{
		if (GetAdminFlag(GetUserAdmin(client), Admin_Ban,Access_Effective))
		{
			if(isPlayerConnected[client]==true)
			{
				PrintToChat(client,"FakeLeave: You are already visible. Type /fakeleave to hide");
			}
			else rejoin(client);
		}
		return Plugin_Handled;
	}
	else if(isPlayerConnected[client]==false)
	{
		PrintToChat(client,"FakeLeave: You are hidden and can not use chat. Please use /rejoin to come back first");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
fakeLeave(client)
{
	new String:auth[MAX_NAME_LENGTH];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth), true);
	PrintToChatAll("\x04%N\x01<\x03%s\x01> disconnected.",client,auth);
	ChangeClientTeam(client, 1);
	ClientCommand(client, "sm_admins 0");
	SetClientListeningFlags(client, VOICE_MUTED);
	isPlayerConnected[client]=false;
}

rejoin(client)
{
	isPlayerConnected[client]=true;
	ClientCommand(client, "sm_admins 1");
	ClientCommand(client, "jointeam random");
	decl String:ip[32],String:name[MAX_NAME_LENGTH],String:country[MAX_NAME_LENGTH],String:from[128],String:auth[MAX_NAME_LENGTH];
	GetClientAuthId(client,AuthId_Steam2,auth,sizeof(auth),true);
	GetClientName(client,name,sizeof(name));
	if (GetClientIP(client,ip,sizeof(ip)) && GeoipCountry(ip,country,sizeof(country)))
		Format(from,sizeof(from)," from \x03%s",country);
	else from = "";
	PrintToChatAll("\x04%s [\x03%s\x04] connected%s",name,auth,from);
	SetClientListeningFlags(client, VOICE_NORMAL);
}
public Hook_OnThinkPost(iEnt)
{
	static bConnectedOffset = -1;
	if (bConnectedOffset == -1) 
	{
		bConnectedOffset = FindSendPropInfo("CTFPlayerResource", "m_bConnected");
	}
	SetEntDataArray(iEnt, bConnectedOffset, isPlayerConnected, MaxClients+1);
}