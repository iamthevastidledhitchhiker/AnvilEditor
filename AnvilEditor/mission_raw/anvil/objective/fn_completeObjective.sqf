/*
	Author: Will Hart

	Description:
	  Called when an objective has been completed, updates the task and global objective state

	Parameter(s):
	  _this: ARRAY, the objective being completed

    Example:
	  objective call AFW_fnc_completeObjective;
	
	Returns:
	  Nothing
*/

#include "defines.sqf"

if (!isServer) exitWith {};

private ["_id", "_task_name", "_str", "_likely", "_ammo_mkr", "_special_mkr"];

_id = O_ID(_this);
_task_name = O_EOS_NAME(_this);

// check if we have already handled completion
if ((_id in completed_objectives) and !(_id in incomplete_objectives)) exitWith {
	diag_log "      Ignoring attempt to complete an objective which has already been completed";
};

// remove item from incomplete if it is still in there
if (_id in incomplete_objectives) then {
	diag_log "      Most likely completing a forcibly completed objective";
	incomplete_objectives = incomplete_objectives - [_id];
	publicVariable "incomplete_objectives";
};

// complete the task
_null = [O_TASK_NAME(_this), "SUCCEEDED", true] spawn BIS_fnc_taskSetState;

// update the marker
O_MARKER(_this) setMarkerType "mil_flag";
O_MARKER(_this) setMarkerColor "ColorGreen";

// deactivate and delete the old marker and EOS spawn area
[[O_EOS_NAME(_this)]] call EOS_Deactivate;
deleteMarker O_EOS_NAME(_this);

// update the completed and current objectives list
if (!(_id in completed_objectives)) then {
	APPEND(completed_objectives, _id);
	publicVariable "completed_objectives";
};

current_objectives = current_objectives - [_id];
publicVariable "current_objectives";

// enable any new objectives
_id call AFW_fnc_spawnObjectives;

// set the objective completed variable
server setVariable [O_OBJ_NAME(_this), true, true];

// check if we are spawning counterattacks
if (("AFW_RandomCounterAttacks" call BIS_fnc_getParamValue) == 1) then {
    _likely = "AFW_CounterAttackLikelihood" call BIS_fnc_getParamValue;
    
    if (_likely > random 100) then {
        diag_log "Launching counter attack";
        _str = "AFW_CounterAttackStrength" call BIS_fnc_getParamValue;
        _nul = [[_task_name],[_str,2],[1,1],[(floor random (_str - 1))],[(floor random (_str - 1)),2],[0,1,enemyTeam],[(floor random 20),1,120,TRUE,FALSE]] call Bastion_Spawn;
    } else {
		diag_log "No counter attack launched";
	};
};

// check if we have a new spawn point here
if (O_SPAWN(_this)) then {
    // notify
	[
		[
			"RespawnAdded", 
			[
				"Respawn added", 
				format ["New respawn at %1", O_DESCRIBE(_this)], 
				"", 
				"\A3\ui_f\data\gui\cfg\Hints\tactical_view_ca.paa"
			]
		],
		"bis_fnc_showNotification"
	] spawn BIS_fnc_MP;
    
    // create a new respawn position
    [WEST, O_POS(_this)] call BIS_fnc_addRespawnPosition;
};

// check if we want to add a new ammo box here
_ammo_mkr = O_AMMO(_this);
if (_ammo_mkr != "") then {
    // place the ammobox
    [_ammo_mkr, "AFW_fnc_spawnAmmo", nil, true ] spawn BIS_fnc_MP;
	
	[
		[
			"ArmoryGearAdded", 
			[
				format ["Ammo spawned at %1", O_DESCRIBE(_this)], 
				"", 
				"\A3\ui_f\data\gui\cfg\Hints\ammotype_ca.paa"
			]
		],
		"bis_fnc_showNotification"
	] spawn BIS_fnc_MP;
};

// check if we want to add a special weapons box
_special_mkr = O_SPECIAL(_this);
if (_special_mkr != "") then {
	[_special_mkr, "AFW_fnc_spawnSpecialWeapon", nil, true ] spawn BIS_fnc_MP;
	[
		[
			"ArmoryGearAdded", 
			[
				format ["Special weapons at %1", O_DESCRIBE(_this)], 
				"", 
				"\A3\ui_f\data\gui\cfg\Hints\ammotype_ca.paa"
			]
		],
		"bis_fnc_showNotification"
	] spawn BIS_fnc_MP;
};

// delete the task after a 30 second delay
if (deleteTasks == 1) then {
	sleep 30;
	[
		[
			O_TASK_NAME(_this), 
			friendlyTeam],
		"BIS_fnc_deleteTask",
		nil,
		true
	] spawn BIS_fnc_MP;
};

// check if we have completed all objectives
if (count completed_objectives == count objective_list) then {
	[
		["TaskSucceeded", ["", "All objectives completed"]],
		"bis_fnc_showNotification"
	] spawn BIS_fnc_MP;
	
	all_objectives_complete = true;
	publicVariable 'all_objectives_complete';
};
