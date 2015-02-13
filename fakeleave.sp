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
	RegAdminCmd("sm_fakeleave",Command_fakeLeave,ADMFLAG_BAN,"Fake leave the server");
	RegAdminCmd("sm_rejoin",Command_rejoin,ADMFLAG_BAN,"Show yourself after fake leaving");
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
public Action:Command_fakeLeave(client,args)
{
	new String:auth[MAX_NAME_LENGTH],String:name[MAX_NAME_LENGTH];
	GetClientName(client,name,sizeof(name));
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth), true);
	PrintToChatAll("\x04%s\x01<\x03%s\x01> disconnected.",name,auth);
	ChangeClientTeam(client, 1);
	ClientCommand(client, "sm_admins 0");
	isPlayerConnected[client]=false;
	return Plugin_Handled;
}
public Action:Command_rejoin(client,args)
{
	isPlayerConnected[client]=true;
	ClientCommand(client, "sm_admins 1");
	ClientCommand(client, "jointeam random");
	return Plugin_Handled;
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