#include <sdktools>
#include <sdkhooks>

new bool:isPlayerConnected[MAXPLAYERS+1] = {false, ...};
public OnPluginStart() 
{
	for(new i=1; i <= MaxClients; i++) 
	{
		if(IsClientConnected(i)) 
		{
			isPlayerConnected[i] = true;
		}
	}
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
public OnClientDisconnect(client)
{
	isPlayerConnected[client]=false;
}
public Action:OnClientSayCommand(client, const String:command[], const String:args[])
{
	if(StrContains(args,"fakeleave",false)>=0)
	{
		if (GetAdminFlag(GetUserAdmin(client), Admin_Ban,Access_Effective))
		{
			fakeLeave(client);
		}
		return Plugin_Handled;
	}
	else if(StrContains(args,"rejoin",false)>=0)
	{
		if (GetAdminFlag(GetUserAdmin(client), Admin_Ban,Access_Effective))
		{
			rejoin(client);
		}
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
	isPlayerConnected[client]=false;
}

rejoin(client)
{
	isPlayerConnected[client]=true;
	ClientCommand(client, "sm_admins 1");
	ClientCommand(client, "jointeam random");
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