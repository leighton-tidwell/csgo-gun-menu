#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <retakes>
#include "retakes/generic.sp"
//#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define MENU_TIME_LENGTH 15
#define TOTAL_PISTOL_ROUNDS 6
#define TOTAL_AWPS_PER_TEAM 1
#define TOTAL_FLASHBANGS_CT 5
#define TOTAL_FLASHBANGS_T 3
#define TOTAL_SMOKES_CT 2
#define TOTAL_SMOKES_T 2
#define TOTAL_HE_CT 2
#define TOTAL_HE_T 2
#define TOTAL_MOLOTOVS_CT 1
#define TOTAL_MOLOTOVS_T 1

// Global Variables
int used_t_he = 0;
int used_ct_he = 0;
int used_t_smoke = 0;
int used_ct_smoke = 0;
int used_t_flash = 0;
int used_ct_flash = 0;
int used_t_molotov = 0;
int used_ct_molotov = 0;

// CT Rifle Constants
const int rifle_choice_ct_famas = 1;
const int rifle_choice_ct_m4a4 = 2;
const int rifle_choice_ct_m4a1_s = 3;
const int rifle_choice_ct_aug = 4;
const int rifle_choice_ct_ssg08 = 5;

// CT Pistol Constants
const int pistol_choice_ct_hkp2000 = 1;
const int pistol_choice_ct_usp = 2;
const int pistol_choice_ct_p250 = 3;
const int pistol_choice_ct_fiveseven = 4;
const int pistol_choice_ct_cz = 5;
const int pistol_choice_ct_deagle = 6;
const int pistol_choice_ct_r8 = 7;

// T Rifle Constants
const int rifle_choice_t_galil = 1;
const int rifle_choice_t_ak47 = 2;
const int rifle_choice_t_sg553 = 3;
const int rifle_choice_t_ssg08 = 4;

// T Pistol Constants
const int pistol_choice_t_glock = 1;
const int pistol_choice_t_p250 = 2;
const int pistol_choice_t_tec9 = 3;
const int pistol_choice_t_cz = 4;
const int pistol_choice_t_deagle = 5;
const int pistol_choice_t_r8 = 6;

// Arrays of player choices
int ct_pistol_round_choices[MAXPLAYERS+1];
int t_pistol_round_choices[MAXPLAYERS+1];
int ct_pistol_choices[MAXPLAYERS+1];
int t_pistol_choices[MAXPLAYERS+1];
int ct_rifle_choices[MAXPLAYERS+1];
int t_rifle_choices[MAXPLAYERS+1];
bool awp_choices[MAXPLAYERS+1];
int player_side[MAXPLAYERS+1];

// Cookie Handles
Handle ct_pistol_round_choice_cookie = INVALID_HANDLE;
Handle t_pistol_round_choice_cookie = INVALID_HANDLE;
Handle ct_pistol_choice_cookie = INVALID_HANDLE;
Handle t_pistol_choice_cookie = INVALID_HANDLE;
Handle ct_rifle_choice_cookie = INVALID_HANDLE;
Handle t_rifle_choice_cookie = INVALID_HANDLE;
Handle awp_choice_cookie = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "Retakes: Gun Menu",
	author = "",
	description = "A private gun menu.",
	version = "1.0.0",
	url = ""
};

public void OnPluginStart()
{
	ct_pistol_round_choice_cookie = RegClientCookie("retakes_ct_pistol_round_choice", "Currently selected CT pistol (pistol round) choice.", CookieAccess_Private);
	t_pistol_round_choice_cookie = RegClientCookie("retakes_t_pistol_round_choice", "Currently selected T pistol (pistol round) choice.", CookieAccess_Private);
	ct_pistol_choice_cookie = RegClientCookie("retakes_ct_pistol_choice", "Currently selected CT pistol choice.", CookieAccess_Private);
	t_pistol_choice_cookie = RegClientCookie("retakes_t_pistol_choice", "Currently selected T pistol choice.", CookieAccess_Private);
	ct_rifle_choice_cookie = RegClientCookie("retakes_ct_rifle_choice", "Currently selected CT rifle choice.", CookieAccess_Private);
	t_rifle_choice_cookie = RegClientCookie("retakes_t_rifle_choice", "Currently selected T rifle choice.", CookieAccess_Private);
	awp_choice_cookie = RegClientCookie("retakes_awp_choice", "Currently selected AWP choice.", CookieAccess_Private);
}

public void OnClientConnected(int client) {
	ct_pistol_round_choices[client] = pistol_choice_ct_usp;
	t_pistol_round_choices[client] = pistol_choice_t_glock;
	ct_pistol_choices[client] = pistol_choice_ct_usp;
	t_pistol_choices[client] = pistol_choice_t_glock;
	ct_rifle_choices[client] = rifle_choice_ct_m4a4;
	t_rifle_choices[client] = rifle_choice_t_ak47;
	awp_choices[client] = false;
	player_side[client] = 0;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args) {
	char guns_chat_commands[][] = { "/gun", "/guns", "gun", "guns", ".gun", ".guns", "!gun", "!guns", "gnus"};
	for (int i = 0; i < sizeof(guns_chat_commands); i++) {
		if (strcmp(args[0], guns_chat_commands[i], false) == 0) {
			GiveMainMenu(client);
		}
	}

	return Plugin_Continue;
}

public void Retakes_OnWeaponsAllocated(ArrayList t_players, ArrayList ct_players, Bombsite bombsite) {
	WeaponAllocator(t_players, ct_players, bombsite);
}

// Updates client weapon settings according to their cookies.
// Ref: https://github.com/BatMen/csgo-retakes-splewis-convar-weapon-allocator/blob/master/retakes_standardallocator.sp#L200
public void OnClientCookiesCached(int client) {
	ct_pistol_round_choices[client] = GetCookieInt(client, ct_pistol_round_choice_cookie);
	t_pistol_round_choices[client] = GetCookieInt(client, t_pistol_round_choice_cookie);
	ct_pistol_choices[client] = GetCookieInt(client, ct_pistol_choice_cookie);
	t_pistol_choices[client] = GetCookieInt(client, t_pistol_choice_cookie);
	ct_rifle_choices[client] = GetCookieInt(client, ct_rifle_choice_cookie);
	t_rifle_choices[client] = GetCookieInt(client, t_rifle_choice_cookie);
	awp_choices[client] = GetCookieBool(client, awp_choice_cookie);
}

// Calculate nades
static void SetNades(char nades[NADE_STRING_LENGTH], bool is_terrorist, bool is_pistol_round, int client) {
	nades = "";

	int total_he_allowed = is_terrorist ? TOTAL_HE_T : TOTAL_HE_CT;
	int total_flashbang_allowed = is_terrorist ? TOTAL_FLASHBANGS_T : TOTAL_FLASHBANGS_CT;
	int total_molotov_allowed = is_terrorist ? TOTAL_MOLOTOVS_T : TOTAL_MOLOTOVS_CT;
	int total_smoke_allowed = is_terrorist ? TOTAL_SMOKES_T : TOTAL_SMOKES_CT;

	int he_number = 0;
	int smoke_number = 0;
	int flashbang_number = 0;
	int molotov_number = 0;

	int max_grenades_per_player = 2;
	int max_flashbangs_per_player = 2;

	int random_number;
	int index = 0;

	for (int i = 0; i < 10; i++) {
		random_number = GetRandomInt(1, 4);

		if (max_grenades_per_player <= index)
			break;

		// No nades for default pistol players as they have armor
		if (is_pistol_round && is_terrorist && t_pistol_choices[client] == pistol_choice_t_glock)
			break;

		if (is_pistol_round && !is_terrorist && (ct_pistol_choices[client] == pistol_choice_ct_hkp2000 || ct_pistol_choices[client] == pistol_choice_ct_usp))
			break;
		
		// Only one nade for pistol round
		if (is_pistol_round && index >= 1)
			break;

		switch (random_number) {
			case 1: {
				if ((is_terrorist ? used_t_he : used_ct_he) < total_he_allowed && he_number == 0) {
					nades[index] = 'h';
					index++;
					he_number++;
					if (is_terrorist)
						used_t_he++;
					else
						used_ct_he++;
				}
			}
			case 2: {
				if ((is_terrorist ? used_t_smoke : used_ct_smoke) < total_smoke_allowed && smoke_number == 0) {
					nades[index] = 's';
					index++;
					smoke_number++;
					if (is_terrorist)
						used_t_smoke++;
					else
						used_ct_smoke++;
				}
			}
			case 3: {
				if ((is_terrorist ? used_t_flash : used_t_flash) < total_flashbang_allowed && flashbang_number < max_flashbangs_per_player) {
					nades[index] = 'f';
					index++;
					flashbang_number++;
					if (is_terrorist)
						used_t_flash++;
					else
						used_ct_flash++;
				}
			}
			case 4: {
				if ((is_terrorist ? used_t_molotov : used_ct_molotov) < total_molotov_allowed && molotov_number == 0) {
					nades[index] = is_terrorist ? 'm' : 'i';
					index++;
					molotov_number++;
					if (is_terrorist) 
						used_t_molotov++;
					else
						used_ct_molotov++;
				}
			}
		}
	}	
}

// Actual weapon allocator
public void WeaponAllocator(ArrayList t_players, ArrayList ct_players, Bombsite bombsite) {
	int total_t_players = GetArraySize(t_players);
	int total_ct_players = GetArraySize(ct_players);

	bool is_pistol_round = Retakes_GetRetakeRoundsPlayed() < TOTAL_PISTOL_ROUNDS;

	char primary[WEAPON_STRING_LENGTH];
	char secondary[WEAPON_STRING_LENGTH];
	char nades[NADE_STRING_LENGTH];

	int health = 100;
	int kevlar = 100;
	bool helmet = true;
	bool kit = true;
	bool give_t_awp = true;
	bool give_ct_awp = true;

	int awps_given = 0;
	int[] treated_t_players = new int[total_t_players];
	for (int i = 0; i < total_t_players; i++) {
		int[] non_treated_t_players = new int[total_t_players - i];
		for (int i_not_treated = 0; i_not_treated < (total_t_players - i); i_not_treated++) {
			for (int candidate = 0; candidate < total_t_players; candidate++) {
				bool is_treated = false;
				for (int i_is_treated = 0; i_is_treated < i; i_is_treated++) {
					if(treated_t_players[i_is_treated] == candidate) {
						is_treated = true;
						break;
					}
				}
				if(!is_treated) {
					non_treated_t_players[i_not_treated] = candidate;					
				}
			}
		}

		// pick a random player from the non-treated players
		int random_index = GetRandomInt(0, total_t_players - i - 1);
		int random_player = non_treated_t_players[random_index];
		treated_t_players[i] = random_player;

		int client = GetArrayCell(t_players, random_player);
		player_side[client] = 1;

		primary = "";
		if (!is_pistol_round) {
			int give_awp_randomizer = GetRandomInt(0, 1);
			if(give_t_awp && awp_choices[client] && give_awp_randomizer == 1 && awps_given < TOTAL_AWPS_PER_TEAM) {
				primary = "weapon_awp";
				give_t_awp = false;
				awps_given++;
			} else {
				int player_t_rifle_choice = t_rifle_choices[client];
				switch (player_t_rifle_choice) {
					case rifle_choice_t_sg553:
						primary = "weapon_sg553";
					case rifle_choice_t_galil:
						primary = "weapon_galilar";
					case rifle_choice_t_ssg08:
						primary = "weapon_ssg08";
					default:
						primary = "weapon_ak47";
				}
			}

			int player_t_pistol_choice = t_pistol_choices[client];
			switch (player_t_pistol_choice) {
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

		if (is_pistol_round) {
			int player_t_pistol_round_choice = t_pistol_round_choices[client];
			switch (player_t_pistol_round_choice) {
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

		if (is_pistol_round) {
			helmet = false;
		}

		kevlar = GetKevlar(is_pistol_round, client);
		kit = GetKit(is_pistol_round, client);

		SetNades(nades, true, is_pistol_round, client);

		Retakes_SetPlayerInfo(client, primary, secondary, nades, health, kevlar, helmet, kit);
	}

	awps_given = 0;
	int[] treated_ct_players = new int[total_ct_players];
	for (int i = 0; i < total_ct_players; i++) {
		int[] non_treated_ct_players = new int[total_ct_players - i];
		for (int i_not_treated = 0; i_not_treated < (total_ct_players - i); i_not_treated++) {
			for (int candidate = 0; candidate < total_ct_players; candidate++) {
				bool is_treated = false;
				for (int i_is_treated = 0; i_is_treated < i; i_is_treated++) {
					if(treated_ct_players[i_is_treated] == candidate) {
						is_treated = true;
						break;
					}
				}
				if(!is_treated) {
					non_treated_ct_players[i_not_treated] = candidate;					
				}
			}
		}

		int random_index = GetRandomInt(0, total_ct_players - i - 1);
		int random_player = non_treated_ct_players[random_index];
		treated_ct_players[i] = random_player;

		int client = GetArrayCell(ct_players, random_player);
		player_side[client] = 2;

		primary = "";
		if (!is_pistol_round) {
			int give_awp_randomizer = GetRandomInt(0, 1);
			if(give_ct_awp && awp_choices[client] && give_awp_randomizer == 1 && awps_given < TOTAL_AWPS_PER_TEAM) {
				primary = "weapon_awp";
				give_ct_awp = false;
				awps_given++;
			} else {
				int player_ct_rifle_choice = ct_rifle_choices[client];
				switch (player_ct_rifle_choice) {
					case rifle_choice_ct_famas:
						primary = "weapon_famas";
					case rifle_choice_ct_m4a1_s:
						primary = "weapon_m4a1_silencer";
					case rifle_choice_ct_aug:
						primary = "weapon_aug";
					case rifle_choice_ct_ssg08:
						primary = "weapon_ssg08";
					default:
						primary = "weapon_m4a4";
				}
			}

			int player_ct_pistol_choice = ct_pistol_choices[client];
			switch (player_ct_pistol_choice) {
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
				default:
					secondary = "weapon_usp_silencer";
			}
		}

		if (is_pistol_round) {
			int player_ct_pistol_round_choice = ct_pistol_round_choices[client];
			switch (player_ct_pistol_round_choice) {
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
				default:
					secondary = "weapon_usp_silencer";
			}
		}

		if (is_pistol_round) {
			helmet = false;
		}

		kevlar = GetKevlar(is_pistol_round, client);
		kit = GetKit(is_pistol_round, client);

		SetNades(nades, false, is_pistol_round, client);

		Retakes_SetPlayerInfo(client, primary, secondary, nades, health, kevlar, helmet, kit);
	}
}

// takes the pistol round and client
// if they do not have default pistol for pistol round, they will not have kevlar
public bool GetKevlar(bool is_pistol_round, int client) {
	if (is_pistol_round) {
		if(player_side[client] == 2) {
			// CT Side
			if(ct_pistol_round_choices[client] != pistol_choice_ct_usp || ct_pistol_round_choices[client] != pistol_choice_ct_hkp2000) {
				return false;
			}
			
			return true;
		} 
		else {
			// T Side
			if(t_pistol_round_choices[client] != pistol_choice_t_glock) {
				return false;
			}
			
			return true;
		}
	}

	return true;
}

// takes in the pistol round, and client
public bool GetKit(bool is_pistol_round, int client) {
	if(is_pistol_round) 
		return false;
	return true;
}

// Specific to pistol rounds for CT
public void GiveCTPistolRoundMenu(int client) {
	Handle menu = CreateMenu(CTPistolRoundMenuHandler);
	SetMenuTitle(menu, "Select a CT Pistol (Pistol Round):");
	AddMenuInt(menu, pistol_choice_ct_hkp2000, "P2000");
	AddMenuInt(menu, pistol_choice_ct_usp, "USP-S");
	AddMenuInt(menu, pistol_choice_ct_p250, "P250");
	AddMenuInt(menu, pistol_choice_ct_fiveseven, "Five-Seven");
	AddMenuInt(menu, pistol_choice_ct_cz, "CZ75-Auto");
	AddMenuInt(menu, pistol_choice_ct_deagle, "Desert Eagle");
	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int CTPistolRoundMenuHandler(Handle menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		int client = param1;
		int gun_choice = GetMenuInt(menu, param2);
		ct_pistol_round_choices[client] = gun_choice;
		SetCookieInt(client, ct_pistol_round_choice_cookie, gun_choice);

		if(player_side[client] != 2)
			GiveTPistolRoundMenu(client);
		else
			GiveCTPistolRoundMenu(client);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

// Specific to pistol rounds for T
public void GiveTPistolRoundMenu(int client) {
	Handle menu = CreateMenu(TPistolRoundMenuHandler);
	SetMenuTitle(menu, "Select a T Pistol (Pistol Round):");
	AddMenuInt(menu, pistol_choice_t_glock, "Glock");
	AddMenuInt(menu, pistol_choice_t_p250, "P250");
	AddMenuInt(menu, pistol_choice_t_tec9, "Tec-9");
	AddMenuInt(menu, pistol_choice_t_deagle, "Deagle");
	AddMenuInt(menu, pistol_choice_t_r8, "R8");
	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int TPistolRoundMenuHandler(Handle menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		int client = param1;
		int gun_choice = GetMenuInt(menu, param2);
		t_pistol_round_choices[client] = gun_choice;
		SetCookieInt(client, t_pistol_round_choice_cookie, gun_choice);

		if(player_side[client] != 1)
			GiveCTPistolRoundMenu(client);
		else
			GiveTPistolRoundMenu(client);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

// All rounds for CT
public void GiveCTPistolMenu(int client) {
	Handle menu = CreateMenu(CTPistolMenuHandler);
	SetMenuTitle(menu, "Select a CT Pistol:");
	AddMenuInt(menu, pistol_choice_ct_hkp2000, "P2000");
	AddMenuInt(menu, pistol_choice_ct_usp, "USP-S");
	AddMenuInt(menu, pistol_choice_ct_p250, "P250");
	AddMenuInt(menu, pistol_choice_ct_fiveseven, "Five-Seven");
	AddMenuInt(menu, pistol_choice_ct_cz, "CZ75-Auto");
	AddMenuInt(menu, pistol_choice_ct_deagle, "Desert Eagle");
	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int CTPistolMenuHandler(Handle menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		int client = param1;
		int gun_choice = GetMenuInt(menu, param2);
		ct_pistol_choices[client] = gun_choice;
		SetCookieInt(client, ct_pistol_choice_cookie, gun_choice);

		if(player_side[client] != 2)
			GiveTPistolMenu(client);
		else
			GiveCTPistolMenu(client);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

// All rounds for T
public void GiveTPistolMenu(int client) {
	Handle menu = CreateMenu(TPistolMenuHandler);
	SetMenuTitle(menu, "Select a T Pistol:");
	AddMenuInt(menu, pistol_choice_t_glock, "Glock");
	AddMenuInt(menu, pistol_choice_t_p250, "P250");
	AddMenuInt(menu, pistol_choice_t_tec9, "Tec-9");
	AddMenuInt(menu, pistol_choice_t_cz, "CZ");
	AddMenuInt(menu, pistol_choice_t_deagle, "Deagle");
	AddMenuInt(menu, pistol_choice_t_r8, "R8");
	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int TPistolMenuHandler(Handle menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		int client = param1;
		int gun_choice = GetMenuInt(menu, param2);
		t_pistol_choices[client] = gun_choice;
		SetCookieInt(client, t_pistol_choice_cookie, gun_choice);

		if(player_side[client] != 1)
			GiveCTPistolMenu(client);
		else
			GiveTPistolMenu(client);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

// All rounds for CT
public void GiveCTRifleMenu(int client) {
	Handle menu = CreateMenu(CTRifleMenuHandler);
	SetMenuTitle(menu, "Select a CT Rifle:");
	AddMenuInt(menu, rifle_choice_ct_famas, "FAMAS");
	AddMenuInt(menu, rifle_choice_ct_m4a4, "M4A4");
	AddMenuInt(menu, rifle_choice_ct_m4a1_s, "M4A1-S");
	AddMenuInt(menu, rifle_choice_ct_aug, "AUG");
	AddMenuInt(menu, rifle_choice_ct_ssg08, "SSG 08");
	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int CTRifleMenuHandler(Handle menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		int client = param1;
		int gun_choice = GetMenuInt(menu, param2);
		ct_rifle_choices[client] = gun_choice;
		SetCookieInt(client, ct_rifle_choice_cookie, gun_choice);
		GiveAwpMenu(client);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

// All rounds for T
public void GiveTRifleMenu(int client) {
	Handle menu = CreateMenu(TRifleMenuHandler);
	SetMenuTitle(menu, "Select a T Rifle:");
	AddMenuInt(menu, rifle_choice_t_galil, "Galil");
	AddMenuInt(menu, rifle_choice_t_ak47, "AK-47");
	AddMenuInt(menu, rifle_choice_t_sg553, "SG 553");
	AddMenuInt(menu, rifle_choice_t_ssg08, "SSG 08");
	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int TRifleMenuHandler(Handle menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		int client = param1;
		int gun_choice = GetMenuInt(menu, param2);
		t_rifle_choices[client] = gun_choice;
		SetCookieInt(client, t_rifle_choice_cookie, gun_choice);

		GiveAwpMenu(client);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public void GiveAwpMenu(int client) {
	Handle menu = CreateMenu(AwpMenuHandler);
	SetMenuTitle(menu, "Allow yourself to recieve AWPs?");
	AddMenuBool(menu, true, "Yes");
	AddMenuBool(menu, false, "No");
	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int AwpMenuHandler(Handle menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		int client = param1;
		int allow_awps = GetMenuInt(menu, param2);
		awp_choices[client] = allow_awps;
		SetCookieBool(client, awp_choice_cookie,allow_awps);
		CloseHandle(menu);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

// Main Menu
public void GiveMainMenu(int client) {
	Handle menu = CreateMenu(MainMenuHandler);
	SetMenuTitle(menu, "Main menu: ");
	AddMenuInt(menu, 1, "Select T rifles");
	AddMenuInt(menu, 2, "Select T pistols");
	AddMenuInt(menu, 3, "Select T pistol round weapon");
	AddMenuInt(menu, 4, "Select CT rifles");
	AddMenuInt(menu, 5, "Select CT pistols");
	AddMenuInt(menu, 6, "Select CT pistol round weapon");
	AddMenuInt(menu, 7, "Recieve awps?");
	DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int MainMenuHandler(Handle menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		int client = param1;
		int open_menu = GetMenuInt(menu, param2);
		switch (open_menu) {
			case 1:
				GiveTRifleMenu(client);
			case 2:
				GiveTPistolMenu(client);
			case 3:
				GiveTPistolRoundMenu(client);
			case 4:
				GiveCTRifleMenu(client);
			case 5:
				GiveCTPistolMenu(client);
			case 6:
				GiveCTPistolRoundMenu(client);
			case 7:
				GiveAwpMenu(client);
		}
		CloseHandle(menu);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}