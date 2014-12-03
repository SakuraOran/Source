#include <sourcemod>
new String:bounty[10][32];
new String:topname[MAX_NAME_LENGTH];
new String:topauthid[MAX_NAME_LENGTH];
new toppoints=0;
new bool:foundplayer=false;
new String:path[]="addons/sourcemod/data/bounty/";
new String:masterpath[]="addons/sourcemod/data/bounty/masterpoints/";
new String:bountiespath[]="addons/sourcemod/data/bounty/playerbounties/";
new Handle:bountyhndl;
new bounties=0;
new bool:ml=false;
new String:grammer[]="points";
public Plugin:myinfo =
{
	name = "Disc-FF Bounty Event",
	author = "SakuraTheBabyfur",
	description = "Bounty event plugin for Disc-FF servers",
	version = "1.0",
	url = "http://www.disc-ff.com"
};
public OnPluginStart()
{
	CreateTimer(180.0,message, _,TIMER_REPEAT);
	CreateDirectory(path,7);
	CreateDirectory(masterpath,7);
	CreateDirectory(bountiespath,7);
	RegConsoleCmd("sm_points", Command_points, "Get your bounty points!");
	RegConsoleCmd("sm_bounty",Command_bounty,"Spend points to add a bounty to someone!");
	RegConsoleCmd("sm_toppoints", Command_toppoints, "See who has the most bounty points!");
	RegAdminCmd("sm_reload_bounty",bounty_reload,ADMFLAG_ROOT,"Reload players with bounty");
	RegAdminCmd("sm_add_bounty",bounty_add,ADMFLAG_ROOT,"Add players to bounty");
	HookEvent("player_death", Event_PlayerDeath);
	loadbounty();
}
public Action:message(Handle:timer)
{
	new rand=GetRandomInt(0,2);
	if(rand==0)PrintToChatAll("\x06[Bounty]\x04Type !points to see your points");
	if(rand==1)PrintToChatAll("\x06[Bounty]\x04Type !toppoints to see who has the most points");
	if(rand==2)PrintToChatAll("\x06[Bounty]\x04Type /bounty to place a bounty on someone");
	return Plugin_Continue;
}
public OnClientDisconnect(client)
{
	top_refresh(0);
}
public OnClientAuthorized(client,const String:auth[])
{
	new String:filename[PLATFORM_MAX_PATH],String:auth2[MAX_NAME_LENGTH],String:auth3[PLATFORM_MAX_PATH];
	new Handle:dirhndl=OpenDirectory(bountiespath);
	Format(auth2,sizeof(auth2),"%s.txt",auth);
	ReplaceString(auth2, PLATFORM_MAX_PATH, ":","-", false);
	while(ReadDirEntry(dirhndl,filename,sizeof(filename)))
	{
		if(StrEqual(filename,auth2,false))
		{
			for (new a = 1; a <= MaxClients; a++)
			{
				if(IsClientInGame(a)&&(!IsFakeClient(a))) ClientCommand(a, "playgamesound vo/Announcer_attention.wav");
			}
			Format(auth3,sizeof(auth3),"%s%s",bountiespath,filename);
			if(FileSize(auth3)==1) grammer="point";
			else grammer="points";
			PrintHintTextToAll("A player who joined has a bounty of %i %s!",FileSize(auth3),grammer);
		}
	}
	for(new i=0;i<=bounties;i++)
	{
		if(StrEqual(auth,bounty[i],false))
		{
			for (new a = 1; a <= MaxClients; a++)
			{
				if(IsClientInGame(a)&&(!IsFakeClient(a))) ClientCommand(a, "playgamesound vo/Announcer_attention.wav");
			}
			PrintHintTextToAll("A player with a bounty has joined!");
		}
	}
} 
public Action:Command_toppoints(client, args)
{
	top_refresh(client);
	return Plugin_Handled;
}

public top_refresh(client)
{
	new String:filename[PLATFORM_MAX_PATH], String:filepath[PLATFORM_MAX_PATH], String:newtopid[MAX_NAME_LENGTH];
	new newpoints=0;
	new Handle:dirhndl=OpenDirectory(masterpath);
	while(ReadDirEntry(dirhndl,filename,sizeof(filename)))
	{
		Format(filepath,sizeof(filepath),"%s%s",masterpath,filename);
		if(FileSize(filepath)>newpoints)
		{
			new String:vars[1][MAX_NAME_LENGTH];
			newpoints=FileSize(filepath);
			ExplodeString(filename, ".", vars, 1, MAX_NAME_LENGTH, false)
			ReplaceString(vars[0], PLATFORM_MAX_PATH, "-",":", false);
			newtopid=vars[0];
		}
	}
	if(!StrEqual(newtopid,topauthid,false))
	{
		foundplayer=false;
		topauthid=newtopid;
		toppoints=newpoints;
		new String:auth[MAX_NAME_LENGTH];
		for(new b=1;b<MaxClients;b++)
		{
			if(IsClientInGame(b)) 
			{
				GetClientAuthId(b,AuthId_Steam2,auth, sizeof(auth), true);
				if(StrEqual(auth,topauthid))
				{
					GetClientName(b,topname,sizeof(topname));
					foundplayer=true;
				}
			}
		}
	}
	if(client!=0)
	{
		if(toppoints==1) grammer="point";
		else grammer="points";
		if(!foundplayer)ReplyToCommand(client,"\x06[Bounty]\x04The offline player with the SteamID %s is in top with %i %s",topauthid,toppoints,grammer);
		else ReplyToCommand(client,"\x06[Bounty]\x04%s has the most points with %i %s",topname,toppoints,grammer);
	}
	CloseHandle(dirhndl);
}
public Action:Command_points(client, args) 
{
	new String:auth[32], String:path2[PLATFORM_MAX_PATH];
	GetClientAuthId(client,AuthId_Steam2,auth, sizeof(auth), true);
	Format(path2,sizeof(path2),"%s%s.txt",masterpath,auth);
	ReplaceString(path2, PLATFORM_MAX_PATH, ":","-", false);
	if(FileSize(path2,false)==1) grammer="point";
	else grammer="points";
	if(!FileExists(path2,false)) PrintToChat(client,"\x06[Bounty]\x04You have 0 points! Kill people with bounties to collect points");
	else PrintToChat(client,"\x06[Bounty]\x04You have %i %s",FileSize(path2,false),grammer);
	return Plugin_Handled;
}
public Action:Command_bounty(client,args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "\x06[Bounty]\x04Usage: sm_bounty <target> <points>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME_LENGTH],String:buffer[MAX_NAME_LENGTH],String:spoints[10];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,spoints,sizeof(spoints));
	new points=StringToInt(spoints);
	new targets[32];
	new count = ProcessTargetString(pattern,0,targets,sizeof(targets),COMMAND_FILTER_CONNECTED,buffer,sizeof(buffer),ml);
	if (count <= 0) ReplyToCommand(client,"\x06[Bounty]\x04Invalid target");
	else if(count>1) ReplyToCommand(client,"\x06[Bounty]\x04You may only target one person at a time");
	else if(points<1) ReplyToCommand(client,"\x06[Bounty]\x04Invalid number of points");
	else if(client==targets[0]) ReplyToCommand(client,"\x06[Bounty]\x04You can't add a bounty to yourself!");
	else
	{
		new String:auth[32], String:path2[PLATFORM_MAX_PATH];
		GetClientAuthId(client,AuthId_Steam2,auth, sizeof(auth), true);
		Format(path2,sizeof(path2),"%s%s.txt",masterpath,auth);
		ReplaceString(path2, PLATFORM_MAX_PATH, ":","-", false);
		new totalpoints=FileSize(path2,false);
		if(points>totalpoints)
		{
			ReplyToCommand(client,"\x06[Bounty]\x04You do not have enough points!");
			return Plugin_Handled;
		}
		if(DeleteFile(path2))
		{
			new Handle:clientpoints=OpenFile(path2,"at");
			for(new c=0;c<totalpoints-points;c++) WriteFileString(clientpoints,"1",false);
			CloseHandle(clientpoints);
			new String:targetname[MAX_NAME_LENGTH], String:targetid[32], String:targetpath[PLATFORM_MAX_PATH];
			GetClientAuthId(targets[0],AuthId_Steam2,targetid, sizeof(targetid), true);
			GetClientName(targets[0],targetname,sizeof(targetname));
			Format(targetpath,sizeof(targetpath),"%s%s.txt",bountiespath,targetid);
			ReplaceString(targetpath, PLATFORM_MAX_PATH, ":","-", false);
			new Handle:targethndl=OpenFile(targetpath,"at");
			for(new t=0;t<points;t++)	WriteFileString(targethndl,"1",false);
			CloseHandle(targethndl);
			if(points==1) grammer="point";
			else grammer="points";
			PrintToChatAll("\x06[Bounty]\x04Someone has put a bounty of %i %s on %s! Kill them to collect it!",points,grammer,targetname);
		}
		else ReplyToCommand(client,"\x06[Bounty]\x04Error adding bounty");
	}
	return Plugin_Handled;
}
public Action:bounty_reload(client, args)
{
	loadbounty();
	ReplyToCommand(client,"\x06[Bounty]\x04Reloaded Bounties");
	return Plugin_Handled;
}
public Event_PlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	new attacker=GetClientOfUserId(GetEventInt(event,"attacker"));
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if(attacker!=client&&attacker!=0)
	{
		new String:attackername[MAX_NAME_LENGTH], String:attackerid[MAX_NAME_LENGTH], String:clientname[MAX_NAME_LENGTH], String:auth[MAX_NAME_LENGTH], String:filename[PLATFORM_MAX_PATH], String:auth2[MAX_NAME_LENGTH];
		GetClientName(client,clientname,MAX_NAME_LENGTH);
		GetClientName(attacker,attackername,MAX_NAME_LENGTH);
		new Handle:dirhndl=OpenDirectory(bountiespath);
		GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth), true);
		Format(auth2,sizeof(auth2),"%s.txt",auth);
		ReplaceString(auth2, PLATFORM_MAX_PATH, ":","-", false);
		while(ReadDirEntry(dirhndl,filename,sizeof(filename)))
		{
			if(StrEqual(filename,auth2,false))
			{
				new String:authpath[PLATFORM_MAX_PATH];
				Format(authpath,sizeof(authpath),"%s%s",bountiespath,auth2);
				new points=FileSize(authpath);
				if(points==1) grammer="point";
				else grammer="points";
				for(new b=1;b<MaxClients;b++)
				{
					if(b!=attacker&& IsClientInGame(b)) PrintToChat(b,"\x06[Bounty]\x04%s has killed %s and collected the bounty of %i %s!",attackername,clientname,points);
				}
				PrintToChat(attacker,"\x06[Bounty]\x04You killed %s and collected the bounty of %i %s",clientname,points,grammer);
				if(!(GetEventInt(event, "death_flags") & 32))
				{
					GetClientAuthId(attacker, AuthId_Steam2,attackerid, sizeof(attackerid), true);
					new String:basepath[PLATFORM_MAX_PATH],String:basepathmaster[PLATFORM_MAX_PATH];
					Format(basepath,sizeof(basepath),"%s%s/%s.txt",path,auth,attackerid);
					Format(basepathmaster,sizeof(basepathmaster),"%s%s.txt",masterpath,attackerid);
					ReplaceString(basepath, PLATFORM_MAX_PATH, ":","-", false);
					ReplaceString(basepathmaster, PLATFORM_MAX_PATH, ":","-", false);
					new Handle:pointsfile=OpenFile(basepath,"at");
					new Handle:pointsmaster=OpenFile(basepathmaster,"at");
					for(new g=0;g<points;g++)
					{
						WriteFileString(pointsfile,"1",false);
						WriteFileString(pointsmaster,"1",false);
					}
					DeleteFile(authpath);
					CloseHandle(pointsmaster);
					CloseHandle(pointsfile);
				}
			}
		}
		for(new i=0;i<=bounties;i++)
		{
			if(StrEqual(auth,bounty[i],false))
			{
				PrintToChat(attacker,"\x06[Bounty]\x04You got 1 point for killing %s",clientname);
				if(!(GetEventInt(event, "death_flags") & 32))
				{
					GetClientAuthId(attacker, AuthId_Steam2,attackerid, sizeof(attackerid), true);
					new String:basepath[PLATFORM_MAX_PATH], String:basepathmaster[PLATFORM_MAX_PATH];
					Format(basepath,sizeof(basepath),"%s%s/%s.txt",path,auth,attackerid);
					Format(basepathmaster,sizeof(basepathmaster),"%s%s.txt",masterpath,attackerid);
					ReplaceString(basepath, PLATFORM_MAX_PATH, ":","-", false);
					ReplaceString(basepathmaster, PLATFORM_MAX_PATH, ":","-", false);
					new Handle:points=OpenFile(basepath,"at");
					WriteFileString(points,"1",false);
					CloseHandle(points);
					new Handle:pointsmaster=OpenFile(basepathmaster,"at");
					WriteFileString(pointsmaster,"1",false);
					CloseHandle(pointsmaster);
				}
			}
		}
		CloseHandle(dirhndl);
	}
}
public loadbounty()
{
	bountyhndl=OpenFile("addons/sourcemod/data/bounty/bounty.txt","rt");
	if(bountyhndl==INVALID_HANDLE)
	{
		PrintToServer("Bounty file created");
		OpenFile("addons/sourcemod/data/bounty/bounty.txt","w");
		bountyhndl=OpenFile("addons/sourcemod/data/bounty/bounty.txt","rt");
	}
	new String:linedata[32];
	new String:loadpath[PLATFORM_MAX_PATH];
	bounties=0;
	while(ReadFileLine(bountyhndl,linedata,sizeof(linedata)))
	{
		TrimString(linedata);
		bounty[bounties]=linedata;
		Format(loadpath,sizeof(loadpath),"%s%s",path,linedata);
		ReplaceString(loadpath, PLATFORM_MAX_PATH, ":","-", false);
		CreateDirectory(loadpath,7);
		bounties++
	}
	CloseHandle(bountyhndl);
	PrintToServer("Loaded Bounties"); 
}
public Action:bounty_add(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x06[Bounty]\x04Usage: sm_add_bounty <target>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME_LENGTH],String:buffer[MAX_NAME_LENGTH];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[32];
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),COMMAND_FILTER_CONNECTED,buffer,sizeof(buffer),ml);
	if (count <= 0) ReplyToCommand(client,"\x06[Bounty]\x04Bad target");
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		new String:auth[MAX_NAME_LENGTH]="Failure2";
		GetClientAuthId(t, AuthId_Steam2, auth, sizeof(auth), true);
		new bool:found=false;
		for(new a=0;a<bounties;a++)
		{
			if(StrEqual(auth,bounty[a]))
			{
				ReplyToCommand(client,"\x06[Bounty]\x04User already has a bounty!");
				found=true;
			}
		}
		if(found!=true)
		{
			bountyhndl=OpenFile("addons/sourcemod/data/bounty/bounty.txt","at");
			new String:name[MAX_NAME_LENGTH];
			GetClientName(t, name, MAX_NAME_LENGTH);
			bounty[bounties]=auth;
			bounties++;
			if(WriteFileLine(bountyhndl,auth)) ReplyToCommand(client,"\x06[Bounty]\x04Added a bounty to %s",name);
			else ReplyToCommand(client,"Failure");
			CloseHandle(bountyhndl);
		}
	}
	return Plugin_Handled;
}