#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <retakes>
#include "retakes/generic.sp"

#pragma semicolon 1
#pragma newdecls required

#define MENU_TIME_LENGTH 15

// Global Variables
int				given_t_he								 = 0;
int				given_ct_he								 = 0;
int				given_t_smoke							 = 0;
int				given_ct_smoke						 = 0;
int				given_t_flash							 = 0;
int				given_ct_flash						 = 0;
int				given_t_molotov						 = 0;
int				given_ct_molotov					 = 0;

// CT Rifle Constants
const int rifle_choice_ct_famas			 = 1;
const int rifle_choice_ct_m4a4			 = 2;
const int rifle_choice_ct_m4a1_s		 = 3;
const int rifle_choice_ct_aug				 = 4;
const int rifle_choice_ct_ssg08			 = 5;

// CT Pistol Constants
const int pistol_choice_ct_hkp2000	 = 1;
const int pistol_choice_ct_usp			 = 2;
const int pistol_choice_ct_p250			 = 3;
const int pistol_choice_ct_fiveseven = 4;
const int pistol_choice_ct_cz				 = 5;
const int pistol_choice_ct_deagle		 = 6;
const int pistol_choice_ct_r8				 = 7;

// CT Force Constants
const int force_choice_ct_ssg08			 = 1;
const int force_choice_ct_deagle		 = 2;
const int force_choice_ct_mp9				 = 3;
const int force_choice_ct_famas			 = 4;

// T Rifle Constants
const int rifle_choice_t_galil			 = 1;
const int rifle_choice_t_ak47				 = 2;
const int rifle_choice_t_sg553			 = 3;
const int rifle_choice_t_ssg08			 = 4;

// T Pistol Constants
const int pistol_choice_t_glock			 = 1;
const int pistol_choice_t_p250			 = 2;
const int pistol_choice_t_tec9			 = 3;
const int pistol_choice_t_deagle		 = 4;
const int pistol_choice_t_r8				 = 5;

// T Force Constants
const int force_choice_t_ssg08			 = 1;
const int force_choice_t_deagle			 = 2;
const int force_choice_t_mac10			 = 3;
const int force_choice_t_galil			 = 4;

// Arrays of player choices
int				ct_pistol_round_choices[MAXPLAYERS + 1];
int				t_pistol_round_choices[MAXPLAYERS + 1];
int				ct_force_round_choices[MAXPLAYERS + 1];
int				t_force_round_choices[MAXPLAYERS + 1];
int				ct_pistol_choices[MAXPLAYERS + 1];
int				t_pistol_choices[MAXPLAYERS + 1];
int				ct_rifle_choices[MAXPLAYERS + 1];
int				t_rifle_choices[MAXPLAYERS + 1];
bool			awp_choices[MAXPLAYERS + 1];

// Cookie Handles
Handle		ct_pistol_round_choice_cookie;
Handle		t_pistol_round_choice_cookie;
Handle		ct_force_round_choice_cookie;
Handle		t_force_round_choice_cookie;
Handle		ct_pistol_choice_cookie;
Handle		t_pistol_choice_cookie;
Handle		ct_rifle_choice_cookie;
Handle		t_rifle_choice_cookie;
Handle		awp_choice_cookie;

// Convar Handles
Handle		sm_total_pistol_rounds;
Handle		sm_force_round_frequency;
Handle		sm_t_awp_enabled;
Handle		sm_ct_awp_enabled;
Handle		sm_t_nades_molotov_max;
Handle		sm_ct_nades_molotov_max;
Handle		sm_t_nades_flash_max;
Handle		sm_ct_nades_flash_max;
Handle		sm_t_nades_smoke_max;
Handle		sm_ct_nades_smoke_max;
Handle		sm_t_nades_he_max;
Handle		sm_ct_nades_he_max;

public Plugin myinfo =
{
	name				= "CS Haven: Gun Menu",
	author			= "CS Haven",
	description = "Official gun menu for CS Haven servers",
	version			= "2.1.0",
	url					= "https://cs-haven.com/"
};

public void OnPluginStart()
{
	// Register client cookies
	ct_pistol_round_choice_cookie = RegClientCookie("ct_pistol", "", CookieAccess_Private);
	t_pistol_round_choice_cookie	= RegClientCookie("t_pistol", "", CookieAccess_Private);
	ct_force_round_choice_cookie	= RegClientCookie("ct_force", "", CookieAccess_Private);
	t_force_round_choice_cookie		= RegClientCookie("t_force", "", CookieAccess_Private);
	ct_pistol_choice_cookie				= RegClientCookie("ct_secondary", "", CookieAccess_Private);
	t_pistol_choice_cookie				= RegClientCookie("t_secondary", "", CookieAccess_Private);
	ct_rifle_choice_cookie				= RegClientCookie("ct_primary", "", CookieAccess_Private);
	t_rifle_choice_cookie					= RegClientCookie("t_primary", "", CookieAccess_Private);
	awp_choice_cookie							= RegClientCookie("awp_choice", "", CookieAccess_Private);

	// Register ConVars
	sm_total_pistol_rounds				= CreateConVar("sm_total_pistol_rounds", "5", "Total number of pistol rounds in a match (first x rounds)");
	sm_force_round_frequency			= CreateConVar("sm_force_round_frequency", "5", "Frequency of force rounds (every x rounds)");
	sm_t_awp_enabled							= CreateConVar("sm_t_awp_enabled", "1", "Enable AWP for Terrorists (0 = no awps)");
	sm_ct_awp_enabled							= CreateConVar("sm_ct_awp_enabled", "1", "Enable AWP for Counter-Terrorists (0 = no awps)");
	sm_t_nades_molotov_max				= CreateConVar("sm_t_nades_molotov_max", "1", "Maximum molotovs allowed for the terrorist side (0 = disabled)");
	sm_ct_nades_molotov_max				= CreateConVar("sm_ct_nades_molotov_max", "1", "Maximum molotovs allowed for the ct side (0 = disabled)");
	sm_t_nades_smoke_max					= CreateConVar("sm_t_nades_smoke_max", "1", "Maximum smokes allowed for the t side (0 = disabled)");
	sm_ct_nades_smoke_max					= CreateConVar("sm_ct_nades_smoke_max", "1", "Maximum smokes allowed for the ct side (0 = disabled)");
	sm_t_nades_flash_max					= CreateConVar("sm_t_nades_flash_max", "1", "Maximum flashes allowed for the t side (0 = disabled)");
	sm_ct_nades_flash_max					= CreateConVar("sm_ct_nades_flash_max", "1", "Maximum flashes allowed for the ct side (0 = disabled)");
	sm_t_nades_he_max							= CreateConVar("sm_t_nades_he_max", "1", "Maximum hes allowed for the t side (0 = disabled)");
	sm_ct_nades_he_max						= CreateConVar("sm_ct_nades_he_max", "1", "Maximum hes allowed for the ct side (0 = disabled)");
}

public void OnClientConnected(int client)
{
	// Set default values for player choices
	ct_pistol_round_choices[client] = pistol_choice_ct_usp;
	t_pistol_round_choices[client]	= pistol_choice_t_glock;
	ct_force_round_choices[client]	= force_choice_ct_deagle;
	t_force_round_choices[client]		= force_choice_t_deagle;
	ct_pistol_choices[client]				= pistol_choice_ct_usp;
	t_pistol_choices[client]				= pistol_choice_t_glock;
	ct_rifle_choices[client]				= rifle_choice_ct_m4a4;
	t_rifle_choices[client]					= rifle_choice_t_ak47;
	awp_choices[client]							= false;
}

public void Retakes_OnGunsCommand(int client)
{
	GiveMainMenu(client);
}

public void Retakes_OnWeaponsAllocated(ArrayList tPlayers, ArrayList ctPlayers, Bombsite bombsite)
{
	WeaponAllocator(tPlayers, ctPlayers, bombsite);
}

public void OnClientCookiesCached(int client)
{
	if (IsFakeClient(client))
		return;

	// Update player choices according to their cookies
	ct_pistol_round_choices[client] = GetCookieInt(client, ct_pistol_round_choice_cookie);
	t_pistol_round_choices[client]	= GetCookieInt(client, t_pistol_round_choice_cookie);
	ct_force_round_choices[client]	= GetCookieInt(client, ct_force_round_choice_cookie);
	t_force_round_choices[client]		= GetCookieInt(client, t_force_round_choice_cookie);
	ct_pistol_choices[client]				= GetCookieInt(client, ct_pistol_choice_cookie);
	t_pistol_choices[client]				= GetCookieInt(client, t_pistol_choice_cookie);
	ct_rifle_choices[client]				= GetCookieInt(client, ct_rifle_choice_cookie);
	t_rifle_choices[client]					= GetCookieInt(client, t_rifle_choice_cookie);
	awp_choices[client]							= GetCookieBool(client, awp_choice_cookie);
}

public void WeaponAllocator(ArrayList tPlayers, ArrayList ctPlayers, Bombsite bombsite)
{
	int tCount			 = tPlayers.Length;
	int ctCount			 = ctPlayers.Length;

	// Reset global counters
	given_t_he			 = 0;
	given_ct_he			 = 0;
	given_t_smoke		 = 0;
	given_ct_smoke	 = 0;
	given_t_flash		 = 0;
	given_ct_flash	 = 0;
	given_t_molotov	 = 0;
	given_ct_molotov = 0;

	char primary[WEAPON_STRING_LENGTH];
	char secondary[WEAPON_STRING_LENGTH];
	char nades[NADE_STRING_LENGTH];
	int	 health		 = 100;
	int	 kevlar		 = 100;
	bool helmet		 = true;
	bool kit			 = true;

	bool giveTawp	 = true;
	bool giveCtawp = true;

	// Disable AWP based on Convars
	if (GetConVarInt(sm_ct_awp_enabled) == 0) giveCtawp = false;
	if (GetConVarInt(sm_t_awp_enabled) == 0) giveTawp = false;

	// Determine if we are on a pistol round, or a force round
	bool isPistolRound = Retakes_GetRetakeRoundsPlayed() < GetConVarInt(sm_total_pistol_rounds);
	bool isForceRound	 = !isPistolRound && Retakes_GetRetakeRoundsPlayed() % GetConVarInt(sm_force_round_frequency) == 0;

	if (!isPistolRound && !isForceRound)
	{
		PrintToServer("It is currently a rifle round.");
		PrintToChatAll("\x04[Retakes]\x01 It is currently a rifle round.");
	}
	else if (isForceRound) {
		PrintToServer("It is currently a force round.");
		PrintToChatAll("\x04[Retakes]\x01 It is currently a force round.");
	}
	else {
		PrintToServer("It is currently a pistol round.");
		PrintToChatAll("\x04[Retakes]\x01 It is currently a pistol round.");
	}

	// Random array of terrorists processed in random order
	int[] tPlayersRandom		= new int[tCount];
	int tPlayersRandomIndex = 0;
	int tPlayersRandomCount = 0;
	while (tPlayersRandomCount < tCount)
	{
		int	 client					 = tPlayers.Get(GetRandomInt(0, tCount - 1));
		bool alreadySelected = false;
		for (int i = 0; i < tPlayersRandomCount; i++)
		{
			if (tPlayersRandom[i] == client)
			{
				alreadySelected = true;
				break;
			}
		}
		if (!alreadySelected)
		{
			tPlayersRandom[tPlayersRandomIndex] = client;
			tPlayersRandomIndex++;
			tPlayersRandomCount++;

			// PrintToChat(client, "We are on round %d. It is %c a pistol round, and %c a force round.", Retakes_GetRetakeRoundsPlayed(), isPistolRound ? 'y' : 'n', isForceRound ? 'y' : 'n');

			// Buy Round
			if (!isPistolRound && !isForceRound)
			{
				// AWP
				int randomAwpChance = GetRandomInt(0, 1);
				if (giveTawp && awp_choices[client] && randomAwpChance)
				{
					primary	 = "weapon_awp";
					giveTawp = false;
				}
				else {
					// Rifle
					int playerRifleChoice = t_rifle_choices[client];
					// PrintToChat(client, "Rifle choice: %d", playerRifleChoice);

					switch (playerRifleChoice)
					{
						case rifle_choice_t_sg553:
							primary = "weapon_sg556";
						case rifle_choice_t_galil:
							primary = "weapon_galilar";
						case rifle_choice_t_ssg08:
							primary = "weapon_ssg08";
						default:
							primary = "weapon_ak47";
					}
				}

				// Secondary
				int playerPistolChoice = t_pistol_choices[client];
				// PrintToChat(client, "Pistol choice: %d", playerPistolChoice);

				switch (playerPistolChoice)
				{
					case pistol_choice_t_p250:
						secondary = "weapon_p250";
					case pistol_choice_t_tec9:
						secondary = "weapon_tec9";
					case pistol_choice_t_deagle:
						secondary = "weapon_deagle";
					case pistol_choice_t_r8:
						secondary = "weapon_revolver";
					default:
						secondary = "weapon_glock";
				}
			}

			// Force Round
			else if (isForceRound)
			{
				int playerForceChoice = t_force_round_choices[client];
				// PrintToChat(client, "Force choice: %d", playerForceChoice);

				switch (playerForceChoice)
				{
					case force_choice_t_ssg08:
					{
						primary		= "weapon_ssg08";
						secondary = "weapon_glock";
					}
					case force_choice_t_mac10:
					{
						primary		= "weapon_mac10";
						secondary = "weapon_glock";
					}
					case force_choice_t_galil:
					{
						primary		= "weapon_galilar";
						secondary = "weapon_glock";
					}
					default:
						secondary = "weapon_deagle";
				}
			}

			// Pistol Round
			else
			{
				int playerPistolChoice = t_pistol_round_choices[client];
				// PrintToChat(client, "Pistol round choice: %d", playerPistolChoice);

				switch (playerPistolChoice)
				{
					case pistol_choice_t_p250:
						secondary = "weapon_p250";
					case pistol_choice_t_tec9:
						secondary = "weapon_tec9";
					case pistol_choice_t_deagle:
						secondary = "weapon_deagle";
					case pistol_choice_t_r8:
						secondary = "weapon_revolver";
					default:
						secondary = "weapon_glock";
				}

				helmet = false;

				if (playerPistolChoice != pistol_choice_t_glock && playerPistolChoice != 0)
				{
					// PrintToChat(client, "For some reason, you don't have kevlar...");
					kevlar = false;
				}

				kit = false;
			}

			SetNades(nades, isPistolRound, true);
			// PrintToChat(client, "Nade choices: %s", nades);

			Retakes_SetPlayerInfo(client, primary, secondary, nades, health, kevlar, helmet, kit);
		}
	}

	// Random array of counter terrorists processed in random order
	int[] ctPlayersRandom		 = new int[ctCount];
	int ctPlayersRandomIndex = 0;
	int ctPlayersRandomCount = 0;
	while (ctPlayersRandomCount < ctCount)
	{
		int	 client					 = ctPlayers.Get(GetRandomInt(0, ctCount - 1));
		bool alreadySelected = false;
		for (int i = 0; i < ctPlayersRandomCount; i++)
		{
			if (ctPlayersRandom[i] == client)
			{
				alreadySelected = true;
				break;
			}
		}
		if (!alreadySelected)
		{
			ctPlayersRandom[ctPlayersRandomIndex] = client;
			ctPlayersRandomIndex++;
			ctPlayersRandomCount++;

			// PrintToChat(client, "We are on round %d. It is %c a pistol round, and %c a force round.", Retakes_GetRetakeRoundsPlayed(), isPistolRound ? 'y' : 'n', isForceRound ? 'y' : 'n');

			// Buy Round
			if (!isPistolRound && !isForceRound)
			{
				// AWP
				int randomAwpChance = GetRandomInt(0, 1);
				if (giveCtawp && awp_choices[client] && randomAwpChance)
				{
					primary		= "weapon_awp";
					giveCtawp = false;
				}
				else {
					// Rifle
					int playerRifleChoice = ct_rifle_choices[client];
					// PrintToChat(client, "Rifle choice: %d", playerRifleChoice);

					switch (playerRifleChoice)
					{
						case rifle_choice_ct_famas:
							primary = "weapon_famas";
						case rifle_choice_ct_m4a1_s:
							primary = "weapon_m4a1_silencer";
						case rifle_choice_ct_aug:
							primary = "weapon_aug";
						case rifle_choice_ct_ssg08:
							primary = "weapon_ssg08";
						default:
							primary = "weapon_m4a1";
					}
				}

				// Secondary
				int playerPistolChoice = ct_pistol_choices[client];
				// PrintToChat(client, "Pistol choice: %d", playerPistolChoice);

				switch (playerPistolChoice)
				{
					case pistol_choice_ct_p250:
						secondary = "weapon_p250";
					case pistol_choice_ct_fiveseven:
						secondary = "weapon_fiveseven";
					case pistol_choice_ct_cz:
						secondary = "weapon_cz75a";
					case pistol_choice_ct_deagle:
						secondary = "weapon_deagle";
					case pistol_choice_ct_r8:
						secondary = "weapon_revolver";
					case pistol_choice_ct_hkp2000:
						secondary = "weapon_hkp2000";
					default:
						secondary = "weapon_usp_silencer";
				}
			}

			// Force Round
			else if (isForceRound) {
				int playerForceChoice = ct_force_round_choices[client];
				// PrintToChat(client, "Force choice: %d", playerForceChoice);

				switch (playerForceChoice)
				{
					case force_choice_ct_ssg08:
					{
						primary		= "weapon_ssg08";
						secondary = "weapon_usp_silencer";
					}
					case force_choice_ct_mp9:
					{
						primary		= "weapon_mp9";
						secondary = "weapon_usp_silencer";
					}
					case force_choice_ct_famas:
					{
						primary		= "weapon_famas";
						secondary = "weapon_usp_silencer";
					}
					default:
						secondary = "weapon_deagle";
				}
			}

			// Pistol Round
			else {
				int playerPistolChoice = ct_pistol_round_choices[client];
				// PrintToChat(client, "Pistol round choice: %d", playerPistolChoice);

				switch (playerPistolChoice)
				{
					case pistol_choice_ct_p250:
						secondary = "weapon_p250";
					case pistol_choice_ct_fiveseven:
						secondary = "weapon_fiveseven";
					case pistol_choice_ct_cz:
						secondary = "weapon_cz75a";
					case pistol_choice_ct_deagle:
						secondary = "weapon_deagle";
					case pistol_choice_ct_r8:
						secondary = "weapon_revolver";
					case pistol_choice_ct_hkp2000:
						secondary = "weapon_hkp2000";
					default:
						secondary = "weapon_usp_silencer";
				}

				helmet = false;

				if (playerPistolChoice > 2)
				{
					// PrintToServer("Pistol choice: %d", playerPistolChoice);
					kevlar = false;
				}

				kit = false;
			}
			SetNades(nades, isPistolRound, false);

			// PrintToChat(client, "Nade choices: %s", nades);

			Retakes_SetPlayerInfo(client, primary, secondary, nades, health, kevlar, helmet, kit);
		}
	}
}

// Set nades
static void SetNades(char nades[NADE_STRING_LENGTH], bool isPistolRound, bool terrorist)
{
	if (isPistolRound)
	{
		nades = "";
		return;
	}

	int	 max_molotov				 = terrorist ? GetConVarInt(sm_t_nades_molotov_max) : GetConVarInt(sm_ct_nades_molotov_max);
	int	 max_flash					 = terrorist ? GetConVarInt(sm_t_nades_flash_max) : GetConVarInt(sm_ct_nades_flash_max);
	int	 max_smoke					 = terrorist ? GetConVarInt(sm_t_nades_smoke_max) : GetConVarInt(sm_ct_nades_smoke_max);
	int	 max_he							 = terrorist ? GetConVarInt(sm_t_nades_he_max) : GetConVarInt(sm_ct_nades_he_max);

	bool reached_max_molotov = terrorist ? given_t_molotov >= max_molotov : given_ct_molotov >= max_molotov;
	bool reached_max_flash	 = terrorist ? given_t_flash >= max_flash : given_ct_flash >= max_flash;
	bool reached_max_smoke	 = terrorist ? given_t_smoke >= max_smoke : given_ct_smoke >= max_smoke;
	bool reached_max_he			 = terrorist ? given_t_he >= max_he : given_ct_he >= max_he;

	int	 rand								 = GetRandomInt(0, 4);
	if (rand == 0)
	{
		nades = "";
	}

	if (rand == 1 && !reached_max_smoke)
	{
		nades = "s";
		if (terrorist) given_t_smoke++;
		else given_ct_smoke++;
	}

	if (rand == 2 && !reached_max_flash)
	{
		nades = "f";
		if (terrorist) given_t_flash++;
		else given_ct_flash++;
	}

	if (rand == 3 && !reached_max_he)
	{
		nades = "h";
		if (terrorist) given_t_he++;
		else given_ct_he++;
	}

	if (rand == 4 && !reached_max_molotov)
	{
		nades = terrorist ? "m" : "i";
		if (terrorist) given_t_molotov++;
		else given_ct_molotov++;
	}
}

// Main Menu
public void GiveMainMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MainMenu);
	menu.SetTitle("Main Menu:");
	AddMenuInt(menu, 1, "T Buy Round (RIFLE/AWP)");
	AddMenuInt(menu, 2, "T Force Round");
	AddMenuInt(menu, 3, "T Pistol Round");
	AddMenuInt(menu, 4, "CT Buy Round (RIFLE/AWP)");
	AddMenuInt(menu, 5, "CT Force Round");
	AddMenuInt(menu, 6, "CT Pistol Round");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MenuHandler_MainMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client = param1;
		int choice = GetMenuInt(menu, param2);

		switch (choice)
		{
			case 1:
				GiveTBuyMenu(client);
			case 2:
				GiveTForceMenu(client);
			case 3:
				GiveTPistolRoundMenu(client);
			case 4:
				GiveCTBuyMenu(client);
			case 5:
				GiveCTForceMenu(client);
			case 6:
				GiveCTPistolRoundMenu(client);
		}
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
}

// T Rifle Menu
public void GiveTBuyMenu(int client)
{
	Menu menu = new Menu(MenuHandler_TBuyMenu);
	menu.SetTitle("T Buy Round:");
	AddMenuInt(menu, rifle_choice_t_galil, "Galil");
	AddMenuInt(menu, rifle_choice_t_ak47, "AK-47");
	AddMenuInt(menu, rifle_choice_t_sg553, "SG 553");
	AddMenuInt(menu, rifle_choice_t_ssg08, "SSG 08");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MenuHandler_TBuyMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client							= param1;
		int choice							= GetMenuInt(menu, param2);
		t_rifle_choices[client] = choice;
		SetCookieInt(client, t_rifle_choice_cookie, choice);

		GiveTPistolMenu(client);
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
}

// T Pistol Menu (For T Buy Round)
public void GiveTPistolMenu(int client)
{
	Menu menu = new Menu(MenuHandler_TBuyPistolMenu);
	menu.SetTitle("T Buy Round Pistol:");
	AddMenuInt(menu, pistol_choice_t_glock, "Glock");
	AddMenuInt(menu, pistol_choice_t_p250, "P250");
	AddMenuInt(menu, pistol_choice_t_tec9, "Tec-9");
	AddMenuInt(menu, pistol_choice_t_deagle, "Deagle");
	AddMenuInt(menu, pistol_choice_t_r8, "R8");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MenuHandler_TBuyPistolMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client							 = param1;
		int choice							 = GetMenuInt(menu, param2);
		t_pistol_choices[client] = choice;
		SetCookieInt(client, t_pistol_choice_cookie, choice);

		GiveAwpMenu(client);
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
}

// T Force Menu
public void GiveTForceMenu(int client)
{
	Menu menu = new Menu(MenuHandler_TForceMenu);
	menu.SetTitle("T Force Round:");
	AddMenuInt(menu, force_choice_t_ssg08, "SSG 08");
	AddMenuInt(menu, force_choice_t_deagle, "Deagle");
	AddMenuInt(menu, force_choice_t_mac10, "MAC 10");
	AddMenuInt(menu, force_choice_t_galil, "Galil");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MenuHandler_TForceMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client										= param1;
		int choice										= GetMenuInt(menu, param2);
		t_force_round_choices[client] = choice;
		SetCookieInt(client, t_force_round_choice_cookie, choice);

		GiveMainMenu(client);
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
}

// T Pistol Round Menu
public void GiveTPistolRoundMenu(int client)
{
	Menu menu = new Menu(MenuHandler_TPistolRoundMenu);
	menu.SetTitle("T Pistol Round:");
	AddMenuInt(menu, pistol_choice_t_glock, "Glock");
	AddMenuInt(menu, pistol_choice_t_p250, "P250");
	AddMenuInt(menu, pistol_choice_t_tec9, "Tec-9");
	AddMenuInt(menu, pistol_choice_t_deagle, "Deagle");
	AddMenuInt(menu, pistol_choice_t_r8, "R8");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MenuHandler_TPistolRoundMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client										 = param1;
		int choice										 = GetMenuInt(menu, param2);
		t_pistol_round_choices[client] = choice;
		SetCookieInt(client, t_pistol_round_choice_cookie, choice);

		GiveMainMenu(client);
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
}

// CT Rifle Menu
public void GiveCTBuyMenu(int client)
{
	Menu menu = new Menu(MenuHandler_CTBuyMenu);
	menu.SetTitle("CT Buy Round:");
	AddMenuInt(menu, rifle_choice_ct_famas, "FAMAS");
	AddMenuInt(menu, rifle_choice_ct_m4a4, "M4A4");
	AddMenuInt(menu, rifle_choice_ct_m4a1_s, "M4A1-S");
	AddMenuInt(menu, rifle_choice_ct_aug, "AUG");
	AddMenuInt(menu, rifle_choice_ct_ssg08, "SSG 08");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MenuHandler_CTBuyMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client							 = param1;
		int choice							 = GetMenuInt(menu, param2);
		ct_rifle_choices[client] = choice;
		SetCookieInt(client, ct_rifle_choice_cookie, choice);

		GiveCTBuyPistolMenu(client);
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
}

// CT Pistol Menu
public void GiveCTBuyPistolMenu(int client)
{
	Menu menu = new Menu(MenuHandler_CTPistolMenu);
	menu.SetTitle("CT Buy Round Pistol:");
	AddMenuInt(menu, pistol_choice_ct_hkp2000, "P2000");
	AddMenuInt(menu, pistol_choice_ct_usp, "USP-S");
	AddMenuInt(menu, pistol_choice_ct_p250, "P250");
	AddMenuInt(menu, pistol_choice_ct_fiveseven, "Five-Seven");
	AddMenuInt(menu, pistol_choice_ct_cz, "CZ75-Auto");
	AddMenuInt(menu, pistol_choice_ct_deagle, "Desert Eagle");
	AddMenuInt(menu, pistol_choice_ct_r8, "R8");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MenuHandler_CTPistolMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client								= param1;
		int choice								= GetMenuInt(menu, param2);
		ct_pistol_choices[client] = choice;
		SetCookieInt(client, ct_pistol_choice_cookie, choice);

		GiveAwpMenu(client);
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
}

// CT Force Menu
public void GiveCTForceMenu(int client)
{
	Menu menu = new Menu(MenuHandler_CTForceMenu);
	menu.SetTitle("CT Force Round:");
	AddMenuInt(menu, force_choice_ct_ssg08, "SSG 08");
	AddMenuInt(menu, force_choice_ct_deagle, "Deagle");
	AddMenuInt(menu, force_choice_ct_mp9, "MP9");
	AddMenuInt(menu, force_choice_ct_famas, "FAMAS");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MenuHandler_CTForceMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client										 = param1;
		int choice										 = GetMenuInt(menu, param2);
		ct_force_round_choices[client] = choice;
		SetCookieInt(client, ct_force_round_choice_cookie, choice);

		GiveMainMenu(client);
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
}

// CT Pistol Round Menu
public void GiveCTPistolRoundMenu(int client)
{
	Menu menu = new Menu(MenuHandler_CTPistolRoundMenu);
	menu.SetTitle("CT Pistol Round:");
	AddMenuInt(menu, pistol_choice_ct_hkp2000, "P2000");
	AddMenuInt(menu, pistol_choice_ct_usp, "USP-S");
	AddMenuInt(menu, pistol_choice_ct_p250, "P250");
	AddMenuInt(menu, pistol_choice_ct_fiveseven, "Five-Seven");
	AddMenuInt(menu, pistol_choice_ct_cz, "CZ75-Auto");
	AddMenuInt(menu, pistol_choice_ct_deagle, "Desert Eagle");
	AddMenuInt(menu, pistol_choice_ct_r8, "R8");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MenuHandler_CTPistolRoundMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client											= param1;
		int choice											= GetMenuInt(menu, param2);
		ct_pistol_round_choices[client] = choice;
		SetCookieInt(client, ct_pistol_round_choice_cookie, choice);

		GiveMainMenu(client);
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
}

// AWP Menu
public void GiveAwpMenu(int client)
{
	Menu menu = new Menu(MenuHandler_AwpMenu);
	menu.SetTitle("AWP:");
	AddMenuBool(menu, true, "Yes");
	AddMenuBool(menu, false, "No");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MenuHandler_AwpMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int	 client					= param1;
		bool choice					= GetMenuBool(menu, param2);
		awp_choices[client] = choice;
		SetCookieBool(client, awp_choice_cookie, choice);

		GiveMainMenu(client);
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
}